#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} getEvent
Description //Retorna evento conforme parametro numérico
@param nOpc
    nOpc = 1 = Peidido recebido
    nOpc = 2 = Pedido cadastrado
    nOpc = 3 = Pedido faturado
@return cEvento 
@author  - Rafael S.Silva
@since: 17-10-2019 /*/
//--------------------------------------------------------------
User Function getEvent(nOpc)
    Local lIsParamOk := ValType(nOpc) == "N" .and. nOpc > 0
    Local cTMPAlias  := GetNextAlias()
    Local cEvento    := ""

    If lIsParamOk

        BeginSql Alias cTMPAlias
            %noparser%

            SELECT 
                ZF_STATUS
            FROM
                %table:SZF%
            WHERE 
                ZF_FILIAL = %xfilial:SZF% 
                AND ZF_EVENTO = %exp:cValToChar(nOpc)%
                AND %notdel%

        EndSQl

        if !(cTMPAlias)->(Eof())
            cEvento := AllTrim(ZF_STATUS)
        Else
            ConOut( "=================================================")
            ConOut( "NENHUM STATUS CADASTRADO COM O ID "+ cValToChar(nOpc))
            ConOut( "=================================================")
        Endif
        
    Endif

Return cEvento