%Spefic rules for Subsystmes, Parameters and Local signal identification
function cfg = slsilcfg_analysis_btc()

ss = 0; pp = 0; ll = 0;

cfg.General.ModelBlkCodeInterface               = 'TopModelCode'; %'TopModelCode or ReferencedModelCode'
cfg.General.ForceBuildReuseBtwExecution         = true; %Applies only for ModelBlkCodeInterface = ReferencedModelCode;

%Scopes identification
cfg.ScopeCfg.AnalyzeScopesHierarchy             = true;  % False => Root subsystem only, True = From Root level down to any lower levels
cfg.ScopeCfg.RootScope.SearchFromFunction       = '';    %Has priority over the rest
cfg.ScopeCfg.LowerScope.Subsys.Allow            = true;
%Filter for Scopes as Atomic Codegeneration subsystem
ss=ss+1;
cfg.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'IsSubsystemVirtual';
cfg.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'off'; %Must be char


%Parameters interfaces identification
cfg.ParameterDOCfg.SearchGlobal.DataObjectName     = {'.'}; %Regular Expressions:  "^c" for every parameter starting with "c" (e.g. cParamName)
cfg.ParameterDOCfg.SearchGlobal.DataObjectClass    = {''};
cfg.ParameterDOCfg.SearchGlobal.FilterMethod       = 'BlackList';
cfg.ParameterDOCfg.SearchGlobal.PropFilter         = [];
pp=pp+1;
cfg.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Name  = 'CoderInfo.StorageClass';
cfg.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Value = {'Custom'};
cfg.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(2).Name  = 'CoderInfo.CustomStorageClass';
cfg.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(2).Value = {'Const','ConstVolatile','Define', 'ImportedDefine'};

%% Set of accepted storage classes for constants
cfg.CustomConstantStorageClasses = {'Define', 'ImportedDefine'};

%Locals interfaces identification
cfg.LocalDOCfg.SearchGlobal.SearchInRefModel = true; %Maybe needed for AUTOSAR style?
cfg.LocalDOCfg.SearchGlobal.TestPointActive  = true; 
%cfg.LocalDOCfg.SearchGlobal.DataObjectName   = {'.'}; %Regexp
cfg.LocalDOCfg.SearchGlobal.DataObjectClass  = {''};
cfg.LocalDOCfg.SearchGlobal.FilterMethod     = 'BlackList';
cfg.LocalDOCfg.SearchGlobal.PropFilter       = [];
ll=ll+1;
cfg.LocalDOCfg.SearchGlobal.PropFilter(ll).Property(1).Name  = 'CoderInfo.StorageClass';
cfg.LocalDOCfg.SearchGlobal.PropFilter(ll).Property(1).Value = {'Custom'};
