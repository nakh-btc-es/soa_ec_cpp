function [oEca, bSuccess] = ep_ec_model_info_prepare(xEnv, stArgs)
% Retrieving EC-SL/Code/Mapping info from an EC model.
%
% function [oEca, bSuccess] = ep_ec_model_info_prepare(xEnv, stArgs)
%
%   INPUT                              DESCRIPTION
%    xEnv              EPEnvironment object
%    stArgs            argument  struct with the following fields
%
%    FieldName:            Meaning of the Value:
%    - ModelFile                (string)*   The absolute path to the Simulink model.
%    - InitScriptFile           (string)*   The absolute path to the init script of the Simulink model.
%                                           (can be empty)
%    - LoadModel                (boolean)   (re-)load the model explictly and (re-)evaluate the init script
%                                           default == true
%
%    - ParameterHandling        (string)*   The parameter handling, either 'Off' or 'ExplicitParam'.
%    - TestMode                 (string)*   The test mode, either 'BlackBox' or 'GreyBox'.
%    - AddCodeModel             (string)*   ('yes' | 'no')
%    - GlobalConfigFolderPath   (string)*   Location where the global settings are stored.
%    - ReuseExistingCode        (string)*   ('yes' | 'no') Default: no
%
%    - AddModelInfoFile         (string)*   Location where the AddModelInfoFile shall be placed.
%    - SlArchFile               (string)*   Location where the SL arch file shall be placed.
%    - MappingFile              (string)*   Location where the Mapping file shall be placed.
%    - CodeModelFile            (string)*   Location where the CodeModel file shall be placed.
%    - AdaptiveStubcodeXmlFile  (string)*   Location where the StubCode (only for AA models) file shall be placed.
%    - MessageFile              (string)*   Location where the Message file shall be placed.
%    - ConstantsFile            (string)*   Location where the Constants file shall be placed
%                                           ----------------------------------------------------------------------------
%    - DSReadWriteObservable    (boolean)   If set to true, Data Stores used as both DSRead and DSWrite are used as an 
%                                           output instead of rejecting them.            
%                                           ----------------------------------------------------------------------------

%
%  OUTPUT                              DESCRIPTION
%    oEca                       (object)    EcaItf analysis object
%    bSuccess                   (boolean)   Flag telling if analysis was successful
%


%%
bSuccess = false;

stArgs = i_evalArgs(stArgs);

% make sure that we return to the current directory
sPwd = pwd();
oOnCleanupReturnToCurrentMatlabDir = onCleanup(@() cd(sPwd));

% initialize main analysis object
oEca = i_initMainAnalysisObject(stArgs);
oEca.bDiagMode = isempty(xEnv);
if oEca.bDiagMode
    xEnv = EPEnvironment();
    xEnv.setEchoMessages(true);
    oOnCleanupClearTmpEnv = onCleanup(@() xEnv.clear());
    oEca.EPEnv = xEnv;
else
    oEca.EPEnv = xEnv;
end

% evaluate settings/hooks
sModelPath = fileparts(stArgs.ModelFile);
sGlobalPath = stArgs.GlobalConfigFolderPath;
oEca = oEca.evalConfigSettings(sGlobalPath, sModelPath);

% analyze: full EC arch analysis with code and model OR simple SL SIL analysis
[bInitSuccess, oEca] = oEca.checkModelInitialization(stArgs.ModelFile, stArgs.InitScriptFile, stArgs.LoadModel);
if bInitSuccess
    if oEca.bMergedArch
        [bSuccess, oEca] = i_analyzeFullArchitectureEC(oEca);
    else
        % Simulink SIL use case
        % NOTE: overwrite original config for SL SIL use case --> TODO make this somehow cleaner
        oEca.stConfig = slsilcfg_analysis_btc;        
        [bSuccess, oEca] = i_analyzeArchitectureSLSIL(oEca);
    end
end
end


%%
function oEca = i_initMainAnalysisObject(stArgs)
oEca = Eca.EcaItf;
oEca.bMergedArch        = strcmpi(stArgs.AddCodeModel, 'yes');
oEca.bDetectLocals      = strcmp(stArgs.TestMode, 'GreyBox');
oEca.bAllowParameters   = strcmp(stArgs.ParameterHandling, 'ExplicitParam');
oEca.bReuseExistingCode = strcmp(stArgs.ReuseExistingCode, 'yes');

oEca.bDSReadWriteObservable = stArgs.DSReadWriteObservable;

% locations of the output files
oEca.sCodeXmlFile             = stArgs.CodeModelFile;
oEca.sAdaptiveStubcodeXmlFile = stArgs.AdaptiveStubcodeXmlFile;
oEca.sMappingXmlFile          = stArgs.MappingFile;
oEca.sModelInfoXmlFile        = stArgs.AddModelInfoFile;
oEca.sMessageFile             = stArgs.MessageFile;
oEca.sConstantsFile           = stArgs.ConstantsFile;
oEca.sTempDir                 = fileparts(stArgs.AddModelInfoFile);
end


%%
function [bSuccess, oEca] = i_analyzeArchitectureSLSIL(oEca)
[oEca, bSuccess] = oEca.analyzeSimulinkSilArchitecture();
if bSuccess
    oEca.createConstantsXml();
    oEca.createModelXml();
end
end


%%
function [bSuccess, oEca] = i_analyzeFullArchitectureEC(oEcaInitial)
oEcaInitial.evalHook('ecahook_pre_analysis');

