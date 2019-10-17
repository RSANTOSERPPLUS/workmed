#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} httpparam
Description //Generates http query parameters
@param aQueryPar - array containing query parameters
@return cParameters -- returns the parameters as a http query
@author  - Rafael S.Silva
@since: 03-10-2019 /*/
//--------------------------------------------------------------
User Function httpparam(aQueryPar,lConsole) 
    Local cParameters := ""
    Local lIsParamOk  := ValType(aQueryPar) == "A" .and. Len(aQueryPar) > 0
    Local nParameter  := 0
    Local cSepToken   := "?" // http separation token
    Local cSetValue   := "=" // indicates that the key in the left will receive a value
    Local cAddparam   := "&" // indicate that it will have one or more parameters
    Local aError      := {}
    Local cFile       := "HTTPPARAM_EROR.LOG"
    Local cError      := ''
    Local cField1     := ''
    Local cField2     := ''

    Default lConsole := .T.

    if lIsParamOk 
        cParameters += cSepToken
        for nParameter := 1 to Len(aQueryPar)
            if (  ValType(aQueryPar[nParameter]) == "A" .and. len(aQueryPar[nParameter]) == 2  )
                if !Empty(aQueryPar[nParameter][1]) .and. !Empty(aQueryPar[nParameter][2])
                    
                    cField1 := Lower(rmspaces(aQueryPar[nParameter][1]))
                    cField2 := Lower(rmspaces(aQueryPar[nParameter][2]))
                    cParameters += cField1 + cSetValue + cField2

                    if nParameter < Len(aQueryPar)
                        cParameters += cAddparam
                    endif
                Else
                    if IsBlind() .or. lConsole
                        Conout('The position '+ cValToChar(nParameter) +' of the array cannot containt empty data')
                    Else
                        MsgInfo('The position '+ cValToChar(nParameter) +' of the array cannot containt empty data','HTTPARAM')
                    Endif    
                Endif
            Else
                aAdd(aError,'The position '+ cValToChar(nParameter) +' of the array is invalid. it must be a two elements array.')
            Endif
        next nParameter
    Endif

    //Cannot return parameters when there are one or more invalid elements.
    if len(aError) > 0
        For nParameter := 1 to len(aError)
            cError += aError[nParameter]
            if nParameter < len(aError)
                cError += CRLF
            Endif            
        Next nParameter

        //Save the errors description in the log file
        MemoWrite(cFile,cError)

        if IsBlind() .or. lConsole
            ConOut('Could not convert the sent data into a http query, please check the log file "'+ cFile +'" in the system root folder')
        Else
            MsgInfo('Could not convert the sent data into a http query, please check the log file "'+ cFile +'" in the system root folder','HTTPPARAM')
        Endif     

    elseif !lIsParamOk
        
        If IsBlind() .or. lConsole
            ConOut('Could not convert data type into a http query. It must be an array and in each array position must contain a two-elements array')
        Else
            MsgInfo('Could not convert data type into a http query.'+ CRLF +'It must be an array and in each array position must contain a two-elements array.','HTTPPARAM')
        endif

    Endif

    aError := {}
    cError := ''
    nParameter := 0

Return cParameters


static function rmspaces(cString)

    Local nX := 0
    Local cStringRet := ''

    for nX := 1 to Len(cString)
        if SubStr(cString,nX,1) != ' '
            cStringRet += SubStr(cString,nX,1)
        endif
    Next nX

return cStringRet