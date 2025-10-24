function astVars = atgcv_m01_dsmvars_get(stEnv, hSubsys, sMode)
% Returns all read/write DataStoreMemory objects in provided subsystem.
%
% function astVars = atgcv_m01_dsmvars_get(stEnv, hSubsys, sMode)
%
%   INPUT           DESCRIPTION
%     stEnv             (struct)       environment structure
%     hSubsys           (handle)       DD handle to the TL toplevel subsystem (DD->Subsystems->"TopLevelName")
%     sMode             (string)       optional: kind of DSM
%                                      'read'  == Signal Injection (<-- default)
%                                      'write' == Signal Tunnelling
%
%   OUTPUT          DESCRIPTION
%     astVars               (array)    array of struct with following data
%       .hVar              (handle)    DD variable of CAL var
%       .stInfo            (struct)    resulting info_struct from "atgcv_m01_variable_info_get"
%       .astBlockInfo       (array)    resulting info_struct from "atgcv_m01_variable_block_info_get"
%       .stDsm             (struct)    additional DSM info
%         .sKind           (string)    'read' | 'write'
%         .sWorkspaceVar   (string)    name of variable in workspace (deprecated)
%         .sPoolVarPath    (string)    path to pool variable in DD (if any)
%         .sType           (string)    type of ML variable (default: double)
%         .oReadSig        (object)    workspace signal where the data is read from (source)
%         .oWriteSig       (object)    workspace signal where the data is written into (destination)
%
%   REMARKS
%
%   <et_copyright>


%% check optional input
if (nargin < 3)
    sMode = 'read';
else
    if ~any(strcmpi(sMode, {'read', 'write'}))
        error('ATGCV:INTERNAL:ERROR', 'wrong usage: mode "%s" unknown', sMode);
    end
end

%% main
astVars = i_getAllVars(stEnv, hSubsys, sMode);
if isempty(astVars)
    return;
end

astVars = i_addVariableInfoAndMergeSameVars(stEnv, astVars);
astVars = i_addDsmInfo(stEnv, astVars, sMode);
astVars = i_removeUnsupportedDsmVariables(stEnv, astVars);
astVars = i_addFlattenedVariableIndex(astVars);
end



%%
function stVarInfo = i_getInitVarInfo(hRootVar, hVar, sWorkspaceVar)
if (nargin < 3)
    sWorkspaceVar = '';
    if (nargin < 2)
        if (nargin < 1)
            hRootVar = [];
            hVar = [];
        else
            hVar = hRootVar;
        end
    end
end
stDsm = struct( ...
    'oWorkspaceSig',  [], ...
    'sWorkspaceVar',  sWorkspaceVar, ...
    'sPoolVarPath',   '', ...
    'sKind',          '', ...
    'sType',          '', ...
    'oReadSig',       [], ...
    'oWriteSig',      []);
stVarInfo = struct( ...
    'hRootVar',       hRootVar, ...
    'hVar',           hVar, ...
    'stInfo',         [], ...
    'astBlockInfo',   [], ...
    'stDsm',          stDsm, ...
    'aiVarIdx',       []);
end


%%
function astVars = i_getAllVars(stEnv, hSubsys, sMode)
if strcmpi(sMode, 'read')
    sVarKind = 'dsm_read';
else
    sVarKind = 'dsm_write';
end

ahVars = atgcv_m01_global_vars_get(stEnv, hSubsys, sVarKind);
% WORKAROUND for SystemTests and UnitTests --> formerly the reverse order was returned
% in order to keep the test expectations stable, reverse the order of DSMs here
if ~isempty(ahVars)
    ahVars = ahVars(end:-1:1);
end

astVars = repmat(i_getInitVarInfo(), 1, 0);
for i = 1:numel(ahVars)
    astVars = [astVars, i_getVarsAndBlockInfo(stEnv, ahVars(i))]; %#ok<AGROW>
end
if ~isempty(astVars)
    % remove variables that have no connection to model blocks
    abSelect = arrayfun(@(x) ~isempty(x.astBlockInfo), astVars);
    astVars = astVars(abSelect);
end

