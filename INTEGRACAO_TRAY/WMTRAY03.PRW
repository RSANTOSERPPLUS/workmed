#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} WMTRAY03
Description //Busca dodos completos do pedido do E-commerce e
            // Grava na tabela intermediÃ¡ria
@param xParam Parameter Description
@return Nil 
@author  - Rafael S.Silva
@since: 07-10-2019 /*/
//--------------------------------------------------------------
User Function WMTRAY03()

    Local cEndPoint  := ''
    Local cPath      := '/web_api'
    Local oRestOrder := Nil
    Local oOrderJson := Nil
    Local aHeader    := {}
    Local lJsonOk    := .F.
    Local cAliasOrd  := GetNextAlias()

    
    oOrderJson := JsonObject():New() //Inicio novo objeto Json

    cEndPoint  := AllTrim(U_TrayUrl()) //EndPoint de conexão com a Tray - https://{api_address}
    cToken     := AllTrim(U_GETTOKEN()) //Token de acesso ao Endpoint    
    oRestOrder := FWRest():New(cEndPoint)

    aAdd(aHeader,"Content-Type: application/json")
    //aadd(aHeader,'Content-Type: multipart/form-data')

    BeginSql Alias cAliasOrd
        %noparser%

        SELECT 
            ZC_IDECOMM, R_E_C_N_O_ AS ZC_RECNO
        FROM 
            %TABLE:SZC%
        WHERE
        	ZC_FILIAL = %xFilial:SZD% AND
            ZC_SAIU = %Exp:'N'% AND
            %notdel%

    EndSql

    (cAliasOrd)->(DbGoTop())

    While !( (cAliasOrd)->(Eof()) )

        cIdOrder := AllTrim((cAliasOrd)->ZC_IDECOMM)

        cPath := '/orders/' + cIdOrder + "/complete/?access_token=" + cToken
        oRestOrder:SetPath(cPath)

        if oRestOrder:Get(aHeader)
            oOrderJson:fromJson(DecodeUtf8(oRestOrder:cResult))

            lJsonOk  := ValType(oOrderJson) == "J" 

            if lJsonOk .and. ValType(oOrderJson['Order']['Customer']['cpf']) != "U" .OR. ValType(oOrderJson['Order']['Customer']['cnpj']) != "U" 
             	
             	lCabOK := GravaCab(oOrderJson)
             	If lCabOK
             		GravaProds(oOrderJson['Order']['ProductsSold'])
             		
             		SZC->(DbGoTo((cAliasOrd)->ZC_RECNO))
             		RecLock("SZC",.F.)
             		SZC->ZC_DTSAIDA	:= Date()
             		SZC->ZC_HRSAIDA	:= Time()
             		SZC->ZC_SAIU 	:= "S"
             		SZC->(MsUnlock())
             		
             	Endif

            Else
            	if IsBlind()
            		Conout("Não foi possível realizar o parser do objeto [WMTRAY003 - PRODUCÃO] ")
            	else
            		MsgInfo("Não foi possível realizar o parser do objeto!","WMTRAY003")
            	Endif
            Endif
        Else
        	if IsBlind()
        		Conout("Erro ao obter os dados do pedido")
        		Conout(oRestOrder:GetLastError())
        	else
        		MsgInfo("Erro ao obter os dados do pedido")
        		MsgInfo(oRestOrder:GetLastError())        		
        	Endif
        Endif  

        (cAliasOrd)->(DbSkip())
    EndDo

Return


static function GravaCab(oOrderJson)

	Local lRet 		:= .F.
	Local cIdOrder 	:= ""
	
	DbSelectArea("SZD")
 	SZD->(dbSetorder(1))
 	
 	cIdOrder := Padr(cIdOrder,TAMSX3("ZD_IDECOMM")[1])
	
	if !SZD->(DbSeek(xFilial("SZD") + cIdOrder ))

		RecLock("SZD",.T.)	
		
		SZD->ZD_GRAVA		:= 'S'
		SZD->ZD_FILIAL      := xFilial("SZD")
		SZD->ZD_IDECOMM     := oOrderJson['Order']['id']
		//SZD->ZD_STATUS      := oOrderJson['Order']['status']
		SZD->ZD_DATA        := Stod(strtran(oOrderJson['Order']['date'],"-",""))
		SZD->ZD_HORA        := oOrderJson['Order']['hour']
		SZD->ZD_TOTPARC     := VAl((oOrderJson['Order']['partial_total']))
		SZD->ZD_PONTO       := oOrderJson['Order']['point_sale']
		SZD->ZD_TAXAS       := Val(oOrderJson['Order']['taxes'])
		SZD->ZD_DESCONT     := Val(oOrderJson['Order']['discount'])
		SZD->ZD_CUPOM       := AllTrim(oOrderJson['Order']['cupom'])
		SZD->ZD_PARCEL      := Val(oOrderJson['Order']['installment'])
		//SZD->ZD_ENTREGA     := oOrderJson['Order']['shipment']
		SZD->ZD_VALENTR     := Val(oOrderJson['Order']['shipment_value'])
		SZD->ZD_TOTAL       := Val(oOrderJson['Order']['total'])
		SZD->ZD_PRAZO		:= oOrderJson['Order']['delivery_time']
		SZD->ZD_FORMAPG		:= oOrderJson['Order']['payment_method_id']
		SZD->ZD_PAGAMEN		:= Decodeutf8(oOrderJson['Order']['payment_method'])
		SZD->ZD_OBSERV		:= oOrderJson['Order']['Customer']['observation']
		
		If !Empty(oOrderJson['Order']['Customer']['cpf'])
			SZD->ZD_CGC     := strTran(StrTran(oOrderJson['Order']['Customer']['cpf'],".",""),"-","")
			SZD->ZD_PESSOA	:= 'F'
		Else
			SZD->ZD_CGC     := strTran(StrTran(oOrderJson['Order']['Customer']['cnpj'],".",""),"-","")
			SZD->ZD_PESSOA	:= 'J'
		Endif		
		
		SZD->ZD_IDCLIEN     := oOrderJson['Order']['Customer']['id']
		SZD->ZD_NOME        := oOrderJson['Order']['Customer']['name']
		SZD->ZD_DTCAD       := Stod(StrTran(oOrderJson['Order']['Customer']['registration_date'],"-",""))
		SZD->ZD_RG          := StrTran(Strtran(oOrderJson['Order']['Customer']['rg'],"-",""),".","")
		SZD->ZD_FONE        := oOrderJson['Order']['Customer']['phone']
		SZD->ZD_NUMCEL      := oOrderJson['Order']['Customer']['cellphone']
		SZD->ZD_DTNASC      := Stod(StrTran(oOrderJson['Order']['Customer']['birth_date'],"-",""))
		SZD->ZD_EMAIL       := oOrderJson['Order']['Customer']['email']
		SZD->ZD_TOKEN       := oOrderJson['Order']['Customer']['token']
		//SZD->ZD_BLOQ        := oOrderJson['Customer']['']
		SZD->ZD_NREDUZ      := oOrderJson['Order']['Customer']['nickname']
		SZD->ZD_INSCR       := oOrderJson['Order']['Customer']['state_inscription']
		SZD->ZD_END         := oOrderJson['Order']['Customer']['address']
		SZD->ZD_CEP         := StrTran(oOrderJson['Order']['Customer']['zip_code'],"-","")
		SZD->ZD_NUMERO      := Val(oOrderJson['Order']['Customer']['number'])
		SZD->ZD_COMPLEM     := oOrderJson['Order']['Customer']['complement']
		SZD->ZD_BAIRRO      := oOrderJson['Order']['Customer']['neighborhood']
		SZD->ZD_EST         := oOrderJson['Order']['Customer']['state']
		SZD->ZD_MUN         := DecodeUtf8(oOrderJson['Order']['Customer']['city'])
		SZD->ZD_FORMAPG		:= oOrderJson['Order']['Customer']['payment_id']
		SZD->ZD_PAGAMEN		:= oOrderJson['Order']['Customer']['payment_method']
		SZD->ZD_ENDENT      := oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['address']
		SZD->ZD_NUMENT      := Val(oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['number'])
		SZD->ZD_COMPENT     := oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['complement']
		SZD->ZD_ESTENT      := oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['state']
		SZD->ZD_MUNENT      := DecodeUtf8(oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['city'])
		SZD->ZD_BAIRROE     := oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['neighborhood']
		SZD->ZD_CEPENT      := StrTran(oOrderJson['Order']['Customer']['CustomerAddresses'][1]['CustomerAddress']['zip_code'],"-","")
		
		SZD->(MsUnlock())
		
		lRet := .T.
	EndIf
return lRet



static function GravaProds(oProdsJson)
	
	Local nItem := 0
	Local nTamItem := TamSx3("ZE_ITEM")[1]
	
	If Select("SZE") == 0
		DbSelectArea("SZE")
	Endif
	
	For nItem := 1 to Len(oProdsJson)
		
		If RecLock("SZE",.T.)
		
			SZE->ZE_FILIAL  := xFilial("SZE")
			SZE->ZE_ITEM	:= StrZero(nItem,nTamItem)
			SZE->ZE_IDPRODE := oProdsJson[nItem]['ProductsSold']['product_id'] 
			SZE->ZE_QUANT	:= Val(oProdsJson[nItem]['ProductsSold']['quantity']) 
			//SZE->ZE_PRECO	:= oProdsJson['ProductsSold']['id'] :=  "11836"
			SZE->ZE_PEDECOM	:= oProdsJson[nItem]['ProductsSold']['order_id'] 
			//oProdsJson['ProductsSold']['name'] " BARBIE CAMISETAS FASHION (Ref. 16022018TARDE1)"
			//oProdsJson['ProductsSold']['original_name']
			//oProdsJson['ProductsSold']['virtual_product'] :=  "0"
			//oProdsJson['ProductsSold']['ean'] ""
			//oProdsJson['ProductsSold']['Sku']  []
			SZE->ZE_PRECO	:= Val(oProdsJson[nItem]['ProductsSold']['price'])
			//oProdsJson['ProductsSold']['cost_price'] :=  "28.40"
			SZE->ZE_PRECORI	:= Val(oProdsJson[nItem]['ProductsSold']['original_price'])
			//oProdsJson['ProductsSold']['weight'] :=  "10"
			//oProdsJson['ProductsSold']['weight_cubic'] :=  "209"
			//oProdsJson['ProductsSold']['brand'] :=  ""
			//oProdsJson['ProductsSold']['model'] :=  ""
			SZE->ZE_PRODUTO	:= oProdsJson[nItem]['ProductsSold']['reference']
			//oProdsJson['ProductsSold']['length'] :=  "10"
			//oProdsJson['ProductsSold']['width'] :=  "10"
			//oProdsJson['ProductsSold']['height'] :=  "10"
			//oProdsJson['ProductsSold']['variant_id'] :=  "0"
			//oProdsJson['ProductsSold']['additional_information'] :=  ""
			//oProdsJson['ProductsSold']['text_variant'] :=  ""
			//oProdsJson['ProductsSold']['warranty'] :=  ""
			//oProdsJson['ProductsSold']['bought_together_id'] :=  "0"
			//oProdsJson['ProductsSold']['ncm'] :=  ""
			//oProdsJson['ProductsSold']['included_items'] :=  ""
			//oProdsJson['ProductsSold']['release_date'] :=  ""
			//oProdsJson['ProductsSold']['commissioner_value'] :=  ""
			//oProdsJson['ProductsSold']['comissao'] :=  "0.00"
			//oProdsJson['ProductsSold']['ProductSoldImage'] :=  []
			//oProdsJson['ProductsSold']['Category'] :=  []
			//oProdsJson['ProductsSold']['is_giveaway'] :=  ""
			//oProdsJson['ProductsSold']['BoughtTogether'] :=  []
			//oProdsJson['ProductsSold']['ProductSoldPackage'] :=  []
			//oProdsJson['ProductsSold']['ProductSoldCard'] :=  []
			SZE->(MsUnlock())
		Endif
		
	Next nItem
return