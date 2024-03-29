#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 
#include 'tbiconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} WMTRAY01
Description //Integra��o de produtos Tray - Ecommerce
            // Envia os produtos cadastrados no Protheus para a Tray.
@param xParam Parameter Description
@return xRet Return Nil
@author  - Rafael S.Silva
@since: 30-09-2019 /*/
//--------------------------------------------------------------
User Function WMTRAY01()

    Local cEndPoint  := ""
    Local cPath      := "/web_api/products"
    Local oProdData  := Nil
    Local oProdJson  := Nil
    Local oJsonRet   := Nil
    Local aHeadStr    := {}
    Local cAliasPrd  := GetNextAlias()
    Local lKeep      := .F.
    Local lChangePrd := .F.
    Local aClose     := {"SB1","DA0","DA1","SB5","SB2"}
    Local lRestOk    := .F.
    Private oRestProd  := Nil

    cEndPoint := U_TrayUrl() //Busco a URL de acesso as API's da Tray - https://{api_address}

    //Retorna o Token de acesso 
    //Geralmente o token expira em 30 dias
    cToken    := U_GETTOKEN()
    
    oRestProd     := FWRest():New(cEndPoint)

    //Defino o tipo de envio/retorno da requisi��o
    aAdd(aHeadStr,"Content-Type: application/json")
    
    BeginSql Alias cAliasPrd
        %noparser%

        SELECT * 
        FROM 
            %table:SZB%
        WHERE
            ZB_INTEGRA = %exp:'1'% AND 
            %notdel%

    EndSql

    While ( !(cAliasPrd)->(Eof())  )

        oProdJson := JsonObject():New() //Instancio um novo objeto Json
        oJsonRet  := JsonObject():New() //Instancio um novo objeto Json

        oProdData  := WMPRODEC():NEW((cAliasPrd)->ZB_PRODERP) //Instancio a classe que carrega os dados do produto

        //Verifico se o produto existe no banco, se n�o passo para o pr�ximo
        if !oProdData:IsProdOk()
            (cAliasPrd)->(DbSkip())
            Loop
        Endif

        //Adicionar os campos obrigat�rios para cadastrar um produto        
        oProdData:setRequired()

        //Atualiza os dados principais do produto
        //Descri��o, ncm, ean...
        oProdData:GetMainData()

        //carrega dados de pre�o e valor do produto
        oProdData:getprodprc()
        
        //Carrega as dimess�es do produto
        oProdData:getDimensions()

        //Carrega o saldo do produuto em estoque
        oProdData:getStock()

        //Verifico se o produto j� foi cadastrado
        lChangePrd := SZB->ZB_CADOK == "S" .or. !Empty(SZB->ZB_PRODECO)

    
        //Defino a disponibilidade do produto
        //0= indispon�vel, 1 = Dispon�vel
        oProdData:SetAvailabilty(1)

        oProdJson['Product'] := JsonObject():New()    
        oProdJson['Product']['ean']  :=  AllTrim(oProdData:ean)
        oProdJson['Product']['ncm']  :=  AllTrim(oProdData:ncm)
        oProdJson['Product']['name'] :=  AllTrim(oProdData:name)
        oProdJson['Product']['description'] := AllTrim(oProdData:description)
        oProdJson['Product']['description_small'] := AllTrim(oProdData:description_small)
        oProdJson['Product']['price'] := oProdData:price	
        oProdJson['Product']['cost_price'] := oProdData:cost_price
        oProdJson['Product']['promotional_price'] := oProdData:promotional_price
        oProdJson['Product']['start_promotion'] := oProdData:start_promotion
        oProdJson['Product']['end_promotion']   := oProdData:end_promotion 
        oProdJson['Product']['brand'] := oProdData:brand
        oProdJson['Product']['model'] := AllTrim(oProdData:model)
        oProdJson['Product']['weight'] := oProdData:weight
        oProdJson['Product']['length'] := oProdData:length
        oProdJson['Product']['width']  := oProdData:width
        oProdJson['Product']['height'] := oProdData:height
        oProdJson['Product']['stock']  := oProdData:stock
        oProdJson['Product']['category_id'] := '33915'//oProdData:category_id
        oProdJson['Product']['available'] := AllTrim(oProdData:available)
        oProdJson['Product']['availability'] := "Disponivel"//oProdData:availability
        oProdJson['Product']['availability_days'] := oProdData:availability_days
        oProdJson['Product']['reference'] := AllTrim(oProdData:reference)
        oProdJson['Product']['related_categories'] := '19921,19925' //oProdData:related_categories//'3,5,7';
        //oProdJson['Product']['release_date'] := ''
        oProdJson['Product']['shortcut'] := ''
        oProdJson['Product']['virtual_product'] := '0'
        
        cPost := oProdJson:toJson()
        
        cPath := "/web_api/products/"
        If lChangePrd
            cPath += AllTrim((cAliasPrd)->ZB_PRODECO)+'/'//Se for Altera��o, passo o ID do produto no e-commerce
        endif

        cPath += "?access_token="+cToken

        oRestProd:setPath(cPath)
        oRestProd:SetPostParams(cPost)
        
        if lChangePrd
        	lRestOk := oRestProd:Put(aHeadStr,cPost)
        Else
        	lRestOk := oRestProd:Post(aHeadStr)
        Endif
        
        if lRestOk
            oJsonRet:fromJson(oRestProd:cReSult)

            if Select("SZB") ==  0  
                DbSelectArea("SZB")
            endif

            if ValType(oJsonRet) == "J"

                If SZB->( DbSeek(xFilial("SZB") + oProdData:cProduto ) )
                    RecLock("SZB",.F.)
                    SZB->ZB_PRODECO := AllTrim(oJsonRet['id'])
                    SZB->ZB_INTEGRA := '1'
                    SZB->ZB_DATAINT := Date()
                    SZB->ZB_HORAINT := Time()
                    SZB->ZB_JSONENV := cPost
                    SZB->ZB_JSONREC := oRestProd:cReSult
                    SZB->ZB_CADOK   := 'S'
                    SZB->(Msunlock())
                Endif
            Endif

        else
            If IsBlind()
                Conout('N�o foi poss�vel cadastrado o produto '+ oProdData:cProduto +' no e-commerce (Erro na requisi��o). ')
                Conout('Retorno: '+ oRestProd:GetLastError())
                Conout(oRestProd:cResult)                                        
            else                                    
                MsgInfo('N�o foi poss�vel cadastrado o produto '+ oProdData:cProduto +' no e-commerce (Erro na requisi��o). ' + CRLF + ; 
                		'Retorno: '+ oRestProd:GetLastError() + CRLF + ;
                		oRestProd:cResult,'WMTRAY01')
            Endif
        endif

        (cAliasPrd)->(DbSkip())

    EndDo

    //AreaClose(aClose)


Return()


Static function AreaClose(aClose)

    Local nAux := 0

    if Len(aClose) > 0
        
        For nAux := 1 to Len(aClose)
            
            if DbSelectArea(aClose[nAux]) > 0
                &(aClose[nAux])->( DbCloseArea() )
            Endif

        Next nAux

    Endif

return


user function JBTRAY01()

    RpcSetType(3)
    RpcSetEnv('02','01')
    
    U_WMTRAY01()
    
return 
