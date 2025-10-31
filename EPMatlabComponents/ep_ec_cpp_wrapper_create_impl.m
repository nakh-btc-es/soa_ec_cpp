function stResult = ep_ec_cpp_wrapper_create_impl(stArgs)
% Creates a wrapper model for classic AUTOSAR models that can be used as a testing framework.
%
% function stResult = ep_ec_aa_wrapper_create_impl(stArgs)
%
%  INPUT              DESCRIPTION
%    stArgs                  (struct)  Struct containing arguments for the wrapper creation with the following fields
%      .ModelName                (string)          Name of the open AUTOSAR model.
%      .InitScript               (string)          The init script (full file) of the AUTOSAR model.
%      .WrapperName              (string)          Name of the wrapper to be created.
%      .OpenWrapper              (baaoolean)         Shall model be open after creation?
%      .GlobalConfigFolderPath   (string)          Path to global EC configuration settings.
%      .Environment              (object)          EPEnvironment object for progress.
%      
%
%  OUTPUT            DESCRIPTION
%    stResult                   (struct)          Return values ( ... to be defined)
%      .sWrapperModel           (string)            Full path to created wrapper model. (might be empty if not
%                                                   successful)
%      .sWrapperInitScript      (string)            Full path to created init script. (might be empty if not
%                                                   successful or if not created)
%      .sWrapperDD              (string)            Full path to created SL DD. (might be empty if not
%                                                   successful or if not created)
%      .bSuccess                (bool)              Was creation successful?
%      .casErrorMessages        (cell)              Cell containing warning/error messages.
%
% 
%   REQUIREMENTS
%     Original AUTOSAR model is assumed to be open.
%


%%
stResult = struct( ...
    'sWrapperModel',      '', ...
    'sWrapperInitScript', '', ...
    'sWrapperDD',         '', ...
    'bSuccess',           false, ...
    'casErrorMessages',   {{}});

sModelName = stArgs.ModelName;
sWrapperModelName = stArgs.WrapperName;

% change into the model directory to avoid creating artifacts like "slprj" into invalid file location
sModelPath = fileparts(get_param(sModelName, 'FileName'));

% now switch to the model path if we are not there already
sCurrentPath = pwd;
if ~strcmpi(sModelPath, sCurrentPath)
    cd(sModelPath);
    onCleanupReturnToCurrentDir = onCleanup(@() cd(sCurrentPath));
end

stModelInfo = ep_ec_aa_model_info_get(sModelName, stArgs.InitScript);
if ~isempty(stModelInfo.casErrorMessages)
    stResult.casErrorMessages = [stResult.casErrorMessages, stModelInfo.casErrorMessages];
    return;
end

try
    stTopModel = ep_ec_aa_wrapper_toplevel_create(stModelInfo, sWrapperModelName);
catch oEx
    sCause = oEx.getReport('basic', 'hyperlinks', 'off');
    sMsg = sprintf('Failed creating a wrapper for the model "%s":\n%s', sModelName, sCause);

    fprintf('\n[ERROR] %s\n\n', sMsg);
    stResult.casErrorMessages{end + 1} = sMsg;
    return;
end

stAdditionalInfo = struct( ...
    'Model',                 sModelName, ...
    'WrapperModel',          sWrapperModelName, ...
    'WrapperInitScriptFile', stTopModel.sInitScript, ...
    'SchedulerSubsystem',    getfullname(stTopModel.hSchedulerSub));
i_evalPostHook(stArgs.GlobalConfigFolderPath, sModelPath, stAdditionalInfo);


% now open model if requested
if stArgs.OpenWrapper
    set(stTopModel.hModel, 'Open', 'on');
else
    % if wrapper is not kept open, close it when done; also close the SL-DD if there is one
    oOnCleanupCloseWrapper = onCleanup(@() i_closeModelsAndSLDD(stTopModel));
end

stResult.bSuccess           = true;
stResult.sWrapperModel      = stTopModel.sModelFile;
stResult.sWrapperInitScript = stTopModel.sInitScript;
stResult.sWrapperDD         = stTopModel.sDataDictionary;
end


%%
function i_closeModelsAndSLDD(stTopModel)
i_closeAllOpenWrapperModels(stTopModel);
i_closeSLDD(stTopModel.sDataDictionary);
end


%%
function i_closeAllOpenWrapperModels(stTopModel)
ahModels = [stTopModel.hModel, stTopModel.stIntegModel.hModel];
if ~isempty(stTopModel.stIntegModel.stServerModel)
    ahModels(end + 1) = stTopModel.stIntegModel.stServerModel.hModel;
end
if ~isempty(stTopModel.stIntegModel.stClientModel)
    ahModels(end + 1) = stTopModel.stIntegModel.stClientModel.hModel;
end

for i = 1:numel(ahModels)
    hModel = ahModels(i);

    try %#ok<TRYNC> 
        close_system(hModel, 0);
    end
end
end


%%
function i_closeSLDD(sDataDictionaryFile)
if ~isempty(sDataDictionaryFile)
    sDataDictionaryName = i_getFileName(sDataDictionaryFile);
    
    casPaths = Simulink.data.dictionary.getOpenDictionaryPaths;
    for i = 1:numel(casPaths)
        sOpenDD = i_getFileName(casPaths{i});
        if strcmpi(sDataDictionaryName, sOpenDD)
            Simulink.data.dictionary.closeAll(sOpenDD);
            break;
        end
    end
end
end


%%
function sFileName = i_getFileName(sFilePath)
[~, f, e] = fileparts(sFilePath);
sFileName = [f, e];
end


%%
function i_evalPostHook(sGlobalConfigPath, sModelPath, stAdditionalInfo)
% message entries not needed --> use empty env object for now
oEnv = [];

stECConfigs = ep_ec_configurations_get(oEnv, sGlobalConfigPath, sModelPath);
stHooks = stECConfigs.stHookFiles;
sHookName = 'ecahook_post_wrapper_create';
ep_ec_hook_file_eval(oEnv, sHookName, stHooks.(sHookName), stAdditionalInfo);
end


