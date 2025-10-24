function ep_simenv_prepare(xEnv, sSimEnvModel, sInitVectorFile, sMode, sSimulationMode, bStepByStep, sInputsVectorFile, sParamsVectorFile, sOutputsVectorFile)
% Prepares the model for simulation (main internal functionality).
%
% function ep_simenv_prepare(xEnv, sSimEnvModel, sInitVectorFile, sMode, sSimulationMode, bStepByStep, ...
%                            sInputsVectorFile, sParamsVectorFile, sOutputsVectorFile)
%
%   INPUT               DESCRIPTION
%     xEnv               Environment settings.
%     sSimEnvModel        File path to simulation model - loaded assumed.
%     sInitVectorFile     Init vector file
%     sMode               'MIL' | 'SIL' | 'PIL'
%     sSimulationMode     Simulink Simulation Mode {normal, accelerator, rapid or external}
%     bStepByStep         Support StepByStep simulation


%%
% clear all the variables from workspace
ep_simenv_clear_base();

if bStepByStep
    assignin('base', ep_simenv_pause_name, 0);
    ep_simenv_mdl_enable_pause(xEnv, sSimEnvModel);
end

% we have to cd into model directory
sCurPath = cd;
oOnCleanupReturn = onCleanup(@() cd(sCurPath));
[sSimModelPath, sSimModelName] = fileparts(sSimEnvModel);
cd(sSimModelPath);

hModel = get_param(sSimModelName, 'Handle');
i_setStopTimeToInfinity(hModel);
i_evalInitScriptInBase(sSimModelPath, sSimModelName);

if strcmp(sMode, 'MIL')
    set_param(sSimModelName, 'SimulationMode', sSimulationMode);
end
xEnv.setProgress(5, 100, 'Init Model');

% preparing S-Function harness
ep_simenv_init_vect_file_to_sfunc_attach( ...
    xEnv, hModel, sInputsVectorFile, sOutputsVectorFile);
ep_simenv_cals2ws_init(sInitVectorFile, sParamsVectorFile);
%special workaround for Matlab 2018a, can be deleted after discontinuing support for this version
%initialization order would else be wrong here
if i_verEquals('matlab','9.4')
    sInitScript = [sSimModelName, '_initfcn'];
    if exist(sInitScript, 'file')
        evalin('base', sInitScript);
    end
end


xEnv.setProgress(70, 100, 'Init Model');

% handling simulation mode for MIL
if strcmp(sMode, 'MIL')
    set_param(sSimModelName, 'SimulationMode', sSimulationMode);
    
    if any(strcmp(sSimulationMode, {'accelerator', 'rapid'}))
        i_accelbuildModel(xEnv, sSimModelName);
    end
end
xEnv.setProgress(100, 100, 'Init Model');
end


%%
function i_accelbuildModel(xEnv, sSimModelName)
oOnCleanupRestoreState = ep_simenv_env_init(xEnv, sSimModelName, false); %#ok<NASGU>
try
    accelbuild(sSimModelName);
    ep_simenv_eval_warning(xEnv);
    
catch oEx
    set_param(sSimModelName, 'SimulationCommand', 'stop');
    
    if (strcmp(oEx.identifier, 'Simulink:SL_CallbackEvalErr') && ...
            ~isempty(strfind(oEx.message, 'TargetLink license check failed')))
        xEnv.throwException( ...
            xEnv.addMessage('EP:SLAPI:TARGETLINK_LICENSE_FAILED', ...
            'model', sSimModelName, ...
            'text',  stError.message));
        
    else
        sMsg = oEx.message;
        xEnv.throwException(...
            xEnv.addMessage('EP:SLAPI:INIT_MODEL_FAILURE',...
            'testcase', 'TestCase', ...
            'text',     sMsg));
        
    end
end
end


%%
function i_evalInitScriptInBase(sSimModelPath, sSimModelName)
sScriptName = [sSimModelName, '_init'];
sInitScript = fullfile(sSimModelPath, [sScriptName, '.m']);
if (exist(sInitScript, 'file') == 2)
    try evalin('base', sScriptName); catch end %#ok
end
end


%%
function i_setStopTimeToInfinity(hModel)
cfgSrc = getActiveConfigSet(hModel);
solver = cfgSrc.getComponent('Solver');
solver.StopTime = 'inf';
end

%%
function bEquals = i_verEquals(sFeature, sCmp)
stInfo = ver(sFeature);
sVersion = stInfo.Version;
bEquals = strcmp(sVersion, sCmp);
end

