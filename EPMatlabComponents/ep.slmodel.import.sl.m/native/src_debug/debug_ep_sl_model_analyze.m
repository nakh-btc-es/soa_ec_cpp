function stResult = debug_ep_sl_model_analyze(varargin)
% ONLY for debugging: do *not* deploy!
warning('ONLY:FOR:DEBUGGING', 'Using debug functionality.');

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
stArgs.ModelAnalysis = fullfile(stArgs.ResultDir, 'ModelAnalysis.xml');

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
        [stResult.stModel, stResult.astModules] = debug_ep_sl_model_info_get(xEnv, stArgs);
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
function stSlOpen = i_openModel(xEnv, sSlModelFile, sSlInitScript, bExplicitlySetFixedStepSolver)
stModelOpenArgs = struct( ...
    'sModelFile',                       sSlModelFile, ...
    'caInitScripts',                    {{sSlInitScript}}, ...
    'bIsTL',                            false, ...
    'bCheck',                           true, ...
    'bActivateMil',                     false, ...
    'bIgnoreInitScriptFail',            false, ...
    'bIgnoreAssertModelKind',           true,  ...
    'bEnableBusObjectLabelMismatch',    true);
stSlOpen = ep_core_model_open(xEnv, stModelOpenArgs);

bIsImplicitSettingAllowed = ~stSlOpen.bIsModelOpen;
bDoSetSolver = bExplicitlySetFixedStepSolver || bIsImplicitSettingAllowed;
if bDoSetSolver
    sModel = getfullname(stSlOpen.hModel);
    ep_core_model_solver_set(sModel);
end
end


%%
function [bIsFixedStep, sSolverType] = i_isModelUsingFixedStepSolver(sModel)
sSolverType = get_param(sModel, 'SolverType');
bIsFixedStep = strcmpi(sSolverType, 'fixed-step');
end


%%
function i_checkConsistencyOfArgs(xEnv, stArgs)
if ~isempty(stArgs.AddModelInfoFile)
    i_validateAddModelInfoFile(xEnv, stArgs.AddModelInfoFile);
end
end


%%
function i_validateAddModelInfoFile(xEnv, sAddModelInfoFile)
sDtdName = 'AddModelInfo.dtd';
sDtd = i_getDtd(sDtdName);
try
    hDoc = mxx_xmltree('load', sAddModelInfoFile);
    xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));
    mxx_xmltree('validate', hDoc, sDtd);
    
catch oEx
    xEnv.addMessage('EP:STD:XML_NOT_VALID', 'xml', sAddModelInfoFile, 'dtd', sDtdName);
    [~, f, e]= fileparts(sAddModelInfoFile);
    sXmlFile = [f, e];    
    error('EP:STD:XML_NOT_VALID', 'The file "%s" does not validate:\n%s', sXmlFile, oEx.message);
end
end


%%
function sDtd = i_getDtd(sDtdFileName)
try
    sDtd = fullfile(ep_core_resource_get('spec/dtd'), sDtdFileName);
catch oEx
    oNewEx = MException('EP:API:RESOURCE_SERVICE_ERROR', 'Error using resource service for DTD "%s".', sDtdFileName);
    oNewEx.addCause(oEx);
    throw(oNewEx);
end
if ~exist(sDtd, 'file')
    error('EP:API:DTD_NOT_FOUND', 'Could not find DTD "%s".', sDtdFileName);
end
end
