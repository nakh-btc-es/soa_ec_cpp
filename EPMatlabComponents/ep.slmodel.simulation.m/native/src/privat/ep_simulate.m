function oSimException = ep_simulate(xEnv, sSimEnvModel, nLength, bInteractiveSimulation)
% Base functionality for simulation the extraction model.
%
% function oSimException = ep_simulate(xEnv, sSimEnvModel, nLength, bInteractiveSimulation)
%
%   INPUT               DESCRIPTION
%     xEnv                   Environment settings.
%     sSimEnvModel           File path to simulation model - loaded and init assumed.
%     nLength                Number of steps to be simulated ( == length of the test vector)
%     bInteractiveSimulation If simulation should be interactive. If not specified, default is false.
%
%   OUTPUT              DESCRIPTION
%     oSimException          Any exception that occured during simulation
%


%%
% last parameters are not mandatory --> use defaults
if (nargin < 4)
    bInteractiveSimulation = false;
end

%%
[sSimModelPath, sSimModelName] = fileparts(sSimEnvModel);

% we have to cd into model directory
sCurPath = cd;
if ~strcmp(sCurPath, sSimModelPath)
    cd(sSimModelPath);
    xOnCleanupReturn = onCleanup(@() cd(sCurPath));
end

% BTS/14992
sModeDir = fullfile(pwd, 'config');
if exist(sModeDir, 'dir')
    addpath(sModeDir);
    xOnCleanupRemovePath = onCleanup(@() rmpath(sModeDir));
end

i_setSolverStopTime(xEnv, sSimModelName, nLength);

if verLessThan('matlab', '9.5')
    % for lower ML versions setting parameters during init phase of main model comes too late for model references
    % --> model references are called earlier and need to be initialized earlier
    % --> manually evaluate the init callback of the main function
    i_evalInitCallback(xEnv, sSimModelName);
end
i_evalPreSimCallback(xEnv, sSimModelName);

oSimException = i_simulate(xEnv, sSimModelName, bInteractiveSimulation);
end


%%
function hSolver = i_getSolver(sModelName)
hModel  = get_param(sModelName, 'Handle');
cfgSrc  = getActiveConfigSet(hModel);
hSolver = cfgSrc.getComponent('Solver');
end


%%
function sSampleTime = i_getSampleTime(xEnv, hSolver, sModelName)
sSampleTime = hSolver.FixedStep;

dSampleTime = evalin('base', sSampleTime);
if (~isnumeric(dSampleTime) || isnan(dSampleTime))
    xEnv.throwException(xEnv.addMessage('EP:SIM:INVALID_SAMPLE_TIME', 'model', sModelName, 'sampleTime', sSampleTime));
end
end


%%
function i_setSolverStopTime(xEnv, sSimModelName, nLength)
hSolver = i_getSolver(sSimModelName);
sSampleTime = i_getSampleTime(xEnv, hSolver, sSimModelName);

nStopLength = max(0, nLength - 1);
hSolver.StopTime = sprintf('%s * %s', sSampleTime, num2str(nStopLength));
end


%%
function oSimException = i_simulate(xEnv, sSimModelName, bInteractiveSimulation)
oSimException = [];

oOnCleanupRestoreState = ep_simenv_env_init(xEnv, sSimModelName, true); %#ok<NASGU>

tic;
try 
    if bInteractiveSimulation
        ep_simenv_simulate_interactive(sSimModelName);
    else
        sSimCommand = sprintf('sim(''%s'');', sSimModelName);
        evalin('base', sSimCommand);       
    end
    ep_simenv_eval_warning(xEnv);
    
catch oSimException
end
fprintf('### Native Simulation Model "%s" Time :\n', sSimModelName);
toc;
end


%%
function i_evalInitCallback(xEnv, sModelName)
i_evalAdditionalCallback(xEnv, [sModelName, '_initfcn']);
end


%%
function i_evalPreSimCallback(xEnv, sModelName)
i_evalAdditionalCallback(xEnv, [sModelName, '_pre_sim']);
end


%%
function i_evalAdditionalCallback(xEnv, sCallback)
if ~isempty(which(sCallback))
    try
        evalin('base', sCallback);

    catch oEx
        sID = 'EP:ERROR:EXEC_CALLBACK_FAILED';
        sExecptionMsg = oEx.getReport('basic', 'hyperlinks', 'off');
        warning(sID, '%s', sExecptionMsg);

        sMsg = sprintf('[%s] -- "%s"\n%s', sID, sCallback, sExecptionMsg);
        xEnv.addMessage('EP:SIM:WARNING', 'msg', sMsg);
    end
end
end
