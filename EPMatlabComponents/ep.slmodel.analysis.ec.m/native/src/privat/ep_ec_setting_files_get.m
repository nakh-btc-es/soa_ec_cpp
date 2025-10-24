function [stConfigFiles, stHookFiles] = ep_ec_setting_files_get(varargin)
% Returns info about all settings/hook files.
%
% This function creates structures with all known configuration and hook files and
% the path where a user custom configuration/hook is found. It also creates a structure containing all the known
% configurations/hooks and the corresponding function for getting the default values
%
%
% [stConfigFiles, stHookFiles] = ep_ec_setting_files_get(varargin)
%
%  INPUT              DESCRIPTION
%    - varargin                        Paths where user custom configuration/hook files are searched for
%
%  OUTPUT            DESCRIPTION
%
%  - stConfigFiles         (structure)    Structure that contains all known configuration files. For each config 
%                                         file is provided the file name containing it's default values 
%                                         and the path where such a custom configuration file is found
%  - stHookFiles           (structure)    Structure that contains all known hook files. For each hook file is 
%                                         provided the file name containing it's default values and the path where
%                                         a custom hook file is found


%%
stConfigFiles = i_get_init_config(ep_ec_registry_configs_get());
stHookFiles   = i_get_init_config(ep_ec_registry_hooks_get);
for i = 1:nargin
    [stConfigFiles, stHookFiles] = i_get_config_files_from_path(stConfigFiles, stHookFiles, varargin{i});
end
end


%%
function stResultSettingFiles = i_get_init_config(stRegistry)
stResultSettingFiles = struct();
casFieldNames = fieldnames(stRegistry);
for i = 1:numel(casFieldNames)
    stData.sDefaultValuesFileName = stRegistry.(casFieldNames{i});
    stData.casFilesPath = {};
    stResultSettingFiles.(casFieldNames{i}) = stData;
end
end

%%
function [stConfigFiles, stHookFiles] = i_get_config_files_from_path(stConfigFiles, stHookFiles, sPath)
astFiles = dir(sPath);
for i = 1:numel(astFiles)
    sFileName = astFiles(i).name;
    if (endsWith(lower(sFileName), '.m') || endsWith(lower(sFileName), '.p'))
        sHook = sFileName(1:end-2);
        if isfield(stConfigFiles, sHook)
            stConfigFiles.(sHook).casFilesPath = [stConfigFiles.(sHook).casFilesPath, {fullfile(sPath, sFileName)}];
        end
        if isfield(stHookFiles, sHook)
            stHookFiles.(sHook).casFilesPath = [stHookFiles.(sHook).casFilesPath, {fullfile(sPath, sFileName)}];
        end
    end
end
end
