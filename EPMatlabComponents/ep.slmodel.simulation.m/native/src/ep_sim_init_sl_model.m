function ep_sim_init_sl_model(varargin)
% This function initializes the provided SL model. It is assumed that the model is already open.
%
% function ep_sim_init_sl_model(varargin)
%
%  INPUT              DESCRIPTION
%   - varargin           ([Key, Value]*)  Key-value pairs with the following possibles values. Inputs marked with (*)
%                                         are mandatory.
%
%    Key(string):            Meaning of the Value:
%         Mode*          (string)  (MIL | SIL | PIL)
%         ModelFile*     (string)  Path to the TargetLink/Simulink model file (.mdl|.slx).
%         InitVectorFile*(string)  Path to the init vector XML File (see InitVector.xsd)
%         SimulationMode (string)  Simulink Simulation Mode {normal, accelerator, rapid or external}
%                                  (default: normal)
%         MessageFile    (string)  The absolute path to the message file for recording errors/warnings/info messages.
%         PreHook    (fcn handle)  Function is evaluated before main func.
%         PostHook   (fcn handle)  Function is evaluated after main func.
%         Progress       (object)  Progress object for progress information.
%  OUTPUT            DESCRIPTION
%


%% Parse input arguments and set up environment
sMessageFile = '';
try
    % init environment
    xEnv = EPEnvironment();
    
    % Parse input arguments
    casValidKeys = { ...
        'Mode', ...
        'ModelFile', ...
        'InitVectorFile', ...
        'SimulationMode', ...
        'MessageFile', ...
        'SimulationKind', ...
        'Progress', ...
        'InputsVectorFile', ...
        'ParamsVectorFile', ...
        'OutputsVectorFile', ...
        'PreHook', ...
        'PostHook'};
    stArgs = ep_core_transform_args(varargin, casValidKeys);
    
    ep_sim_argcheck('Mode',              stArgs, 'obligatory', {'class', 'char'}, {'keyvalue_i', {'MIL', 'SIL', 'PIL'}});
    ep_sim_argcheck('ModelFile',         stArgs, 'obligatory', {'class', 'char'}, 'file');
    ep_sim_argcheck('InitVectorFile',    stArgs, 'obligatory', {'class', 'char'}, 'file');
    ep_sim_argcheck('InitVectorFile',    stArgs, {'xsdvalid', 'InitVector.xsd'});
    ep_sim_argcheck('SimulationMode',    stArgs, {'class', 'char'}, {'keyvalue_i', {'normal', 'accelerator', 'rapid' ,'external'}});
    ep_sim_argcheck('InputsVectorFile',  stArgs, {'class', 'char'});
    ep_sim_argcheck('ParamsVectorFile',  stArgs, {'class', 'char'});
    ep_sim_argcheck('OutputsVectorFile', stArgs, {'class', 'char'});
    ep_sim_argcheck('MessageFile',       stArgs, {'class', 'char'});
    ep_sim_argcheck('PreHook',           stArgs, {'class', 'function_handle'});
    ep_sim_argcheck('PostHook',          stArgs, {'class', 'function_handle'});
    ep_sim_argcheck('Progress',          stArgs, {'class','ep.core.ipc.matlab.server.progress.Progress'});
    ep_sim_argcheck('SimulationKind',    stArgs, 'obligatory', {'class', 'char'});
    
    sMode = 'MIL';
    if (isfield(stArgs, 'Mode'))
        sMode = stArgs.Mode;
    end
    
    sModelFile = stArgs.ModelFile;
    sInitVectorFile = stArgs.InitVectorFile;
    
    sSimulationMode = 'normal';
    if isfield(stArgs, 'SimulationMode')
        sSimulationMode = stArgs.SimulationMode;
    end
    
    if isfield(stArgs, 'MessageFile')
        sMessageFile = stArgs.MessageFile;
    end
    
    sInputsVectorFile = '';
    if isfield(stArgs, 'InputsVectorFile')
        sInputsVectorFile = stArgs.InputsVectorFile;
    end
    
    sParamsVectorFile = '';
    if isfield(stArgs, 'ParamsVectorFile')
        sParamsVectorFile = stArgs.ParamsVectorFile;
    end
    
    sOutputsVectorFile = '';
    if isfield(stArgs, 'OutputsVectorFile')
        sOutputsVectorFile = stArgs.OutputsVectorFile;
    end
    
    hPreHook = @i_preHookSL;
    if isfield(stArgs, 'PreHook')
        hPreHook = stArgs.PreHook;
    end
    
    hPostHook = @i_postHookSL;
    if isfield(stArgs, 'PostHook')
        hPostHook = stArgs.PostHook;
    end
    
    if isfield(stArgs, 'Progress')
        xEnv.attachProgress(stArgs.Progress);
    end
    
    bSupportStepByStep = false; % NOT YET SUPPORTED
    
    %% init environment
    tic;
    
    % we have to cd into model directory
    sCurPath = cd;
    oOnCleanupReturn = onCleanup(@() cd(sCurPath));
    sSimModelPath = fileparts(sModelFile);
    cd(sSimModelPath);
    
    if ~isempty(hPreHook)
        feval(hPreHook, xEnv);
    end
    
    ep_simenv_prepare( ...
        xEnv, ...
        sModelFile, ...
        sInitVectorFile, ...
        sMode, ...
        sSimulationMode, ...
        bSupportStepByStep, ...
        sInputsVectorFile, ...
        sParamsVectorFile, ...
        sOutputsVectorFile);
    
    if ~isempty(hPostHook)
        feval(hPostHook, xEnv);
    end
    
    [~, sModelName] = fileparts(sModelFile);
    fprintf('\n### Model "%s" -- Preparation Time:\n', sModelName);
    
    toc;
    
    xEnv.attachMessages(sMessageFile);
    xEnv.exportMessages(sMessageFile);
    xEnv.clear();
    
catch oEx
    EPEnvironment.cleanAndThrowException(xEnv, oEx, sMessageFile);
end
end


%%
function i_preHookSL(varargin)
end


%%
function i_postHookSL(varargin)
end
