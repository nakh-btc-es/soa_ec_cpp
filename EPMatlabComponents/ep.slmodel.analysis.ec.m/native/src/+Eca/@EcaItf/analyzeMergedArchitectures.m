function oEca = analyzeMergedArchitectures(oEca)
% Main analysis function for the EC workflow. Info is added to the provided object and this modified version is returned.
%
% function oEca = analyzeMergedArchitectures(oEca)
%
%   INPUT                                DESCRIPTION
%    oEca                       (object)    Eca.EcaItf main object (filled with some rudimentary info)
%
%  OUTPUT                                DESCRIPTION
%    oEca                       (object)    Eca.EcaItf main object (filled with full analysis info)
%

%%
if oEca.isWrapperMode()
    oEca.consoleInfoPrint('Analyzing model and code architectures in "wrapper" mode ...');
else
    oEca.consoleInfoPrint('Analyzing model and code architectures ...');
end

% main
[oEca, stSimTimeStub] = i_evaluateCodegenInfo(oEca);

oEca = i_analyzeHierarchyAndInterfaces(oEca);

if ~isempty(stSimTimeStub)
    i_createSimtimeStub(oEca, stSimTimeStub);
end
end


%%
function oEca = i_analyzeHierarchyAndInterfaces(oEca)
% bring model into compiled mode and ensure that the mode is reverted when finished here
oEca.startModelCompilation();
oOnCleanupStopCompilation = onCleanup(@() oEca.stopModelCompilation());

oEmbSignalsCache = Eca.EmbeddedSignalsCache.getInstance;
oEmbSignalsCache.reset(); % just in case, clear the cache before starting the analysis ...
oOnCleanupClearCache = onCleanup(@() oEmbSignalsCache.reset()); % ... but also try to cleanup the cache properly after the analysis

if oEca.bIsAdaptiveAutosar
    oEca.oRootScope = oEca.getAutosarRootScopeAA();
    oEca.astCodegenSourcesFiles = oEca.oRootScope.astCodegenSourcesFiles; % HACK: required for transferring the Adapter file info

else
    % check if we have an export function model and prepare the corresponding data
    oEca.astExportFuncSubsystems = ep_core_feval('ep_ec_export_func_subsystems_get', oEca.hModel);
    
    % SL-functions
    oEca.astSLFunctions = ep_core_feval('ep_model_slfunctions_get', oEca.hModel);
    
    % DataStores
    oEca.stDataStores = oEca.analyzeDataStoreInfo();
    
    % Parameters and Constants
    [oEca.aoModelWiseCalParams, oEca.aoModelWiseDefineParams, oEca.astConstants] = i_getParametersAndConstants(oEca);
    
    % Scopes
    if oEca.bIsAutosarArchitecture
        [oEca.oRootScope, oEca.aoRunnableScopes] = oEca.getAutosarRootScope();
    else
        oEca.oRootScope = oEca.getRootScope();
    end
end
end


%%
function [oEca, stSimTimeStub] = i_evaluateCodegenInfo(oEca)
stSimTimeStub = [];

casInclPaths  = oEca.getCodegenIncludePaths();
casHeaders    = oEca.getCodegenHeaderFiles();
casAddHeaders = oEca.findHeaderFiles(casInclPaths);

if oEca.isWrapperMode()
    casLegacyInclPaths = {};
    casLegacyHeaders   = {};
    astLegacySrcFiles  = [];
    
else
    [stLegacyCode, stSimTimeStub] = i_callPrestepHooks(oEca);
    casLegacyInclPaths = stLegacyCode.casInclPaths;
    casLegacyHeaders   = oEca.findHeaderFiles(stLegacyCode.casInclPaths);
    astLegacySrcFiles  = stLegacyCode.astSrcFiles;

    % Defines
    oEca.astDefines = stLegacyCode.astDefines;

    % Pre-step
    if ~isempty(stLegacyCode.sPreStepFunctionName)
        oEca.sPreStepCFunctionName = stLegacyCode.sPreStepFunctionName;
    end
end

% Include paths
oEca.casCodegenIncludePaths = unique(strrep([casInclPaths, casLegacyInclPaths], '/', filesep), 'stable');

%Header files
oEca.casCodegenHeaderFiles = unique(strrep([casHeaders, casAddHeaders, casLegacyHeaders], '/', filesep), 'stable');

% Sources files
stExcludedFilesNames = oEca.evalHook('ecahook_ignore_code');
oEca.astCodegenSourcesFiles = [oEca.getCodegenSourceFiles(stExcludedFilesNames.casFileNames), astLegacySrcFiles];
end


%%
function [aoCalParams, aoDefineParams, astConstants] = i_getParametersAndConstants(oEca)
astParams = i_findParametersInModel(oEca);

