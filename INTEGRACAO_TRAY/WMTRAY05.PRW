#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} WMTRAY05
Description //Altera status dos pedidos no E-commerce da TRAY
@param xParam Parameter Description
@return xRet Return Description
@author  - Rafael S.Silva
@since: 16-10-2019 /*/
//--------------------------------------------------------------
User Function WMTRAY05()
    
    Local cAliasT   := GetNextAlias()
    Local cAliasPed := GetNextAlias()
    Local aOrder    := {} //usado para controle de quantidade de pedidos
    Local cStatus   := ""
    Local nZDRec    := 0
    Local lUpdNf    := .F.

    BeginSql Alias cAliasT
        %noparser%

        SELECT R_E_C_N_O_ AS ZD_RECNO,* 
        FROM 
            %table:SZD%
        WHERE
            ZD_FILIAL = %xfilial:SZD% AND
            ZD_FINALIZ = %exp:'N'% AND 
            %notdel%
    EndSql

    While !(cAliasT)->(Eof())

        cPedido := (cAliasT)->ZD_IDERP
        cOrder  := (cAliasT)->ZD_IDECOMM
        nZDRec  := (cAliasT)->ZD_RECNO

        If !Empty(cPedido)

            BeginSql Alias cAliasPed
                %noparser%
                
                SELECT 										   
                     C5_CLIENTE
                    ,C5_LOJACLI
                    ,C5_NOTA
                    ,C6_NUM
                    ,C6_NOTA
                    ,C6_SERIE
                    ,C6_PRODUTO
                    ,C6_QTDVEN
                    ,C6_VALOR
                    ,ISNULL(F2_CHVNFE,'') AS F2_CHVNFE
                    ,C5_EMISSAO
                    ,(C5_VOLUME1 + C5_VOLUME2 + C5_VOLUME3 + C5_VOLUME4) AS VOLUMES
                    ,F2_FRETE                          
                FROM 
                    %table:SC6% SC6               
                INNER JOIN 
                    %table:SC5%  SC5         
                    ON C5_FILIAL = %xFilial:SC5%
                    AND C6_NUM = C5_NUM  
                    AND SC5.%notdel%
                LEFT JOIN 
                    %table:SF2% SF2
                    ON F2_FILIAL = %xFilial:SF2%
                    AND C6_NOTA = F2_DOC 
                    AND C6_SERIE = F2_SERIE                       
                    AND C6_CLI = F2_CLIENTE                       
                    AND C6_LOJA = F2_LOJA                         
                    AND SF2.%notdel%
                WHERE 
                    C6_FILIAL = %xFilial:SF2%
                    AND C6_NUM = %exp:cPedido% 			   
                    AND SC6.%notdel%
                    
            EndSql

            aOrder := {}

            While ! (cAliasPed)->(Eof())

                if ( aScan(aOrder, { |x|  AllTrim(x) == AllTrim((cAliasPed)->C6_NUM) } ) ) == 0

                    if  !Empty((cAliasPed)->F2_DOC)
                        lUpdNf   := .T.
                        cStatus  := u_getEvent(1)
                        cNfiscal := (cAliasPed)->F2_DOC
                        cSerieNf := (cAliasPed)->F2_SERIE

                        SZD->(DbGoTo(nZDRec))
                        RecLock('SZD',.F.)
                        SZD->ZD_NOTA  := cNfiscal
                        SZD->ZD_SERIE := cSerieNf
                        
                        SZD->(Msunlock())

                        invoiceUpd(nZDRec,cOrder,cNfiscal,cSerieNf)
                    Else
                        cStatus := u_getEvent(2)
                    Endif

                    aAdd(aOrder, AllTrim((cAliasPed)->C6_NUM))

                Endif

                (cAliasPed)->(DbSkip())

            EndDo
        Else
            cStatus := u_getEvent(1)
        Endif

        statusUpd(cStatus)//Atualizo status do pedido

        (cAliasT)->(DbSkip())

    EndDo
    
    (cAliasT)->(DbCloseArea())
    (cAliasPed)->(DbCloseArea())

Return()


static function invoiceUpd(nRecno,cPedido,cNota,cSerieNf)
    Local lIsParamOk := ValType(cNota) == "C" .and. ValType(cNota) == "C" 
    Local cToken     := "?access_token=" + U_GETTOKEN()
    Local cUrl       := U_TRAYURL()
    Local cPath      := "/orders/:id/invoices/"
    Local cStatusRet := ""
    Local aHeadOut   := {"Content-Type: application/json"}
    Local oInvoice   := FwRest():New(cUrl)
    Local oJsonEnv   := JsonObject():New()
    Local oJsonRet   := JsonObject():New()
    Local oCFOPData 
    Local TMPNF      := GetNextAlias()
    Local cAliasProd := GetNextAlias()
    Local aProdutos  := {}

    if lIsParamOk

        cPath := StrTran(cPath, ":id",cPedido)
        cPath += cToken

        oInvoice:SetPath(cPath)

        BeginSql Alias TMPNF  
            %noparser%

            SELECT
                 F2_VALFAT
                ,F2_CHVNFE
                ,D2_DOC
                ,D2_SERIE
                ,D2_COD
                ,D2_EMISSAO
                ,D2_CF
            FROM    
                %table:SD2% SD2
            INNER JOIN
                %table:SF2% SF2 ON
                F2_FILIAL = %xFilial:SF2%
                AND F2_DOC = D2_DOC 
                AND F2_SERIE = D2_SERIE 
                AND F2_CLIENTE = D2_CLIENTE
                AND F2_LOJA = D2_LOJA     
            INNER JOIN
                %table:SZB% SZB ON
                ZB_FILIAL = %xFilial:SZB%
                AND ZB_PRODERP = D2_COD 
                AND SZB.D_E_L_E_T_ = ' '                            
            WHERE
                D2_FILIAL = %xFilial:SD2%
                AND D2_DOC = %exp:cNota%
                AND D2_SERIE = %exp:cSerieNf%
                AND SD2.%notdel%
                AND SF2.%notdel%

        EndSql

        aProdutos := {}
        lHeader   := .T.
        While (TMPNF)->(Eof())

            if lHeader  
                lHeader   := .F.
                oJsonEnv['issue_date']  := SubStr((TMPNF)->D2_EMISSAO,1,4) + '-' + SubStr((TMPNF)->D2_EMISSAO,5,2) + '-' + SubStr((TMPNF)->D2_EMISSAO,7,2)
                oJsonEnv['number']      := (TMPNF)->D2_DOC
                oJsonEnv['serie']       := (TMPNF)->D2_SERIE
                oJsonEnv['value']       := (TMPNF)->F2_VALFAT
                oJsonEnv['key']         := AllTrim((TMPNF)->F2_CHVNFE)
            Endif

            oCFOPData  := JsonObject():New()
            oCFOPData['product_id']   := AllTrim((TMPNF)->ZB_PRODECO)
            oCFOPData['variation_id'] := AllTrim((TMPNF)->ZB_PRODECO)
            oCFOPData['cfop']         := AllTrim((TMPNF)->D2_CF) 

            aAdd(aProdutos,oCFOPData)

            FreeObj(oCFOPData)

            (TMPNF)->(DbSkip()) 
        EndDo

        oJsonEnv['ProductCfop'] := aProdutos  

        oInvoice:SetPostParams(oJsonEnv:ToJson())    

        if oInvoice:Post(aHeadOut)
            oJsonRet:fromJson(oInvoice:cResult)
            
            SZD->(DbGoTo(nRecno))
            
            RecLock('SZD',.F.)
            SZD->ZD_NOTA  := cNota
            SZD->ZD_IDNOTA := oJsonRet['id']
            SZD->(Msunlock())
        Else
            ConOut("=============================================================================")
            ConOut("ERRO CRIAR NOTA FISCAL NO E-COMMERCE")
            ConOut("ERRO: " + oInvoice:getLastError())
            ConOut(oInvoice:cResult)
            ConOut("=============================================================================")
        Endif
   
    Endif

return


static function statusUpd(cStatus)
    Local lIsParamOk := ValType(cStatus) == "C"
    Local cToken     := U_GETTOKEN()
    Local cUrl       := U_TRAYURL()
    Local cPath      := "/orders/"
    Local cStatusRet := ""
    Local aHeadOut   := {"Content-Type: application/json"}
    Local oStatus    := FwRest():New(cUrl)
    Local oJsonPed   := JsonObject():New()

    If lIsParamOk

        oJsonPed['Order'] := JsonObject():New()
        oJsonPed['Order']['status_id'] := 


        oStatus:Put()

    Endif

return
