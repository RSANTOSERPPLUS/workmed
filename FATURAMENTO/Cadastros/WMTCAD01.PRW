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

Static cTitulo := "Manutenção de status - Tray"

User Function WMTCAD01()

    Local aArea   := GetArea()
    Local oBrowse
    Local cFunBkp := FunName()
    Private aRotina := MenuDef()
    Private aRotLeg := {|| WMTLEGENDA() }

    SetFunName("WMTCAD01")
     
    //Instânciando FWMBrowse - Somente com dicionário de dados
    oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    oBrowse:SetAlias("SZF")
 
    //Setando a descrição da rotina
    oBrowse:SetDescription(cTitulo)
     
    //Legendas
    oBrowse:AddLegend( "SZF->ZF_CADOK == 'S' ", "GREEN","Cadastrado no E-Commerce" )
    oBrowse:AddLegend( "SZF->ZF_CADOK == 'N' ", "RED","Não cadastrado no E-commerce" )
     
    //Filtro 
    //oBrowse:SetFilterDefault("ZZ1->ZZ1_COD >= '000000' .And. ZZ1->ZZ1_COD <= 'ZZZZZZ'")
     
    //Ativa a Browse
    oBrowse:Activate()
     
    SetFunName(cFunBkp)
    RestArea(aArea)


Return


Static Function MenuDef()
    Local aRot := {}
     
    //Adicionando opções
    ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION aRot TITLE 'Legenda'    ACTION 'Eval(aRotLeg)'    OPERATION 6                      ACCESS 0 //OPERATION X
    ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.WMTCAD01' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return aRot


Static Function ModelDef()
    //Criação do objeto do modelo de dados
    Local oModel := Nil
     
    //Criação da estrutura de dados utilizada na interface
    Local oStSZF := FWFormStruct(1, "SZF")
     
    //Editando características do dicionário
    oStZZ1:SetProperty('ZF_ID',      MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edição
    oStZZ1:SetProperty('ZF_CADOK',   MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edição
    oStZZ1:SetProperty('ZF_DEFAULT', MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  ' "0" '))   //Ini Padrão
    //oStZZ1:SetProperty('ZZ1_DESC',    MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   ' !Empty(M->ZZ1_DESC) '))   //Validação de Campo
    oStZZ1:SetProperty('ZF_STATUS',    MODEL_FIELD_OBRIGAT, RetCodUsr() != '000000' )  //Campo Obrigatório
     
    //Instanciando o modelo, não é recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
    oModel := MPFormModel():New("zWTCAD1M",/*bPre*/, /*bPos*/,/*bCommit*/,/*bCancel*/) 
     
    //Atribuindo formulários para o modelo
    oModel:AddFields("FORMSZF",/*cOwner*/,oStSZF)
     
    //Setando a chave primária da rotina
    oModel:SetPrimaryKey({'ZF_FILIAL','ZF_ID'})
     
    //Adicionando descrição ao modelo
    oModel:SetDescription(cTitulo)
     
    //Setando a descrição do formulário
    oModel:GetModel("FORMSZF"):SetDescription("Formulário de "+cTitulo)
Return oModel

Static Function ViewDef()
    Local aStruZZ1    := SZF->(DbStruct())
     
    //Criação do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
    Local oModel := FWLoadModel("zWTCAD1")
     
    //Criação da estrutura de dados utilizada na interface do cadastro de Autor
    Local oStSZF := FWFormStruct(2, "SZF")  //pode se usar um terceiro parâmetro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZZ1_NOME|SZZ1_DTAFAL|'}
     
    //Criando oView como nulo
    Local oView := Nil
 
    //Criando a view que será o retorno da função e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Atribuindo formulários para interface
    oView:AddField("VIEW_SZF", oStZZ1, "FORMSZF")
     
    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)
     
    //Colocando título do formulário
    oView:EnableTitleView('VIEW_SZF', 'Dados - '+cTitulo )  
     
    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({||.T.})
     
    //O formulário da interface será colocado dentro do container
    oView:SetOwnerView("VIEW_SZF","TELA")
     
    /*
    //Tratativa para remover campos da visualização
    For nAtual := 1 To Len(aStruZZ1)
        cCampoAux := Alltrim(aStruZZ1[nAtual][01])
         
        //Se o campo atual não estiver nos que forem considerados
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
    AADD(aLegenda,{"BR_VERMELHO",    "Não cadastrado no E-Commerce"})
     
    BrwLegenda(cTitulo, "Status", aLegenda)
Return
/*User Function WMTCAD01()

Private cCadastro := "Geração de etiquetas de pallet" 
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
aAdd( aLegenda, { "BR_VERMELHO", "Não cadastrado no E-Commerce" })

BrwLegenda( cCadastro, "Legenda", aLegenda ) 

Return Nil 
*/