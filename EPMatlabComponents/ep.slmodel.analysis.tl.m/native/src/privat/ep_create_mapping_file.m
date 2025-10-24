function ep_create_mapping_file(stModel, sMappingResultFile)
% TL Use Case: Generates XML-File for the Mapping (see mapping.xsd),
%
% function ep_create_mapping_file(stModel, sMappingResultFile)
%
%   INPUT               DESCRIPTION
%     stModel               (struct)  model info struct as produced by "ep_model_info_get"
%     sMappingResultFile    (string)  path to the Mapping output file
%
%   OUTPUT              DESCRIPTION
%       -                      -
%

%%
if (nargin < 2)
    sMappingResultFile = fullfile(pwd, 'mapping.xml');
end

%% main
stPathInfo = struct( ...
    'sTlRoot',  stModel.sTlRoot, ...
    'sSlRoot',  stModel.sSlRoot);

hDoc = mxx_xmltree('create', 'Mappings');
xOnCleanupClearMappingDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

hArchMapping = i_addArchitectureMapping(hDoc, stModel.sTlModel, stModel.sSlModel);

casCodePaths = ep_scope_code_paths_get(stModel.astSubsystems);
for i = 1:length(stModel.astSubsystems)
    stSub = stModel.astSubsystems(i);
    if (stSub.bIsDummy || i_isHidden(stSub))
        continue;
    end

    hScopeMapping = i_addScopeMapping(hArchMapping, stSub, casCodePaths{i});
    i_addInterfaceMapping(hScopeMapping, stSub, stModel, stPathInfo);
end
mxx_xmltree('save', hDoc, sMappingResultFile);
end


%%
function bIsHidden = i_isHidden(stObject)
bIsHidden = i_getField(stObject, 'bIsHidden', false);
end


%%
function hArchMapping = i_addArchitectureMapping(hParentNode, sTlModel, sSlModel)
hArchMapping = mxx_xmltree('add_node', hParentNode, 'ArchitectureMapping');

i_addMappingArch(hArchMapping, 'id0', sTlModel);
i_addMappingArch(hArchMapping, 'id1', [sTlModel, ' [C-Code]']);
if ~isempty(sSlModel)
    i_addMappingArch(hArchMapping, 'id2', sSlModel);
end
end


%%
function hScopeMapping = i_addScopeMapping(hParentNode, stSub, sCodePath)
hScopeMapping = mxx_xmltree('add_node', hParentNode, 'ScopeMapping');
sTlPath = i_deleteModelNameFromPath(stSub.sTlPath);
i_addMappingPath(hScopeMapping, 'id0',  sTlPath);
i_addMappingPath(hScopeMapping, 'id1', sCodePath);
if (isfield(stSub, 'sSlPath') && ~isempty(stSub.sSlPath))
    sSlPath = i_deleteModelNameFromPath(stSub.sSlPath);
    i_addMappingPath(hScopeMapping, 'id2', sSlPath);
end
end


%%
function i_addInterfaceMapping(hParentNode, stSubsystem, stModel, stPathInfo)
stInterface = stSubsystem.stInterface;

bWithSL = ~isempty(stPathInfo.sSlRoot);

% ---- add Inputs -----------------
mMapAlias = containers.Map;
for i = 1:length(stInterface.astInports)
    if ~i_skipMappingForInt64Interface(stInterface.astInports(i).stCompInfo.astSignals, stModel.bAdaptiveAutosar)
        i_addMappingForPort(hParentNode, 'Input', stInterface.astInports(i), ...
            stSubsystem.sStepFunc, stSubsystem.stFuncInterface, bWithSL, mMapAlias);
    end
end

% ---- add Outputs ----------------
mMapAlias = containers.Map;
for i = 1:length(stInterface.astOutports)
    if ~i_skipMappingForInt64Interface(stInterface.astOutports(i).stCompInfo.astSignals, stModel.bAdaptiveAutosar)
        i_addMappingForPort(hParentNode, 'Output', stInterface.astOutports(i), ...
            stSubsystem.sStepFunc, stSubsystem.stFuncInterface, bWithSL, mMapAlias);
    end
end

