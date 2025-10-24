function oEca = ep_ec_model_wrapper_extend(oEca, oEcaWrapper)
% Provided with the analysis object of the wrapper model, extend the analysis object of the original AUTOSAR model.
%
% function oEca = ep_ec_model_wrapper_extend(oEca, oEcaWrapper)
%
%   INPUT                              DESCRIPTION
%     oEca                         (object)      Analysis results of the original AUTOSAR model
%     oEcaWrapper                  (object)      Analysis result of the wrapper model
%
%  OUTPUT                              DESCRIPTION
%     oEca                         (object)      Analysis results of the original AUTOSAR model extended with the info
%                                                from the wrapper analysis
%


%%
% ---- extend C file info ------
astAllSourcesFiles = i_extendSourceFiles( ...
    oEca.oRootScope.astCodegenSourcesFiles, ...
    oEcaWrapper.oRootScope.astCodegenSourcesFiles, ...
    oEcaWrapper.sModelName);
casAllIncludePaths = i_extendIncludePaths( ...
    oEca.oRootScope.casCodegenIncludePaths, ...
    oEcaWrapper.oRootScope.casCodegenIncludePaths);

% hack: currently code info is handled in main object *and* in root (and other) scopes --> TODO needs to be cleaned up
oEca.astCodegenSourcesFiles = astAllSourcesFiles;
oEca.oRootScope.astCodegenSourcesFiles = astAllSourcesFiles;

oEca.casCodegenIncludePaths = casAllIncludePaths;
oEca.oRootScope.casCodegenIncludePaths = casAllIncludePaths;
oEca.sAutosarWrapperCodegenPath = oEcaWrapper.sCodegenPath;

% ---- extend interfaces -------
oEca.oRootScope.oaInputs     = i_extendInterfaces(oEca.oRootScope.oaInputs, oEcaWrapper.oRootScope.oaInputs);
oEca.oRootScope.oaOutputs    = i_extendInterfaces(oEca.oRootScope.oaOutputs, oEcaWrapper.oRootScope.oaOutputs);
oEca.oRootScope.oaParameters = i_extendParameters( ...
    oEca.oRootScope.oaParameters, ...
    oEcaWrapper.oRootScope.oaParameters, ...
    oEca.sAutosarWrapperVariantSubsystem);

% ---- merge constants ----
oEca.astConstants = [oEcaWrapper.astConstants oEca.astConstants];

% ---- fill incomplete DS info in Runnables and child scopes ---
mWrapperDsms = i_getWrapperDataStores(oEcaWrapper.oRootScope);
oEca.oRootScope.oaChildrenScopes = i_enhanceDsmInterfacesWithWrapperInfo(oEca.oRootScope.oaChildrenScopes, mWrapperDsms);

% note: this is probably not necessary, since the runnables info is already present in the child-scopes of the root
oEca.aoRunnableScopes = i_enhanceDsmInterfacesWithWrapperInfo(oEca.aoRunnableScopes, mWrapperDsms);

% typedef namespace workaround for ECAA
oEca = ep_ec_aa_wrapper_namespace_header_create(oEca);
end


%%
% repair incomplete DS info in Runnables with complete info from Wrapper DS objects ---
function aoRunnableScopes = i_enhanceDsmInterfacesWithWrapperInfo(aoRunnableScopes, mWrapperDsms)
aoRunnableScopes = arrayfun(@(o) i_enhanceDsmInterfaces(o, mWrapperDsms), aoRunnableScopes);
end


%%
function oScope = i_enhanceDsmInterfaces(oScope, mWrapperDsms)

% first recursively ehance the children scopes
oScope.oaChildrenScopes = i_enhanceDsmInterfacesWithWrapperInfo(oScope.oaChildrenScopes, mWrapperDsms);

% now enhance the interfaces of *this* scope
oScope.oaInputs  = arrayfun(@(o) i_enhaceDsmInterface(o, mWrapperDsms), oScope.oaInputs);
oScope.oaOutputs = arrayfun(@(o) i_enhaceDsmInterface(o, mWrapperDsms), oScope.oaOutputs);
end


%%
function oIntf = i_enhaceDsmInterface(oIntf, mWrapperDsms)
if (~oIntf.isDsm || ~mWrapperDsms.isKey(i_getKey(oIntf)))
    return;
end

% 1) keep old state in memory for later transfer ...
oIncompleteIntf = oIntf;

% 2) ... then replace old state fully ...
oIntf = mWrapperDsms(i_getKey(oIntf));

% 3) ... then transfer some relevant attributes from old to new state
casTransfAttr = { ...
    'sParentModelName', ...
    'sParentScopePath', ...
    'sParentScopeAccess', ...
    'sParentScopeModelRef', ...
    'sParentScopeDefFile', ...
    'sParentScopeFuncName', ...
    'sParentRunnableName', ...
    'sParentRunnablePath'};
for i = 1:numel(casTransfAttr)
    oIntf.(casTransfAttr{i}) = oIncompleteIntf.(casTransfAttr{i});
