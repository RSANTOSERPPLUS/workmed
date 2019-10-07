#INCLUDE "PROTHEUS.CH"
#INCLUDE "parmtype.ch"


//--------------------------------------------------------------
/*/{Protheus.doc} PEMTA010 P.E
Description //Descrição da Função
@param xParam Parameter Description
@return xRet Return Description
@author  - Rafael S.Silva
@since: 02-10-2019 /*/
//--------------------------------------------------------------
USER FUNCTION ITEM()
	Local aArea 	:= GetArea()
	Local xRet		:= .T.
	Local aParam	:= PARAMIXB
	Local oObj
	Local cIdPonto
	Local cIdModel 
	Local lIsGrid

	If aParam <> Nil
        oObj := aParam[1]
        cIdPonto := aParam[2]
        cIdModel := aParam[3]
        lIsGrid := (Len(aParam) > 3)	
        
        If UPPER(ALLTRIM(cIdPonto)) == "FORMCOMMITTTSPOS"
        	// Inclusão do produto para integração Wevo
        	If SB1->B1_PROMOC == 'S'
	        	SZB->(dbSetOrder(1))//ZB_FILIAL+ZB_PRODERP

	        	If !SZB->( dbSeek( xFilial("SZB") + SB1->B1_COD) )
		        	SZB->(RecLock("SZB",.T.))
		        	SZB->ZB_FILIAL  := SZB->(xFILIAL("SZB"))
		        	SZB->ZB_PRODERP := SB1->B1_COD
		        	SZB->ZB_INTEGRA := "1"
		        	SZB->ZB_DATACAD := Date()
		        	SZB->ZB_HORACAD := Time()
					SZB->ZB_CADOK	:= "N" //Indica que ainda não foi cadastrado no e-commerce
		        	SZB->(MsUnLock())
				Else
					SZB->(RecLock("SZB",.F.))
		        	SZB->ZB_INTEGRA := "1"
		        	SZB->ZB_DATACAD := Date()
					SZB->ZB_CADOK	:= IIF(!Empty(ALLTRIM(ZB_PRODECO)),'S','N')
		        	SZB->ZB_HORACAD := Time()										
					SZB->(MsUnLock())
		        Endif

			Endif
	    Endif
	Endif	
	
	RestArea(aArea)
RETURN xRet