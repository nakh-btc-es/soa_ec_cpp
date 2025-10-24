classdef EcaItf
    %ECITF Summary of this class goes here
    % Detailed explanation goes here
    
    properties (SetAccess = private)
        %Constants
        BTCPRESTEPFUNCNAME  = 'btcStepCounter';
    end
    
    properties
        bMergedArch = true; %True = Model+ProductionCode, False = SimulinkSIL
        sAnalysisMode = 'MODEL';   % currently two analysis modes: 'MODEL' and 'WRAPPER'
        
        sModelFile = '';
        sModelName = '';
        sModelPath = '';
        sStubCodeFolderPath = '';
        sModelExt  = '';
        casModelRefs = {};
        
        oModelActiveCfg = [];  %Simulink Config Set
        
        sMscriptFile = '';
        sMscriptName = '';
        sMscriptPath = '';
        sCurrMatlabFolder = '';
        
        sSLDDFile = '';
        sSLDDName = '';
        sSLDDPath = '';
        
        hModel = [];
        
        casValidAutosarVersions = {};
        stConfig = [];
        stAutosarConfig = [];
        stActiveCodeFormat = [];
        stHooks = [];
        
        sSystemTargetFileName = '';
        bIsSLDDUsed = false;
        dModelSampleTime = [];
        astExportFuncSubsystems = [];
        
        mCombineOutputUpdate = [];
        
        %Objects
        oRootScope = [];
        oBuildInfo = [];
        
        %Codegen
        sCodegenPath = '';
        casCodegenIncludePaths = {};
        casCodegenHeaderFiles  = {};
        astCodegenSourcesFiles = [];
        astDefines = [];
        sPreStepCFunctionName  = ''; % maybe should not really be here?
        bReuseExistingCode = false;
        
        
        %Analysis config
        bAllowParameters    = true;
        bDetectLocals       = false;
        bStubGenerated      = false;
        bAnalysisCompleted  = false;
        bDiagMode           = false;
                
        %EP related
        sTempDir                 = '';
        sCodeXmlFile             = '';
        sAutosarXmlFile          = '';
        sMappingXmlFile          = '';
        sModelInfoXmlFile        = '';
        sAdaptiveStubcodeXmlFile = '';
        sMessageFile             = '';
        sConstantsFile           = '';
        
        %Diagnostics reporting
        sArchiveMatFile      = '';
        sTextAnalysisReport  = '';
        sExcelAnalysisReport = '';
        
        %DataStores and Parameters
        stDataStores = [];
        aoModelWiseCalParams = [];
        aoModelWiseDefineParams = [];
        bDSReadWriteObservable = false;

        %Constants
        astConstants = [];
        
        %SL-functions
        astSLFunctions = [];
        
        %EPEnv for messages
        EPEnv = [];
        
        %Autosar Properties
        bIsAutosarArchitecture  = false;
        bIsAutosarMultiInstance = false;
        bIsAdaptiveAutosar      = false;
        bIsWrapperComplete      = false;
        
        oAutosarProps = [];
        oAutosarSLMapping = [];
        mApp2Imp = [];
        sArComponentPath = '';
        sArComponentName = '';
        bArStubGenerated = false;
        sAutosarVersion = '';
        mParamReceiverPortsToInterface = [];
        jDeclaredRteParams = [];
        
        sAutosarModelName = '';
        hAutosarModel = [];
        sAutosarCodegenPath = '';
        oAutosarBuildInfo = [];
        
        oAutosarMetaProps = [];
        %aoAutosarCom = [];
        aoAutosarRun = [];
        aoRunnables = []; %Meta info of all runnables available in the model
        aoRunnableScopes = []; %Scope objects of runnables actually modeled
        
        sAutosarArchitectureType = '';
        sAutosarWrapperModelName = '';
        sAutosarWrapperCodegenPath = '';
        sAutosarWrapperRootSubsystem = '';
        sAutosarWrapperRefSubsystem = '';
        sAutosarWrapperSchedSubsystem = '';
        sAutosarWrapperVariantSubsystem = '';
        stAutosarWrapperCodeInfo = [];
        
        %Code Descriptor - Function args info
        oCodeDescSubInfoMap = [];
    end
    
    methods
        %--------------------------
        function oEca = EcaItf()
            oEca.oCodeDescSubInfoMap = containers.Map; % initialize as empty map
        end
        %--------------------------
        function consoleInfoPrint(oEca, sMsg)
            if oEca.bDiagMode
                fprintf('%s\n', sMsg);
            end
        end
        %--------------------------
        function consoleWarningPrint(oEca, sMsg)
            if oEca.bDiagMode
                warning('%s\n', sMsg);
            end
        end
        %--------------------------
        function consoleErrorPrint(oEca, sMsg)
            if oEca.bDiagMode
                error('%s\n', sMsg);
            end
        end
        %--------------------------
        function stSettings = evalHook(oEca, sHookName, stAdditionalInfo)
            if (nargin < 3)
                stAdditionalInfo = oEca.getHookCommonAddInfo();
            end
            stSettings = ep_core_feval('ep_ec_hook_file_eval', ...
                oEca.EPEnv, ...
                sHookName, ...
                oEca.stHooks.(sHookName), ...
                stAdditionalInfo);
        end
        %--------------------------
        function b = isExportFuncModel(oEca)
            b = ~isempty(oEca.astExportFuncSubsystems);
        end
        %--------------------------
        function b = isWrapperMode(oEca)
            b = strcmpi(oEca.sAnalysisMode, 'WRAPPER');
        end
        %--------------------------
        function b = isSlSilAnalysis(oEca)
            b = ~oEca.bMergedArch;
        end
        %--------------------------
        function b = hasModelReferences(oEca)
            b = ~isempty(oEca.casModelRefs);
        end
        %--------------------------
        function str = getMScriptFile(oEca)
            str = oEca.sMscriptFile;
        end
        %--------------------------
        function startModelCompilation(oEca, sModelName)
            if (nargin < 2)
                if (oEca.bIsWrapperComplete && ~oEca.isWrapperMode())
                    sModelName = oEca.sAutosarModelName;
                else
                    sModelName = oEca.sModelName;
                end
            end
            i_compileModelWithModelRefs(sModelName);
        end
        %--------------------------
        function stopModelCompilation(oEca, sModelName)
            if (nargin < 2)
                if (oEca.bIsWrapperComplete && ~oEca.isWrapperMode())
                    sModelName = oEca.sAutosarModelName;
                else
                    sModelName = oEca.sModelName;
                end
            end
            i_termModelWithModelRefs(sModelName);
        end
        %--------------------------
        function oException = addMessageEPEnv(oEca, varargin)
            if ~isempty(oEca.EPEnv)
                oException = oEca.EPEnv.addMessage(varargin{:});
            else
                oException = [];
            end
        end
        %--------------------------
        function addMultiWarningsEPEnv(oEca, casWarnMsgs)
            if ~isempty(oEca.EPEnv)
                
                casIDs = repmat({'EP:SLC:WARNING'}, 1, numel(casWarnMsgs));
                ccasKeyVals = cellfun(@(s) {'msg', s}, casWarnMsgs, 'uni', false);
                oEca.EPEnv.addMessages(casIDs, ccasKeyVals);
            end
        end        
        %--------------------------
        function sStubDir = createStubDir(oEca)
            sStubDir = getStubCodeDir(oEca);
            if ~exist(sStubDir, 'dir')
                mkdir(sStubDir);
            end
        end
        %--------------------------
        function sStubDir = getStubCodeDir(oEca)
            sStubRootDir = ep_core_feval('ep_core_canonical_path', oEca.sStubCodeFolderPath, oEca.sModelPath);
            sStubDir = fullfile(sStubRootDir, [oEca.sModelName '_ep_stubs']);
        end
        %--------------------------
        function oBuildInfo = getStoredBuildInfo(oEca)
            if oEca.bIsAutosarArchitecture
                oBuildInfo = oEca.oAutosarBuildInfo;
            else
                oBuildInfo = oEca.oBuildInfo;
            end
        end
        %--------------------------
        function oEca = evalConfigSettings(oEca, sGlobalPath, sModelPath)
            stECConfigs = ep_core_feval('ep_ec_configurations_get', oEca.EPEnv, sGlobalPath, sModelPath);
            oEca.stConfig = stECConfigs.stConfigs.ecacfg_analysis;
            oEca.stAutosarConfig = stECConfigs.stConfigs.ecacfg_analysis_autosar;
            
            oEca.stActiveCodeFormat = i_mergeDisjointStructs( ...
                stECConfigs.stConfigs.ecacfg_codeformat, ...
                stECConfigs.stConfigs.ecacfg_codeformat_autosar);
            
            oEca.stHooks = stECConfigs.stHookFiles;
        end
        %--------------------------
        function stActiveConfig = stActiveConfig(oEca)
            % NOTE: this is just a hack that mimicks a direct access of the structure via the object
            % please use "getActiveConfig()" instead
            stActiveConfig = oEca.getActiveConfig();
        end
        %--------------------------
        function stActiveConfig = getActiveConfig(oEca)
            if oEca.bIsAutosarArchitecture
                stActiveConfig = oEca.stAutosarConfig;
            else
                stActiveConfig = oEca.stConfig;
            end
        end
        %--------------------------
        function sFile = getStubHeaderFile(oEca, sStubContext)
            sFile = [i_getGenericStubPath(oEca, sStubContext), '.h'];
        end
        %--------------------------
        function sFile = getStubSourceFile(oEca, sStubContext)
            sFile = [i_getGenericStubPath(oEca, sStubContext), '.c'];
        end        
        %--------------------------
        function stAdditionalInfo = getHookCommonAddInfo(oEca)
            stAdditionalInfo = i_getHookCommonAddInfo(oEca);
        end
        %--------------------------
        function astSubs = getSubsystemsMappableToExportFuncs(oEca)
            if isempty(oEca.astExportFuncSubsystems)
                astSubs = [];
            else
                astSubs = i_filterOutSubsystemsTriggeredBySameRootInport(oEca.astExportFuncSubsystems);
            end
        end
    end
    
    methods (Static)
        %--------------------------
        function casFileName = FileName(casFilePath)
            casFilePath = cellstr(casFilePath);
            casFileName = cell(1, numel(casFilePath));
            for k = 1:numel(casFilePath)
                [~, name, ext] = fileparts(casFilePath{k});
                casFileName{k} = [name, ext];
            end
        end
        %--------------------------
        function casHeaderFiles = findHeaderFiles(casInclPaths)
            casHeaderFiles = {};
            casInclPaths = cellstr(casInclPaths);
            for k = 1:numel(casInclPaths)
                dirContent = dir(casInclPaths{k});
                for m=1:numel(dirContent)
                    if length(dirContent(m).name)>2
                        sFilename = dirContent(m).name;
                        if strcmpi(sFilename(end-1:end), '.h')
                            casHeaderFiles{end+1} = fullfile(casInclPaths{k}, sFilename);
                        end
                    end
                end
            end
        end
        %--------------------------
        function bOk = allInterfacesMapped(oaScopes)
            bOk = true;
            for iScope = 1:numel(oaScopes)
                if ~isempty(oaScopes(iScope).oaInputs)
                    bOk =  bOk && all([oaScopes(iScope).oaInputs(:).bMappingValid]);
                end
                if ~isempty(oaScopes(iScope).oaOutputs)
                    bOk =  bOk && all([oaScopes(iScope).oaOutputs(:).bMappingValid]);
                end
                if ~isempty(oaScopes(iScope).oaParameters)
                    bOk =  bOk && all([oaScopes(iScope).oaParameters(:).bMappingValid]);
                end
                if ~isempty(oaScopes(iScope).oaLocals)
                    bOk =  bOk && all([oaScopes(iScope).oaLocals(:).bMappingValid]);
                end
            end
        end
        %----------------------
        function bOk = anyInterfacesMapped(oaScopes)
            bOk = false;
            for iScope = 1:numel(oaScopes)
                if ~isempty(oaScopes(iScope).oaInputs)
                    bOk =  bOk || any([oaScopes(iScope).oaInputs(:).bMappingValid]);
                end
                if ~isempty(oaScopes(iScope).oaOutputs)
                    bOk =  bOk || any([oaScopes(iScope).oaOutputs(:).bMappingValid]);
                end
                if ~isempty(oaScopes(iScope).oaParameters)
                    bOk =  bOk || any([oaScopes(iScope).oaParameters(:).bMappingValid]);
                end
                if ~isempty(oaScopes(iScope).oaLocals)
                    bOk =  bOk || any([oaScopes(iScope).oaLocals(:).bMappingValid]);
                end
            end
        end
    end