end
end


%%
function mWrapperDsms = i_getWrapperDataStores(oRootScope)
mWrapperDsms = containers.Map();

for i = 1:numel(oRootScope.oaInputs)
    if oRootScope.oaInputs(i).isDsm
        mWrapperDsms(i_getKey(oRootScope.oaInputs(i))) = oRootScope.oaInputs(i);
    end
end
for i = 1:numel(oRootScope.oaOutputs)
    if oRootScope.oaOutputs(i).isDsm
        mWrapperDsms(i_getKey(oRootScope.oaOutputs(i))) = oRootScope.oaOutputs(i);
    end
end
end


%%
function sKey = i_getKey(oItf)
if oItf.isBusElement
    oMetaBus = oItf.getMetaBus;

    % Note: Do not use the oMetaBus.modelSignalPath as extended key because it contains the root signal name, which
    % might deviate between wrapper and autosar info objects.
    sKey = [oItf.sourceBlockFullName, oMetaBus.codeVariableAccess];
else
    sKey = oItf.sourceBlockFullName;
end
end


%%
function aoAllInterfaces = i_extendInterfaces(aoArInterfaces, aoWrapperInterfaces)
% initialize with full list of original model
aoAllInterfaces = aoArInterfaces;
mBlockToIdx = i_getBlockToIndexMap(aoAllInterfaces);

for i = 1:numel(aoWrapperInterfaces)
    oWrapperIF = aoWrapperInterfaces(i);    
    sKey = i_getKey(oWrapperIF);
    
    if mBlockToIdx.isKey(sKey)
        iIdx = mBlockToIdx(sKey);
        aoAllInterfaces(iIdx) = i_mergeInterfaces(aoAllInterfaces(iIdx), oWrapperIF);
    else
        if ~isempty(aoAllInterfaces)
            aoAllInterfaces(end + 1) = oWrapperIF; %#ok<AGROW>
        else
            aoAllInterfaces = oWrapperIF;            
        end
    end
end
end


%%
% Note: The interface object of the port that was evaluated in *wrapper* mode is complete in context of MIL but 
%       incomplete in context of SIL and vice-versa for the interface object of the same port in *AUTOSAR* mode.
%       Goal of this function is to combine both information sources into a complete object that can later provide
%       the correct mapping information for the Mapping XML and the code information for the CodeModel XML.
function oMergedIF = i_mergeInterfaces(oAutosarModeIF, oWrapperModeIF)
% use the wrapper-mode info as basis --> MIL info is now complete but SIL info is either incomplete or plain wrong
oMergedIF = oWrapperModeIF;

% replace the code info with the info from the autosar-mode
casAttributesToBeReplaced = oAutosarModeIF.getCodeAttributeNames;
for i = 1:numel(casAttributesToBeReplaced)
    sAtt = casAttributesToBeReplaced{i};
    oMergedIF.(sAtt) = oAutosarModeIF.(sAtt);
end

if (strcmp(oMergedIF.kind, 'OUT') && oMergedIF.isBusElement)
    sWrapperRootSigName = i_getRootSigName(oMergedIF);
    sArRootSigName = i_getRootSigName(oAutosarModeIF);
    if (isempty(sWrapperRootSigName) && ~isempty(sArRootSigName))
        oMergedIF.oMetaBusSig_ = oMergedIF.oMetaBusSig_.copyWithDifferentRootName(sArRootSigName);
        oMergedIF.metaBusSignal.oMetaBusSig = oMergedIF.oMetaBusSig_;
        oMergedIF.metaBusSignal.modelSignalPath = oMergedIF.oMetaBusSig_.modelSignalPath;
    end
end
end


%%
function sSigName = i_getRootSigName(oIF)
if ~isempty(oIF.oSigSL_)
    sSigName = oIF.oSigSL_.getName();
else
    sSigName = '';
end
end



%%
function aoAllParams = i_extendParameters(aoParams, aoWrapperParams, sAutosarWrapperVariantSubsystem)
% initialize all-params with filtered list of original model
[aoAllParams, aoModelParamArgs] = i_filterModelParamArguments(aoParams);
if ~isempty(aoAllParams)
    casKnownNames = arrayfun(@(o) o.getName(), aoAllParams, 'UniformOutput', false);
else
    casKnownNames = {};
end
jKnownInterfaces = i_asSet(casKnownNames);

for i = 1:numel(aoWrapperParams)
    oWrapperParam = aoWrapperParams(i);    
    sName = oWrapperParam.getName();
    
    if i_isVariantSubsystemMaskModelArgument(oWrapperParam, sAutosarWrapperVariantSubsystem)
        [oWrapperParam, bIsValid] = i_replaceCodeInfoInParameterWithAutosarInfo(oWrapperParam, aoModelParamArgs);
        if ~bIsValid
            % if the code information cannot be replaced in a valid way, just ignore the model argument
            continue;
        end
    end
    if ~jKnownInterfaces.contains(sName)
        if ~isempty(aoAllParams)
            aoAllParams(end + 1) = oWrapperParam; %#ok<AGROW>
        else
            aoAllParams = oWrapperParam;            
        end
        jKnownInterfaces.add(sName);
    end