%astRteStatusVars = atgcv_m01_rtestatus_vars_get(stEnv, hSubsys, sMode);
% RTE signals are currently only used for injection and not tunneling
if strcmp(sMode, 'read')
    astRteStatusVars = ep_rtesignal_vars_get(hSubsys);
    for i = 1:length(astRteStatusVars)
        stRteVar = astRteStatusVars(i);

        % remove vars without reference in the model --> cannot access these during MIL simulations
        [astBlockInfo, hRootVar] = i_getBlockInfoConsideringParentVars(stEnv, stRteVar.hVar, stRteVar.signalName);
        if isempty(astBlockInfo)
            continue;
        end

        stVarInfo = i_getInitVarInfo(hRootVar, stRteVar.hVar, stRteVar.signalName);
        stVarInfo.astBlockInfo = astBlockInfo;

        astVars(end + 1) = stVarInfo; %#ok<AGROW>
    end
end
end


%%
function [astBlockInfo, hRootVar] = i_getBlockInfoConsideringParentVars(stEnv, hVar, sSignalName)
hRootVar = hVar;
astBlockInfo = atgcv_m01_variable_block_info_get(stEnv, hVar);
if isempty(astBlockInfo)
    hParentVar = i_getParentVar(hVar);
    if ~isempty(hParentVar)
        [astBlockInfo, hRootVar] = i_getBlockInfoConsideringParentVars(stEnv, hParentVar, sSignalName);
    end
else
    for i = 1:numel(astBlockInfo)
        sTlPath = astBlockInfo(i).sTlPath;
        if strcmp(get_param(sTlPath, 'BlockType'), 'SubSystem')
            casDataStorePath = find_system(sTlPath, 'LookUnderMasks', 'all', 'FollowLinks', 'on', 'DataStoreName', sSignalName);
            if numel(casDataStorePath) == 1
                astBlockInfo(i).sTlPath = casDataStorePath{1};
            end
        end
    end
end
end


%%
function hParentVar = i_getParentVar(hVar)
hParentVar = dsdd('GetAttribute', hVar, 'hDDParent');
if ~isempty(hParentVar) 
    if strcmp(dsdd('GetAttribute', hParentVar, 'Name'), 'Components')
        hParentVar = dsdd('GetAttribute', hParentVar, 'hDDParent');
    else
        hParentVar = [];
    end
end
end


%%
function astVars = i_getVarsAndBlockInfo(stEnv, hVar, hRootVar)
if (nargin < 3)
    hRootVar = hVar;
end
astBlockInfo = atgcv_m01_variable_block_info_get(stEnv, hVar);
if ~isempty(astBlockInfo)
    astVars = i_getInitVarInfo(hRootVar, hVar);
    astVars.astBlockInfo = astBlockInfo;
else
    astVars = repmat(i_getInitVarInfo(), 1, 0);
    
    [bIsStruct, hComp] = dsdd('Exist', 'Components', 'Parent', hVar);
    if bIsStruct
        ahFieldVars = dsdd('GetChildren', hComp);
        for i = 1:numel(ahFieldVars)
            astVars = [astVars, i_getVarsAndBlockInfo(stEnv, ahFieldVars(i), hRootVar)]; %#ok<AGROW>
        end
    end
end
end


%%
function astVars = i_addVariableInfoAndMergeSameVars(stEnv, astVars)
jVarHash = java.util.HashMap();
abSelect = true(size(astVars));
nVars = length(astVars);
for i = 1:nVars
    astVars(i).stInfo = atgcv_m01_variable_info_get(stEnv, astVars(i).hVar);
    
    sKey = i_getKeyFromVarInfo(astVars(i).stInfo);
    iIdx = jVarHash.get(sKey);
    if isempty(iIdx)
        jVarHash.put(sKey, i);
    else
        abSelect(i) = false;
        astVars(iIdx).astBlockInfo = i_addExtraBlockInfos(astVars(iIdx).astBlockInfo, astVars(i).astBlockInfo);
    end
end
astVars = astVars(abSelect);
end


%%
% get one scalar value from a structure that is unique for a variable
function sKey = i_getKeyFromVarInfo(stVarInfo)
sKey = [stVarInfo.sModuleName, '|', stVarInfo.sRootName, stVarInfo.sAccessPath];
end


%%
% add new block info only if it is not already part of the existing block info
function astBlockInfo = i_addExtraBlockInfos(astBlockInfo, astAddBlockInfo)
jInfoSet = java.util.HashSet();
for i = 1:length(astBlockInfo)
    jInfoSet.add(astBlockInfo(i).sTlPath);
end
for i = 1:length(astAddBlockInfo)
    if ~jInfoSet.contains(astAddBlockInfo(i).sTlPath)
        astBlockInfo(end + 1) = astAddBlockInfo(i); %#ok<AGROW>
    end
end
end


