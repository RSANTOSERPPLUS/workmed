#include 'protheus.ch'
#include 'parmtype.ch'
#include 'topconn.ch'


/*{Protheus.doc} WMECOPED
Description //Grava pedidos da tabela ZZE no prothus
@param 
@return Nil 
@author  - Rafael S.Silva
@since: 10-10-2019 */
user function WMECOPED()
	Local cCod_mun	 := ""
	Local cAliasCab  := GetNextAlias()
	Local cAliasGrid := GetNextAlias()
	Local cAliasMun	 := GetNextAlias()
	Local aCliente   := {}
	Local aCabec	 := {}
	Local aItens     := {}
	Local aLinha	 := {}
	Local cDDD		 := ""
	Local cTelefone  := ""
	Local cOrderCod	 := ""
	Local cInscR	 := ""
	Local cMunEnt    := ""
	
	private cCliente := ""
	private cLojaCli := ""
	
	BeginSql Alias cAliasCab
		%noparser%
		
		SELECT R_E_C_N_O_ ZD_RECNO,*
		FROM
			%table:SZD%
		WHERE
			ZD_FILIAL = %xFilial:SZD% AND
			ZD_GRAVA = %exp:'S'% AND
			%notdel%
	EndSql
	
	
	While !( (cALiasCab)->(Eof()) )
		
		cOrderCod := AllTrim((cALiasCab)->ZD_IDECOMM)
		aCliente := {}
		
		If (cALiasCab)->ZD_PESSOA == "F"
			cInscR := Iif(!Empty(AllTrim((cALiasCab)->ZD_INSCR)),Upper(AllTrim((cALiasCab)->ZD_INSCR)),"ISENTO")
		Endif
		
		cDDD 	  := SubStr(AllTrim((cALiasCab)->ZD_FONE),1,2)
		cTelefone := SubStr(AllTrim((cALiasCab)->ZD_FONE),3,Len(AllTrim((cALiasCab)->ZD_FONE))-2) 
		
		aAdd(aCliente,{"A1_TIPO","F",Nil})
		aAdd(aCliente,{"A1_PESSOA",(cALiasCab)->ZD_PESSOA,Nil})
		aAdd(aCliente,{"A1_NOME",Upper(DecodeUtf8((cALiasCab)->ZD_NOME)),Nil})
		aAdd(aCliente,{"A1_NREDUZ",Upper((cALiasCab)->ZD_NREDUZ), Nil})
		aAdd(aCliente,{"A1_CGC",(cALiasCab)->ZD_CGC, NIL})
		aAdd(aCliente,{"A1_INSCR",cInscR, NIL})
		aAdd(aCliente,{"A1_PFISICA",(cALiasCab)->ZD_RG, NIL})
		aAdd(aCliente,{"A1_CONTRIB",IIF((cALiasCab)->ZD_PESSOA == "F","2","1"),Nil})
		aAdd(aCliente,{"A1_DDD",cDDD,NIL})
		aAdd(aCliente,{"A1_TEL",cTelefone,NIL})		
		aAdd(aCliente,{"A1_TELEX",cTelefone,NIL})
		aAdd(aCliente,{"A1_EMAIL",DecodeUtf8((cALiasCab)->ZD_EMAIL),Nil})
		aAdd(aCliente,{"A1_SATIV1","000001" , Nil})
		aAdd(aCliente,{"A1_XMAILC",DecodeUtf8((cALiasCab)->ZD_EMAIL) , Nil})
		aAdd(aCliente,{"A1_XQUAL", "D", Nil})
		aAdd(aCliente,{"A1_XVCQ", Ctod("31/12/2049"), Nil})		
		aAdd(aCliente,{"A1_CEP",(cALiasCab)->ZD_CEP,NIL})
		aAdd(aCliente,{"A1_END",Upper(DecodeUtf8((cALiasCab)->ZD_END)),NIL})
		aAdd(aCliente,{"A1_CARGO1",(cALiasCab)->ZD_NUMERO,NIL})
		aAdd(aCliente,{"A1_COMPLEM",Upper(DecodeUtf8((cALiasCab)->ZD_COMPLEM)),Nil})
		aAdd(aCliente,{"A1_BAIRRO",Upper(DecodeUtf8((cALiasCab)->ZD_BAIRRO)),NIL})
		aAdd(aCliente,{"A1_EST",AllTrim((cALiasCab)->ZD_EST),Nil})
		
		//PESQUISO CODIGO DO MUNICÍPIO
		BeginSql Alias cAliasMun
			%noparser%
			
			SELECT 
				CC2_CODMUN,CC2_MUN 
			FROM 
				%table:CC2%
			WHERE
				CC2_FILIAL = %xFilial:CC2% AND
				CC2_EST = %exp:AllTrim((cALiasCab)->ZD_EST)% AND 
				CC2_MUN = %exp:FwNoAccent(Upper(AllTrim((cALiasCab)->ZD_MUN)))%	AND
				%notdel%		
		EndSql
		
		if !(cAliasMun)->(Eof())
			cCod_mun := (cAliasMun)->CC2_CODMUN
			cMunEnt := (cAliasMun)->CC2_MUN
		Endif
		
		(cAliasMun)->(DbCloseArea())
		     
		AAdd(aCliente,{"A1_COD_MUN",cCod_mun, NIl })
		
		//aAdd(aCliente,{"A1_MUN",(cALiasCab)->ZD_MUN,NIL})
		aAdd(aCliente,{"A1_NATUREZ","10101",NIL})
		aAdd(aCliente,{"A1_CEPE",DecodeUtf8((cALiasCab)->ZD_CEPENT),NIL})
		aAdd(aCliente,{"A1_ENDENT",Upper(DecodeUtf8((cALiasCab)->ZD_ENDENT)),NIL})
		aAdd(aCliente,{"A1_BAIRROE",Upper(DecodeUtf8((cALiasCab)->ZD_BAIRROE)),NIL})
		aAdd(aCliente,{"A1_MUNE",cMunEnt,NIL})
		aAdd(aCliente,{"A1_ESTE",DecodeUtf8((cALiasCab)->ZD_ESTENT),NIL})
		aAdd(aCliente,{"A1_RISCO","A",NIL})
		aAdd(aCliente,{"A1_LC",100000,NIL})
		aAdd(aCliente,{"A1_VENCLC",CTOD("31/12/2048"),NIL})
		
		lCliOK := CADCLI(aCliente,(cALiasCab)->ZD_CGC)
		
		If lCliOK
			aAdd(aCabec,{"C5_NUM",,Nil}) //TODO: Verificar este campo
			aAdd(aCabec,{"C5_TIPO","N",Nil})
			aAdd(aCabec,{"C5_CLIENTE",cCliente,Nil})
			aAdd(aCabec,{"C5_LOJACLI",cLojaCli,Nil})
			aAdd(aCabec,{"C5_TRANSP","000001",Nil})
			aAdd(aCabec,{"C5_CODPAG","001",Nil})
			//aAdd(aCabec,{"C5_VOLUME1",,Nil})
			//aAdd(aCabec,{"C5_VOLUME2",,Nil})
			//aAdd(aCabec,{"C5_VOLUME3",,Nil})
			//aAdd(aCabec,{"C5_VOLUME4",,Nil})
		
			if Len(aCabec) > 0 
		
				BeginSql Alias cAliasGrid
					%noparser%
					
					SELECT * 
					FROM
						%table:SZE% 
					WHERE
						ZE_PEDECOM = %exp:cOrderCod% AND
						%notdel%
				EndSql
				
				(cAliasGrid)->(DbGoTop())
				While !( (cAliasGrid)->(Eof()) )
					
					aLinha := {}
					
					//aAdd(aCabec,{"C6_ITEM",StrZero(VAL((cAliasGrid)->ZE_ITEMM),),Nil})
					aAdd(aLinha,{"C6_PRODUTO",(cAliasGrid)->ZE_IDPRODE,Nil})
					//aAdd(aCabec,{"C6_XCLASSE",(cAliasGrid)->,Nil})
					aAdd(aLinha,{"C6_QTDVEN",(cAliasGrid)->ZE_QUANT,Nil})
					aAdd(aLinha,{"C6_PRCVEN",(cAliasGrid)->ZE_PRECO,Nil})
					aAdd(aLinha,{"C6_TES","501",Nil})
					aAdd(aLinha,{"C6_LOCAL","01",Nil})
					
					aAdd(aItens,aLinha)
					
					(cAliasGrid)->(DbSkip())
				EnDdo
				
				(cAliasGrid)->(DbCloseArea())
			Endif
			
			if Len(aItens) > 0
				
				lMsErroAuto := .F.
				MSExecAuto({|x,y,z|Mata410(x,y,z)},aCabec,aItens,3)
				
				If lMsErroAuto
					CONOUT("ERRO NO CADASTRO DO PEDIDO")
					CONOUT(MOSTRAERRO("ERRO_PEDIDO_ECOMMERCE_"+Time()+".TXT"))
				Else
					SZD->((cAliasCab)->ZD_RECNO)
					RecLock("SZD",.F.)
					SZD->ZD_IDERP 	:= SC5->C5_NUM
					SZD->ZD_GRAVA	:= "N" //PEDIDO GRAVADO
					SZD->(MsUnlock())
				Endif
				
				Sleep(3000)
			Endif
			
		Endif
		(cALiasCab)->(DbSkip())
	Enddo
	
	(cALiasCab)->(DbCloseArea())
