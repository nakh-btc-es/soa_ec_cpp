function stSettings = ep_ec_hook_file_eval(xEnv, sHookName, stHookFiles, stAdditionalInfo)
% This function evaluates all given hook files and merges the found user settings with default hook values
%
% stSettings = ep_ec_hook_file_eval(xEnv, sHookName, stHookFiles, stAdditionalInfo)
%
%  INPUT              DESCRIPTION
%   - xEnv                                      EPEnvironment object
%   - sHookName                 (string)        The hook name
%   - stHookFiles               (structure)     Structure containing all hook files found near the model and/or in a
%                                               global path having the specified name and the file name containing
%                                               default values for each hook file
%   - stAdditionalInfo          (structure)     Additional information needed by the hook file
%
%  OUTPUT            DESCRIPTION
%
%  - stSettings                    Structure containing settings for the EC analysis
%
%%
bFatal = false;
if isempty(stHookFiles.sDefaultValuesFileName)
    stSettings = struct();
else
    stSettings = i_get_default_settings(stHookFiles.sDefaultValuesFileName);
end
for k = 1:numel(stHookFiles.casFilesPath)
    sHookFile = stHookFiles.casFilesPath{k};
    sMsg = sprintf('Customer settings file "%s" is being used.', sHookFile);
    if ~isempty(xEnv)
        xEnv.addMessage('EP:SLC:INFO', 'msg', sMsg);
    end
    try
        stSettings = i_eval_user_hook_file(sHookFile, stSettings, stAdditionalInfo);
    catch oEx
        bFatal = true;
        sMsg = sprintf('Error occured when evaluating custom settings file "%s": %s.', sHookFile, oEx.message);
        if ~isempty(xEnv)
            xEnv.addMessage('EP:SLC:ERROR', 'msg', sMsg);
        end
        break;
    end
end
if ~isempty(fieldnames(stSettings))
    if ~isempty(stHookFiles.casFilesPath)
        if bFatal
            stSettings = i_get_default_settings(stHookFiles.sDefaultValuesFileName);
            sMsg = sprintf('For settings "%s", default values will be used.', sHookName);
            if ~isempty(xEnv)
                xEnv.addMessage('EP:SLC:ERROR', 'msg', sMsg);
            end
        else
            stSettings = i_merge_default_with_user_settings(xEnv, stSettings, stHookFiles.sDefaultValuesFileName);
        end
    end
end
end

%%
function stDefaultsettings = i_get_default_settings(sDefaultValuesFileName)
stDefaultsettings = feval(sDefaultValuesFileName);
end

%%
function stMergedsettings = i_merge_default_with_user_settings(xEnv, stUserSettings, sDefaultValuesFileName)
stMergedsettings = feval(sDefaultValuesFileName, xEnv, stUserSettings);
end

%%
function stSettings = i_eval_user_hook_file(sHookFile, stSettings, stAdditionalInfo)
sWorkDir = pwd();
xOnCleanup = onCleanup(@() cd(sWorkDir));
[sPath, sFunctionName] = fileparts(sHookFile);
cd(sPath);
stSettings = feval(sFunctionName, stSettings, stAdditionalInfo);
end
