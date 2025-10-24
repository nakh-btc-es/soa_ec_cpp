function stResult = ep_ec_configurations_get(xEnv, sGlobalPath, sModelPath)
% Returns all settings for the EC analysis inside one single struct.
%
% This function creates a structure with all known configuration file names
% and the custom values found for each file in the given locations. If the given paths are not valid, the returned
% structure has default values for each config file. The output structure contains also a structure with all known 
% hook file names and the file name containing the default values for each hook.
%
%     stResult = ep_ec_configurations_get(xEnv, sGlobalPath, sModelPath)
%
%  INPUT              DESCRIPTION
%    - xEnv               (EPEnvironment)   Environment object (if empty, *error/warnings* are not logged!).
%    - sGlobalPath        (dir)             The path where user custom configuration files are searched for.
%                                           Is optional and can be empty.
%    - sModelPath         (dir)             The model path where user custom configuration files are searched for
%                                           Is optional and can be empty.
%
%  OUTPUT            DESCRIPTION
%
%  - stResult             (struct)       Structure containing all settings for the EC analysis.
%


%%
if (nargin < 3)
    sModelPath = '';
end
if (nargin < 2)
    sGlobalPath = '';
end
if (nargin < 1)
    xEnv = [];
end

stResult.stConfigs = struct();
stResult.stHookFiles = struct();

casPaths = {};
if ~isempty(sGlobalPath)
    if exist(sGlobalPath, 'dir')
        casPaths{end+1} = sGlobalPath;
    else
        if ~isempty(xEnv)
            sStr = sprintf('Global configuration path "%s" is not valid and is being ignored.', sGlobalPath);
            xEnv.addMessage('EP:SLC:WARNING', 'msg', sStr);
        end
    end
end
if ~isempty(sModelPath)
    if exist(sModelPath, 'dir')
        casPaths{end+1} = sModelPath;
    else
        if ~isempty(xEnv)            
            sStr = sprintf('Local configuration path "%s" is not valid and is being ignored.', sModelPath);
            xEnv.addMessage('EP:SLC:WARNING', 'msg', sStr);
        end
    end
end

[stConfigFiles, stHookFiles] = ep_ec_setting_files_get(casPaths{:});
casAllConfigs = fieldnames(stConfigFiles);
stAdditionalInfo = struct();
for i = 1:numel(casAllConfigs)
    sConfigName = casAllConfigs{i};
    stFoundConfigFiles = stConfigFiles.(sConfigName);
    stConfigs = ep_ec_hook_file_eval(xEnv, sConfigName, stFoundConfigFiles, stAdditionalInfo);
    stResult.stConfigs.(sConfigName) = stConfigs;
end

stResult.stHookFiles = stHookFiles;
end



