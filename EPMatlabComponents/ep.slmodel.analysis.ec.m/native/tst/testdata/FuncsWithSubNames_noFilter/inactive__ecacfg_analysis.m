%Spefic rules for Subsystmes, Parameters and Local signal identification
function stConfig = ecacfg_analysis(stConfig, ~)

%General options
stConfig.General.bExcludeScopesWithoutMapping        = false;


%Filter for Scopes as Atomic Codegeneration subsystem
stConfig.ScopeCfg.Subsys.PropFilter = [];

ss=1;
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'IsSubsystemVirtual';
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'off'; %Must be char
ss=ss+1;
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'RTWSystemCode';
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'Nonreusable function'; %Must be char
ss=ss+1;
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'RTWFcnNameOpts';
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = {'User specified', 'Use subsystem name'}; %Must be char or cell
ss=ss+1;
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterName  = 'FunctionInterfaceSpec';
stConfig.ScopeCfg.Subsys.PropFilter(ss).BlockParameterValue = 'void_void'; %Must be char
end