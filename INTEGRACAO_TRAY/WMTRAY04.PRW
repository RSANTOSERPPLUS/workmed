#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 
#include 'tbiconn.ch'

//--------------------------------------------------------------
/*/{Protheus.doc} WMTRAY04
Description //Cadastrar status de pedidos - TRAY
@param 
@return xRet Return Description
@author  - Rafael S.Silva
@since: 16-10-2019 /*/
//--------------------------------------------------------------
User Function WMTRAY04()
    Local lIsparamOk := .F.
    Local cToken     := U_GETTOKEN()
    Local cUrl       := U_TRAYURL()
    Local cPath      := "/orders/statuses/"
    Local cStatusRet := ""
    Local aHeadOut   := {"Content-Type: application/json"}
    Local oStatus    := FwRest():New(cUrl)
    Local oJsonEnv   
    Local cAliasTmp  := GetNextAlias()
    Local OJsonRet   := JsonObject():New()

    DbSelectArea('SZF')
    SZF->(DbSetOrder(1))

    lIsparamOk := !Empty(cToken) .and.!Empty(cUrl)

    if lIsparamOk

        BeginSql Alias cAliasTmp
            %noparser%

            SELECT 
                R_E_C_N_O_ AS ZF_RECNO,
                *
            FROM
                %table:SZF% (NOLOCK)
            WHERE
                ZF_INTEGRA = %exp:S% AND
                %notdel%

        EndSql

        While (cAliasTmp)->(Eof())

            oJsonEnv   := JsonObject():New()

            oJsonEnv['OrderStatus']['status']   := AllTrim((cAliasTmp)->ZF_STATUS)
            oJsonEnv['OrderStatus']['default']  := AllTrim((cAliasTmp)->ZF_DEFAULT)

            If (cAliasTmp)->ZF_CADOK == 'N'

                oStatus:SetPath(cPath + AllTrim((cAliasTmp)->ZF_ID))
                oStatus:setPostParams(oJsonEnv:ToJson())
                
                If oStatus:Post(aHeadOut)
                    
                    SZF->( DbGoTo((cAliasTmp)->ZF_RECNO))
                    RecLock("SZF",.F.)
                    SZF->ZF_ID      := OJsonRet['id']
                    SZF->ZF_CADOK   := 'S'
                    SZF->ZF_INTEGRA := 'N'
                    SZF->(Msunlock())

                Endif

            Else
                oStatus:SetPath(cPath + AllTrim((cAliasTmp)->ZF_ID))

                If oStatus:Put(aHeadOut,oJsonEnv:ToJson())//Se o Cadastro Existir, altero
                    SZF->( DbGoTo((cAliasTmp)->ZF_RECNO))
                    RecLock("SZF",.F.)
                    SZF->ZF_INTEGRA := 'N'
                    SZF->(Msunlock())  
                Endif

            Endif

            (cAliasTmp)->(DbSkip())

            FreeObj(oJsonEnv)
            FreeObj(OJsonRet)

        EndDo
    Endif

return