end


%%
% return only subsystems that have a 1:1 mapping to their fcn-call root inport
function astSubs = i_filterOutSubsystemsTriggeredBySameRootInport(astSubs)
if (numel(astSubs) < 2)
    return;
end

mKnownSet = containers.Map();
abSelect = true(size(astSubs));
for i = 1:numel(astSubs)
    if mKnownSet.isKey(astSubs(i).sFcnCallInport)
        iPrevIndex = mKnownSet(astSubs(i).sFcnCallInport);
        abSelect(i) = false;
        abSelect(iPrevIndex) = false;
    else
        mKnownSet(astSubs(i).sFcnCallInport) = i;
    end
end
astSubs = astSubs(abSelect);
end


%%
function i_compileModelWithModelRefs(sModelName)
casModels = ep_core_feval('ep_find_mdlrefs', sModelName);
casModels = casModels(end:-1:1);
i_compileModelsRobustly(casModels);
end


%%
function i_compileModelsRobustly(casModels)
for k = 1:numel(casModels)
    try
        if verLessThan('matlab', '9.9') % less than ML2020b
            feval(casModels{k}, [], [], [], 'compile');
        else
            i_compileForNewML(casModels{k});
        end
    catch oEx
        if ~strcmp(oEx.identifier, 'Simulink:Engine:UseTopModel')
            if (k > 1)
                i_termModelsRobustly(casModels(1:k-1));
            end
            rethrow(oEx);
        end
    end
