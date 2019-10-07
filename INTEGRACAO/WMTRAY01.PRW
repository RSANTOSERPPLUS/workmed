#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} WMTRAY01
Description //Integração de produtos Tray - Ecommerce
            // Envia os produtos cadastrados no Protheus para a Tray.
@param xParam Parameter Description
@return xRet Return Nil
@author  - Rafael S.Silva
@since: 30-09-2019 /*/
//--------------------------------------------------------------
User Function WMTRAY01()

    Local cEndPoint  := ""
    Local cUserApi   := ""
    Local cPath      := ""
    Local oRestProd  := Nil
    Local oProdData  := Nil
    Local oProdJson  := Nil
    Local aHeader    := {}
    Local cAliasPrd  := GetNextAlias()
    Local lKeep      := .T.

    oProdJson := JsonObject():New() //Inicio novo objeto Json
    cEndPoint := AllTrim(GetMv("MV_XURLECO")) //EndPoint de coneção com a Tray - https://{api_address}/products
    cToken    := AllTrim(GetMv("MV_XTOKECO")) //Token de acesso ao Endpoint    
    oRestProd     := FWRest():New(cEndPoint)

    aAdd(aHeader,"Content-Type: application/json")

    oRestProd:setPath("/products/?access_token="+cToken)

    BeginSql Alias cAliasPrd
        %noparser%

        SELECT * FROM %table:SZB%
        WHERE
            ZB_INTEG = %eXP:'1'% 
            %notdel%

    EndSql

    While ( !(cAliasPrd)->(Eof())  )

        oProdData  := WMPRODEC((cAliasPrd)->ZB_PRODERP):NEW() //Instancio a classe que gera os dados do produto

        lKeep := .T.
        
        //Atualiza os dados principais do produto
        if lKeep .and. !oProdData:GetMainData()
            lKeep := .F.
        Endif

        //carrega dados de pre�o e valor do produto
        if lKeep .and. !oProdData:getprodprc()
            lKeep := .F.
        Endif

        //Retorna as dimens�es do produto
        if lKeep .and. !oProdData:getDimensions()
            lKeep := .F.
        Endif

        if lKeep .and. !oProdData:getBalance()
            lKeep := .F.
        endif

        if lKeep
            oProdJson['Product']['ean']  :=  oProdData:ean
            oProdJson['Product']['ncm']  :=  oProdData:ncm
            oProdJson['Product']['name'] :=  oProdData:name
            oProdJson['Product']['description'] := oProdData:description
            oProdJson['Product']['description_small'] := oProdData:
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
            oProdJson['Product']['release_date'] := '';
            oProdJson['Product']['shortcut'] := '';
            oProdJson['Product']['virtual_product'] := '0';
           
            cPost := FWJsonSerialize(oProdJson:toJson(),.T.,.T.)//Serializa o Objeto Json

            oRestProd:SetPostParams(cPost)

            if oRestProd:Post(aHeader)
                
            else

            endif
                
        Endif

        (cAliasPrd)->(DbSkip())

    EndDo



Return()


Static function AreaClose(aClose)

    Local nAux := 0

    if Len(aClose) > 0
        
        For nAux := 1 to Len(aClose)
            
            if DbSelectArea(aClose[nAux]) > 0
                (aClose[nAux])->( DbCloseArea() )
            Endif

        Next nAux

    Endif

return