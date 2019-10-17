#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch'
#include 'tbiconn.ch' 

//--------------------------------------------------------------
/*{Protheus.doc} WMTRAY02
Description //Integração de pedidos Tray - E-commerce
            // Cadastra os pedidos craidos no Tray E-commerce no protheus.
@param xParam Parameter Description
@return xRet Return Nil
@author  - Rafael S.Silva
@since: 03-10-2019 */

Static  nTotAtu  := 0

User Function WMTRAY02(cPage,lTest,cJSontest)

    Local cEndPoint  := ''
    Local cJson      := ''
    Local cPath      := '/web_api/orders/'
    Local oRestOrder := Nil
    Local oOrderJson := Nil
    Local aHeader    := {}
    Local lMThread   := .F.
    Local lJsonOk    := .F.
    Local lTestOK    := .F.
    Local nOrders    := 0
    Local nMaxOrder  := 0
    Local nLimit     := 0
    Local ntotOrders := 0

    Default cPage    := '1'
    Default lTest    := .F.
    Default cJSontest := ''

    oOrderJson := JsonObject():New() //Inicio novo objeto Json

    If !lTest
        nMaxOrder  := SuperGetMv('MV_XMAXORD',,30) //Quantidade máxima de pedidos por thread
        cEndPoint  := AllTrim(U_TrayUrl()) //EndPoint de coneÃ§Ã£o com a Tray - https://{api_address}
        cToken     := AllTrim(U_GETTOKEN()) //Token de acesso ao Endpoint    
        oRestOrder := FWRest():New(cEndPoint)

        aAdd(aHeader,"Content-Type: application/json")
        //aadd(aHeader,'Content-Type: multipart/form-data')

        cPath += "?access_token="+cToken

        if Val(cPage) > 1
            cPath += "&page="+cPage
        Endif

        oRestOrder:SetPath(cPath)

        if oRestOrder:Get(aHeader)
            oOrderJson:fromJson(oRestOrder:cResult)

            lJsonOk     := ValType(oOrderJson) == "J"
            ntotOrders  := oOrderJson['paging']['total']
            nLimit      := oOrderJson['paging']['limit']
            nOrders      := Len(oOrderJson['Orders'])

            if lJsonOk
                lMThread := nOrders > nMaxOrder
                OrderQueue(oOrderJson,lMThread,nMaxOrder,cPage,nLimit,ntotOrders)//grava pedido na fila 
            Else
                Conout("Não foi possível realizar o parser do objeto [WMTRAY002 - PRODUCÃO] ")
            Endif

        Else
            Conout("================ERRO AO CONSUMIR O SERVIÇO DE CONSULTA DE PEDIDOS - TRAY=============")
            Conout(oOrderJson:GerLastErro())
            Conout("================ERRO AO CONSUMIR O SERVIÇO DE CONSULTA DE PEDIDOS - TRAY=============")
            //TODO: Gravar log de erros
        Endif
    Else //Json recebido via parâmetro - Teste
        oOrderJson:fromJson(cJSontest)

        lJsonOk := ValType(oOrderJson) == "J"
        
        if  lJsonOk
            if ValType(oOrderJson['Order']) == "A" .AND. len(oOrderJson['Order']) > 0
                lTestOK := .T.
            Endif

            return lTestOK
        Else
            if IsBlind()
                Conout("Não foi possível realizar o parser do objeto [WMTRAY002 - TESTE] ")
            Else    
                MsgAlert("Não foi possível realizar o parser do objeto [WMTRAY002 - TESTE] ")
            Endif
        Endif

    Endif

Return