if oEca.bAllowParameters
    stBlackList = oEca.evalHook('ecahook_param_blacklist', i_getHookArgsParamBlacklist(oEca));
    casParamBlackList = stBlackList.casParamlist;
    
    %Parameters interfaces
    aoCalParams = oEca.getModelWiseParameters('PARAM', astParams, casParamBlackList);
    
    %Defines
    aoDefineParams = oEca.getModelWiseParameters('DEFINE', astParams, casParamBlackList);
else
    aoCalParams = [];
    aoDefineParams = [];
end

%Constants
astConstants = oEca.getConstants(astParams);
end


%%
function astParams = i_findParametersInModel(oEca)

xEnv = oEca.EPEnv;

if oEca.bIsAutosarArchitecture
    sModelName = oEca.sAutosarModelName;
else
    sModelName = oEca.sModelName;
end
stResult = ep_core_feval('ep_model_params_get', ...
    'Environment',   xEnv, ...
    'ModelContext',  sModelName, ...
    'SearchMethod',  'cached', ...
    'IncludeModelWorkspace', oEca.bMergedArch);

astParams = reshape(stResult.astParams, 1, []);
astParams = arrayfun(@i_extendWithObjectInfo, astParams);
end


%%
function stParam = i_extendWithObjectInfo(stParam)
stParam.oObj = i_getVariableObjFromParam(stParam);
end


%%
function oObj = i_getVariableObjFromParam(stParam)
oObj = [];
if isempty(stParam.astBlockInfo)
    return;
end

oModelContext = EPModelContext.get(stParam.astBlockInfo(1).sPath);
oObj = oModelContext.getVariable(stParam.sRawName);
end


%%
% Note: currently there are two pre-step hooks:
%  1) legacy hook
%  2) simtime hook
% Both are mutually exclusive. In case both are present a warning is issued and the legacy hook has prio.
%
function [stLegacyCode, stSimTimeStub] = i_callPrestepHooks(oEca)
stSimTimeStub = [];

stLegacyCode = oEca.evalHook('ecahook_legacy_code');
stUserTimeStubFunc = oEca.evalHook('ecahook_simulationtime_get_fun');

if ~isempty(stUserTimeStubFunc.funcname)
    if isempty(stLegacyCode.sPreStepFunctionName)
        stSimTimeStub = struct( ...
            'sPreStepFunc', oEca.BTCPRESTEPFUNCNAME, ...
            'sStubFile',    fullfile(oEca.createStubDir(), stUserTimeStubFunc.filename), ...
            'stFuncInfo',   stUserTimeStubFunc);
    
        stCFile = i_createSimtimeStubFileData(oEca, stSimTimeStub.sStubFile);
        
        stLegacyCode.astSrcFiles = [stLegacyCode.astSrcFiles, stCFile];
        stLegacyCode.sPreStepFunctionName = stSimTimeStub.sPreStepFunc;
    else
        sMsg = strcat('## An external preStep function name and a simulation time stub function', ...
            'is unexpectedly available. Check the provided customization.');
        oEca.addMessageEPEnv('EP:SLC:WARNING', 'msg', sMsg);
        oEca.consoleWarningPrint(sMsg);
    end
end
end


%%
function stCFile = i_createSimtimeStubFileData(oEca, sStubFile)
stCFile = struct( ...
    'path',    sStubFile, ...
    'codecov', false, ...
    'hide',    false);

casSourceFilesTmp = getFullFileList(oEca.getStoredBuildInfo, 'source');
if oEca.bIsAutosarArchitecture && ...
        strcmp(strrep(fileparts(casSourceFilesTmp{1}), '/', filesep),...
        strrep(fullfile(oEca.sAutosarCodegenPath, 'stub'), '/', filesep))
    stCFile.hide = true;
end
end


%%
function i_createSimtimeStub(oEca, stSimTimeStub)
if oEca.bDiagMode
    fprintf('## Generation of Stub code for Get Simulation Time... \n');
end

dSampleTime = oEca.oRootScope.nSampleTime;
ep_core_feval('ep_ec_stub_get_simtime_create', ...
    stSimTimeStub.sPreStepFunc, ...
    stSimTimeStub.sStubFile, ...
    dSampleTime, ...
    stSimTimeStub.stFuncInfo);

if oEca.bDiagMode
    fprintf('<a href="matlab:winopen(''%s'')">%s</a>\n', stSimTimeStub.sStubFile, stSimTimeStub.sStubFile);
end
end


%%
function stAdditionalInfo = i_getHookArgsParamBlacklist(oEca)
stAdditionalInfo = oEca.getHookCommonAddInfo();
stAdditionalInfo.stAutosarMetaInfo = oEca.oAutosarMetaProps;
end