% --- add DSM Ports ---------------
mMapAlias = containers.Map;
nDsmVars = length(stSubsystem.astDsmRefs);
for i = 1:nDsmVars
    iVarIdx = stSubsystem.astDsmRefs(i).iVarIdx;
    stDsmVar = stModel.astDsmVars(iVarIdx);

    if ~i_skipMappingForInt64Interface(stDsmVar.astSignals, stModel.bAdaptiveAutosar)
        i_addMappingForDsmPort(hParentNode, stDsmVar, stPathInfo, mMapAlias);
    end
end

% ---- add Parameters --------------
nCalVars = length(stSubsystem.astCalRefs);
for i = 1:nCalVars
    stCalRef = stSubsystem.astCalRefs(i);

    stParameter = stModel.astCalVars(stCalRef.iVarIdx);
    if i_isHidden(stParameter)
        continue;
    end

    stParameter.stBlockInfo = stParameter.astBlockInfo(stCalRef.aiBlockIdx(1));
    i_addMappingForParameter(hParentNode, stParameter, stPathInfo);
end

% ---- add Locals --------------------
mMapAlias = containers.Map;
nDispVars = length(stSubsystem.astDispRefs);
for i = 1:nDispVars
    stDispRef = stSubsystem.astDispRefs(i);

    stLocal = stModel.astDispVars(stDispRef.iVarIdx);
    stLocal.stBlockInfo = stLocal.astBlockInfo(1); % currently only one model reference supported

    i_addMappingForLocal(hParentNode, stLocal, stPathInfo, mMapAlias);
end
end


%%
function bSkipInterfaceMapping = i_skipMappingForInt64Interface(astSignals, bSkipInt64BitInterfaces)
bSkipInterfaceMapping = false;
if bSkipInt64BitInterfaces % True in Adaptive Autosar usecase
    for i = 1:numel(astSignals)
        sType = astSignals(i).sType;
        if (strcmp(sType, 'uint64') || strcmp(sType, 'int64'))
            bSkipInterfaceMapping = true;
            return;
        end
    end
end
end


%%
function [sTlPath, bIsSF] = i_getBlockTlPath(stBlockInfo)
bIsSF = false;
if (~isempty(stBlockInfo.stSfInfo) && ~isempty(stBlockInfo.stSfInfo.sSfName))
    sTlPath = [stBlockInfo.sTlPath, '/', stBlockInfo.stSfInfo.sSfName];
    bIsSF = true;
else
    sTlPath = stBlockInfo.sTlPath;
end
end


%%
function [sTlPath, sSlPath, sCPath, sKind] = i_getInterfaceInfoForLocal(stLocal, stPathInfo)
[sTlPath, bIsSF] = i_getBlockTlPath(stLocal.stBlockInfo);
sTlPath = i_deleteModelNameFromPath(sTlPath);
sTlRoot = i_deleteModelNameFromPath(stPathInfo.sTlRoot);
sSlRoot = i_deleteModelNameFromPath(stPathInfo.sSlRoot);
if ~bIsSF
    sTlPath = [sTlPath, sprintf('(%d)', stLocal.iPortNumber)];
end
if isempty(stPathInfo.sSlRoot)
    sSlPath = '';
else
    sSlPath = regexprep(sTlPath, ['^', regexptranslate('escape', sTlRoot)], sSlRoot);
end
stVarInfo = stLocal.stInfo;
sCPath = [stVarInfo.sRootName, stVarInfo.sAccessPath];
sKind = 'Local';
end


%%
function bIsRowOrCol = i_isRowOrColVectorDimension(aiDim)
bIsRowOrCol = (aiDim(1) == 2 && ((aiDim(2) == 1 && aiDim(3) > 1) || (aiDim(3) == 1 && aiDim(2) > 1)));
end


%%
% removes the element access from an access path, e.g. ".a.b.c[2][0]" --> ".a.b.c" or "[1]" --> ""
function sAccessPath = i_removeCodeArrayAccess(sAccessPath)
if ~isempty(sAccessPath)
    % remove all "[", "]", and digits from the *end* of the access path
    sAccessPath = regexprep(sAccessPath, '[\[\]0-9]+$', '');
end
end


