#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} GETTOKEN
Description //Busca token de acesso na plataforma Tray
@param Nil
@return cAccessTk - Retorna o token de acesso
@author  - Rafael S.Silva
@since: 04-10-2019 /*/
//--------------------------------------------------------------
User Function GETTOKEN()
    Local cConsumKey := ""
    Local cConSecret := ""
    Local cCode      := ""
    Local cUrl       := ""
    Local aHeader    := {}
    Local cPath      := "/web_api/auth"
    Local oParamPost := JsonObject():new()
    Local cAccesTok  := ""
    Private oRestCli   
    
    aadd(aHeader,'Content-Type: application/json')
    aadd(aHeader,'Content-Type: multipart/form-data')

    cUrl        := AllTrim(U_TrayUrl())
    cConsumKey  := AllTrim(getConsKey())
    cConSecret  := AllTrim(getSecret())
    cCode       := AllTrim(getCode())

    oRestCli :=  FwRest():New(cUrl)

    oRestCli:SetPath(cPath)

    oParamPost['consumer_key'] := cConsumKey
    oParamPost['consumer_secret'] := cConSecret
    oParamPost['code'] := cCode

    cJson  := oParamPost:toJson()

    oRestCli:setPostParams(cJson)
    
    FreeObj(oParamPost)
    oParamPost := JsonObject():new() 

    if oRestCli:Post(aHeader)
        oParamPost:fromJson(oRestCli:GetResult())
        cAccesTok := oParamPost['access_token']
    Else
        CONOUT("================================================================================")
        CONOUT("Could not get the access token. the request returned the following error: ")
        CONOUT("Error:" + oRestCli:GetLastError())
        CONOUT("================================================================================")
    endif

Return cAccesTok


//--------------------------------------------------------------
/*/{Protheus.doc} getConsKey
Description //Retorna a chave 'consumer_key'
@param xParam Parameter Description
@return cConsKey Retorna a chave 'consumer_secret' para consumo das API's
@author  - Rafael S.Silva
@since: 04-10-2019 /*/
//--------------------------------------------------------------
Static function getConsKey()
    local cConsKey := "c8cf7fef1dbc5cd4622d08b37f47b3b8fb1d355d3f9aaa7be82f18094c321342"//GetMv("MV_XCONKEY")
return cConsKey

//--------------------------------------------------------------
/*/{Protheus.doc} getSecret
Description //Retorna a chave 'consumer_secret'
@param xParam Parameter Description
@return cSecret Retorna a chave 'consumer_secret' para consumo das API's
@author  - Rafael S.Silva
@since: 04-10-2019 /*/
//--------------------------------------------------------------
Static function getSecret()
    local cSecret := "f5474c622ff5633efa2b4d93734c8be50e49e17c9a089ee586c15305025cec07"//GetMv("MV_XSECRET")
return cSecret


//--------------------------------------------------------------
/*/{Protheus.doc} getCode
Description //Retorna a chave 'code'
@param  
@return cCode Retorna a chave 'code' para consumo das API's
@author  - Rafael S.Silva
@since: 04-10-2019 /*/
//--------------------------------------------------------------
Static function getCode()
    local cCode := "3da28f1213f0ca6624ef22f3d7b6617783ea2b9ef0235f52a41602046f8b26f8"//GetMv("MV_XACCODE")
return cCode