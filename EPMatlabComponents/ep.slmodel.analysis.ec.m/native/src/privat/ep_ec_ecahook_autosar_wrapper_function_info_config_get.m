function stConfig = ep_ec_ecahook_autosar_wrapper_function_info_config_get(xEnv, stUserConfig)
% Called without parameters the function returns the default configurations for
% "ecahook_autosar_wrapper_function_info" hook file
%
% Called with parameters the function merges the default configurations for
% "ecahook_ignore_code" hook file with the custom user passes
% ecahook_autosar_wrapper_function_info and returns the result
%
% stConfig = ep_ec_ecahook_autosar_wrapper_function_info_config_get(xEnv, stUserConfig)
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
% Return user-defined information about the C-code function to map with an
% Autosar SWC wrapper model. The function logic shall be identic to the
% function-call logic modeled the block <WrapperModel>/<WrapperSubsytem>/Scheduler,
% meaning the main function shall call the runnables at the same rate and
% the order as modeled in the "Scheduler" subsystem to avoid different
% behavior between model and code.
%
% stAutosarWrapperCodeInfo (Struct)
%	.sCFile             (String)
%   .casIncludePaths    (Cell-Array-String)
%   .sStepFunName       (String)
%   .sInitFunName       (String)
%
% REMARKS: Place this hook function file next to the model
%
%-------------------------------- Examples --------------------------------
% stAutosarWrapperCodeInfo = struct(...
%     'sCFile', 'C:/wrapper_folder/swc_scheduler.c', ...
%     'casIncludePaths', {{'C:/wrapper_folder', ...
%                         'C:/model_folder/autosar_model_autosar_rtw', ...
%                         'C:/model_folder/autosar_model_autosar_rtw/stub'}}, ...
%     'sStepFunName', 'swc_scheduler_step', ...
%     'sInitFunName', 'swc_scheduler_init');
%---------------------------------------------------------------------------

stDefaultConfig = struct(...
    'sCFile', '', ...
    'casIncludePaths', {{}}, ...
    'sStepFunName', '', ...
    'sInitFunName', '');
end
