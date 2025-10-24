function oEca = eca_run_diagnostics(sModelName, sInitFile, sGlobalConfigFolderPath)
% eca_run_diagnostics(sModelName, sInitFile, sGlobalConfigFolderPath)
% Analyze and report information about the extracted model and code architecture of the Embedded Coder model.
% The currently selected configuration folder in preferences is used if "sGlobalConfigFolderPath" is not
% explicitly provided
%
% Execute the script from the directory containing the model and m-script.
%
%   sModelName              : (string) : name of the model including the extension
%   sInitFile               : (string) : name of the init m-file (optional)
%   sGlobalConfigFolderPath : (string) : the path to global configurations folder (optional)


%%
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

sTempDir = tempname();
mkdir(sTempDir);
oOnCleanupRemoveDir = onCleanup(@() rmdir(sTempDir, 's'));

stArgs = struct( ...
    'ModelFile',              sModelFile, ...
    'InitScriptFile',         sInitFile, ...
    'GlobalConfigFolderPath', sGlobalConfigFolderPath,...
    'ParameterHandling',      'ExplicitParam',...
    'DSReadWriteObservable',  false,...
    'TestMode',               'GreyBox', ...
    'TempDir',                '', ...
    'AddModelInfoFile',       fullfile(sTempDir, 'AddModelInfoGen.xml'), ...
    'MappingFile',            fullfile(sTempDir, 'mapping.xml'),...
    'CodeModelFile',          fullfile(sTempDir, 'CodeModel.xml'), ...
    'ConstantsFile',          fullfile(sTempDir, 'ecConstants.xml'), ...
    'MessageFile',            '', ...
    'ReuseExistingCode',      'no', ...
    'AddCodeModel',           'yes');

stArgs.AdaptiveStubcodeXmlFile = fullfile(sTempDir, 'stubCodeAA.xml');

xEnv = [];
oEca = ep_ec_model_info_prepare(xEnv, stArgs);
oEca = oEca.createDiagnosticsReports();
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
