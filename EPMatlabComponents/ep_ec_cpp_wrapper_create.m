function stResult = ep_ec_cpp_wrapper_create(stArgs)
% Creates a wrapper model for SOA Cpp models that can be used as a testing framework.
%
% function stResult = ep_ec_cpp_wrapper_create(stArgs)
%
%  INPUT              DESCRIPTION
%    stArgs                  (struct)  Struct containing arguments for the wrapper creation with the following fields
%      .ModelName                (string)          Name of the open AUTOSAR model.
%      .InitScript               (string)          The init script (full file) of the AUTOSAR model.
%      .WrapperName              (string)          Name of the wrapper to be created.
%      .OpenWrapper              (boolean)         Shall model be open after creation?
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
sImplFunc = i_findImplementationFunction();
if isempty(sImplFunc)
    stResult = struct( ...
        'sWrapperModel',      '', ...
        'sWrapperInitScript', '', ...
        'sWrapperDD',         '', ...
        'bSuccess',           false, ...
        'casErrorMessages',   {{'Wrapper creation for Adaptive AUTOSAR models is not supported.'}});
else
    stResult = feval(sImplFunc, stArgs);
end
end


%%
function sImplFunc = i_findImplementationFunction()
sImplFunc = '';

if (~ep_ec_aa_version_check())
    return;
end

sImplFuncName = 'ep_ec_cpp_wrapper_create_impl';

sFoundScript = which(['/', sImplFuncName]);
if ~isempty(sFoundScript)
    sImplFunc = sImplFuncName;
end
end
