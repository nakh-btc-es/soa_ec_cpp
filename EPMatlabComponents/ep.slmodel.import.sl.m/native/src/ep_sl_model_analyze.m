function stResult = ep_sl_model_analyze(varargin)
% Analyzes a Simulink model and saves the architecture information as XML (spec: simulink_architecture.xsd).
%
% function stResult = ep_sl_model_analyze(varargin)
%
%  INPUT              DESCRIPTION
%    varargin   ([Key, Value]*)    Key-value pairs with the following possibles values. Parameters with * are mandatory.
%
%    Key(string):            Meaning of the Value:
%    - ModelFile               (String)*   The absolute path to the Simulink model.
%    - InitScriptFile          (String)    The absolute path to the init script of the Simulink model.
%    - ParameterHandling       (String)    ('Off' | {'ExplicitParam'})
%                                          ---------------- 'Off' ---------------------
%                                          Only regular inputs in the interface of subsystems are observed.
%                                          ------------ 'ExplicitParam' ---------------
%                                          Parameter variables are regarded as
%                                          additional inputs to subsystems. Their value is set once during the initial
%                                          phase of the simulation and is held constant thereafter.
%                                          (default is 'ExplicitParam')
%    - TestMode                (String)    ('BlackBox' | {'GreyBox'})
%                                          If set to 'GreyBox', local variables are regarded as additional outputs of
%                                          subystems. For BlackBox-Testing only the regular outputs in the interfaces of
%                                          subsystems are observed. (default is 'GreyBox')
%   - FixedStepSolver          (String)    ('yes' | {'no'})
%                                          ----------------- 'yes' --------------------------------------------------
%                                          The analyzed Simulink model will be set to the fixed-step solver type
%                                          automatically. The usage of the EmbeddedPlatform requires a
%                                          fixed-step solver. If the model is open and the fixed-step solver
%                                          is not already set, this might lead to a modified model.
%                                          ----------------- 'no' ---------------------------------------------------
%                                          The analyzed Simulink model will not be set to the
%                                          fixed-step solver automatically. If the fixed-step solver is not already set
%                                          in the model, the method return with state of a non fixed-step solver.
%                                          In order to proceed the user has to set the
%                                          fixed-step solver manually in the simulation settings.
%                                          ---------------------------------------------------------------------------
%    - DSReadWriteObservable  (boolean)    If set to true, Data Stores used as both DSRead and DSWrite are used as an 
%                                          output instead of rejecting them.            
%                                          ---------------------------------------------------------------------------
%                                          Note: The option is ignored if the model is currently not in an
%                                          open/loaded state. In this case it has no visible side-effect.
%    - AddModelInfoFile        (string)*   The absolute path to additional model information.
%                                          The format is described by the AddModelInfo.dtd.
%    - AddModelInfoIsGenerated (boolean)*  Indicates if the add model info
%                                          file is generated
%    - SlArchFile              (String)*   The absolute path to the Simulink output file.
%    - MessageFile             (String)*   The absolute path to the message file.
%    - CompilerFile            (String)*   The absolute path to the compiler file.
%    - Progress                (object)    Progress object for progress information.
%
%  OUTPUT            DESCRIPTION
%  - stResult                   (Struct)
%      .bFixedStepSolver        (boolean)  Indicates if the model uses a fixed-step solver type. True, means a
%                                          fixed-step solver is used. Otherwise, false is returned.
%


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
        if i_isML2019b()
            % For ML2019b variables with an Enum type defined inside the SLDD lead to the problem that the type cannot
            % be removed. This can potentially cause problems with later simulations. As a workaround replace all 
            % Enum values that can be part of the Param structure with the corresponding int32 value.
            stResult.stModel.astParams = i_removeEnumTypeValuesFromParams(stResult.stModel.astParams);
        end
    else
        stResult.bIsValid = false;
        xEnv.addMessage('ATGCV:MOD_ANA:SOLVER_TYPE_NOT_SUPPORTED', ...
            'solver_type', sSolverType, ...
            'model',       sModel);
    end
    xEnv.setProgress(80, 100, 'Analyzing Simulink Model');
    
    % get MEX compiler settings
    if (isfield(stArgs, 'CompilerFile') && ~isempty(stArgs.CompilerFile))
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
    'sModelFile',                    sSlModelFile, ...
    'caInitScripts',                 {{sSlInitScript}}, ...
    'bIsTL',                         false, ...
    'bCheck',                        true, ...
    'bActivateMil',                  false, ...
    'bIgnoreInitScriptFail',         false, ...
    'bIgnoreAssertModelKind',        true, ...
    'bEnableBusObjectLabelMismatch', true);
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

%%
function bIsML2019b = i_isML2019b()
bIsML2019b = ~verLessThan('matlab', '9.7') && verLessThan('matlab', '9.8'); % ML2019b == 9.7
end

%%
function astParams = i_removeEnumTypeValuesFromParams(astParams)
for i = 1:numel(astParams)
    if (isenum(astParams(i).xValue) && strcmp(astParams(i).sSourceType, 'data dictionary'))
        astParams(i).xValue = int32(astParams(i).xValue);
    end
end
end
