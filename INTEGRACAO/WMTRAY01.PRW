#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} WMTRAY01
Description //Integrao de produtos Tray - Ecommerce
            // Envia os produtos cadastrados no Protheus para a Tray.
@param xParam Parameter Description
@return xRet Return Nil
@author  - Rafael S.Silva
@since: 30-09-2019 /*/
//--------------------------------------------------------------
User Function WMTRAY01()

    Local cEndPoint  := ""
    Local cPath      := "/products/"
    Local oRestProd  := Nil
    Local oProdData  := Nil
    Local oProdJson  := Nil
    Local oJsonRet   := Nil
    Local aHeader    := {}
    Local cAliasPrd  := GetNextAlias()
    Local lKeep      := .F.
    Local lChangePrd := .F.
    Local aClose     := {"SB1","DA0","DA1","SB5","SB2"}

    RpcSetType(3)
    RpcSetEnv('99','01')

    cEndPoint := U_TrayUrl() //Busco a URL de acesso as API's da Tray - https://{api_address}

    //Retorna o Token de acesso 
    //Geralmente o token expira em 30 dias
    cToken    := U_GETTOKEN()
    
    oRestProd     := FWRest():New(cEndPoint)

    //Defino o tipo de envio/retorno da requisição
    aAdd(aHeader,"Content-Type: application/json")
    
    BeginSql Alias cAliasPrd
        %noparser%

        SELECT * 
        FROM 
            %table:SZB%
        WHERE
            ZB_INTEG = %exp:'1'% 
            %notdel%

    EndSql

    While ( !(cAliasPrd)->(Eof())  )

        oProdJson := JsonObject():New() //Instancio um novo objeto Json
        oJsonRet  := JsonObject():New() //Instancio um novo objeto Json

        oProdData  := WMPRODEC():NEW((cAliasPrd)->ZB_PRODERP) //Instancio a classe que carrega os dados do produto

        //Verifico se o produto existe no banco, se não passo para o próximo
        if !oProdData:IsProdOk()
            (cAliasPrd)->(DbSkip())
            Loop
        Endif

        //Adicionar os campos obrigatórios para cadastrar um produto        
        oProdData:setRequired()

        //Atualiza os dados principais do produto
        //Descrição, ncm, ean...
        oProdData:GetMainData()

        //carrega dados de preo e valor do produto
        oProdData:getprodprc()
        
        //Carrega as dimenses do produto
        oProdData:getDimensions()

        //Carrega o saldo do produuto em estoque
        oProdData:getStock()

        //Verifico se o produto já foi cadastrado
        lChangePrd := SZB->ZB_CADOK == "S"

    
        //Defino a disponibilidade do produto
        //0= indisponível, 1 = Disponível
        oProdData:SetAvailabilty(1)

        oProdJson['Product'] := JsonObject():New()    
        oProdJson['Product']['ean']  :=  oProdData:ean
        oProdJson['Product']['ncm']  :=  oProdData:ncm
        oProdJson['Product']['name'] :=  oProdData:name
        oProdJson['Product']['description'] := oProdData:description
        oProdJson['Product']['description_small'] := oProdData:description_small
        oProdJson['Product']['price'] := oProdData:price
        oProdJson['Product']['cost_price'] := oProdData:cost_price
        oProdJson['Product']['promotional_price'] := oProdData:promotional_price
        oProdJson['Product']['start_promotion'] := oProdData:start_promotion
        oProdJson['Product']['end_promotion']   := oProdData:end_promotion 
        oProdJson['Product']['brand'] := oProdData:brand
        oProdJson['Product']['model'] := oProdData:model
        oProdJson['Product']['weight'] := oProdData:weight
        oProdJson['Product']['length'] := oProdData:length
        oProdJson['Product']['width']  := oProdData:width
        oProdJson['Product']['height'] := oProdData:height
        oProdJson['Product']['stock']  := oProdData:stock
        oProdJson['Product']['category_id'] := oProdData:category_id
        oProdJson['Product']['available'] := oProdData:available
        oProdJson['Product']['availability'] := oProdData:availability
        oProdJson['Product']['availability_days'] := oProdData:availability_days
        oProdJson['Product']['reference'] := oProdData:reference
        oProdJson['Product']['related_categories'] = oProdData:related_categories//'3,5,7';
        oProdJson['Product']['release_date'] := ''
        oProdJson['Product']['shortcut'] := ''
        oProdJson['Product']['virtual_product'] := '0'
        
        cPost := oProdJson:toJson()//Serializa o Objeto Json

        If lChangePrd
            cPath += AllTrim((cAliasPrd)->ZB_PRODECO)+'/'//Se for Alteração, passo o ID do produto no e-commerce
        endif

        cPath+= "?access_token="+cToken

        oRestProd:setPath(cPath)
        oRestProd:SetPostParams(cPost)

        if oRestProd:Post(aHeader)
            oJsonRet:fromJson(oRestProd:cReSult)

            if Selcet("SZB") ==  0  
                SZB->(DbSelectArea())
            endif

            if ValType(oJsonRet) == "J"
                oJsonRet['id']

                If ( DbSeek(xFilial("SZB") + oProdData:cProduto ) )
                    RecLock("SZB",.F.)
                    SZB->ZB_PRODECO := AllTrim(oJsonRet['id'])
                    SZB->ZB_INTEGRA := '1'
                    SZB->ZB_DATAREC := Date()
                    SZB->ZB_HORAREC := Time()
                    SZB->ZB_JSONREC := oRestProd:cReSult
                    SZB->ZB_CADOK   := 'S'
                    SZB->(Msunlock())
                Endif
            Endif

        else
            If IsBlind()
                MsgInfo('Não foi possível cadastrado o produto '+ oProdData:cProduto +' no e-commerce (Erro na requisição). ','WMTRAY01')
            else
                Conout('Não foi possível cadastrado o produto '+ oProdData:cProduto +' no e-commerce (Erro na requisição). ')
            Endif
        endif

        (cAliasPrd)->(DbSkip())

    EndDo

    AreaClose(aClose)


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