end
end


%%
% Note: It is essential that ML versions higher-equal ML2020b are using "compileForRTW" when bringing the model into
%       compiled mode. Otherwise RTW info for deriving Code artifact names/types will be missing.
function i_compileForNewML(sModelName)
try
    feval(sModelName, [], [], [], 'compileForRTW');
catch oEx
    feval(sModelName, [], [], [], 'compile');
end
end


%%
function i_termModelWithModelRefs(sModelName)
casModels = ep_core_feval('ep_find_mdlrefs', sModelName);
casModels = casModels(end:-1:1);
i_termModelsRobustly(casModels);
end


%%
function i_termModelsRobustly(casModels)
if isempty(casModels)
    return;
end
for k = 1:numel(casModels)
    try
        feval(casModels{k}, [], [], [], 'term');
    catch oEx
        if ~any(strcmp(oEx.identifier, {'Simulink:Engine:UseTopModel', 'Simulink:Engine:BdNotCompiled'}))
            warning('EP:EC:TERM_MODEL_FAILED', 'Could not terminate model "%s".\n%s', casModels{k}, oEx.getReport());
        end
    end
end
end


%%
function stStruct = i_mergeDisjointStructs(stStruct, stOtherStruct)
casFieldnames = fieldnames(stOtherStruct);
for i = 1:numel(casFieldnames)
    sField = casFieldnames{i};
    
    if ~isfield(stStruct, sField)
        stStruct.(sField) = stOtherStruct.(sField);
    else
        error('EP:EC:FAILED_MERGE_DISJOINT_STRUCTS', 'Fieldname "%s" encountered in both structs.', sField);
    end
