
setenv('EP_DEACTIVATE_AA_VERSION_CHECK', 'true')

sModelName = 'oClientServer_Model';
load_system(sModelName)

stCreationArgs.ModelName = sModelName;    
stCreationArgs.InitScript = 'init.m';
stCreationArgs.WrapperName = ['Wrapper_' sModelName];
stCreationArgs.OpenWrapper = true;
stCreationArgs.GlobalConfigFolderPath = '';
stCreationArgs.Environment = "";

stResult = ep_ec_adaptive_autosar_wrapper_create(stCreationArgs);