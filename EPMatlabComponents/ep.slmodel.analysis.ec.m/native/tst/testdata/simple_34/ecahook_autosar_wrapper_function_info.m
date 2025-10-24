function stConfig = ecahook_autosar_wrapper_function_info(stConfig, stAdditionalInfo)
% Returns user-defined information about the C-code function to map with an
% Autosar SWC wrapper model. The function logic shall be identic to the
% function-call logic modeled the block <WrapperModel>/<WrapperSubsytem>/Scheduler,
% meaning the main function shall call the runnables at the same rate and
% the order as modeled in the "Scheduler" subsystem to avoid different
% behavior between model and code.
%
% stConfig (Struct)
%	.sCFile             (String)                  The C-Code file to map with an Autosar SWC wrapper model
%   .casIncludePaths    (Cell-Array-String)       The needed paths that have to be included
%   .sStepFunName       (String)                  The step function name
%   .sInitFunName       (String)                  The init function name
%
% REMARKS: Place this hook function file next to the model
%
%-------------------------------- Examples --------------------------------
% stConfig.sCFile          = 'C:/wrapper_folder/swc_scheduler.c';
% stConfig.casIncludePaths = {'C:/wrapper_folder', ...
%                              'C:/model_folder/autosar_model_autosar_rtw', ...
%                              'C:/model_folder/autosar_model_autosar_rtw/stub'};
% stConfig.sStepFunName    = 'swc_scheduler_step';
% stConfig.sInitFunName    = 'swc_scheduler_init';
%---------------------------------------------------------------------------

stConfig.casIncludePaths = {'A:\BcD', 'x:/yZ'};

end