%%
function [sReadSignal, sWriteSignal] = i_getSignalProperties(hVar)
sReadSignal = i_getNonmacroStringValue(hVar, 'SimulationValueSource', '');
sWriteSignal = i_getNonmacroStringValue(hVar, 'SimulationValueDestination', '');
end


%%
function sValue = i_getNonmacroStringValue(hHandleDD, sProperty, sDefaultValue)
sValue = sDefaultValue;
try %#ok<TRYNC>
    sTryValue = dsdd(['Get', sProperty], hHandleDD);
    
    % do not accept an empty property or a property using DD-Macros (starting with $)
    if (~isempty(sTryValue) && ~any(sTryValue == '$'))
        sValue = sTryValue;
    end
end
end


%%
function astVars = i_addDsmInfo(stEnv, astVars, sMode)
nVars = length(astVars);
for i = 1:nVars
    sModelContext = astVars(i).astBlockInfo(1).sTlPath; % as model context use the first found block where it's used
    [sReadSignal, sWriteSignal] = i_getSignalProperties(astVars(i).hRootVar);
    astVars(i).stDsm.oReadSig = i_evalWorkspaceSignal(sReadSignal, sModelContext);
    astVars(i).stDsm.oWriteSig = i_evalWorkspaceSignal(sWriteSignal, sModelContext);
    
    oWorkspaceSig = [];
    if ~isempty(astVars(i).stDsm.sWorkspaceVar)
        % For AUTOSAR RTE workflows the name of the workspace var has already been determined
        oWorkspaceSig = i_evalWorkspaceSignal(astVars(i).stDsm.sWorkspaceVar, sModelContext);
    end
    if isempty(oWorkspaceSig)
        if strcmpi(sMode, 'read')
            if ~isempty(astVars(i).stDsm.oReadSig)
                oWorkspaceSig = astVars(i).stDsm.oReadSig;
            end
        else
            if ~isempty(astVars(i).stDsm.oWriteSig)
                oWorkspaceSig = astVars(i).stDsm.oWriteSig;
            end
        end
    end
    if isempty(oWorkspaceSig)
        sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astVars(i).hRootVar, 'Name');
        oWorkspaceSig = i_evalWorkspaceSignal(sVarName, sModelContext);
    end
    
    bIsValid = i_checkWorkspaceSig(stEnv, astVars(i).hRootVar, oWorkspaceSig);
    if bIsValid
        sWorkspaceVar = oWorkspaceSig.getName;
        sWorkspaceType = oWorkspaceSig.getType;
        if isempty(sWorkspaceType)
            sWorkspaceType = 'double';
        end
    else
        sWorkspaceVar = '';
        sWorkspaceType = '';
    end
    
    astVars(i).stDsm.sKind         = sMode;
    astVars(i).stDsm.oWorkspaceSig = oWorkspaceSig;
    astVars(i).stDsm.sWorkspaceVar = sWorkspaceVar;
    astVars(i).stDsm.sPoolVarPath  = i_getPoolVarPath(stEnv, astVars(i).hRootVar);
    astVars(i).stDsm.sType         = sWorkspaceType;
end
end


%%
function oSig = i_evalWorkspaceSignal(sSignal, sModelContext)
if isempty(sSignal)
    oSig = [];
else
    stOpts = struct( ...
        'sName', sSignal);
    if ((nargin > 1) && ~isempty(sModelContext))
        stOpts.sModelContext = sModelContext;
    end
    oSig = ep_datastore_signal_info_get(stOpts);
    if ~oSig.isValid()
        oSig = [];
    end
end
end


%%
% perform three checks on workspace variables
%    1) existence
%    2) legal/valid type
%    3) same size as C-variable
function bIsValid = i_checkWorkspaceSig(stEnv, hVar, oSig)
bIsValid = ~isempty(oSig);
if bIsValid
    if ~i_checkWorkspaceVarType(oSig.getType)
        bIsValid = false;
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:VARCHECK_ILLEGAL_TYPE_WORKSPACE_VAR', ...
            'variable',  sWorkspaceVar, ...
            'type',      oSig.getType);
        return;
    end
    
    % compare sizes on workspace an C level
    anSize = atgcv_mxx_dsdd(stEnv, 'GetWidth', hVar);
    if isempty(anSize)
        % take care: scalars do not have a width in DD
        anSize = 1;
    end
    
    anWsSize = oSig.getWidth;
    % if vector: just get length; don't care if row or col vector
    if any(anWsSize == 1)
        anWsSize = max(anWsSize);
    end
    
    if ~isequal(anSize, anWsSize)
        bIsValid = false;
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:VARCHECK_SIZEDIFF_WORKSPACE_VAR', ...
            'variable',  sWorkspaceVar, ...
            'size_c',    num2str(anSize), ...
            'size_m',    num2str(anWsSize));
    end
