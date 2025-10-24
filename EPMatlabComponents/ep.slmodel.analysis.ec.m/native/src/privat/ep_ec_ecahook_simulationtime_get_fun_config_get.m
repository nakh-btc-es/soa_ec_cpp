function stConfig = ep_ec_ecahook_simulationtime_get_fun_config_get(xEnv, stUserConfig)
% Called without parameters the function returns the default configurations for
% "ecahook_simulationtime_get_fun" hook file
%
% Called with parameters the function merges the default configurations for
% "ecahook_simulationtime_get_fun" hook file with the custom user passes
% configurations and returns the result
%
% stConfig = ep_ec_ecahook_simulationtime_get_fun_config_get(xEnv, stUserConfig)
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
% stFuncInfo
%   .funcname    : name of the function to be stubbed
%   .filename    : name of the stub file
%   .includefile : name of one include file (e.g. datatypes definition)
%   .returntype  : datatype of the return time variable
%   .usfactor    : unit of time
%                  1         -> time in microsecond (us)
%                  10^-3     -> time in millisecond (ms)
%                  10^-6     -> time in second (s)
%
%                  Hint: the unit of time should be precized enough
%                  to represent the sample time (e.g. if sampletime
%                  == 0.001s, the factor should be greater than 10^-3
%                  otherwize a time value 0 will be returned.
% ------------------------EXAMPLE---------------------------------
% stDefaultConfig.funcname         = 'getSimulationTime';
% stDefaultConfig.filename         = 'getSimulationTime.c';
% stDefaultConfig.includefile      = 'rtwtypes.h';
% stDefaultConfig.returntype       = 'uint32_T';
% stDefaultConfig.usfactor         = 1; %get time in microsecond
%------------------------------------------------------------------
stDefaultConfig = struct (...
    'funcname',          '', ...
    'filename',          '', ...
    'includefile',       '', ...
    'returntype',        '', ...
    'usfactor',          []);
end