return


static function CADCLI(aCliente,cCGC)

	local lRet := .F.
	Local lParOk := Valtype(aCliente) == "A" .and. Len(aCliente) > 0
	Local nOpc   := 4
	
	if lParOk
		DbSelectArea("SA1")
		SA1->(DbSetOrder(3))//A1_FILIAL+A1_CGC
		
		If !SA1->( DbSeek(xFilial("SA1") + cCGC ) )
			nOpc := 3
			aSize(aCliente,Len(aCliente)+3)
			aIns(aCliente,1)
			aCliente[1]:= {"A1_LOJA","01",NIl}
			aIns(aCliente,1)
			aCliente[1]:= {"A1_TIPO","F",NIl}
			aIns(aCliente,1)
			aCliente[1]:= {"A1_COD",GetSxeNum("SA1","A1_COD"),NIl}			
		Endif
		
		lMsErroAuto := .F.
		MSExecAuto({|x,y,z|Mata030(x,y,z)},aCliente,nOpc)
		
		if !lMsErroAuto
			SA1->( DbSeek(xFilial("SA1") + cCGC ) )
			cCliente := SA1->A1_COD
			cLojaCli := SA1->A1_LOJA
			lRet := .T.
		Else
			CONOUT("ERRO AO CADASTRAR CLIENTE")
			CONOUT(MOSTRAERRO("ERRO_CLIENTE_ECOMMERCE_"+Time()+".TXT"))
		Endif
	Endif
	
return lRet