end
end


%%
function hPoolVar = i_getPoolVar(stEnv, hVar)
hPoolVar = [];
if dsdd('Exist', hVar, 'Property', {'Name', 'PoolRef'})
    hPoolVar = atgcv_mxx_dsdd(stEnv, 'GetPoolRefTarget', hVar);
end
end


%%
function sPoolVarPath = i_getPoolVarPath(stEnv, hVar)
hPoolVar = i_getPoolVar(stEnv, hVar);
if ~isempty(hPoolVar)
    sPoolVarPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hPoolVar, 'path');
else
    sPoolVarPath = '';
end
end


%%
% note: currently only based on a black-list (not white list)
function bIsLegal = i_checkWorkspaceVarType(sType)
bIsLegal = true;

% safety check
if (~ischar(sType) || isempty(sType))
    bIsLegal = false;
end
end


%%
function astVars = i_removeUnsupportedDsmVariables(~, astVars)
if isempty(astVars)
    return;
end
astVars = astVars(arrayfun(@(x) i_isDsmValid(x.stDsm), astVars));
end


%%
function bIsValid = i_isDsmValid(stDsm)
bIsValid = ~isempty(stDsm.sWorkspaceVar);
if bIsValid
    bIsValid = ~stDsm.oWorkspaceSig.containsArrayOfBuses;
end
if bIsValid
    if strcmpi(stDsm.sKind, 'read')
        % a reader should not be written into inside the SUT
        bIsValid = isempty(stDsm.oWriteSig);
    else
        % a writer should not be written from inside the SUT
        bIsValid = isempty(stDsm.oReadSig);
    end
end
end


%%
% Add the field variable indexes of the flattened struct signals.
function astVars = i_addFlattenedVariableIndex(astVars)
if isempty(astVars)
    return;
end

mRootVar2IndexMap = containers.Map;

abIsValid = true(size(astVars));
for i = 1:length(astVars)
    stVar = astVars(i);
    try
        bIsStruct = stVar.hRootVar ~= stVar.hVar;
        if bIsStruct
            sRootKey = i_getKey(stVar.hRootVar);
            if mRootVar2IndexMap.isKey(sRootKey)
                mVar2Index = mRootVar2IndexMap(sRootKey);
            else
                mVar2Index = i_getFlattenedVar2IndexMapForRootSig(stVar.hRootVar);
                mRootVar2IndexMap(sRootKey) = mVar2Index;
            end
            sVarKey = i_getKey(stVar.hVar);
            if mVar2Index.isKey(sVarKey)
                astVars(i).aiVarIdx = mVar2Index(sVarKey);
            else
                abIsValid(i) = false;
            end
        end
    catch
        abIsValid(i) = false;
    end
end
astVars = astVars(abIsValid);
end


%%
function mVar2Index = i_getFlattenedVar2IndexMapForRootSig(hRootVar)
mVar2Index = containers.Map;

iFlatStartIdx = 1;
ahLeafVars = i_getLeafVars(hRootVar);
for i = 1:numel(ahLeafVars)
    hLeafVar = ahLeafVars(i);
    
    iElems = i_getNumOfElements(hLeafVar);
    iFlatEndIdx = iFlatStartIdx + iElems - 1;
    aiVarIdx = iFlatStartIdx:iFlatEndIdx;
    
    mVar2Index(i_getKey(hLeafVar)) = aiVarIdx;
    
    iFlatStartIdx = iFlatEndIdx + 1;
end
end


%%
function iElems = i_getNumOfElements(hVar)
aiWidth = dsdd('GetWidth', hVar);
if isempty(aiWidth)
    iElems = 1;
else
    iElems = prod(aiWidth);
end
end


%%
function sKey = i_getKey(hDdHandle)
sKey = sprintf('%d', hDdHandle);
end


%%
function ahLeafVars = i_getLeafVars(hVar)
ahLeafVars = [];

[bIsStruct, hComp] = dsdd('Exist', 'Components', 'Parent', hVar);
if bIsStruct
    ahFieldVars = dsdd('GetChildren', hComp);
    for i = 1:numel(ahFieldVars)
        ahLeafVars = [ahLeafVars, i_getLeafVars(ahFieldVars(i))]; %#ok<AGROW>
    end
else
    ahLeafVars = hVar;
end
end