%%
function hProp = i_addModuleProperty(hParentNode, sModuleName)
if ~isempty(sModuleName)
    hProp = mxx_xmltree('add_node', hParentNode, 'Property');
    mxx_xmltree('set_attribute', hProp, 'name', 'module');
    mxx_xmltree('set_attribute', hProp, 'value', sModuleName);
end
end


%%
function sPath = i_getParameterModelPath(stCal, stBlockInfo)
sPath = stBlockInfo.sTlPath;
if isempty(stBlockInfo.stSfInfo)
    if strcmp(stCal.sKind, 'explicit')
        sPath = [sPath, '/', stCal.sUniqueName];
    else
        sUsage = i_getLimitedBlocksetUsage(stBlockInfo);
        if ~isempty(sUsage)
            sNamePrefix = i_getNameFromPath(stBlockInfo.sTlPath);
            sPath = [sPath, '/', sNamePrefix, '[', sUsage, ']'];
        end
    end
else
    sPath = [sPath, '/', stBlockInfo.stSfInfo.sSfName];
end
end


%%
function i_addMappingForParameter(hParentNode, stParameter, stPathInfo)
sTlPathOrg = i_getParameterModelPath(stParameter.stCal, stParameter.stBlockInfo);
sTlPath = i_deleteModelNameFromPath(sTlPathOrg);

if ~isempty(stPathInfo.sSlRoot)
    sSlPath = strrep(sTlPathOrg, stPathInfo.sTlRoot, stPathInfo.sSlRoot);
    sSlPath = i_deleteModelNameFromPath(sSlPath);
else
    sSlPath = '';
end

stVarInfo = stParameter.stInfo;
if isempty(stVarInfo.sAccessPath)
    sCPath = stVarInfo.sRootName;
else
    sCPath = [stVarInfo.sRootName, stVarInfo.sAccessPath];
end

sTlAccessPath = '';
sSlAccessPath = '';

% Note: usually the cal arrays can be mapped on root level but for the follinwg special case, the mapping is
%       needed on element level.
%       Special Case: scalar variable is mapped to a C-array with one element
if (~isempty(stVarInfo.aiWidth) && (prod(stVarInfo.aiWidth) == 1) && (length(stVarInfo.astProp) == 1))
    sCAccessPath = stVarInfo.astProp(1).sAccessPath;
else
    sCAccessPath = '';
end

hIfCPath = i_deprecated_addInterfaceWithSignalMapping(hParentNode, 'Parameter', sTlPath, sSlPath, sCPath, ...
    sTlAccessPath, sSlAccessPath, sCAccessPath);
if (strcmpi(stVarInfo.stVarClass.sStorage, 'static') && ~isempty(stVarInfo.sModuleName))
    i_addModuleProperty(hIfCPath, stVarInfo.sModuleName);
end
end


%%
function i_addMappingForPort(hParentNode, sKind, stPort, sStepFunc, stFuncInterface, bWithSL, mMapAlias)
sTlPath = i_getNameFromPath(stPort.sModelPortPath);
if bWithSL
    sSlPath = sTlPath;
else
    sSlPath = [];
end

for ni = 1:length(stPort.astSignals)
    stSignal = stPort.astSignals(ni);

    % Check if the C-Code contains any variable to map the signal to. If not, no mapping required.
    if isempty(stSignal.stVarInfo)
        continue;
    end

    sCPath = i_getPortCodePath(stFuncInterface, stSignal, sStepFunc);
    i_addMappingPortSignal(hParentNode, sKind, sTlPath, sSlPath, sCPath, stSignal, ...
        stPort.stCompInfo.sSigKind, mMapAlias);
end
end


%%
function i_addMappingForDsmOrLocal(hParentNode, stDsmOrLocal, hGetInterfaceInfoAndKind, stPathInfo, mMapAlias)
[sTlPath, sSlPath, sCPath, sKind] = feval(hGetInterfaceInfoAndKind, stDsmOrLocal, stPathInfo);
stSigTL = struct( ...
    'sPath',   sTlPath, ...
    'sAccess', '');
stSigSL = struct( ...
    'sPath',   sSlPath, ...
    'sAccess', '');
stSigC = struct( ...
    'sPath',   sCPath, ...
    'sAccess', '');

