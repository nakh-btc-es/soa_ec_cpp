function stResult = ep_ec_model_wrapper_create(varargin)
% Creates a wrapper model for AUTOSAR models that can be used as testing framework.
%
% function stResult = ep_ec_model_wrapper_create(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following possibles values
%
%    Allowed Keys:            Meaning of the Value:
%    - ModelFile                (string)*         The AUTOSAR model file.
%    - InitScript               (string)          The init script of the AUTOSAR model.
%    - WrapperName              (string)          Name of the wrapper to be created (default == "Wrapper_<model>")
%    - OpenWrapper              (boolean)         Shall model be open after creation?
%    - IsBatchMode              (boolean)         In batch mode, errors are returned as output argument instead of
%                                                 throwing exceptions (default = false).
%    - GlobalConfigFolderPath   (string)          Path to global EC configuration settings.
%    - Progress                 (object)          Optional (Java) progress object.
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


%%
[stArgs, stCreationArgs] = i_evalArgs(varargin{:});

oKind = Eca.ModelKind.get(stCreationArgs.ModelName);
if oKind.isClassicAUTOSAR()
    stResult = ep_ec_classic_autosar_wrapper_create(stCreationArgs);

elseif oKind.isAdaptiveAUTOSAR()
    stResult = ep_ec_adaptive_autosar_wrapper_create(stCreationArgs);

else
    stResult = i_createFailureResult( ...
        sprintf('Model "%s" is not a valid AUTOSAR model. Cannot create wrapper.', stCreationArgs.ModelName));
end

if (stResult.bSuccess && stCreationArgs.OpenWrapper)
    % If the Wrapper creation succeeded and the Wrapper shall be opened, assume that the user wants to work with it and
    % switch the current directory to the model location.
    cd(fileparts(stResult.sWrapperModel));
end
if (~stArgs.IsBatchMode && ~stResult.bSuccess)
    error('EP:EC:WRAPPER_CREATE_FAILED', '%s', strjoin(stResult.casErrorMessages, '\n'));
end
end


%%
function stResult = i_createFailureResult(sMsg)
stResult = struct( ...
    'sWrapperModel',      '', ...
    'sWrapperInitScript', '', ...
    'sWrapperDD',         '', ...
    'bSuccess',           false, ...
    'casErrorMessages',   {{sMsg}});
end


%%
function [stArgs, stCreationArgs] = i_evalArgs(varargin)
stArgs = struct ( ...
    'ModelFile',              '', ...
    'InitScript',             '', ...
    'WrapperName',            '', ...
    'OpenWrapper',            false, ...
    'IsBatchMode',            false, ...
    'GlobalConfigFolderPath', '', ...
    'Progress',               []);

stUserArgs = ep_core_transform_args(varargin, fieldnames(stArgs));
if (nargin < 1)
    % debug workflow: script called without arguments
    stUserArgs.ModelFile = get_param(bdroot, 'FileName');
end

casUserArgs = fieldnames(stUserArgs);
for i = 1:numel(casUserArgs)
    sArgName = casUserArgs{i};
    stArgs.(sArgName) = stUserArgs.(sArgName);
end
oEnvironment = EPEnvironment();
stArgs.oOnCleanupClearEnv = onCleanup(@() oEnvironment.clear());

if (isfield(stArgs, 'Progress') && ~isempty(stArgs.Progress))
    oEnvironment.attachProgress(stArgs.Progress);
end

if ~isempty(stArgs.ModelFile)
    stArgs.ModelFile = ep_core_canonical_path(stArgs.ModelFile);
end
if ~isempty(stArgs.InitScript)
    stArgs.InitScript = ep_core_canonical_path(stArgs.InitScript);
end
if ~isempty(stArgs.GlobalConfigFolderPath)
    stArgs.GlobalConfigFolderPath = ep_core_canonical_path(stArgs.GlobalConfigFolderPath);
end

stOpenModel = i_openModel(oEnvironment, stArgs.ModelFile, stArgs.InitScript);
stArgs.oOnCleanupCloseModel = onCleanup(@() ep_core_model_close(oEnvironment, stOpenModel));

sModelName = get_param(stOpenModel.hModel, 'Name');
if isempty(stArgs.WrapperName)
    stArgs.WrapperName = ['Wrapper_', sModelName];
end

stCreationArgs = struct ( ...
    'ModelName',              sModelName, ...
    'InitScript',             stArgs.InitScript, ...
    'WrapperName',            stArgs.WrapperName, ...
    'OpenWrapper',            stArgs.OpenWrapper, ...
    'GlobalConfigFolderPath', stArgs.GlobalConfigFolderPath, ...
    'Environment',            oEnvironment);
end


%%
function stOpenModel = i_openModel(xEnv, sModelFile, sInitScript)
stArgs = struct( ...
    'sModelFile',    sModelFile, ...
    'caInitScripts', {{}}, ...
    'bIsTL',         false, ...
    'bCheck',        false);
if ~isempty(sInitScript)
    stArgs.caInitScripts = {sInitScript};
end
stOpenModel = ep_core_model_open(xEnv, stArgs);
end
