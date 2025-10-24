function stResult = ep_debug_sl_model_analyze(varargin)
% ONLY for debugging:

%%
stResult = struct( ...
    'bIsValid',         true, ...
    'bFixedStepSolver', false, ...
    'stModel',          [], ...
    'astModules',       []);

%%
caxArgs = varargin;
if (numel(caxArgs) < 8)
    % with so few arguments, we are probably in DEBUG mode --> fill up the missing args with defaults
    caxArgs = ep_sl_args_default('', caxArgs{:});
end
stArgs = ep_sl_args_eval(caxArgs{:});

xEnv = EPEnvironment(stArgs.Progress);
i_checkConsistencyOfArgs(xEnv, stArgs);

%%
try
    % go to model directory
    sPwd = pwd;
    sPath = fileparts(stArgs.ModelFile);
    cd(sPath);
    oOnCleanupReturn = onCleanup(@() cd(sPwd));
    
    % open the model
    xEnv.setProgress(0, 100, 'Opening Simulink Model');
    bExplicitlySetFixedStepSolver = strcmpi(stArgs.FixedStepSolver, 'yes');
    stSlOpen = i_openModel(xEnv, stArgs.ModelFile, stArgs.InitScriptFile, bExplicitlySetFixedStepSolver);
    oOnCleanupCloseModel = onCleanup(@() ep_core_model_close(xEnv, stSlOpen));
    sModel = getfullname(stSlOpen.hModel);
    
    % check Simulink model and retrieve meta information about the model
    [stResult.bFixedStepSolver, sSolverType] = i_isModelUsingFixedStepSolver(sModel);    
    if stResult.bFixedStepSolver
        [stResult.stModel, stResult.astModules] = ep_sl_model_info_get(xEnv, stArgs);
    else
        stResult.bIsValid = false;
        xEnv.addMessage('ATGCV:MOD_ANA:SOLVER_TYPE_NOT_SUPPORTED', ...
            'solver_type', sSolverType, ...
            'model',       sModel);
    end
    xEnv.setProgress(80, 100, 'Analyzing Simulink Model');
    
    % get MEX compiler settings
    if isfield(stArgs, 'CompilerFile') && ~isempty(stArgs.CompilerFile)
        ep_core_compiler_settings_get('XMLOutputFile', stArgs.CompilerFile);
    end

    xEnv.setProgress(100, 100, 'Analyzing Simulink Model');
        
    % clean up
    xEnv.exportMessages(stArgs.MessageFile);
    xEnv.clear();
    
catch oEx
    EPEnvironment.cleanAndThrowException(xEnv, oEx, stArgs.MessageFile);
end
end



%%
function stResult = i_old(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs)
if (nargin < 5)
    stOverrideArgs = struct();
end

stArgs = ut_sl_args_get(xEnv, sModelFile, sInitScript, sResultDir, stOverrideArgs);

i_legacyModelSlAnalyse(xEnv, stArgs);
stModel    = [];
astModules = [];

stResult = struct( ...
    'sSlArch',           stArgs.SlArchFile, ...
    'sSlConstr',         stArgs.SlConstrFile, ...
    'sMessages',         stArgs.MessageFile, ...
    'stModel',           stModel, ...
    'astModules',        astModules);
end


%%
function [stModel, astModules] = i_legacyModelSlAnalyse(xEnv, stArgs)
stOpt = i_adaptArgsToLegacy(xEnv, stArgs);

astModules = ep_arch_get_model_modules(stArgs.Model);
stOpt.astSlModules = astModules;

stModel = ep_model_analyse(stOpt);
end


%%
function stOpt = i_adaptArgsToLegacy(xEnv, stArgs)
stOpt = struct( ...
    'xEnv',              xEnv, ...
    'sModelMode',        'SL', ...
    'sSlModel',          stArgs.Model, ...
    'bCalSupport',       false, ...
    'bDispSupport',      true, ...
    'bParamSupport',     false, ...
    'sAddModelInfo',     stArgs.AddModelInfoFile, ...
    'sModelAnalysis',    fullfile(stArgs.ResultDir, 'ModelAnalysis.xml'), ...
    'sSlResultFile',     stArgs.SlArchFile, ...
    'sSlArchConstrFile', stArgs.SlConstrFile);
if strcmp(stArgs.ParameterHandling, 'ExplicitParam')
    stOpt.bCalSupport   = false;
    stOpt.bParamSupport = true;
end

if strcmp(stArgs.TestMode, 'BlackBox')
    stOpt.bDispSupport   = false;
end
end