bIsBus = strcmp(stDsmOrLocal.sSigKind, 'bus');

% note: take module name into account *only* for static variables
stVarInfo = stDsmOrLocal.stInfo;
bIsStatic = strcmpi(stVarInfo.stVarClass.sStorage, 'static');
if bIsStatic
    sModuleName = stVarInfo.sModuleName;
else
    sModuleName = '';
end

aiSigGroupIdx = unique([stDsmOrLocal.astSomeSubSigs(:).iSigIdx]);
for k = 1:numel(aiSigGroupIdx)
    iSigGroupIdx = aiSigGroupIdx(k);
    aiGroupIdxSet = sort(find([stDsmOrLocal.astSomeSubSigs(:).iSigIdx] == iSigGroupIdx));

    iGroupFirstIdx = aiGroupIdxSet(1);
    stFirstSubSig = stDsmOrLocal.astSomeSubSigs(iGroupFirstIdx);
    aiDim = stFirstSubSig.aiDim;

    if bIsBus
        sSigAccess = i_normalizeBusAccessPath(stFirstSubSig.sName);
        stSigTL.sAccess = sSigAccess;
        stSigSL.sAccess = sSigAccess;
    end
    stSigC.sAccess = i_removeCodeArrayAccess(stVarInfo.astProp(iGroupFirstIdx).sAccessPath);

    bIsSingleElem = (numel(aiGroupIdxSet) < 2);

    % Note: Case that a 1xN or Nx1 matrix on MIL must be mapped to a simple array on SIL
    bIsSpecialRowOrColMapping = ~bIsSingleElem && i_isRowOrColVectorDimension(aiDim);
    if bIsSpecialRowOrColMapping
        for i = 1:numel(aiGroupIdxSet)
            iIdx = aiGroupIdxSet(i);

            stElementSigTL = stSigTL;
            stElementSigSL = stSigSL;
            stElementSigC  = stSigC;

            iSigIdx = stDsmOrLocal.astSomeSubSigs(iIdx).iSubSigIdx;
            aiMatIdx = i_linToMatrixSignalIdx(aiDim, iSigIdx);

            stElementSigTL.sAccess = [stSigTL.sAccess, sprintf('(%i)', aiMatIdx(:))];
            stElementSigSL.sAccess = stElementSigTL.sAccess;
            stElementSigC.sAccess  = stVarInfo.astProp(iIdx).sAccessPath;

            stElementSigC = i_makeUniqueForMultiUse(stElementSigC, mMapAlias, sModuleName);
            hIfCPath = i_addInterfaceWithSignalMapping( ...
                hParentNode, ...
                sKind, ...
                stElementSigTL, ...
                stElementSigSL, ...
                stElementSigC);
            i_addModuleProperty(hIfCPath, sModuleName);
        end
    else
        % Note: usually the array signals can be mapped on root signal level but for the following special case,
        %       the mapping is needed on element level.
        %       Special Case: scalar signal is mapped to a C-array with one element
        %       --> in this case do *not* remove the arrayAccess but use the original access path directly
        if bIsSingleElem
            stSigC.sAccess = stVarInfo.astProp(iGroupFirstIdx).sAccessPath;
        end
        stSigC = i_makeUniqueForMultiUse(stSigC, mMapAlias, sModuleName);

        hIfCPath = i_addInterfaceWithSignalMapping( ...
            hParentNode, ...
            sKind, ...
            stSigTL, ...
            stSigSL, ...
            stSigC);
        i_addModuleProperty(hIfCPath, sModuleName);
    end
end
end


%%
function i_addMappingForDsmPort(hParentNode, stDsmPort, stPathInfo, mMapAlias)
i_addMappingForDsmOrLocal(hParentNode, stDsmPort, @i_getInterfaceInfoForDsmPort, stPathInfo, mMapAlias);
end


%%
function i_addMappingForLocal(hParentNode, stLocal, stPathInfo, mMapAlias)
i_addMappingForDsmOrLocal(hParentNode, stLocal, @i_getInterfaceInfoForLocal, stPathInfo, mMapAlias);
end


