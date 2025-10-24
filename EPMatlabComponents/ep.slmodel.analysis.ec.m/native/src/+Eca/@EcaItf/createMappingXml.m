function createMappingXml(oEca)

if oEca.bDiagMode
    fprintf('\n## Generation of Model and Code mapping file ...\n');
end

hMappings = mxx_xmltree('create', 'Mappings');
hArchMapping = mxx_xmltree('add_node', hMappings, 'ArchitectureMapping');
hModelArch = mxx_xmltree('add_node', hArchMapping, 'Architecture');
mxx_xmltree('set_attribute', hModelArch, 'id', i_getModelID());
mxx_xmltree('set_attribute', hModelArch, 'name', oEca.sModelName);
hCodeArch = mxx_xmltree('add_node', hArchMapping, 'Architecture');
mxx_xmltree('set_attribute', hCodeArch, 'id', i_getCodeID());
mxx_xmltree('set_attribute', hCodeArch, 'name', [oEca.sModelName, ' [C-Code]']);

%All hierarchical scopes into one array
aoScopes = oEca.getAllValidScopes('Mapping');
abMappableScopes = ~cellfun('isempty', {aoScopes.sCFunctionName});

% Prepare mapping XML
for iScope = find(abMappableScopes)
    sSubsysMappingPath = i_deleteModelNameFromPath(aoScopes(iScope).sSubSystemFullName);
    
    %"Path"-nodes of ScopeMapping
    hScopeMapping = mxx_xmltree('add_node', hArchMapping, 'ScopeMapping');
    hSubsysPath = mxx_xmltree('add_node', hScopeMapping, 'Path');
    mxx_xmltree('set_attribute', hSubsysPath, 'path', sSubsysMappingPath);
    mxx_xmltree('set_attribute', hSubsysPath, 'refId', i_getModelID());
    hFunctionPath = mxx_xmltree('add_node', hScopeMapping, 'Path');
    mxx_xmltree('set_attribute', hFunctionPath, 'path', aoScopes(iScope).sEPCFunctionPath);
    mxx_xmltree('set_attribute', hFunctionPath, 'refId', i_getCodeID());
    
    %Element: InterfaceObjectMapping (Inputs)
    i_createMappingStructure(hScopeMapping, aoScopes(iScope).oaInputs, 'Input', aoScopes(iScope).bIsRootScope, oEca);
    
    %Element: InterfaceObjectMapping (Outputs)
    i_createMappingStructure(hScopeMapping, aoScopes(iScope).oaOutputs, 'Output', aoScopes(iScope).bIsRootScope, oEca);
    
    %Element: InterfaceObjectMapping (Local)
    if oEca.bMergedArch
        aoLocals = aoScopes(iScope).getAllValidUniqLocalsInclChdrScopes();
    else
        aoLocals = aoScopes(iScope).oaLocals;
    end
    i_createMappingStructure(hScopeMapping, aoLocals, 'Local', aoScopes(iScope).bIsRootScope, oEca);
    
    %Element: InterfaceObjectMapping (Parameters)
    i_createMappingStructure(hScopeMapping, aoScopes(iScope).oaParameters, 'Parameter', aoScopes(iScope).bIsRootScope, oEca);
end

if (any(abMappableScopes) || oEca.bIsAdaptiveAutosar)
    mxx_xmltree('save', hMappings, oEca.sMappingXmlFile);
end
end


%%
function i_createMappingStructure(hScopeMapping, aoItfs, sKind, bIsRootScope, oEca)
if isempty(aoItfs)
    return;
end

abIsActive       = [aoItfs(:).bIsActive];
abIsMappingValid = [aoItfs(:).bMappingValid];
abIsAccepted     = abIsActive & abIsMappingValid;

if oEca.bDiagMode
    for iItf = find(~abIsAccepted)
        strLink = sprintf('<a href = "matlab:open_system(''%s'');hilite_system(''%s'')">%s <"%s"></a>',...
            aoItfs(iItf).getBdroot(), aoItfs(iItf).sourceBlockFullName, aoItfs(iItf).sourceBlockFullName, aoItfs(iItf).name);
        fprintf('# Interface [%s] %s cannot be mapped.\n', aoItfs(iItf).kind, strLink);
    end
end

for iValid = find(abIsAccepted)
    oItf = aoItfs(iValid);
    
    [stModel, stCode] = i_getInterfaceMapping(oItf, sKind, bIsRootScope, oEca);
    i_addInterfaceMapping(hScopeMapping, sKind, stModel, stCode);
