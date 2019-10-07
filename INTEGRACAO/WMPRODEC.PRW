#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

Class WMPRODEC

    Data cProduto as String
    Data cArmz    as String
    Data cFilial  as String
    Data ProdRec  as String

    //Fields that will be available in the json 
    Data ean as string
    Data ncm as String
    Data name as string
    Data description as string
    Data description_small as string
    Data price as numeric
    Data cost_price as numeric
    Data promotional_price as numeric
    Data start_promotion as string
    Data end_promotion  as string
    Data brand as string 
    Data model as string
    Data weight as numeric
    Data length as numeric
    Data width as numeric
    Data height as numeric
    Data stock as numeric
    Data category_id as string
    Data available   as string
    Data availability  as string
    Data availability_days as numeric
    Data reference as string
    Data related_categories as string
    Data release_date as string
    Data shortcut as string
    Data virtual_product as string

    Method New(cProduto,cArmz,cFilial) Constructor
    Method GetMainData(cProduto,cArmz,cFilial) 
    Method getprodprc()
    Method getDimensions()
    Method getBalance()

EndClass


/*
Method: New()
Description: Create the instance of a product
Author: Rafael S.Silva 
Since: 2019-10-01
*/
Method New(cProduto,cProdFil) Class WMPRODEC
 
    Local cQuery     := "" 
    Local lRet       := .T.
    
    Default cProdFil := xFilial("SB1")
    Default cProduto := ""
    
    self:ean    := ""
    self:ncm    := ""
    self:name   := ""
    self:description := ""
    self:description_small := ""
    self:price := 0
    self:cost_price := 0
    self:promotional_price := 0
    self:start_promotion := ""
    self:end_promotion := ""
    self:brand := ""
    self:model := ""
    self:weight := 0
    self:length := 0
    self:width := 0
    self:height := 0
    self:stock := 0
    self:category_id := ""
    self:available := ""
    self:availability := ""
    self:availability_days := 0
    self:reference := ""
    self:related_categories := ""
    self:release_date := ""
    self:shortcut := ""
    self:virtual_product := "0"

    self:ProdRec := 0

    DbSelectArea('SB1')
    SB1->( DbSetorder(1) ) //B1_FILIAL+B1_COD 

    if Empty(cProduto)
        lRet := .F. 
    Endif

    //If the product code isn't empty, I check if it's in the database
    if lRet

        lRet := .F. 

        if SB1->( DbSeeK( cProdFil +  cProduto ) )

            self:ProdRec := SB1->(Recno() )
            self:cProduto := SB1->B1_COD
            self:reference := AllTrim(SB1->B1_COD)
            lRet := .T. //if found, I set return as true
        Else

            Return lRet
            
        Endif

    Endif

Return lRet


/*
Method: GetMainData()
Description: get the main product data, such as 
           // Description, WareHouse, Weight, height...
Author: Rafael S.Silva 
Since: 2019-10-01
*/
Method GetMainData() Class WMPRODEC

    Local lRet := .T.

    if self:ProdRec == 0
        lRet := .F.
    Endif

    if lRet

        if SB1->( DbGoTo(self:ProdRec) )
            self:ean  := SB1->B1_CODBAR
            self:ncm  := SB1->B1_POSIPI
            self:name := AllTrim(SB1->B1_DESC)
            self:description := AllTrim(SB1->B1_DESC)
            self:description_small := Left(AllTrim(SB1->B1_DESC),40) //check this field length
            self:price := SB1->B1_PRV1  
            self:reference  := AllTrim(SB1->B1_COD)

        Endif

    Endif


return lRet