//--------------------------------------------------------------
/*{Protheus.doc} OrderQueue
Description //grava pedidos na fila de execução
            //verificando se serão abertas multiplas threads.
@param xParam 
       oOrders -> Pedidos do tipo Obj
       lMult   -> Indica se serão abertas multiplcas threads
       nMaxOrders-> Indica o número máximo de pedidos por Thread
@return Nil
@author  - Rafael S.Silva
@since: 03-10-2019 */
//--------------------------------------------------------------
Static Function OrderQueue(oOrders,lMult,nMaxOrders,cPage,nLimit,nTotal)
    
    Local lIsOrdOk := .F.
    Local lOrderOK := .F.
    Local nOrder   := 0
    Local ntotOrders := 0
    Local nTotTrd    := 0
    Local nIni       := 0
    Local nFim       := 0
    Local nCont      := 0
    Local nZ         := 0
    Local aAux       := {}
    Local aData      := {}
    local cOrderID   := ''

    Default oOrders    := Nil 
    Default nMaxOrders := SuperGetMv("MV_XMAXORD",,15) //Quantidade máxima de pedidos por thread
    Default lMult      := len(nMaxOrders) > nMaxOrders


    lIsOrdOk := ValType(oOrders) == "J" .and. Len(oOrders['Orders']) > 0

    ntotOrders := Len(oOrders['Orders'])
    nTotTrd := IIF(Mod(ntotOrders,nMaxOrders) > 0 , Round(ntotOrders/nMaxOrders+0.5,0), (ntotOrders/nMaxOrders) ) 

    If lIsOrdOk

        If Select("SZC") == 0        
            DbSelectArea('SZC')
            SZC->( dBsetOrder(1) ) //ZC_FILIAL+ZC_IDECOMM
        Endif

        If lMult
            For nOrder := 1 to ntotOrders

                nIni := (nOrder-1)*nMaxOrders+1
                nFim := Min(nOrder*nMaxOrders,ntotOrders)
                aAux := {}
                nCont ++

                For nZ := nIni to nFim
                    aAdd(aAux,oOrders['Orders'][nZ])
                Next                                                              
                
                sleep(1000)
                
                startjob("U_OrdThreads",getenvserver(),.T., aAux,cEmpAnt,cFilAnt)
                
                aadd(aSemaforo, _cArqSemaf)

            Next nOrder
        Endif

        //Se não for multiplas threads, apenas gravo os Id's na fila
        if ( !lMult )
            For nOrder := 1 to ntotOrders
                If ( VALTYPE(oOrders['Orders'][nOrder]['Order']['OrderStatus']) == "U" ; 
                    .and. Empty(oOrders['Orders'][nOrder]['Order']['status']) .or. ;
                    VALTYPE(oOrders['Orders'][nOrder]['Order']['OrderStatus']) == "A" )
                    Loop
                Endif
                lOrderOK   := Upper(oOrders['Orders'][nOrder]['Order']['OrderStatus']['type']) == "OPEN"
                cOrderID   := AllTrim(oOrders['Orders'][nOrder]['Order']['id'])
                cOrderID   := PadR(cOrderID,TamSX3('ZC_IDECOMM')[1] )
                If  ( !SZC->( DbSeek(xFilial('SZC') + cOrderID ) )  .and. lOrderOK )
                    SZC->( RecLock('SZC', .T.) )
                    SZC->ZC_IDECOMM := cOrderID
                    SZC->ZC_DTREC   := Date()
                    SZC->ZC_HORAREC := Time()
                    SZC->ZC_SAIU    := 'N' //identifica se os dados do pedido já foram gravados
                    SZC->( MsUnlock() )
                Endif
            Next nOrder
        Endif

    Endif

    nTotAtu += nLimit
    if nTotal > nTotAtu
        cPage := Soma1(cPage)
        U_WMTRAY02(cPage)
    Endif

Return 


//--------------------------------------------------------------
/*/{Protheus.doc} OrdThreads
Description //Grava pedidos na fila via MultThread
@param oOrders Parameter Description
@return  Nil
@author  - Rafael S.Silva
@since: 03-10-2019 /*/
//--------------------------------------------------------------
User function OrdThreads(aOrders,cCompany,cBranch)

    Local lIsParamOk := ValType(aOrders) == "A" .and. Len(aOrders) > 0
    Local nOrder     := 0
    Local ntotOrders := 0
    Local lOrderOK   := .F.

    //garanto que a empresa e filial serão mantidas
    //cEmpAnt := cCompany
    //cFilAnt := cBranch

    if lIsParamOk

        ntotOrders := Len(aOrders) > 0

        DbSelectArea("SZC")
        SZC->(dBsetOrder(1))

        For nX := 1 to Len(aOrders)
            For nOrder := 1 to ntotOrders
                lOrderOK   := Upper(oOrders['Orders'][nOrder]['OrderStatus']:GetJsonText('type')) == "FINALIZADO"
                cOrderID   := oOrders['Orders'][nOrder]:GetJsonText('id')
                cOrderID   := PadR(cOrderID,TamSX3('ZC_IDECOMM')[1] )

                If ! ( SZC->( DbSeek(xFilial('SZC') + cOrderID ) )  .and. lOrderOK )
                    SZC->( RecLock('SZC', .T.) )
                    SZC->ZC_IDECOMM := cOrderID
                    SZC->ZC_DTREC   := Date()
                    SZC->ZC_HORAREC := Time()
                    SZC->ZC_SAIU    := 'N'
                    SZC->( MsUnlock() )
                Endif

            Next nOrder        
        Next nX

    Endif


return