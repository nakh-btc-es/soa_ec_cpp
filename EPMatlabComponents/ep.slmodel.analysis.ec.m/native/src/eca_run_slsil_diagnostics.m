function oEca = eca_run_slsil_diagnostics(sModelName, sInitFile, sGlobalConfigFolderPath)
% eca_run_diagnotics(sModelName, sInitFile, sGlobalConfigFolderPath)
% Analyze and report information about the extracted model and code
% architecture of the Embedded Coder model
%
% Execute the script from the directory containing the model and m-script.
%
%   sModelName : (string) : name of the model including the extension
%   sInitFile  : (string) : name of the init m-file (optional)



%%
%Full path to model
sModelFile = ep_core_canonical_path(sModelName);

if (nargin < 2)
    sInitFile = '';
else
    if ~isempty(sInitFile)
        sInitFile = ep_core_canonical_path(sInitFile);
    end
end

if (nargin < 3)
    sGlobalConfigFolderPath = i_getUserGlobalFolder();
end

stArgs = struct( ...
    'ModelFile',              sModelFile, ...
    'InitScriptFile',         sInitFile, ...
    'GlobalConfigFolderPath', sGlobalConfigFolderPath,...
    'ParameterHandling',     'ExplicitParam',...
    'TestMode',              'GreyBox', ...
    'TempDir',               '', ...
    'AddModelInfoFile',      fullfile(fileparts(sModelFile), 'AddModelInfoGen.xml'), ...
    'MappingFile',           fullfile(fileparts(sModelFile), 'mapping.xml'),...
    'CodeModelFile',         fullfile(fileparts(sModelFile), 'CodeModel.xml'), ...
    'MessageFile',           '', ...
    'AddCodeModel',          'no');

xEnv = [];
oEca = ep_ec_model_info_prepare(xEnv, stArgs);
if strcmp(get(oEca.hModel, 'Open'), 'off')
    close_system(oEca.sModelName, 0);
end
end


%%
function sGlobalConfigFolderPath = i_getUserGlobalFolder()
sGlobalConfigFolderPath = '';

try 
    sPreviousPrefXML = ep_core_set_preference_location_env('');
    oOnCleanupRestorePref = onCleanup(@() ep_core_set_preference_location_env(sPreviousPrefXML));
    
    sGlobalConfigFolderPath = ep_core_path_get('EC_CONFIGS');
    
catch
    warning('EP:EC_DIAGNOSTICS', ...
        'Failed to evaluate the users''s preferences. The global configuration folder cannot be taken into account.');
end
end
