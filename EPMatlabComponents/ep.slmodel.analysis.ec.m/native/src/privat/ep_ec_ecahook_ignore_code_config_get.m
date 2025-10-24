function stConfig = ep_ec_ecahook_ignore_code_config_get(xEnv, stUserConfig)
% Called without parameters the function returns the default configurations for
% "ecahook_ignore_code" hook file
%
% Called with parameters the function merges the default configurations for
% "ecahook_ignore_code" hook file with the custom user passes
% configurations and returns the result
%
% stConfig = ep_ec_ecahook_ignore_code_config_get(xEnv, stUserConfig)
%
%  INPUT              DESCRIPTION
%    - xEnv                              EPEnvironment object
%    - stUserConfig                      The user custom configs
%
%  OUTPUT            DESCRIPTION
%
%  - stConfig          The configurations to use
if (nargin == 0)
    stConfig = i_get_default_config();
else
    casKnownIndermediateSettings = {};
    stConfig = ep_ec_settings_merge(xEnv, i_get_default_config(), stUserConfig, casKnownIndermediateSettings);
end
end

%%
function stDefaultConfig = i_get_default_config()
% casFileNames : cell array of strings of excluded C/C++ file names
stDefaultConfig = struct( ...
    'casFileNames', {{'rt_main.c', 'rt_main.cpp', 'main.cpp'}});
end
