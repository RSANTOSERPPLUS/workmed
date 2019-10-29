//Bibliotecas
#Include 'Protheus.ch'
#Include 'FWMVCDef.ch'
 
//Variáveis Estáticas
Static cTitulo := "Kits de produtos"
 

/*/{Protheus.doc} WMCADKIT
//TODO Descrição auto-gerada.
@author Rafael S.Silva
@since 29/10/2019
@version 1.0
@return

@type function
/*/
User Function WMCADKIT()
    Local oBrowse
    Private aRotina := MenuDef()
     
    DbSelectArea("SZI") 
     
    //Instânciando FWMBrowse - Somente com dicionário de dados
    oBrowse := FWMBrowse():New()
     
    //Setando a tabela de cadastro de CDs
    oBrowse:SetAlias("SZI")
 
    //Setando a descrição da rotina
    oBrowse:SetDescription(cTitulo)
     
    //Ativa a Browse
    oBrowse:Activate()
     
    RestArea(aArea)
Return Nil
 
/*---------------------------------------------------------------------*
 | Func:  MenuDef                                                      |
 | Autor: Daniel Atilio                                                |
 | Data:  03/09/2016                                                   |
 | Desc:  Criação do menu MVC                                          |
 *---------------------------------------------------------------------*/
 
Static Function MenuDef()
    Local aRot := {}
     
    //Adicionando opções
    ADD OPTION aRot TITLE 'Visualizar' ACTION 'VIEWDEF.WMCADKIT' OPERATION MODEL_OPERATION_VIEW   ACCESS 0 //OPERATION 1
    ADD OPTION aRot TITLE 'Incluir'    ACTION 'VIEWDEF.WMCADKIT' OPERATION MODEL_OPERATION_INSERT ACCESS 0 //OPERATION 3
    ADD OPTION aRot TITLE 'Alterar'    ACTION 'VIEWDEF.WMCADKIT' OPERATION MODEL_OPERATION_UPDATE ACCESS 0 //OPERATION 4
    ADD OPTION aRot TITLE 'Excluir'    ACTION 'VIEWDEF.WMCADKIT' OPERATION MODEL_OPERATION_DELETE ACCESS 0 //OPERATION 5
 
Return aRot
 
/*---------------------------------------------------------------------*
 | Func:  ModelDef                                                     |
 | Autor: Daniel Atilio                                                |
 | Data:  03/09/2016                                                   |
 | Desc:  Criação do modelo de dados MVC                               |
 *---------------------------------------------------------------------*/
 
Static Function ModelDef()
    Local oModel         := Nil
    Local oStPai         := FWFormStruct(1, 'SZI')
    Local oStFilho       := FWFormStruct(1, 'SZJ')
    Local aSZIRel        := {}
     
    //Definições dos campos
    oStPai:SetProperty('ZI_CODIGO',    MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))                                 //Modo de Edição
    oStPai:SetProperty('ZI_CODIGO',    MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  'GetSXENum("SZI", "ZI_CODIGO")'))       //Ini Padrão
    oStPai:SetProperty('ZI_DESCRI',    MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   '!EMPTY(M->ZI_DESCRI)'))      //Validação de Campo
    //oStFilho:SetProperty('ZJ_ITEM',    MODEL_FIELD_INIT,    FwBuildFeature(STRUCT_FEATURE_INIPAD,  'u_zIniMus()'))                         //Ini Padrão    
    oStFilho:SetProperty('ZJ_CODKIT',  MODEL_FIELD_WHEN,    FwBuildFeature(STRUCT_FEATURE_WHEN,    '.F.'))                                 //Modo de Edição
    oStFilho:SetProperty('ZJ_PRODUTO', MODEL_FIELD_OBRIGAT, .T. )                                                                          //Campo Obrigatório
    oStFilho:SetProperty('ZJ_DESCRI',  MODEL_FIELD_OBRIGAT, .F. )                                                                          //Campo Obrigatório
    oStFilho:SetProperty('ZJ_PRODUTO', MODEL_FIELD_VALID,   FwBuildFeature(STRUCT_FEATURE_VALID,   '!EXISTCPO(M->ZJ_PRODUTO)'))      		//Validação de Campo
    
    //Criando o modelo e os relacionamentos
    oModel := MPFormModel():New('SZIOUTRO')
    oModel:AddFields('SZIMASTER',/*cOwner*/,oStPai)
    oModel:AddGrid('SZJDETAIL','SZIMASTER',oStFilho,/*bLinePre*/, /*bLinePost*/,/*bPre - Grid Inteiro*/,/*bPos - Grid Inteiro*/,/*bLoad - Carga do modelo manualmente*/)  //cOwner é para quem pertence
     
    //Fazendo o relacionamento entre o Pai e Filho
    aAdd(aSZIRel, {'SZI_FILIAL',' xFilial( "SZI'} )
    aAdd(aSZIRel, {'SZI_CODIGO','SZJ_CODKIT'}) 
     
    oModel:SetRelation('SZJDETAIL', aSZIRel, SZI->(IndexKey(1))) //IndexKey -> quero a ordenação e depois filtrado
    oModel:GetModel('SZJDETAIL'):SetUniqueLine({"SZJ_DESCRI"})    //Não repetir informações ou combinações {"CAMPO1","CAMPO2","CAMPOX"}
    oModel:SetPrimaryKey({})
     
    //Setando as descrições
    oModel:SetDescription("Cadastro de " + cTitulo)
    oModel:GetModel('SZIMASTER'):SetDescription('Kit')
    oModel:GetModel('SZJDETAIL'):SetDescription('Produto do Kit')
Return oModel
 
 


 
/*/{Protheus.doc} ViewDef
//TODO Descrição auto-gerada.
@author 
@since 29/10/2019
@version 1.0
@return ${return}, ${return_description}

@type function
/*/
Static Function ViewDef()
    Local oView       := Nil
    Local oModel      := ModelDef()
    Local oStPai      := FWFormStruct(2, 'SZI')
    Local oStFilho    := FWFormStruct(2, 'SZJ')
     
    //Criando a View
    oView := FWFormView():New()
    oView:SetModel(oModel)
     
    //Adicionando os campos do cabeçalho e o grid dos filhos
    oView:AddField('VIEW_SZI',oStPai,'SZIMASTER')
    oView:AddGrid('VIEW_SZJ',oStFilho,'SZJDETAIL')
     
    //Setando o dimensionamento de tamanho
    oView:CreateHorizontalBox('CABEC',30)
    oView:CreateHorizontalBox('GRID',70)
     
    //Amarrando a view com as box
    oView:SetOwnerView('VIEW_SZI','CABEC')
    oView:SetOwnerView('VIEW_SZJ','GRID')
     
    oView:AddIncrementField("VIEW_SZJ", "ZJ_ITEM") 
     
    //Habilitando título
    oView:EnableTitleView('VIEW_SZI','Kit')
    oView:EnableTitleView('VIEW_SZJ','Produtos')
     
    //Força o fechamento da janela na confirmação
    oView:SetCloseOnOk({||.T.})
     
    //Remove os campos 
    oStPai:RemoveField('ZI_USERCAD')
    oStPai:RemoveField('ZI_USERALT')
    oStPai:RemoveField('ZI_USERCAD')
    oStFilho:RemoveField('ZJ_CODKIT')
    oStFilho:RemoveField('ZI_CODKIT')
Return oView