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
    Local cFilLeg := ""
    Local cFunBkp := FunName()
    Private aRotina := MenuDef()

    SetFunName("WMTCAD01")
     
    //Instânciando FWMBrowse - Somente com dicionário de dados
    oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de Autor/Interprete
    oBrowse:SetAlias("SZF")
 
    //Setando a descrição da rotina
    oBrowse:SetDescription(cTitulo)
     
    cFilLeg := " SZC  " 
     
    //Legendas
    oBrowse:AddLegend( "SZF->ZF_INTEGRA == 'S' ", "ORANGE","Cadastro pendente" )
    oBrowse:AddLegend( "SZF->ZF_CADOK == 'S' .AND. SZF->ZF_INTEGRA == 'N' ", "GREEN","Cadastrado no E-Commerce" )
    oBrowse:AddLegend( "SZF->ZF_CADOK == 'N' .AND. SZF->ZF_INTEGRA == 'N' ", "RED","Não cadastrado no E-commerce" )
     
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
    ADD OPTION aRot TITLE 'Legenda'    ACTION 'U_WMTLEG()'    OPERATION 6                      ACCESS 0 //OPERATION X
    ADD OPTION aRot TITLE 'Enviar P/Site'    ACTION 'U_WMTRAY04()' OPERATION 2    ACCESS 0 //OPERATION X    
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
    oStSZF:SetProperty('ZF_CODIGO',  MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  ' GETSXENUM("SZF","ZF_CODIGO") '))   //Ini Padrão    
    oStSZF:SetProperty('ZF_CODIGO',  MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edição    
    oStSZF:SetProperty('ZF_ID',      MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edição
    oStSZF:SetProperty('ZF_CADOK',   MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))  //Modo de Edição
    oStSZF:SetProperty('ZF_CADOK',   MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  ' "N" '))   //Ini Padrão
    oStSZF:SetProperty('ZF_INTEGRA', MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  ' "S" '))   //Ini Padrão    
    oStSZF:SetProperty('ZF_DEFAULT', MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  ' "0" '))   //Ini Padrão
    //oStZZ1:SetProperty('ZZ1_DESC',    MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   ' !Empty(M->ZZ1_DESC) '))   //Validação de Campo
    oStSZF:SetProperty('ZF_STATUS',    MODEL_FIELD_OBRIGAT, RetCodUsr() != '000000' )  //Campo Obrigatório
     
    //Instanciando o modelo, não é recomendado colocar nome da user function (por causa do u_), respeitando 10 caracteres
    oModel := MPFormModel():New("SZFOUTRO",/*bPre*/,/*{ |oMdl| ENVSTATUS( oMdl ) }*/,/*bCommit*/,/*bCancel*/) 
     
    //Atribuindo formulários para o modelo
    oModel:AddFields("SZFMASTER",,oStSZF)
     
    //Setando a chave primária da rotina
    oModel:SetPrimaryKey({'ZF_FILIAL','ZF_ID'})
     
    //Adicionando descrição ao modelo
    oModel:SetDescription(cTitulo)
     
    //Setando a descrição do formulário
    oModel:GetModel("SZFMASTER"):SetDescription("Formulário de "+cTitulo)
Return oModel

Static Function ViewDef()
    Local aStruSZF    := SZF->(DbStruct())
     
    //Criação do objeto do modelo de dados da Interface do Cadastro de Autor/Interprete
    Local oModel := ModelDef()
     
    //Criação da estrutura de dados utilizada na interface do cadastro 
    Local oStSZF := FWFormStruct(2, "SZF")  //pode se usar um terceiro parâmetro para filtrar os campos exibidos { |cCampo| cCampo $ 'SZZ1_NOME|SZZ1_DTAFAL|'}
     
    //Criando oView como nulo
    Local oView := Nil
 
    //Criando a view que será o retorno da função e setando o modelo da rotina
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Atribuindo formulários para interface
    oView:AddField("VIEW_SZF", oStSZF, "SZFMASTER")
     
    //Criando um container com nome tela com 100%
    oView:CreateHorizontalBox("TELA",100)
     
    //O formulário da interface será colocado dentro do container
    oView:SetOwnerView("VIEW_SZF","TELA")     
    //Colocando título do formulário
    oView:EnableTitleView('VIEW_SZF', 'Dados - '+cTitulo )  
     
    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({||.T.})
     
    oStSZF:RemoveField("ZF_CADOK")
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

 
User Function WMTLEG()
    Local aLegenda := {}
     
    //Monta as cores
    AADD(aLegenda,{"BR_VERDE",        "Cadastrado no E-Commerce"  })
    AADD(aLegenda,{"BR_VERMELHO",    "Não cadastrado no E-Commerce"})
    AADD(aLegenda,{"BR_LARANJA",    "Cadastro pendente"})
     
    BrwLegenda(cTitulo, "Legenda", aLegenda)
Return


Static Function ENVSTATUS( oModel )
	Local nOperation := oModel:GetOperation()
	Local cCodigo	 := ""
	Local lRet := .T.
	
	If nOperation == MODEL_OPERATION_INSERT .OR. MODEL_OPERATION_UPDATE 
	   If Empty( oModel:GetValue( 'SZFMASTER', 'ZF_INTEGRA' ) ) .OR. oModel:GetValue( 'SZFMASTER', 'ZF_INTEGRA' ) == 'S'
	   //Help( ,, 'HELP',, 'Informe a data', 1, 0)      
	   		cCodigo := oModel:GetValue( 'SZFMASTER', 'ZF_CODIGO' )
	   		If !Empty(cCodigo)
	   			U_WMTRAY04(cCodigo)
	   		EndIf
	   EndIf
	EndIf

Return lRet