end
end


%%
function sGenericPath = i_getGenericStubPath(oEca, sStubContext)
sStubDir = oEca.getStubCodeDir();
switch lower(sStubContext)
    case 'main'
        if oEca.bIsAutosarArchitecture
            sPrefix = oEca.sAutosarModelName;
        else
            sPrefix = oEca.sModelName;
        end
        sGenericPath = fullfile(sStubDir, [sPrefix, '_ep_main_stub']);
        
    case 'rte'
        sPrefix = oEca.sAutosarModelName;
        sGenericPath = fullfile(sStubDir, [sPrefix, '_ep_rte_stub']);
        
    case 'scheduler'
        sPrefix = oEca.sAutosarModelName;
        sGenericPath = fullfile(sStubDir, [sPrefix, '_ep_scheduler_stub']);
        
    case 'routing'
        sPrefix = oEca.sModelName;
        sGenericPath = fullfile(sStubDir, [sPrefix, '_ep_routing_stub']);
        
    otherwise
        error('EP:DEV:INTERNAL_ERROR', 'Unknown stub context "%s".', sStubContext);
end
end


%%
function stAdditionalInfo = i_getHookCommonAddInfo(oEca)
if oEca.isSlSilAnalysis()
    sStubCodeFolder = '';
else
    sStubCodeFolder = oEca.getStubCodeDir();    
end
sAutosarModelName = oEca.sAutosarModelName;
if (isempty(sAutosarModelName) || strcmp(oEca.sModelName, sAutosarModelName))
    sWrappedAutosarModel = '';
else
    sWrappedAutosarModel = sAutosarModelName;
end
stAdditionalInfo = struct( ...
    'sModelPath',           oEca.sModelPath, ...
    'sModelName',           oEca.sModelName, ...
    'sInitFilePath',        oEca.sMscriptPath, ...
    'sInitFileName',        oEca.sMscriptName, ...
    'sStubCodeFolder',      sStubCodeFolder, ...
    'casReferencedModels',  {oEca.casModelRefs}, ...
    'bIsWrapperMode',       oEca.isWrapperMode(), ...
    'sWrappedAutosarModel', sWrappedAutosarModel);
end
