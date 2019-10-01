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
    Local oRestProd  := Nil
    Local oProdJson  := Nil
    Local aHeader    := {}
    Local cPath      := ""

    oProdJson := JsonObject():New() //Inicio novo objeto Json
    cEndPoint := AllTrim(GetMv("MV_XURLECO")) //EndPoint de coneção com a Tray - https://{api_address}/products
    cToken    := AllTrim(GetMv("MV_XTOKECO")) //Token de acesso ao Endpoint    
    oRestProd     := FWRest():New(cEndPoint)

    if GetMainData()
        //Atualiza os dados princiáis do produto

        if getprodprc()
            //cria os dados de preço do produto
            


        Endif

    Endif


    FWJsonSerialize(oProdJson:ToJson(),.T.,.T.)//Serializa o Objeto Json

    aAdd(aHeader,"Content-Type: application/json")

    oRestProd:setPath("/products/?access_token="+cToken)
    oRestProd:SetPostParams(cPost)

    if oRestProd:Post(aHeader)

    endif






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