%%
function [sTlPath, sSlPath, sCPath, sKind] = i_getInterfaceInfoForDsmPort(stDsmPort, stPathInfo)
sTlRoot = i_deleteModelNameFromPath(stPathInfo.sTlRoot);
sSlRoot = i_deleteModelNameFromPath(stPathInfo.sSlRoot);

sTlPath = i_getBlockTlPath(stDsmPort.astBlockInfo(1));
sTlPath = i_deleteModelNameFromPath(sTlPath);
if ~isempty(sSlRoot)
    sSlPath = regexprep(sTlPath, ['^', regexptranslate('escape', sTlRoot)], sSlRoot);
else
    sSlPath = '';
end
stVarInfo = stDsmPort.stInfo;
sCPath = [stVarInfo.sRootName, stVarInfo.sAccessPath];
if strcmpi(stDsmPort.stDsm.sKind, 'read')
    sKind = 'Input';
else
    sKind = 'Output';
end
end


%%
function [aiSigElements, aiVarElements, bIsFullyMapped] = i_getMappedElementIndices(stSignal)
aiSigElements = 1:length(stSignal.astSubSigs);
bIsFullyMapped = length(aiSigElements) == prod(stSignal.astSubSigs(1).aiDim);
if isempty(stSignal.aiElements)
    aiVarElements = 1:length(stSignal.stVarInfo.astProp);

    % Note: ----- check special case -----
    %       MIL signal width=1 and SIL array variable with width 1 instead of scalar variable
    if (all(stSignal.iWidth == 1) && ~isempty(stSignal.stVarInfo.aiWidth))
        bIsFullyMapped = false;
    end
else

    aiLinElements = i_getLinearElementsIdx(stSignal.stVarInfo.aiWidth, stSignal.aiElements, stSignal.aiElements2);
    % Note: transform zero-based indexing to one-based
    aiVarElements = aiLinElements + 1;
    bIsFullyMapped = false;
end
end


%%
function i_addMappingPortSignal(hParentNode, sKind, sTlPath, sSlPath, sCPath, stSignal, sSigKind, mMapAlias)
[aiSigElements, aiVarElements, bIsFullyMapped] = i_getMappedElementIndices(stSignal);

if bIsFullyMapped
    sCAccessPath = '';
    bIsPointer =  i_isPortVariablePointer(stSignal.stVarInfo);
    if bIsPointer
        sCAccessPath = '->';
    end
    if strcmp(sSigKind, 'bus')
        sTlAccessPath = i_getBusAccessPath(stSignal, stSignal.astSubSigs(1));
    else
        sTlAccessPath = '';
    end
    sSlAccessPath = sTlAccessPath;
    i_deprecated_addInterfaceWithSignalMapping( ...
        hParentNode, sKind, sTlPath, sSlPath, sCPath, sTlAccessPath, sSlAccessPath, sCAccessPath, mMapAlias);
    return;
end

% Note: using following assumption --> length(aiSigElements) == length(aiVarElements) == nMappedElements
nMappedElems = length(aiSigElements);
for nj = 1:nMappedElems
    iSigElem = aiSigElements(nj);
    iVarElem = aiVarElements(nj);

    sCAccessPath = stSignal.stVarInfo.astProp(iVarElem).sAccessPath;
    if strcmp(sSigKind, 'bus')
        sTlSignalPath = i_getBusAccessPath(stSignal, stSignal.astSubSigs(iSigElem));
    else
        sTlSignalPath = '';
    end

    iSigIdx = stSignal.astSubSigs(iSigElem).iSubSigIdx;

    if isempty(iSigIdx)
        sTlAccessPath = sTlSignalPath;
    else
        aiDim =  stSignal.astSubSigs(iSigElem).aiDim;
        aiMatIdx = i_linToMatrixSignalIdx(aiDim, iSigIdx);
        sTlAccessPath = [sTlSignalPath, sprintf('(%i)', aiMatIdx(:))];
    end

    sSlAccessPath = sTlAccessPath;
    i_deprecated_addInterfaceWithSignalMapping( ...
        hParentNode, sKind, sTlPath, sSlPath, sCPath, sTlAccessPath, sSlAccessPath, sCAccessPath, mMapAlias);
end
end