end
end


%%
function [aoParams, aoModelParamArgs] = i_filterModelParamArguments(aoParams)
abIsModelParamArg = arrayfun(@i_isModelParamArg, aoParams);
aoModelParamArgs = aoParams(abIsModelParamArg);
aoParams = aoParams(~abIsModelParamArg);
end


%%
function bIsModelParamArg = i_isModelParamArg(oParam)
bIsModelParamArg = oParam.stParam_.bIsModelArg;
end


%%
function bIsArg = i_isVariantSubsystemMaskModelArgument(oWrapperParam, sAutosarWrapperVariantSubsystem)
casBlockPaths = {oWrapperParam.stParam_.astBlockInfo(:).sPath};
bIsArg = any(strcmp(sAutosarWrapperVariantSubsystem, casBlockPaths));
end


%%
function [oWrapperParam, bIsValid] = i_replaceCodeInfoInParameterWithAutosarInfo(oWrapperParam, aoModelParamArgs)
bIsValid = false;

oModelParamArg = i_getCorrespondingModelParamArg(oWrapperParam, aoModelParamArgs);
if (~isempty(oModelParamArg) && oModelParamArg.bMappingValid)
    oWrapperParam = oWrapperParam.replaceCodeProperties(oModelParamArg);
    bIsValid = true;
end
end


%%
function oModelParamArg = i_getCorrespondingModelParamArg(oWrapperParam, aoModelParamArgs)
oModelParamArg = [];

% NOTE: correspondence is currently only based on variable name equality 
%       --> could be replaced by a more thorough check
%           WrapperParam (WP) is-used-by MaskParam (MP) is-used-by ModelReferenceArgument (MRA)
sWrapperParamName = oWrapperParam.name;
for i = 1:numel(aoModelParamArgs)
    if strcmp(sWrapperParamName, aoModelParamArgs(i).name)
        oModelParamArg = aoModelParamArgs(i);
        return;
    end
end
end


%%
function casAllIncludePaths = i_extendIncludePaths(casIncludePaths, casWrapperIncludePaths)
% initialize with full list of original model
casAllIncludePaths = casIncludePaths;
jKnownPaths = i_asSet(casAllIncludePaths);

for i = 1:numel(casWrapperIncludePaths)
    sPath = casWrapperIncludePaths{i};
    
    if ~jKnownPaths.contains(sPath)
        casAllIncludePaths{end + 1} = sPath; %#ok<AGROW>
        jKnownPaths.add(sPath);
    end
end
end


%%
function astAllFiles = i_extendSourceFiles(astFiles, astWrapperFiles, sWrapperModel)
% initialize with full list of original model
astAllFiles = astFiles;
jKnownFiles = i_asSet(i_getNormalizedNames({astFiles.path}));

% add all C files that are not part
for i = 1:numel(astWrapperFiles)
    stWrapperFile = astWrapperFiles(i);    
    sName = i_getNormalizedName(stWrapperFile.path);
    
    % do not overwrite/redefine files from the original model
    if jKnownFiles.contains(sName)
        continue;
    end
    
    % filter out EP dummy files
    if startsWith(sName, 'ep_dummy_code')
        continue;
    end
    
    % only the main file of the wrapper shall be annotated --> no annotation for the others
    if ~strcmpi(sName, sWrapperModel)
        stWrapperFile.codecov = false;
    end
    
    % extend the list
    astAllFiles(end + 1) = stWrapperFile; %#ok<AGROW>
    
    jKnownFiles.add(sName);
end
end


%%
function casNames = i_getNormalizedNames(casPaths)
casNames = cellfun(@i_getNormalizedName, casPaths, 'UniformOutput', false);
end


%%
function sName = i_getNormalizedName(sPath)
[~, sName] = fileparts(sPath);
end


%%
function jSet = i_asSet(casStrings)
jSet = java.util.HashSet(numel(casStrings));
for i = 1:numel(casStrings)
    jSet.add(casStrings{i});
end
end


%%
function mMap = i_getBlockToIndexMap(aoInterfaces)
mMap = containers.Map;
for i = 1:numel(aoInterfaces)
    mMap(i_getKey(aoInterfaces(i))) = i;
end
end


%%
function bContainsUpdateEvents = i_bContainsUpdateEvents(oEca)
bContainsUpdateEvents = false;
if (~oEca.bIsAdaptiveAutosar)
    return;
end
astRequiredPorts = oEca.oAutosarMetaProps.astRequiredPorts;
if ~isempty(astRequiredPorts)
    for i = 1:numel(astRequiredPorts)
        stInterface = astRequiredPorts(i).stInterface;
        astFields = stInterface.astFields;
        if ~isempty(astFields)
            for k = 1:numel(astFields)
                bContainsUpdateEvents = astFields(k).bHasNotifier;
                if bContainsUpdateEvents
                    return;
                end
            end
        end
    end
end
end