end
end


%%
function i_addInterfaceMapping(hScopeMapping, sKind, stModel, stCode)
hIoMapping = mxx_xmltree('add_node', hScopeMapping, 'InterfaceObjectMapping');
mxx_xmltree('set_attribute', hIoMapping, 'kind', sKind);

i_addPath(hIoMapping, stModel.sInterfacePath, i_getModelID());
i_addPath(hIoMapping, stCode.sInterfacePath, i_getCodeID());

% Assumption: both cell arrays contain the same number of strings!
for i = 1:numel(stModel.casSignalPaths)
    sModelSigPath = stModel.casSignalPaths{i};
    sCodeSigPath = stCode.casSignalPaths{i};
    
    i_addSignalMapping(hIoMapping, sModelSigPath, sCodeSigPath);
end
end


%%
function i_addSignalMapping(hParentNode, sModelSigPath, sCodeSigPath)
hSignalMapping = mxx_xmltree('add_node', hParentNode, 'SignalMapping');
i_addPath(hSignalMapping, sModelSigPath, i_getModelID());
i_addPath(hSignalMapping, sCodeSigPath, i_getCodeID());
end


%%
function hPathNode = i_addPath(hParentNode, sPath, sRefID)
hPathNode = mxx_xmltree('add_node', hParentNode, 'Path');
mxx_xmltree('set_attribute', hPathNode, 'path', sPath);
mxx_xmltree('set_attribute', hPathNode, 'refId', sRefID);
end


%%
function [stModel, stCode] = i_getInterfaceMapping(oItf, sKind, bIsRootScope, oEca)
stModel = struct( ...
    'sInterfacePath', i_getInterfaceMappingModelPath(oItf, sKind, bIsRootScope, oEca), ...
    'casSignalPaths', {{}});

stCode = struct( ...
    'sInterfacePath', i_getInterfaceMappingCodePath(oItf), ...
    'casSignalPaths', {{}});

if (oItf.isScalar() && ~oItf.isArrayOfBus())
    [stModel.casSignalPaths, stCode.casSignalPaths] = i_getScalarSignalMappingPaths(oItf);

else
    [stModel.casSignalPaths, stCode.casSignalPaths] = i_getGenericSignalMappingPaths(oItf);
end
end


%%
function [casModelSignalPaths, casCodeSignalPaths] = i_getGenericSignalMappingPaths(oItf)
if oItf.isArrayOfBus()
    [casSignalPartsModel, caaiPartWidthModel] = i_getSignalPartsModel(oItf);
    [casSignalPartsCode, caaiPartWidthCode] = i_getSignalPartsCode(oItf);
else
    [casSignalPartsModel, caaiPartWidthModel] = i_getSignalPartsModelLegacy(oItf);
    [casSignalPartsCode, caaiPartWidthCode] = i_getSignalPartsCodeLegacy(oItf);
end
if i_isParameter(oItf)
    caaiPartWidthModel = i_adaptColOrRowParamWidths(caaiPartWidthModel);
end
casModelSignalPaths = ep_core_feval('ep_flat_indexed_signals_get', casSignalPartsModel, caaiPartWidthModel);
casCodeSignalPaths  = ep_core_feval('ep_flat_indexed_signals_get', casSignalPartsCode, caaiPartWidthCode, oItf.getHandling2D);
end


%%
function bIsParam = i_isParameter(oItf)
bIsParam = strcmpi(oItf.kind, 'PARAM');
end


%%
function caaiWidths = i_adaptColOrRowParamWidths(caaiWidths)
if (numel(caaiWidths) > 0)
    aiLeafWidth = caaiWidths{end};
    
    % treat any row-parameter or col-parameter with dimension=2 as a simple array-parameter with dimension=1
    if ((numel(aiLeafWidth) == 2) && any(aiLeafWidth == 1))
        aiLeafWidth = prod(aiLeafWidth);
        caaiWidths{end} = aiLeafWidth;
    end
end
end


%%
function [casSignalParts, caaiPartWidth] = i_getSignalPartsModel(oItf)
if ~isempty(oItf.oMetaBusSig_)
    [casSignalParts, caaiPartWidth] = oItf.oMetaBusSig_.getModelSigParts();
else
    [casSignalParts, caaiPartWidth] = i_getSignalPartsModelLegacy(oItf);
end
end