%%
function bIsPointer = i_isPortVariablePointer(stVarInfo)
if (~stVarInfo.bIsUsable && ~isempty(regexpi(stVarInfo.stInterfaceVar.sKind, 'GLOBAL', 'once')))
    bIsPointer = false; % actually not enough info here; but "false" is a good default
elseif (~stVarInfo.bIsUsable && ~strcmp(stVarInfo.sRootName, stVarInfo.stInterfaceVar.sOrigRootName))
    bIsPointer = false; % actually not enough info here; but "false" is a good default
else
    bIsPointer = strcmp(stVarInfo.stVarType.sBase, 'Pointer');
end
end


%%
function sCPath = i_getPortCodePath(stFuncInterface, stSignal, sStepFunc)
stVarInfo = stSignal.stVarInfo;
if isfield(stVarInfo, 'stInterfaceVar')
    stIfVar = stVarInfo.stInterfaceVar;
    if strcmp(stIfVar.sKind, 'RETURN_VALUE')
        sCPath = [sStepFunc, ':return'];
    else
        if (~isempty(stIfVar.iArgIdx) && (stIfVar.iArgIdx > 0))
            stFormalArgs = stFuncInterface.astFormalArgs(stIfVar.iArgIdx);
            sRootName = stFormalArgs.sArgName;
            if (~isempty(stVarInfo.sAccessPath) && stFormalArgs.bIsStruct && stFormalArgs.bIsPointer)
                sCPath = [sRootName, '->', stVarInfo.sAccessPath(2:end)];
            else
                sCPath = [sRootName, stVarInfo.sAccessPath];
            end
        else
            if stVarInfo.bIsUsable
                sRootName = stVarInfo.sRootName;
            else
                sRootName = stIfVar.sOrigRootName;
            end
            sCPath = [sRootName, stVarInfo.sAccessPath];
        end
    end
else
    sCPath = [stVarInfo.sRootName, stVarInfo.sAccessPath];
end
end


%%
function sSignalName = i_getBusAccessPath(stSignal, stSubSig)
if ((nargin < 2) || isempty(stSubSig))
    if length(stSignal.astSubSigs)==1
        sSignalName = stSignal.astSubSigs.sName;
    else
        sSignalName = stSignal.sSignalName;
    end
else
    sSignalName = stSubSig.sName;
end

sSignalName = i_normalizeBusAccessPath(sSignalName);
end


%%
function sNormSignalName = i_normalizeBusAccessPath(sSignalName)
if isempty(sSignalName)
    sNormSignalName = sSignalName;
else
    if (sSignalName(1) == '.')
        sNormSignalName = ['.<signal1>', sSignalName];
    else
        sNormSignalName = ['.', sSignalName];
    end
end
end


%%
function hArch = i_addMappingArch(hParentNode, sID, sName)
hArch = mxx_xmltree('add_node', hParentNode, 'Architecture');
mxx_xmltree('set_attribute', hArch, 'id', sID);
mxx_xmltree('set_attribute', hArch, 'name', sName);
end


%%
function hPath = i_addMappingPath(hParentNode, sRefID, sPath)
hPath = mxx_xmltree('add_node', hParentNode, 'Path');
mxx_xmltree('set_attribute', hPath, 'refId', sRefID);
mxx_xmltree('set_attribute', hPath, 'path', sPath);
end


%%
function [hTlPath, hCPath, hSlPath] = i_addAllMappingPaths(hParentNode, sTlPath, sCPath, sSlPath)
hTlPath = i_addMappingPath(hParentNode, 'id0', sTlPath);
if (nargin > 3)
    hSlPath = i_addMappingPath(hParentNode, 'id2', sSlPath);
else
    hSlPath = [];
end
hCPath = i_addMappingPath(hParentNode, 'id1', sCPath);
end


%%
function [hIfMapping, hCPath] = i_addInterfaceObjMapping(hParentNode, sKind, varargin)
hIfMapping = mxx_xmltree('add_node', hParentNode, 'InterfaceObjectMapping');
mxx_xmltree('set_attribute', hIfMapping, 'kind', sKind);
[~, hCPath] = i_addAllMappingPaths(hIfMapping, varargin{:});
end


%%
function hSigMapping = i_addSignalMapping(hParentNode, varargin)
casMappingPaths = varargin;
if all(cellfun('isempty', casMappingPaths))
    return; % if all signal paths are empty, there is nothing to add (mapping is done via the parent nodes)