/*Seach product costs/prices through price list*/
Method getprodprc() Class WMPRODEC
    Local lRet := .F.
    Local cTabPrc := AllTrim(supergetMV("MV_XTBECOM",,"001")) //Deafult price list
    Local cDA0FIL := xFilial("DA0")
    Local cPlistCode := "" 
    Local cAliasTmp  := GetNextAlias()

    if Empty(cTabPrc) .and. Empty(self:cProduto) .or. self:ProdRec == 0
        return lRet
    Endif

    DbSelectArea("DA0")
    DA0->( DbSetorder(1) )//DA0_FILIAL+DA0_CODTAB

    DbSelectArea("DA1")
    DA1->( DbSetorder(1) )//DA1_FILIAL+DA1_CODTAB+DA1_CODPRO

    If Select("SB1") == 0
        DbSelectArea("SB1")
    Endif

    SB1->( DbGoTo(self:ProdRec ) )

    If DA0->( DbSeeK(cDA0FIL + cTabPrc ) )
         lRet := .T.
         self:start_promotion := SubStr(DTOS(DA0->DA0_DATDE),1,4) + '-' + SubStr(DTOS(DA0->DA0_DATDE),5,2) + '-' + SubStr(DTOS(DA0->DA0_DATDE),7,2)
         self:end_promotion   := SubStr(DTOS(DA0->DA0_DATATE),1,4) + '-' + SubStr(DTOS(DA0->DA0_DATATE),5,2) + '-' + SubStr(DTOS(DA0->DA0_DATATE),7,2)       
    Endif

    if lRet
        lRet := .F.
        If  DA1->(DbSeeK( cFilDA1 + cTabPrc + self:cProduto ))
            If DA1->DA1_DATVIG >= dDataBase
                self:price := SB1->B1_PRV1
                self:cost_price := 0 // TODO: Check the cost price
                self:promotional_price := DA1->DA1_PRCVEN          
                
                lRet := .T.
            Endif
        Endif
    Endif

return lRet


/*get product's dimenssions*/
Method getDimensions() Class WMPRODEC
    Local lRet    := .T.
    Local cFilSB5 := xFilial("SB5") 
    
    if Empty(AllTrim(self:cProduto))
        lRet := .F.
    Endif

    if lRet

        If Select("SB5") == 0
            DbSelectArea("SB5")
        Endif

        If Select("SB1") == 0
            DbSelectArea("SB1")
        Endif

        SB5->( DbSetorder(1) )
        SB1->( DbGoTo(self:ProdRec) )

        lRet := .F.

        if SB5->(DbSeeK(cFilSB5+self:cProduto) )
            
            self:weight := SB1->B1_PESO
            self:length := SB5->B5_COMPR
            self:width  := SB5->B5_LARG
            self:height := SB5->B5_ALTURA

            lRet := .T.
        Endif

    Endif

return lRet


/*get product's balance*/
Method getBalance() Class WMPRODEC

    Local cWhouse   := supergetMV("MV_XWHECOM",,"01") //Deafult WareHouse
    Local cAliasTmp := GetNextAlias()
    Local cQuery    := ""
    Local nBalance  := 0

	cQuery := CRLF + " SELECT "
	cQuery += CRLF + "   B2_COD , B1_ESTSEG , SUM(B2_QATU - B2_QEMP - B2_RESERVA) B2_SALDO "
	cQuery += CRLF + " FROM "
	cQuery += CRLF + "   "+ SB2->(RetSQLName("SB2")) +" B2 "
	cQuery += CRLF + "   INNER JOIN "+ SB1->(RetSQLName("SB1")) +" B1 ON "
	cQuery += CRLF + "     B1_FILIAL = '"+ SB1->(xFILIAL("SB1")) +"' AND B1_COD = B2_COD	
	cQuery += CRLF + "     AND B1_TIPO = 'PA' AND B1.D_E_L_E_T_ = ' ' "
	cQuery += CRLF + " WHERE "
	cQuery += CRLF + "   B2_FILIAL = '"+ SB2->(xFILIAL("SB2")) +"' AND "
    cQuery += CRLF + "   B2_LOCAL IN "+ FORMATIN( cWhouse ,";") +" "
	cQuery += CRLF + "   AND B2.D_E_L_E_T_ = ' ' "
	cQuery += CRLF + " GROUP BY "
	cQuery += CRLF + "   B2_COD , B1_ESTSEG
	cQuery += CRLF + " ORDER BY "
	cQuery += CRLF + "   B2_COD "   

	MEMOWRITE("PROD_BALANCE.SQL",cQuery)
	    
	TcQuery cQuery Alias TSB2 New

    TSB2->(dbGoTop())
	If !TSB2->(EOF())

		nBalance := TSB2->B2_SALDO - TSB2->B1_ESTSEG

		If nBalance < 0
			nBalance := 0
        Endif

    Endif 

    self:stock := nBalance
    
return 