%%
function [casSignalParts, caaiPartWidth] = i_getSignalPartsCode(oItf)
if ~isempty(oItf.oMetaBusSig_)
    [casSignalParts, caaiPartWidth] = oItf.oMetaBusSig_.getCodeSigParts(i_getCodeCustomParts(oItf));
else
    [casSignalParts, caaiPartWidth] = i_getSignalPartsCodeLegacy(oItf);
end
end


%%
function casCustomParts = i_getCodeCustomParts(oItf)
if ~isempty(oItf.codeStructName)
    casCustomParts = {oItf.codeStructName};
    
    sFullSubSigPath = regexprep(oItf.codeStructComponentAccess, '^\.', ''); % remove the first access token "."
    if ~isempty(sFullSubSigPath)
        casSubSigs = regexp(sFullSubSigPath, '\.', 'split');
        casCustomParts = [casCustomParts, casSubSigs];
    end
else
    casCustomParts = {oItf.codeVariableName};
end
end


%%
function [casSignalParts, caaiPartWidth] = i_getSignalPartsModelLegacy(oItf)
oMetaBus = oItf.getMetaBus();
if oItf.isBusElement
    casSignalParts = {i_getCleanSignalName(oMetaBus.modelSignalPath)};
else
    casSignalParts = {''};
end
caaiPartWidth = {oItf.getModelLeafWidth()};
end


%%
function [casSignalParts, caaiPartWidth] = i_getSignalPartsCodeLegacy(oItf)
if (oItf.isCodeStructComponent)
    casSignalParts = {oItf.codeStructComponentAccess};
else
    casSignalParts = {''};
end
caaiPartWidth = {oItf.getCodeLeafWidth()};
end


%%
function [casModelSignalPaths, casCodeSignalPaths] = i_getScalarSignalMappingPaths(oItf)
casModelSignalPaths = {};
casCodeSignalPaths = {};

sModelSignalPath = '';
sCodeSignalPath = '';

if oItf.isBusElement
    sModelSignalPath = i_getCleanSignalName(oItf.getMetaBus().modelSignalPath);
end
if (oItf.isCodeStructComponent)
    sCodeSignalPath = oItf.codeStructComponentAccess;
end
if (~isempty(sModelSignalPath) || ~isempty(sCodeSignalPath))
    casModelSignalPaths = {sModelSignalPath};
    casCodeSignalPaths = {sCodeSignalPath};
end
end


%%
function sCodeMappingPath = i_getInterfaceMappingCodePath(oItf)
sCodeMappingPath = oItf.getCodeRootVarName();
end


%%
function sModelMappingPath = i_getInterfaceMappingModelPath(oItf, sKind, bIsRootScope, oEca)
if strcmp(sKind, 'Parameter')
    sModelMappingPath = oItf.getName();
    
elseif strcmp(sKind, 'Local')
    if (oEca.oRootScope.bIsWrapperModel && ~oEca.bIsWrapperComplete)
        %path = <relativewrappersubsystempath>/<referencedmodel>/<blockpath>(nPort)
        sModelMappingPath = [i_deleteModelNameFromPath(oEca.oRootScope.sSubSystemFullName), '/', ...
            oItf.sourceBlockFullName, '(', num2str(oItf.sourceBlockPortNumber), ')'];
    else
        %path = <relativeblockpath>/<blockname>
        sModelMappingPath = [i_deleteModelNameFromPath(oItf.getVirtualPath()), ...
            '(', num2str(oItf.sourceBlockPortNumber), ')'];
    end
    
else %Input or Output
    if (bIsRootScope || oItf.isDsm)
        sModelMappingPath = i_deleteModelNameFromPath(oItf.getVirtualPath());
    else
        %path = /<referencedmodel>/<blockpath>/<blockname>
        sModelMappingPath = [i_deleteModelNameFromPath(oItf.sParentScopePath), '/', oItf.sourceBlockName];
    end
end
end


%%
function sPath = i_deleteModelNameFromPath(sPath)
if ~isempty(sPath)
    if any(sPath == '/')
        sPath = regexprep(sPath, '^([^/]|(//))*/', '');
    else
        sPath = '';
    end
end
end


%%
% remove angles "<" and ">" from the access path
% but *not* for <signal1> because this one signifies an EMPTY signal name
function sSignalName = i_getCleanSignalName(sSignalName)
if isempty(regexp(sSignalName, '<signal1>', 'once'))
    sSignalName = regexprep(sSignalName, '[<,>]', '');
end
end


%%
function sID = i_getModelID()
sID = 'id0';
end


%%
function sID = i_getCodeID()
sID = 'id1';
end
