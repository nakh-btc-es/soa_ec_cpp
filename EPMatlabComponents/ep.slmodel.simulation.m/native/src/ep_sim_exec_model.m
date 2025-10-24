function ep_sim_exec_model(varargin)
% This function simulates the provided model (this can be a TargetLink or
% Simulink model). It is assumed that the model is already open.
%
% function ep_sim_exec_model(varargin)
%
%  INPUT              DESCRIPTION
%   - varargin           ([Key, Value]*)  Key-value pairs with the following
%                                       possibles values. Inputs marked with (*)
%                                       are mandatory.
%    Key(string):            Meaning of the Value:
%         ModelFile*              Path to the TargetLink/Simulink model
%                                 file (.mdl|.slx).
%         StimuliVectorFile       Path to the input vector XML File (see
%                                 TestVector.xsd) Note: Important for
%                                 StepByStep Simulation
%         ResultVectorFile*       Path to the result vector XML File. The
%                                 file contain the expected output
%                                 interface.(see TestVector.xsd)
%         MessageFile             The absoulte path to the message file for
%                                 recording errors/warnings/info messages.
%         TestCaseName            The test case's name
%         OriginalScopePath       The original scope's path
%         PhysicalScopePath       The Matlab scope path
%         ExecutionMode           The execution mode
%         InteractiveSimulation   Boolean specifying if the simulation
%                                 should be interactive
%                                 If not specified, default value is false.
%         Progress     (object)   Progress object for progress information.
%  OUTPUT            DESCRIPTION
%



%% init environment
xEnv = EPEnvironment();
stArgs = i_evalArgs(xEnv, varargin{:});


%% simulate
i_call_pre_simulation_hook_function(stArgs);
if  isfield(stArgs, 'LocalsVectorFile')
    oSimException = i_simulate(xEnv, stArgs.ModelFile, stArgs.ResultVectorFile, stArgs.InteractiveSimulation, ...
        stArgs.LocalsVectorFile);
else
    oSimException = i_simulate(xEnv, stArgs.ModelFile, stArgs.ResultVectorFile, stArgs.InteractiveSimulation);
end

xEnv.attachMessages(stArgs.MessageFile);
xEnv.exportMessages(stArgs.MessageFile);
xEnv.clear();


%% throw exceptions if needed
if ~isempty(oSimException)
    rethrow(oSimException);
end
end



%%
function stArgs = i_evalArgs(xEnv, varargin)
try    
    casValidKeys = {'Mode', 'ModelFile', 'MessageFile', 'Progress', 'StimuliVectorFile', 'ResultVectorFile', ...
        'ExecutionMode', 'OriginalScopePath', 'PhysicalScopePath', 'TestCaseName', 'InteractiveSimulation', ...
        'LocalsVectorFile'};
    stArgs = ep_core_transform_args(varargin, casValidKeys);
    
    ep_sim_argcheck('ModelFile', stArgs, 'obligatory', {'class', 'char'});
    ep_sim_argcheck('ModelFile', stArgs, 'file');
    ep_sim_argcheck('StimuliVectorFile', stArgs, {'class', 'char'});
    ep_sim_argcheck('StimuliVectorFile', stArgs, {'xsdvalid', 'TestVector.xsd'});
    ep_sim_argcheck('ResultVectorFile', stArgs, 'obligatory', {'class', 'char'});
    ep_sim_argcheck('ResultVectorFile', stArgs, 'file');
    ep_sim_argcheck('ResultVectorFile', stArgs, {'xsdvalid', 'TestVector.xsd'});
    ep_sim_argcheck('LocalsVectorFile', stArgs, {'class', 'char'});
    ep_sim_argcheck('MessageFile', stArgs, {'class', 'char'});
    ep_sim_argcheck('Progress', stArgs, {'class', 'ep.core.ipc.matlab.server.progress.Progress'});
    ep_sim_argcheck('ExecutionMode', stArgs, {'class', 'char'});
    ep_sim_argcheck('OriginalScopePath', stArgs, {'class', 'char'});
    ep_sim_argcheck('PhysicalScopePath', stArgs, {'class', 'char'});
    ep_sim_argcheck('TestCaseName', stArgs, {'class', 'char'});
    ep_sim_argcheck('InteractiveSimulation',stArgs,{'class','logical'});
    
    if ~isfield(stArgs, 'MessageFile')
        stArgs.MessageFile = '';
    end
    if ~isfield(stArgs,'InteractiveSimulation')
        stArgs.InteractiveSimulation = false;
    end
    if isfield(stArgs, 'Progress')
        xEnv.attachProgress(stArgs.Progress);
    end
    
catch oEx
    xEnv.clear();
    rethrow(oEx);
end
end


%%
function oSimException = i_simulate(xEnv, sModelFile, sResultVectorFile, bInteractiveSimulation, sLocalsVectorFile)
oSimException = [];

tic;
try
    if nargin < 5
        ep_simenv_fullexec(xEnv, sModelFile, sResultVectorFile, bInteractiveSimulation);
    else
        ep_simenv_fullexec(xEnv, sModelFile, sResultVectorFile, bInteractiveSimulation, sLocalsVectorFile);
    end
catch oSimException
end
[~, sModelName] = fileparts(sModelFile);
fprintf('### Simulation Model "%s" Time :\n', sModelName);
toc;
end

%%
function i_call_pre_simulation_hook_function(stArgs)
% pre simulation hook
ep_core_eval_hook('ep_hook_pre_simulation', ...
    'ExtractionModelName', i_getExtractionModelName(stArgs.ModelFile), ...
    'TestCaseName',        stArgs.TestCaseName, ...
    'OriginalScopePath',   stArgs.OriginalScopePath,  ....
    'PhysicalScopePath',   stArgs.PhysicalScopePath, ...
    'ExecutionMode',       stArgs.ExecutionMode);
end

%%
function sExtractionModelName = i_getExtractionModelName(sModelFile)
[~, sName, sExt] = fileparts(sModelFile);
sExtractionModelName = strcat(sName, sExt);
end

