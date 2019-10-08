#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 

//--------------------------------------------------------------
/*/{Protheus.doc} testorders
Description //Função para testar a gravação da fila de pedidos
@param : Nil
@return NIl
@author  - Rafael S.Silva
@since: 04-10-2019 /*/
//--------------------------------------------------------------
User Function testorders()

    Local oMainJson := JsonObject():New() 
    Local oJsonOrd  := JsonObject():New()
    Local oJsonSort := JsonObject():New()
    Local oJsonProd := JsonObject():New()
    Local aProducts := {}
    Local aSort     := {}
    Local aAvFilters:= {} 
    Local aOrders   := {}
    Local cJson     := ''
    Local nX        := 0
    Local nTotal    := 2

    oMainJson['paging'] := JsonObject():New()
    oMainJson['paging']['total']    := 5
    oMainJson['paging']['page']     := 0
    oMainJson['paging']['offset']   := 0
    oMainJson['paging']['limit']    := 30
    oMainJson['paging']['maxlimit'] := 50


    oJsonSort['id'] := 'asc'
    aAdd(aSort,oJsonSort)

    oMainJson['sort'] := aSort

    aAdd(aAvFilters, 'id')
    aAdd(aAvFilters, 'status')
    aAdd(aAvFilters, 'partner_id')
    aAdd(aAvFilters, 'session_id')
    aAdd(aAvFilters, 'sending_code')
    aAdd(aAvFilters, 'customer_id')
    aAdd(aAvFilters, 'shipment')
    aAdd(aAvFilters, 'point_sale')
    aAdd(aAvFilters, 'payment_form')
    aAdd(aAvFilters, 'access_code')
    aAdd(aAvFilters, 'external_code')
    aAdd(aAvFilters, 'modified')
    aAdd(aAvFilters, 'date')
    aAdd(aAvFilters, 'shipment_date')
    aAdd(aAvFilters, 'payment_date')

    oMainJson['availableFilters'] := aAvFilters
    oMainJson['appliedFilters'] := []

    For nX := 1 to nTotal

        oJsonOrd['status']:= "CANCELADO AUT"
        oJsonOrd['id']:= "2
        oJsonOrd['date']:= "2018-03-08"
        oJsonOrd['customer_id']:= "1"
        oJsonOrd['partial_total']:= "200.00"
        oJsonOrd['taxes']:= "0.00"
        oJsonOrd['discount']:= "0.00"
        oJsonOrd['point_sale']:= "LOJA VIRTUAL"
        oJsonOrd['shipment']:= "Encomenda PAC"
        oJsonOrd['shipment_value']:= "19.20"
        oJsonOrd['shipment_date']:= ""
        oJsonOrd['discount_coupon']:= ""
        oJsonOrd['payment_method_rate']:= "0.00"
        oJsonOrd['value_1']:= "0.00"
        oJsonOrd['payment_form']:= "Boleto - Yapay"
        oJsonOrd['sending_code']:= ""
        oJsonOrd['session_id']:= "123abc123abc123abc123abc12"
        oJsonOrd['total']:= "219.20"
        oJsonOrd['payment_date']:= "0000-00-00"
        oJsonOrd['access_code']:= "AD8BC6B29CAD4D9"
        oJsonOrd['shipment_integrator']:= "Correios"
        oJsonOrd['modified']:= "2018-04-05 16:= 27:= 26"
        oJsonOrd['id_quotation']:= ""
        oJsonOrd['estimated_delivery_date']:= "2018-03-15"
        oJsonOrd['external_code']:= ""
        oJsonOrd['total_comission_user']:= "0.00"
        oJsonOrd['total_comission']:= "0.00"
        oJsonOrd['is_traceable']:= "0"
        oJsonOrd['OrderStatus'] := JsonObject():New()
        oJsonOrd['OrderStatus']['type'] := "canceled"
        oJsonOrd['OrderStatus']['allow_edit_order'] := "0"

        aProducts := {}
        oJsonProd['id'] := '2'
        aAdd(aProducts,oJsonProd)

        oJsonOrd['ProductsSold'] := aProducts

        oJsonOrd['payment'] = []
        oJsonOrd['OrderInvoice'] := []
        oJsonOrd['MlOrder']      := []
        oJsonOrd['OrderTransactions'] := []
        oJsonOrd['Extentions'] := []

        aAdd(aOrders,oJsonOrd)
    Next nX
    
    oMainJson['Order'] := aOrders
    
    cJson := oMainJson:toJson()

    if ValType(cJson) == "C"
        //Faz a chamada da função de recebimento dos pedidos
        if U_WMTRAY02("1",.T.,cJson)
            MsgInfo("===========TESTE FINALIZADO COM SUCESSO!=============")
        Endif
    Endif

Return