end

hSigMapping = mxx_xmltree('add_node', hParentNode, 'SignalMapping');
i_addAllMappingPaths(hSigMapping, casMappingPaths{:});
end


%%
function hCPath = i_deprecated_addInterfaceWithSignalMapping(hMapSubsystemNode, sKind, sTlPath, sSlPath, sCPath, ...
    sTlAccessPath, sSlAccessPath, sCAccessPath, mMapAlias)
if (nargin > 8)
    % handle special case: same C-code names
    sCAliasKey = [sCPath, ':', sCAccessPath];
    if isKey(mMapAlias, sCAliasKey)
        mMapAlias(sCAliasKey) = mMapAlias(sCAliasKey) + 1;
        sCPath = [sCPath, ':', num2str(mMapAlias(sCAliasKey))];
    else
        mMapAlias(sCAliasKey) = 1; %#ok<NASGU> changing map content
    end
end

if isempty(sSlPath)
    [hIfMapping, hCPath] = i_addInterfaceObjMapping(hMapSubsystemNode, sKind, sTlPath, sCPath);
    if any(~cellfun('isempty', {sTlAccessPath, sCAccessPath}))
        i_addSignalMapping(hIfMapping, sTlAccessPath, sCAccessPath);
    end
else
    [hIfMapping, hCPath] = i_addInterfaceObjMapping(hMapSubsystemNode, sKind, sTlPath, sCPath, sSlPath);
    if any(~cellfun('isempty', {sTlAccessPath, sCAccessPath, sSlAccessPath}))
        i_addSignalMapping(hIfMapping, sTlAccessPath, sCAccessPath, sSlAccessPath);
    end
end
end


%%
function hCPath = i_addInterfaceWithSignalMapping(hMapSubsystemNode, sKind, stSigTL, stSigSL, stSigC)
% since mapping importer of EP is very restrictive, for now a workaround is needed for the C-Code path and access split
stSigC = i_workaroundForAccessVsInterfaceDilemmaInCode(stSigC);

% NOTE: the following order of the arguments
%     (1) TL
%     (2) Code
%     (3) SL
% is *very* important for the called functions because (3) SL is an optional argument
if isempty(stSigSL.sPath)
    casPaths = {stSigTL.sPath, stSigC.sPath};
    casAccess = {stSigTL.sAccess, stSigC.sAccess};
else
    casPaths = {stSigTL.sPath, stSigC.sPath, stSigSL.sPath};
    casAccess = {stSigTL.sAccess, stSigC.sAccess, stSigSL.sAccess};
end
[hIfMapping, hCPath] = i_addInterfaceObjMapping(hMapSubsystemNode, sKind, casPaths{:});
i_addSignalMapping(hIfMapping, casAccess{:});
end


%%
% split access path into "struct-access" and "array-access" --> for C-Code arch the struct-access part belongs to the
% main path
function stSigC = i_workaroundForAccessVsInterfaceDilemmaInCode(stSigC)
if ~isempty(stSigC.sAccess)
    casAccessParts = regexp(stSigC.sAccess, '^(\.(\w|\.)+)(.*)$', 'tokens', 'once');
    if (numel(casAccessParts) == 2)
        stSigC.sPath   = [stSigC.sPath, casAccessParts{1}];
        stSigC.sAccess = casAccessParts{2};
    end
end
end


%%
% handle special case: same C-code names used multiple times --> create an alias for each usage
function stSig = i_makeUniqueForMultiUse(stSig, oMapAlias, sModule)
sAliasKey = [stSig.sPath, ':', stSig.sAccess, ':', sModule];
if isKey(oMapAlias, sAliasKey)
    oMapAlias(sAliasKey) = oMapAlias(sAliasKey) + 1;
    stSig.sPath = [stSig.sPath, ':', num2str(oMapAlias(sAliasKey))];
else
    oMapAlias(sAliasKey) = 1; %#ok<NASGU> changing map content
end
end


