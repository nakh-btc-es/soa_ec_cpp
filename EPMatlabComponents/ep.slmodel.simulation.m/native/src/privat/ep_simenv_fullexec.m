function ep_simenv_fullexec(xEnv, sSimEnvModel, sResultVectorFile, bInteractiveSimulation, sLocalsVectorFile)
% Simulates the model in the previous defined simulation kind.
%
% function ep_simenv_fullexec(xEnv, sSimEnvModel, sResultVectorFile)
%
%   INPUT               DESCRIPTION
%     xEnv                   Environment settings.
%     sSimEnvModel           File path to simulation model - loaded and init assumed.
%     sResultVectorFile      Result vector file
%     bInteractiveSimulation If simulation should be interactive. If not specified, default is false.
%     sLocalsVectorFile      ...
%
%   OUTPUT              DESCRIPTION
%


%%
% last parameters are not mandatory --> use defaults
if (nargin < 4)
    bInteractiveSimulation = false;
end
if (nargin < 5)
    sLocalsVectorFile = '';
end


%%
try    
    [sSimModelPath, sSimModelName] = fileparts(sSimEnvModel);
    hSimModel = get_param(sSimModelName, 'handle');
    
    % we have to cd into model directory
    sCurPath = cd;
    cd(sSimModelPath);
    xOnCleanupReturn = onCleanup(@() cd(sCurPath));
    
    xEnv.setProgress(10, 100, 'Simulate Model');
    
    [nLength, sVecName] = ep_simenv_vec2mat(xEnv, sResultVectorFile);    
    oSimException = ep_simulate(xEnv, sSimEnvModel, nLength, bInteractiveSimulation);
        
    % Evaluate the logging results
    bAvailableTLDS = false;
    anExecutionTime = [];
    anStackSize = 0;
    
    sTempDir = xEnv.getTempDirectory();
    sLoggingFile = fullfile(sSimModelPath, [sSimModelName, '_logging.xml']);    
    if exist(sLoggingFile, 'file')
        if (isempty(oSimException) && atgcv_use_tl)
            stEvalTLDS = ep_sim_tlds_eval();
            bAvailableTLDS = stEvalTLDS.bTLDS;
            anExecutionTime = stEvalTLDS.anExecutionTime;
            anStackSize = stEvalTLDS.anStackSize;
        end
        
        % TODO check will be removed when TL MIL use case is also adapted
        if ~isempty(sLocalsVectorFile)
            if (bAvailableTLDS && i_isLoggingKindTL(sLoggingFile))
                astLocalsData = i_getLocalsFromTLDS(xEnv, sLoggingFile);
            else
                astLocalsData = i_getLocalsFromLoggingVar(xEnv, sLoggingFile);
            end
            ep_sim_log_data_to_mdf_write(sLocalsVectorFile, astLocalsData, nLength);
            
        else
            % TODO: legacy approach to logging that should be gone after MIL harness refactoring
            ep_simenv_logging_evaluate(xEnv, sTempDir, sLoggingFile);
            if bAvailableTLDS
                ep_simenv_tlds_logging_old_approch(xEnv, sTempDir, sLoggingFile, nLength);
            end
        end
    end
    
    
    %% extract values for outputs
    if isempty(oSimException)
        sStatus = 'success';
    else
        sStatus = 'error';
    end
    hSFunctionOut = ep_find_system(hSimModel, 'BlockType', 'S-Function', 'Tag', 'BTC_SIM_MODEL_OUTPUTS');
    if ~isempty(hSFunctionOut)
        if bAvailableTLDS
            i_addSimulationInfo(sResultVectorFile, anExecutionTime, anStackSize, sStatus);
        end
    else
        % TODO: else-block is for the old non-S-Func-harness and is probably DEAD code! check if it can be removed
        ep_simenv_base2tv(sTempDir, sResultVectorFile, bAvailableTLDS, anExecutionTime, anStackSize, sStatus);
    end
    
    xEnv.setProgress(100, 100, 'Simulate Model');
    ep_simenv_eval_exception(xEnv, oSimException, sSimModelName, sVecName);
    
catch exception
    xEnv.rethrowException(exception);
end
end


%%
function bIsTL = i_isLoggingKindTL(sLoggingFile)
hDoc = mxx_xmltree('load', sLoggingFile);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

xLoggingAnalysis = mxx_xmltree('get_root', hDoc);
sKind = mxx_xmltree('get_attribute', xLoggingAnalysis, 'kind');
bIsTL = strcmp(sKind, 'TL');
end


%%
function astLocalsData = i_getLocalsFromLoggingVar(xEnv, sLoggingFile)
astLocalsData = [];
bFoundLogVar = evalin('base', 'exist(''et_logsout'', ''var'');');
if bFoundLogVar    
    oLoggingVar = evalin('base', 'et_logsout');
    evalin('base', 'clear et_logsout;');
    
    astLocalsData = i_evaluateLoggingData(xEnv, sLoggingFile, @(x, y) ep_sim_logvar_to_log_data(x, y, oLoggingVar));
end
end


%%
function astLocalsData = i_getLocalsFromTLDS(xEnv, sLoggingFile)
astLocalsData = i_evaluateLoggingData(xEnv, sLoggingFile, @ep_sim_tlds_to_log_data);
end


%%
function astLocalsData = i_evaluateLoggingData(xEnv, sLoggingFile, hLoggingEvalFunc)
[hSubsystem, xOnCleanupClearDoc] = i_getRootSubsystemNode(sLoggingFile); %#ok<ASGLU> onCleanup object
astLocalsData = feval(hLoggingEvalFunc, xEnv, hSubsystem);
end


%%
function [hSubsystem, xOnCleanupClearDoc] = i_getRootSubsystemNode(sLoggingFile)
hDoc = mxx_xmltree('load', sLoggingFile);
hLoggingAnalysis = mxx_xmltree('get_root', hDoc);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahSubsystems = mxx_xmltree('get_nodes', hLoggingAnalysis, './Subsystem');
hSubsystem = ahSubsystems(1);
end


%%
function i_addSimulationInfo(sResultVectorFile, anExecutionTime, anStackSize, sSimStatus)
xDocInit = mxx_xmltree('load', sResultVectorFile);
xOnCleanupCloseFile = onCleanup(@() mxx_xmltree('clear', xDocInit));
xStimVec = mxx_xmltree('get_root', xDocInit);

% status
xSimStatus = mxx_xmltree('add_node', xStimVec, 'SimStatus');
mxx_xmltree('set_attribute', xSimStatus, 'status', sSimStatus);

% execution time
if( ~isempty(anExecutionTime) )
    hExecutionTime = mxx_xmltree('add_node', xStimVec, 'ExecutionTime');
    mxx_xmltree('set_attribute', hExecutionTime,'value', num2str(anExecutionTime));
end

%stack size
if( ~isempty(anStackSize) )
    hStackSize = mxx_xmltree('add_node', xStimVec, 'StackSize');
    mxx_xmltree('set_attribute', hStackSize, 'value', num2str(anStackSize));
end

mxx_xmltree('save', xDocInit, sResultVectorFile);
mxx_xmltree('clear', xDocInit);
end
