function [stResultUI, stResultAPI, stFullResult] = ep_ec_model_analyze(varargin)
% This function retrieves model and code information.
%
% function stResult = ep_ec_model_analyze(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following possibles values
%
%    Key(string):            Meaning of the Value:
%    - ModelFile                (string)*   The absolute path to the Simulink model.
%    - InitScriptFile           (string)*   The absolute path to the init script of the Simulink model. (can be empty)
%
%    - FixedStepSolver          (string)*   ('yes' | 'no')
%                                           Handling when a non-fixed-step solver is ecountered: If 'yes', the solver
%                                           is automatically set to fixed-step. Otherwise an error is issued.
%    - ParameterHandling        (string)*   The parameter handling, either 'Off' or 'ExplicitParam'.
%                                           ----------------------------------------------------------------------------
%    - DSReadWriteObservable    (boolean)   If set to true, Data Stores used as both DSRead and DSWrite are used as an 
%                                           output instead of rejecting them.            
%                                           ----------------------------------------------------------------------------
%    - TestMode                 (string)*   The test mode, either 'BlackBox' or 'GreyBox'.
%    - AddCodeModel             (string)*   ('yes' | 'no')
%                                           ----------------- 'yes' ----------------------------------------------------
%                                           Simulink model and C-Code model are imported.
%                                           ----------------- 'no' -----------------------------------------------------
%                                           CodeModel file and Mapping file are not extracted for the import. Meaning
%                                           only the Simulink model is analyzed. C-Code and mapping are omitted.
%                                           ----------------------------------------------------------------------------
%    - GlobalConfigFolderPath   (string)*   Path to the global configuration folder
%
%    - CompilerFile             (string)*   Location where the Compiler file shall be placed.
%    - AddModelInfoFile         (string)*   Location where the AddModelInfoFile shall be placed.
%    - SlArchFile               (string)*   Location where the SL architecture file shall be placed.
%    - SlConstrFile             (string)*   Location where the SL constraints file shall be placed.
%    - MappingFile              (string)*   Location where the Mapping file shall be placed.
%    - ConstantsFile            (string)*   Location where the Constants file shall be placed.
%    - CodeModelFile            (string)*   Location where the CodeModel file shall be placed.
%    - MessageFile              (string)*   Location where the Message file shall be placed.
%
%    - Progress                 (object)    Object for tracking progress, e.g. UI workflow.
%
%  OUTPUT            DESCRIPTION
%    stResultUI                 (struct)    reduced info about subsystems/parameters to be presented in the EC Import UI
%    stResultAPI                (struct)    mixture of original arguments and results; to be processed by API workflows
%    stFullResult               (struct)    full info for debugging
%


%%
stResultUI = struct( ...
    'bIsValid',                 true, ...
    'bFixedStepSolver',         false, ...
    'stModel',                  [], ...
    'sSlInitScript',            '', ...
    'astModules',               [], ...
    'sResultDir',               '', ...
    'sCodeModel',               '', ...
    'sAdaptiveStubcodeXmlFile', '', ...
    'sMappingFile',             '', ...
    'sConstantsFile',           '', ...
    'sSlArchFile',              '', ...
    'sSlConstrFile',            '', ...
    'sAddModelInfo',            '', ...
    'bAddCodeModel',            true, ...
    'sParameterHandling',       '', ...
    'sTestMode',                '', ...
    'sMessageFile',             '', ...
    'bReuseExistingCode',       false, ...
    'astFileList',               []);


%%
caxArgs = varargin;
if (numel(caxArgs) < 8)
    % with so few arguments, we are probably in DEBUG mode --> fill up the missing args with defaults
    caxArgs = ep_ec_args_default('', caxArgs{:});
end
stEcArgs = ep_ec_args_eval(caxArgs{:});

% for now use fixed name for StubCodeAA XML; later use an argument key-value pair for that
stEcArgs.AdaptiveStubcodeXmlFile = fullfile(fileparts(stEcArgs.CodeModelFile), 'stubCodeAA.xml');

xEnv = EPEnvironment(stEcArgs.Progress);
stResultUI.sSlInitScript = stEcArgs.InitScriptFile;
stResultUI.sResultDir = stEcArgs.ResultDir;
stResultUI.sMessageFile = stEcArgs.MessageFile;
stResultUI.sParameterHandling = stEcArgs.ParameterHandling;
stResultUI.sTestMode = stEcArgs.TestMode;
stResultUI.bAddCodeModel = stEcArgs.AddCodeModel;
stResultUI.bReuseExistingCode = stEcArgs.ReuseExistingCode;

try
    % go to model directory
    sPwd = pwd;
    sPath = fileparts(stEcArgs.ModelFile);
    cd(sPath);
    oOnCleanupReturn = onCleanup(@() cd(sPwd));
    
    % open the model
    xEnv.setProgress(0, 100, 'Opening Simulink Model');
    bExplicitlySetFixedStepSolver = strcmpi(stEcArgs.FixedStepSolver, 'yes');
    stSlOpen = i_openModel(xEnv, stEcArgs.ModelFile, stEcArgs.InitScriptFile, bExplicitlySetFixedStepSolver);
    oOnCleanupCloseModel = onCleanup(@() ep_core_model_close(xEnv, stSlOpen));
    
    % check Simulink model and retrieve meta information about the model
    xEnv.setProgress(20, 100, 'Analyzing Simulink Model');    
    i_assertValidity(xEnv, stEcArgs.Model);
    
    stResultUI.bFixedStepSolver = i_checkSolverType(xEnv, stEcArgs.Model);
    if stResultUI.bFixedStepSolver
        [stResultUI.stModel, stResultUI.astModules] = ep_ec_model_info_get(xEnv, stEcArgs);
        
        stResultUI.sCodeModel     = stEcArgs.CodeModelFile;
        stResultUI.sMappingFile   = stEcArgs.MappingFile;
        stResultUI.sSlArchFile    = stEcArgs.SlArchFile;
        stResultUI.sSlConstrFile  = stEcArgs.SlConstrFile;
        stResultUI.sConstantsFile = stEcArgs.ConstantsFile;
        stResultUI.sAddModelInfo  = stEcArgs.AddModelInfoFile;
        stResultUI.sAdaptiveStubcodeXmlFile = stEcArgs.AdaptiveStubcodeXmlFile;
    end

    %%
    xEnv.setProgress(80, 100, 'Analyzing Compiler');
    % get MEX compiler settings
    if isfield(stEcArgs, 'CompilerFile') && ~isempty(stEcArgs.CompilerFile)
        ep_core_compiler_settings_get('XMLOutputFile', stEcArgs.CompilerFile);
        stResultUI.sCompilerFile = stEcArgs.CompilerFile;
    end
    
    % Collect all the C code if existing in this command mode for Linux REST servers
    if isunix && exist(stResultUI.sCodeModel, 'file') ~= 0
        ep_arch_collect_c_sources(xEnv, stResultUI.sCodeModel, ~isempty(stResultUI.sAdaptiveStubcodeXmlFile));
    end    
    
    % combine and adapt results
    stFullResult = stResultUI;
    stResultUI = i_getReducedVersion(stFullResult);
    
    stResultAPI = i_combineArgumentsAndResultsForAPI(stEcArgs, stFullResult);
    stResultUI.astFileList = stResultAPI.astFileList;
    
    xEnv.setProgress(100, 100, 'Analysis finished');
    
    % clean up
    xEnv.exportMessages(stEcArgs.MessageFile);
    xEnv.clear();
    
catch oEx
    EPEnvironment.cleanAndThrowException(xEnv, oEx, stEcArgs.MessageFile);
end
end


%%
function i_assertValidity(xEnv, sModel)

% checks Simulink model if contains Variant subblocks with unsupported mode (only from ML2020b)
[bBlackListedVariants, sBlackListedBlks] = i_hasBlocksUsingUnsupportedVariantMode(sModel);
if bBlackListedVariants
    throw(xEnv.addMessage('ATGCV:MOD_ANA:VARIANT_CONTROL_MODE_OPTION_NOT_SUPPORTED', 'blocks', sBlackListedBlks));
end
end


%%
function bFixedStepSolver = i_checkSolverType(xEnv, sModel)
[bFixedStepSolver, sSolverType] = i_isUsingFixedStepSolver(sModel);
if ~bFixedStepSolver
    xEnv.addMessage('ATGCV:MOD_ANA:SOLVER_TYPE_NOT_SUPPORTED', ...
        'solver_type', sSolverType, ...
        'model',       sModel);
end
end


%%
function [bIsFixedStep, sSolverType] = i_isUsingFixedStepSolver(sModel)
sSolverType = get_param(sModel, 'SolverType');
bIsFixedStep = strcmpi(sSolverType, 'fixed-step');
end


%%
function [bHasUnsupportedBlocks, sUnsupportedBlocksAsString] = i_hasBlocksUsingUnsupportedVariantMode(sModel)
if verLessThan('matlab', '9.9')
    casUnsupportedBlocks = {};
else
    % for ML2020b and higher: Unsupported blocks == with Variantcontrol mode: {'(sim)'} {'(codegen)'}
    casUnsupportedBlocks = ep_find_system(sModel, ...
        'LookInsideSubsystemReference', 'on',  ...
        'VariantControlMode',           'sim codegen switching');
end
bHasUnsupportedBlocks = ~isempty(casUnsupportedBlocks);
if bHasUnsupportedBlocks
    sUnsupportedBlocksAsString = sprintf('%s; ', casUnsupportedBlocks{:});
else
    sUnsupportedBlocksAsString = '';
end
end


%%
function stResultAPI = i_combineArgumentsAndResultsForAPI(stEcArgs, stResult)
stResultAPI = stEcArgs;

if ~isempty(stResult.stModel)
    % reduce the information in subsystems to avoid problems when transferring it to Java (ep_ipc_transform_m2j.m)
    astSubs = stResult.stModel.astSubsystems;
    if ~isempty(astSubs)
        astSubs = rmfield(astSubs, 'stCompInfo');
    end
    stResultAPI.castSubs = num2cell(astSubs);
    
    % reduce the information in parameters to avoid problems when transferring it to Java (ep_ipc_transform_m2j.m)
    astParams = stResult.stModel.astParams;
    if ~isempty(astParams)
        astParams = rmfield(astParams, 'astBlockInfo'); 
    end
    stResultAPI.castParams = num2cell(astParams);
    stResultAPI.astFileList = i_extractSUTinformation(stResult.sCodeModel);
else
    stResultAPI.castSubs   = {};
    stResultAPI.castParams = {};
end
stResultAPI.FixedStepSolver = stResult.bFixedStepSolver;
stResultAPI.TempDir = stResult.sResultDir;
end


%%
function astFileList = i_extractSUTinformation(sFile)

if (~isempty(sFile) && exist(sFile, 'file'))
    hFileHandle = mxx_xmltree('load', sFile);
    ahFileNodes = mxx_xmltree('get_nodes', hFileHandle, '/CodeModel/Files/File[@annotate="yes"]');
    nFiles = numel(ahFileNodes);
    astFileList = repmat(struct( ...
            'sName', '', ...
            'sPath', ''), 1, nFiles);
    for i = 1:nFiles
        astFileList(i).sName = mxx_xmltree('get_attribute', ahFileNodes(i),'name');
        astFileList(i).sPath = mxx_xmltree('get_attribute', ahFileNodes(i),'path');
    end
    mxx_xmltree('clear', hFileHandle);
else
    astFileList = [];
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
    [~, sModel] = fileparts(stSlOpen.sModelFile);
    ep_core_model_solver_set(sModel);
end
end


%%
function stReducedResult = i_getReducedVersion(stResult)
stReducedResult = ep_sl_model_reduced_info_get(stResult.stModel);
stReducedResult.sResultDir = stResult.sResultDir;
stReducedResult.bFixedStepSolver = stResult.bFixedStepSolver;
stReducedResult.sConstantsFile = stResult.sConstantsFile;
end