%%
% extracts the block name from the model path
function sName = i_getNameFromPath(sPath)
% note: slashes in names are escaped by "//" --> do not split at such locations ...
sName = regexprep(sPath, '.*[^/]/([^/])', '$1');
% ... but replace them afterwards with simple slashes
sName = regexprep(sName, '//', '/');
end


%%
function sUsage = i_getLimitedBlocksetUsage(stBlockInfo)
sMaskType = stBlockInfo.sBlockKind;
if isempty(sMaskType)
    if atgcv_sl_block_isa(sBlockPath, 'Stateflow')
        sMaskType = 'stateflow';
    else
        sMaskType = '<empty>';
    end
end
switch lower(sMaskType)
    case 'tl_gain'
        sUsage = 'gain';

    case 'tl_constant'
        sUsage = 'const';

    case 'tl_saturate'
        switch lower(stBlockInfo.sBlockUsage)
            case 'upperlimit'
                sUsage = 'sat_upper';

            case 'lowerlimit'
                sUsage = 'sat_lower';

            otherwise
                sUsage = ''; % TODO: issue an error
        end

    case 'tl_switch'
        sUsage = 'switch_threshold';

    case 'tl_relay'
        switch lower(stBlockInfo.sBlockUsage)
            case 'offoutput'
                sUsage = 'relay_out_off';

            case 'onoutput'
                sUsage = 'relay_out_on';

            case 'offswitch'
                sUsage = 'relay_switch_off';

            case 'onswitch'
                sUsage = 'relay_switch_on';

            otherwise
                sUsage = ''; % TODO: issue an error
        end
    case 'stateflow'
        sUsage = 'sf_const';

    otherwise
        sUsage = ''; % TODO: issue an error
end
end


%%
% Converts the given linear index to the correct matrix index
%
%   PARAMETER(S)    DESCRIPTION
%   -  aiDim           (array) aiDim is analog to the block Property "CompiledPortDimensions":
%                              first element provides number of dimensions, the rest provides the widths
%   -  iIdx            (int)   the linear index for which the matrix index
%                              should be computed
%   OUTPUT
%   - aiMatIdx         (array) The converted matrix index
%
function aiMatIdx = i_linToMatrixSignalIdx(aiDim, iIdx)
if (isempty(aiDim) || (length(aiDim) < 3))
    % not a multi-dim signal
    aiMatIdx = iIdx;
else
    % general case
    nDim = aiDim(1);
    caiMatIdx = cell(nDim, 1);
    [caiMatIdx{:}] = ind2sub(aiDim(2:end), iIdx);
    aiMatIdx = cell2mat(caiMatIdx);
end
end


%%
% Converts the number of matrix indexes to a linear index
%
%   PARAMETER(S)    DESCRIPTION
%   - aiWidth           (array) width of the matrix  [n m]
%
%   - aiElements        (array) number of indexes
%
%   - aiElements2       (array) nummber of indexes
%   OUTPUT
%   - aiLinElements     (array) linear index of the given indexes
%
function aiLinElements = i_getLinearElementsIdx(aiWidth, aiElements, aiElements2)
if isempty(aiElements)
    aiLinElements = [];
    return;
end

if any(aiElements < 0)
    aiElements = 0:(aiWidth(1) - 1);
end

if isempty(aiElements2)
    aiLinElements = aiElements;
    return;
end

if any(aiElements2 < 0)
    aiElements2 = 0:(aiWidth(2) - 1);
end

iLen1 = length(aiElements);
iLen2 = length(aiElements2);

% create subindex of matrix (account for offset 1 by adding one)
aiSubIdx  = reshape(repmat(aiElements + 1, 1, iLen2), 1, []);
aiSubIdx2 = reshape(repmat(aiElements2 + 1, iLen1, 1), 1, []);

% create linear index (accound for offset 0 by subtracting one)
aiLinElements = sub2ind(aiWidth, aiSubIdx, aiSubIdx2) - 1;
end


%%
function sPath = i_deleteModelNameFromPath(sPath)
sPath = regexprep(sPath, '^([^/]|(//))*/', '');
end


%%
function xValue = i_getField(stStruct, sField, xDefaultValue)
if isfield(stStruct, sField)
    xValue = stStruct.(sField);
else
    if (nargin > 2)
        xValue = xDefaultValue;
    else
        xValue = [];
    end
end
end


