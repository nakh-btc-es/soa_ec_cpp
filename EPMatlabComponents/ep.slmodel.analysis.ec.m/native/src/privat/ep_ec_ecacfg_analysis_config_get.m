function stConfig = ep_ec_ecacfg_analysis_config_get(xEnv, stUserConfig)

if (nargin == 0)
    stConfig = i_getDefaultConfig();
else
    casKnownIndermediateSettings = { ...
        'General', ...
        'ScopeCfg', ...
        'RootScope', ...
        'LowerScope', ...
        'ModelRef', ....
        'Subsys', ...
        'ParameterDOCfg', ...
        'SearchGlobal', ...
        'LocalDOCfg', ...
        'DefineDOCfg'};
    stConfig = ep_ec_settings_merge(xEnv, i_getDefaultConfig(), stUserConfig, casKnownIndermediateSettings);
end
end


%%
% Spefic rules for Subsystmes, Parameters and Local signal identification
function stDefaultConfig = i_getDefaultConfig()

stDefaultConfig.General.AllowStubGeneration            = true;
stDefaultConfig.General.GenerateSeparateStubFiles      = true; % writing stubs in multiple files
stDefaultConfig.General.sStubCodeFolderPath            = '.';
stDefaultConfig.General.bExcludeScopesWithoutMapping   = false;
stDefaultConfig.General.bExcludeParamsWithoutMapping   = true;
stDefaultConfig.General.sCodegenPath                   = '';


%% Scopes identification
ss = 0; 
stDefaultConfig.ScopeCfg.RootScope.SearchFromFunction = '';    %Has priority over the rest
%ForceUseOfModelStepFnc=false->Use of Subsystem or ModelRef Block c-function
stDefaultConfig.ScopeCfg.RootScope.ForceUseOfModelStepFunc = false;

%Filter for Scopes as Atomic Codegeneration subsystem
% ss = ss + 1;
% stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'IsSubsystemVirtual';
% stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'off'; %Must be char

ss = ss + 1;
stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'RTWSystemCode';
stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = {'Nonreusable function', 'Reusable function'}; %Must be char

% ss = ss + 1;
% stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'RTWFcnNameOpts';
% stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'User specified'; %Must be char

% ss = ss + 1;
% stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'FunctionInterfaceSpec';
% stDefaultConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'void_void';

%% Parameters interfaces identification
pp = 0;
%Regular Expressions:  "^c" for every parameter starting with "c" (e.g. cParamName)
stDefaultConfig.ParameterDOCfg.SearchGlobal.DataObjectName  = {'.'};
stDefaultConfig.ParameterDOCfg.SearchGlobal.DataObjectClass = { ...
    'BTC.Parameter', ...
    'Simulink.Parameter', ...
    'mpt.Parameter', ...
    'Simulink.Breakpoint', ...
    'Simulink.LookupTable'};
stDefaultConfig.ParameterDOCfg.SearchGlobal.FilterMethod = 'WhiteList'; %or Blacklist
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter   = [];

pp = pp + 1;
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Name  = 'CoderInfo.StorageClass';
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Value = {'Custom'};
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(2).Name  = 'CoderInfo.CustomStorageClass';
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(2).Value = { ...
    'Const', ...
    'Default', ...
    'ConstVolatile', ...
    'FileScope', ...
    'Global', ...
    'ExportToFile', ...
    'Volatile', ...
    'ImportFromFile', ...
    'GetSet', ...
    'Struct'};

pp = pp + 1;
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Name  = 'CoderInfo.StorageClass';
stDefaultConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Value = {'ExportedGlobal', 'ImportedExtern'};

%% Set of accepted storage classes for constants
stDefaultConfig.CustomConstantStorageClasses = {'Define', 'ImportedDefine'};


%% Locals interfaces identification
ff = 0; 
stDefaultConfig.LocalDOCfg.SearchGlobal.DataObjectName  = {'.'}; %Regexp
stDefaultConfig.LocalDOCfg.SearchGlobal.DataObjectClass = {'BTC.Signal', 'Simulink.Signal', 'mpt.Signal'};
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter      = [];

ff = ff + 1;
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter(ff).Property(1).Name  = 'CoderInfo.StorageClass';
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter(ff).Property(1).Value = {'Custom'};
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter(ff).Property(2).Name  = 'CoderInfo.CustomStorageClass';
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter(ff).Property(2).Value = { ...
    'Global', ...
    'FileScope', ...
    'Reusable', ...
    'ExportToFile', ...
    'Default', ...
    'GetSet', ...
    'ImportFromFile', ...
    'BitField', ...
    'Struct', ...
    'Volatile'};

ff = ff + 1;
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter(ff).Property(1).Name  = 'CoderInfo.StorageClass';
stDefaultConfig.LocalDOCfg.SearchGlobal.PropFilter(ff).Property(1).Value = {'ExportedGlobal', 'ImportedExtern'};


%% Defines macros identification (for Stub generation)
dd = 0;
%Regular Expressions:  "^c" for every parameter starting with "c" (e.g. cParamName)
stDefaultConfig.DefineDOCfg.SearchGlobal.DataObjectName  = {'.'};
stDefaultConfig.DefineDOCfg.SearchGlobal.DataObjectClass = { ...
    'BTC.Parameter', ...
    'Simulink.Parameter', ...
    'mpt.Parameter', ...
    'Simulink.Breakpoint', ...
    'Simulink.LookupTable'};
stDefaultConfig.DefineDOCfg.SearchGlobal.PropFilter = [];

dd = dd + 1;
stDefaultConfig.DefineDOCfg.SearchGlobal.PropFilter(dd).Property(1).Name  = 'CoderInfo.StorageClass';
stDefaultConfig.DefineDOCfg.SearchGlobal.PropFilter(dd).Property(1).Value = {'Custom'};
stDefaultConfig.DefineDOCfg.SearchGlobal.PropFilter(dd).Property(2).Name  = 'CoderInfo.CustomStorageClass';
stDefaultConfig.DefineDOCfg.SearchGlobal.PropFilter(dd).Property(2).Value = {'ImportedDefine'};
end
