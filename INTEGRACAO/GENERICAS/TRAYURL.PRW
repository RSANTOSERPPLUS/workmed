#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} getUrl
Description //Retorna a Url para consumo de API's
@param xParam Parameter Description
@return cUrl Retorna a chave 'consumer_secret' para consumo das API's
@author  - Rafael S.Silva
@since: 04-10-2019 /*/
//--------------------------------------------------------------
user function TrayUrl()
    local cUrl := 'https://trayparceiros.commercesuite.com.br/web_api'//GetMv("MV_XURLECO")
return cUrl