oModelInfo = Eca.ModelInfo.get(oEcaInitial.sModelName);
bIsAdaptive = i_isAdaptiveAutosar(oModelInfo);
if bIsAdaptive
    hAnalyzeFunc = @ep_ec_model_aa_internal_analyze;
else
    hAnalyzeFunc = @ep_ec_model_internal_analyze;
end

[bSuccess, oEca] = i_analyzeModel(oEcaInitial, oModelInfo, hAnalyzeFunc);
if bSuccess
    i_exportResultFiles(oEca, bIsAdaptive);
    oEca.evalHook('ecahook_post_analysis', i_getPostAnalysisAddInfo(oEca));
end

oEca.createMessages();
end


%%
function bIsAA = i_isAdaptiveAutosar(stPreInfo)
bIsAA = stPreInfo.bIsValid && stPreInfo.bIsAutosarArchitecture && stPreInfo.stAutosarStyle.bIsAdaptiveAutosar;
end


%%
function [bSuccess, oEca] = i_analyzeModel(oEcaInitial, stPreInfo, hAnalyzeFunc)
[bSuccess, oEca] = feval(hAnalyzeFunc, oEcaInitial, stPreInfo);
if oEca.bIsWrapperComplete
    if bSuccess
        oEcaInitial = i_transferSomeAutosarInfo(oEca, oEcaInitial);
        [bSuccess, oEcaWrapper] = i_analyzeInWrapperMode(oEcaInitial, oEca.sAutosarWrapperVariantSubsystem);
        if bSuccess
            oEca = ep_ec_model_wrapper_extend(oEca, oEcaWrapper);
        end
    end
else
    bSuccess = bSuccess && i_validateAnalysis(oEca);
end
[bHookFound, astConstants] = ep_core_eval_hook('ep_hook_constants_mod', oEca.sModelPath, oEca.astConstants);
if bHookFound
    oEca.astConstants = astConstants;
end
end


%%
function i_exportResultFiles(oEca, bIsAdaptive)
oEca.createCodeXml();
oEca.createMappingXml();
oEca.createModelXml();
oEca.createConstantsXml();
oEca.createImportAsToplevelXml();
if bIsAdaptive
    oEca.createAdaptiveStubcodeXml();
    oEca.createMocksAndExtendCodeXml();
end
end


%%
function oEcaInitial = i_transferSomeAutosarInfo(oEcaAutosar, oEcaInitial)
casProps = { ...
    'sAutosarCodegenPath', ...
    'sAutosarModelName'};

for i = 1:numel(casProps)
    sProp = casProps{i};
    
    oEcaInitial.(sProp) = oEcaAutosar.(sProp);
end
end


%%
function [bSuccess, oEcaWrapper] = i_analyzeInWrapperMode(oEcaInitial, sVariantSub)
oRestoreVariant = i_switchVariantToDummy(sVariantSub); %#ok<NASGU> onCleanup object

oEcaInitial.sAnalysisMode = 'WRAPPER';
[bSuccess, oEcaWrapper] = ep_ec_model_internal_analyze(oEcaInitial);
end


%%
function oRestoreVariant = i_switchVariantToDummy(sVariantSubsystem)
sModel = bdroot(sVariantSubsystem);

% note: the switching of the variant will make the model artificially dirty 
% --> try to avoid that and to return to the previous dirty sate
bHasCleanStateBefore = ~strcmp(get_param(sModel, 'Dirty'), 'on');

sCurrentVariant = get_param(sVariantSubsystem, 'OverrideUsingVariant');
if ~strcmp(sCurrentVariant, 'orig')
    error('EP:DEV:ERROR', 'Expecting variant "orig" to be the overriding active variant.');
end
set_param(sVariantSubsystem, 'OverrideUsingVariant', 'dummy');

oRestoreVariant = onCleanup(@() i_restoreVariant(sVariantSubsystem, sCurrentVariant, bHasCleanStateBefore));
end


%%
function i_restoreVariant(sVariantSubsystem, sCurrentVariant, bSetNonDirty)
set_param(sVariantSubsystem, 'OverrideUsingVariant', sCurrentVariant);

if bSetNonDirty
    sModel = bdroot(sVariantSubsystem);
    set_param(sModel, 'Dirty', 'off');
end
end


%%
% note: analysis is not usable for EP if for an ExportedFunction model only the model level is valid
% --> Example for invalid analysis: AUTOSAR model where *all* runnables are invalid
function bIsValid = i_validateAnalysis(oEca)
bIsValid = true;

bIsExportedFuncModel = ~isempty(oEca.astExportFuncSubsystems);
if ~bIsExportedFuncModel
    return;
end

aoValidScopes = oEca.getAllValidScopes('Model');
bIsValid = (numel(aoValidScopes) > 1) || ((numel(aoValidScopes) == 1) && ~aoValidScopes.bScopeIsModel);
end


%%
function stArgs = i_evalArgs(stArgs)
if ~isfield(stArgs, 'GlobalConfigFolderPath')
    stArgs.GlobalConfigFolderPath = '';
end
if ~isfield(stArgs, 'LoadModel')
    stArgs.LoadModel = true;
end
end


%%
function stAdditionalInfo = i_getPostAnalysisAddInfo(oEca)
stAdditionalInfo = oEca.getHookCommonAddInfo();
stAdditionalInfo.sAddModelinfoFile = oEca.sModelInfoXmlFile;
stAdditionalInfo.sCodeModelFile    = oEca.sCodeXmlFile;
stAdditionalInfo.sMappingFile      = oEca.sMappingXmlFile;
end
