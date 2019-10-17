#include 'protheus.ch' 
#include 'totvs.ch' 
#include 'topconn.ch' 
#Include 'FWMVCDef.ch'

//--------------------------------------------------------------
/*/{Protheus.doc} WMTCAD01
Description //Cadasto de status de pedido.
@param NIl
@return NIl
@author  - Rafael S.Silva
@since: 16-10-2019 /*/
//--------------------------------------------------------------

Static cTitulo := "Manuten��o de status - Tray"

User Function WMTCAD01()

    Local aArea   := GetArea()
    Local oBrowse
    Local cFunBkp := FunName()
    Private aRotina := MenuDef()
    Private aRotLeg := {|| WMTLEGENDA() }

    SetFunName("WMTCAD01")
     
    //Inst�nciando FWMBrowse - Somente com dicion�rio de dados
    oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    oBrowse:SetAlias("SZF")
 
    //Setando a descri��o da rotina
    oBrowse:SetDescription(cTitulo)
     
    //Legendas
    oBrowse:AddLegend( "SZF->ZF_CADOK == 'S' ", "GREEN","Cadastrado no E-Commerce" )
    oBrowse:AddLegend( "SZF->ZF_CADOK == 'N' ", "RED","N�o cadastrado no E-commerce" )
     
    //Filtro 
    //oBrowse:SetFilterDefault("ZZ1->ZZ1_COD >= '000000' .And. ZZ1->ZZ1_COD <= 'ZZZZZZ'")
     
    //Ativa a Browse
    oBrowse:Activate()
     
    SetFunName(cFunBkp)
    RestArea(aArea)


Return


Static Function MenuDef()
    Local aRot := {}
     
    //Adicionando op��es
    ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION aRot TITLE 'Legenda'    ACTION 'Eval(aRotLeg)'    OPERATION 6                      ACCESS 0 //OPERATION X
    ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return aRot


Static Function ModelDef()
    //Cria��o do objeto do modelo de dados
    Local oModel := Nil
     
    //Cria��o da estrutura de dados utilizada na interface
    Local oStSZF := FWFormStruct(1, "SZF")
     
    //Editando caracter�sticas do dicion�rio
    oStZZ1:SetProperty('ZF_ID',      MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edi��o
    oStZZ1:SetProperty('ZF_CADOK',   MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edi��o
    oStZZ1:SetProperty('ZF_DEFAULT', MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  ' "0" '))   //Ini Padr�o
    //oStZZ1:SetProperty('ZZ1_DESC',    MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   ' !Empty(M->ZZ1_DESC) '))   //Valida��o de Campo
    oStZZ1:SetProperty('ZF_STATUS',    MODEL_FIELD_OBRIGAT, RetCodUsr() != '000000' )  //Campo Obrigat�rio
     
    //Instanciando o modelo, n�o � recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
    oModel := MPFormModel():New("zWTCAD1M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
     
    //Atribuindo formul�rios para o modelo
    oModel:AddFields("FORMSZF",/*cOwner*/,oStSZF)
     
    //Setando a chave prim�ria da rotina
    oModel:SetPrimaryKey({'ZF_FILIAL','ZF_ID'})
     
    //Adicionando descri��o ao modelo
    oModel:SetDescription(cTitulo)
     
    //Setando a descri��o do formul�rio
    oModel:GetModel("FORMSZF"):SetDescription("Formul�rio de "+cTitulo)
Return oModel

Static Function ViewDef()
    Local aStruZZ1    := SZF->(DbStruct())
     
    //Cria��o do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
    Local oModel := FWLoadModel("zWTCAD1")
     
    //Cria��o da estrutura de dados utilizada na interface do cadastro de Autor
    Local oStSZF := FWFormStruct(2, "SZF")  //pode se usar um terceiro par�metro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZZ1_NOME|SZZ1_DTAFAL|'}
     
    //Criando oView como nulo
    Local oView := Nil
 
    //Criando a view que ser� o retorno da fun��o e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Atribuindo formul�rios para interface
    oView:AddField("VIEW_SZF", oStZZ1, "FORMSZF")
     
    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)
     
    //Colocando t�tulo do formul�rio
    oView:EnableTitleView('VIEW_SZF', 'Dados - '+cTitulo )  
     
    //For�a o fechamento da janela na confirma��o
    oView:SetCloseOnOk({||.T.})
     
    //O formul�rio da interface ser� colocado dentro do container
    oView:SetOwnerView("VIEW_SZF","TELA")
     
    /*
    //Tratativa para remover campos da visualiza��o
    For nAtual := 1 To Len(aStruZZ1)
        cCampoAux := Alltrim(aStruZZ1[nAtual][01])
         
        //Se o campo atual n�o estiver nos que forem considerados
        If Alltrim(cCampoAux) $ "ZZ1_COD;"
            oStZZ1:RemoveField(cCampoAux)
        EndIf
    Next
    */
Return oView

 
User Function WMTLEGENDA()
    Local aLegenda := {}
     
    //Monta as cores
    AADD(aLegenda,{"BR_VERDE",        "Cadastrado no E-Commerce"  })
    AADD(aLegenda,{"BR_VERMELHO",    "N�o cadastrado no E-Commerce"})
     
    BrwLegenda(cTitulo, "Status", aLegenda)
Return
/*User Function WMTCAD01()

Private cCadastro := "Gera��o de etiquetas de pallet" 
Private cAlias    := "SZF"
Private aCores    := {}
Private aRotina   := {}
Private aRotNew   := { || NewStatus() }
Private aRotUpd   := { || UpdStatus() }

aAdd(aCores,{ "SZF->ZF_CADOK == 'S' ","BR_VERDE"} )
aAdd(aCores,{ "SZF->ZF_CADOK == 'N' ","BR_VERMELHO"} )

AADD(aRotina, {"Visualizar"   ,"AXVISUAL"       ,0,2})  
AADD(aRotina, {"Novo &Status" ,"Eval(aRotNew)"  ,0,3}) 
AADD(aRotina, {"Novo &Status" ,"Eval(aRotUpd)"  ,0,4}) 
AADD(aRotina, {"Excluir"      ,"AXEXCLUI"       ,0,5})


MBROWSE(6,1,22,75,cAlias,,,,,aCores)



Return

//LEGENDA DO BROWSE
Static function brwlegenda()
     
Local aLegenda := {} 

aAdd( aLegenda, { "BR_VERDE", "Cadastrado no E-Commerce" }) 
aAdd( aLegenda, { "BR_VERMELHO", "N�o cadastrado no E-Commerce" })

BrwLegenda( cCadastro, "Legenda", aLegenda ) 

Return Nil 
*/