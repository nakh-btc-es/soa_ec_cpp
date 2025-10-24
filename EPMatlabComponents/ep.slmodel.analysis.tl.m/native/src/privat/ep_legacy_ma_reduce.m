function stModel = ep_legacy_ma_reduce(stModel, sAddModelInfo, sModelAnalysis, bIsTlWorkflow)
% Remove Subsystems and/or Cal/Disp variables from ModelAnalysis in a consistent way.
%
% function stModel = ep_legacy_ma_reduce(stModel, sAddModelInfo, sModelAnalysis, bIsTlWorkflow)
%
%   INPUT                  DESCRIPTION
%     stEnv                 (struct)   Environment data:
%        .hMessenger        (object)   Messenger for Errors/Warnings
%        .sTmpPath          (object)   tmp directory for intermediate results
%
%     stReduce              (struct)   info about the Objects to be removed
%       .casSubIds          (cell)     IDs of Susystems to be removed
%       .casVarIds          (cell)     IDs of Variables to be removed
%     sModelAna             (file)     in: original ModelAnalysis.xml file
%     sModelAnaReduced      (file)     out: reduced ModelAnalysis.xml file
%     bIsTlWorkflow         (bool)     optional: flag if reduce is used for the TL import workflow (default == true)
%
%   OUTPUT                 DESCRIPTION
%      stChanges            (struct)   info about the changes
%        .astRemovedSubs    (array)    info about removed Subsystems
%           .sFuncName      (string)   step function name
%           .sSubId         (string)   Subsystem ID
%           .sSubPath       (string)   Subsystem model path
%
%        .astRemovedCals    (array)    info about removed Calibrations
%           .sVarName       (string)   name of the C-code variable
%           .sBlockPath     (string)   model block path of the Calibration
%           .sSubPath       (string)   corresponding Subsystem model path
%
%        .astRemovedDisps   (array)    info about removed Displays
%           .sVarName       (string)   name of the C-code variable
%           .sBlockPath     (string)   model block path of the Display
%           .sSubPath       (string)   corresponding Subsystem model path
%
%   <et_copyright>


%%
if (nargin < 4)
    bIsTlWorkflow = true;
end

%% main
stReduce = i_getReductionSet(sModelAnalysis, sAddModelInfo, bIsTlWorkflow);
if i_isReductionNeeded(stReduce)
    stChanges = i_reduceModelAnalysis(sModelAnalysis, stReduce);
    stModel   = i_reduceModelInfo(stModel, stChanges);
end
end


%%
function stChanges = i_reduceModelAnalysis(sModelAna, stReduce)
stChanges = struct( ...
    'astRemovedSubs',  [], ...
    'astRemovedCals',  [], ...
    'astRemovedDisps', []);

hDoc = mxx_xmltree('load', sModelAna);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

stChanges.astRemovedSubs = i_reduceSubsystems(hDoc, stReduce.casSubIds);
[stChanges.astRemovedCals, stChanges.astRemovedDisps] = i_reduceVariables(hDoc, stReduce.casVarIds);

mxx_xmltree('save', hDoc, sModelAna);
end


%%
function stModel = i_reduceModelInfo(stModel, stChanges)
if ~isempty(stChanges.astRemovedSubs)
    casHiddenSubIDs = {stChanges.astRemovedSubs(:).sSubId};
    for i = 1:length(stModel.astSubsystems)
        stModel.astSubsystems(i).bIsHidden = any(strcmpi(stModel.astSubsystems(i).sId, casHiddenSubIDs));
    end
end
if ~isempty(stChanges.astRemovedCals)
    casHiddenCals = unique({stChanges.astRemovedCals(:).sVarName});
    for i = 1:length(stModel.astCalVars)
        sVarName = i_getParameterName(stModel.astCalVars(i));
        stModel.astCalVars(i).bIsHidden = any(strcmpi(sVarName, casHiddenCals));
    end
end
end


%%
function sName = i_getParameterName(stParam)
if strcmp(stParam.stCal.sKind, 'explicit')
    sWorkspaceVar = stParam.stCal.sWorkspaceVar;
    if ~isempty(sWorkspaceVar)
        % for Parameters WorkspaceVar is shown with highest Prio
        sName = sWorkspaceVar;
    else
        % if there is no WorkspaceVar, the Parameter is shown with C-Name
        % --> the C-Name is read out from the DD Pool-Variable or from the Variable directly
        sDdPath = stParam.stCal.sPoolVarPath;
        if ~isempty(sDdPath)
            % replace /Components/ with DotNotation for structs
            sName = regexprep(sDdPath, '/Components/', '.');
            
            % get rid of DdPrefix //DD0/Pool/Variables/<VariableGroup1>/...
            % <==> everything before and including the last slash
            casTmpName = regexp(sName, '.*/(.*)', 'tokens', 'once');
            sName = casTmpName{1};
        else
            sName = stParam.stInfo.sRootName;
        end
    end
else
    sName = stParam.stInfo.sRootName;
end
end


%%
function stReduce = i_getReductionSet(sModelAnalysis, sAddModelInfo, bIsTlWorkflow)
stList = i_getScopeParamListInfo(sAddModelInfo);

hMaDoc = mxx_xmltree('load', sModelAnalysis);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hMaDoc));

if bIsTlWorkflow
    hRemoveScopeCriterion = i_getRemoveScopeCriterion( ...
        stList.casScopes, ...
        stList.bIsScopeWhitelist, ...
        stList.bIsScopeBlacklist, ...
        stList.sTopPath, ...
        hMaDoc);
else
    hRemoveScopeCriterion = i_getRemoveScopeCriterion( ...
        stList.casScopes, ...
        stList.bIsScopeWhitelist, ...
        stList.bIsScopeBlacklist, ...
        '', ...
        hMaDoc);
end
hRemoveParamCriterion = i_getRemoveParamCriterion(stList.casParams, stList.bIsParamWhitelist);

stReduce = struct(...
    'casSubIds', {i_getIdsOfSubsystemsToBeRemoved(hMaDoc, hRemoveScopeCriterion, bIsTlWorkflow)}, ...
    'casVarIds', {i_getIdsOfCalVariablesToBeRemoved(hMaDoc, hRemoveParamCriterion)});
end


%%
function hRemoveCriterion = i_getRemoveScopeCriterion(casScopes, bIsScopeWhitelist, bIsScopeBlacklist, sTopPath, hMaDoc)
if bIsScopeWhitelist
    % criterion: remove scope if its path is not on the white list
    if ~isempty(sTopPath)
        casKeepScopes = i_adaptTopLevelPath(hMaDoc, sTopPath, casScopes, false);
    else
        casKeepScopes = casScopes;
    end
    hRemoveCriterion = @(sPath) ~any(strcmpi(sPath, casKeepScopes));
else
    if bIsScopeBlacklist
        % criterion: remove scope if its path is on the black list
        if ~isempty(sTopPath)
            casRemoveScopes = i_adaptTopLevelPath(hMaDoc, sTopPath, casScopes, true);
        else
            casRemoveScopes = casScopes;
        end
        hRemoveCriterion = @(sPath) any(strcmpi(sPath, casRemoveScopes));
    else
        % if neither whitelist nor blacklist, do not remove anything
        hRemoveCriterion = @(sPath) false;
    end
end
end


%%
function hRemoveCriterion = i_getRemoveParamCriterion(casParams, bIsParamWhitelist)
if bIsParamWhitelist
    % criterion: remove param if its name is not on the white list
    casKeepParams = casParams;
    hRemoveCriterion = @(sName) ~any(strcmp(sName, casKeepParams));
else
    % criterion: remove param if its name is on the black list
    casRemoveParams = casParams;
    hRemoveCriterion = @(sName) any(strcmp(sName, casRemoveParams));
end
end


%%
function casSubIds = i_getIdsOfSubsystemsToBeRemoved(hDoc, hRemoveCriterion, bIsTlWorkflow)
casSubIds = {};

ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    
    sPath = mxx_xmltree('get_attribute', hSub, 'tlPath');
    if feval(hRemoveCriterion, sPath)
        sId = mxx_xmltree('get_attribute', hSub, 'id');
        if (strcmp(sId, 'ss1') && bIsTlWorkflow)
            warning('ATGCV:ADD_MODEL_REDUCE_TOPLEVEL', 'Cannot unselect the toplevel subsystem.');
        else
            casSubIds{end + 1} = sId; %#ok<AGROW>
        end
    end
end
end


%%
function casVarIds = i_getIdsOfCalVariablesToBeRemoved(hDoc, hRemoveCriterion)
casVarIds = {};

ahCals = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/ma:Input/ma:Calibration');
for i = 1:length(ahCals)
    hCal = ahCals(i);
    
    sName = mxx_xmltree('get_attribute', hCal, 'name');
    if isempty(sName)
        % for "LimitedInit" there is no Cal-name
        astRes = mxx_xmltree('get_attributes', hCal, './ma:Variable', 'globalName', 'varid');
        for k = 1:length(astRes)
            if feval(hRemoveCriterion, astRes(k).globalName)
                casVarIds{end + 1} = astRes(k).varid; %#ok<AGROW>
            end
        end
    else
        if feval(hRemoveCriterion, sName)
            astRes = mxx_xmltree('get_attributes', hCal, './ma:Variable', 'varid');
            casIds = {astRes(:).varid};
            casVarIds = [casVarIds, casIds]; %#ok<AGROW>
        end
    end
end
end


%%
function casScopePaths = i_adaptTopLevelPath(hDoc, sTopPath, casScopePaths, bAdaptModelName)
astRes = mxx_xmltree('get_attributes', hDoc, '/ma:ModelAnalysis/ma:Subsystem[@id="ss1"]', 'tlPath');
if isempty(astRes)
    % did not work! just ignore for now
    return;
end

if bAdaptModelName
    sNewTopPath = i_getModeNameFromScopePath(astRes(1).tlPath);
else
    sNewTopPath = astRes(1).tlPath;
end
if strcmpi(sNewTopPath, sTopPath)
    % if paths are equal, there is nothing to do --> just return
    return;
end

nTopLen = length(sTopPath);
for i = 1:length(casScopePaths)
    sPath = casScopePaths{i};
    if (length(sPath) > nTopLen) || bAdaptModelName
        casScopePaths{i} = [sNewTopPath, casScopePaths{i}(nTopLen+1:end)];
    else
        casScopePaths{i} = sNewTopPath;
    end
end
end


%%
function stList = i_getScopeParamListInfo(sAddModelInfo)
hDoc = mxx_xmltree('load', sAddModelInfo);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

[bIsWhitelist, bIsBlacklist] = i_isScopeWhitelistBlacklistNeither(hDoc);
stList = struct( ...
    'bIsScopeWhitelist', bIsWhitelist, ...
    'bIsScopeBlacklist', bIsBlacklist, ...
    'bIsParamWhitelist', i_isParamWhitelist(hDoc), ...
    'sTopPath',          '', ...
    'casScopes',         {{}}, ...
    'casParams',         {{}});

if stList.bIsScopeWhitelist
    stTopLevel = mxx_xmltree('get_attributes', hDoc, ...
        '/AdditionalModelInformation/Subsystems/Subsystem[@isTopLevel="true"]', 'modelPath');
    if ~isempty(stTopLevel)
        stList.sTopPath = stTopLevel(1).modelPath;
    end
end

astSubs = mxx_xmltree('get_attributes', hDoc, '/AdditionalModelInformation/Subsystems/Subsystem', 'modelPath');
if ~isempty(astSubs)
    stList.casScopes = {astSubs(:).modelPath};
    if stList.bIsScopeBlacklist
        sTopLevel = i_getModeNameFromScopePath( stList.casScopes{1});
        if ~isempty(sTopLevel)
            stList.sTopPath = sTopLevel;
        end
    end
end

astParams = mxx_xmltree('get_attributes', hDoc, '/AdditionalModelInformation/Parameters/GlobalParameter', 'name');
if ~isempty(astParams)
    stList.casParams = {astParams(:).name};
end
end


%%
function [bIsWhitelist, bIsBlacklist] = i_isScopeWhitelistBlacklistNeither(hDoc)
bIsWhitelist = false;
bIsBlacklist = false;

stRes = mxx_xmltree('get_attributes', hDoc, '/AdditionalModelInformation/Subsystems', 'usage');
if (~isempty(stRes) && ~isempty(stRes.usage))
    bIsWhitelist = strcmp(stRes.usage, 'whitelist');
    bIsBlacklist = strcmp(stRes.usage, 'blacklist');
end
end


%%
function bIsWhitelist = i_isParamWhitelist(hDoc)
stRes = mxx_xmltree('get_attributes', hDoc, '/AdditionalModelInformation/Parameters', 'usage');
bIsWhitelist = ~isempty(stRes) && (isempty(stRes.usage) || ~strcmp(stRes.usage, 'blacklist'));
end


%%
function astRemovedSubs = i_reduceSubsystems(hDoc, casSubIds)
astRemovedSubs = repmat(i_getInitSubInfo(), 0, 0);
if isempty(casSubIds)
    return;
end
stHierarchy    = i_getHierarchy(hDoc);
stHierarchy    = i_reduceHierarchyConsistently(stHierarchy, casSubIds);
astRemovedSubs = i_removeSubsystems(hDoc, stHierarchy);
end


%%
function stHierarchy = i_getHierarchy(hDoc)
ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
nSub = length(ahSubs);

stHierarchy = struct( ...
    'jIdIndexMap', java.util.HashMap(), ...
    'astSubs',     repmat(struct('sId', '', 'sParentId', ''), 1, nSub));

for i = 1:nSub
    hSub = ahSubs(i);
    sId  = mxx_xmltree('get_attribute', hSub, 'id');
    
    stHierarchy.jIdIndexMap.put(sId, i);
    stHierarchy.astSubs(i).sId = sId;
    stHierarchy.astSubs(i).sParentId = i_getParentId(hSub);
end
end


%%
function stHierarchy = i_reduceHierarchyConsistently(stHierarchy, casSubIds)
abKeep = true(size(stHierarchy.astSubs));

jToBeRemoved = i_createAndFillHashSet(casSubIds);
for i = 1:length(stHierarchy.astSubs)
    sId = stHierarchy.astSubs(i).sId;
    if jToBeRemoved.contains(sId)
        abKeep(i) = false;
        
        % don't bother finding parents for children that will be removed anyway
        continue;
    end
    
    % try to find a valid (== not to be removed) Parent by climbing the ancestor chain higher and higher
    sParentId = stHierarchy.astSubs(i).sParentId;
    while ~isempty(sParentId)
        if jToBeRemoved.contains(sParentId)
            % current ancestor is to be removed --> try next highest ancestor
            iParentIdx = stHierarchy.jIdIndexMap.get(sParentId);
            sParentId = stHierarchy.astSubs(iParentIdx).sParentId;
        else
            % found a valid ancestor as a new parent --> break the loop
            break;
        end
    end
    stHierarchy.astSubs(i).sParentId = sParentId;
end

stHierarchy.astSubs = stHierarchy.astSubs(abKeep);
stHierarchy.jIdIndexMap.clear();
for i = 1:length(stHierarchy.astSubs)
    stHierarchy.jIdIndexMap.put(stHierarchy.astSubs(i).sId, i);
end
end


%%
function astRemovedSubs = i_removeSubsystems(hDoc, stHierarchy)
astRemovedSubs = repmat(i_getInitSubInfo(), 0, 0);

% note: Tree in ModelAnalysis is a doubly-linked Tree --> infer info about children with links to parent
ccasChildIds = i_getChildrenIds(stHierarchy);

ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    sId  = mxx_xmltree('get_attribute', hSub, 'id');
    iIdx = stHierarchy.jIdIndexMap.get(sId);
    if isempty(iIdx)
        % subsystem to be removed
        astRemovedSubs(end + 1) = i_getInitSubInfo( ...
            mxx_xmltree('get_attribute', hSub, 'stepFct'), ...
            sId, ...
            mxx_xmltree('get_attribute', hSub, 'tlPath')); %#ok<AGROW>
        
        mxx_xmltree('delete_node', hSub);
    else
        % subsystem to be kept --> adapt the parent/child relationships
        i_adaptParent(hSub, stHierarchy.astSubs(iIdx).sParentId);
        i_adaptChildren(hSub, ccasChildIds{iIdx});
    end
end
end


%%
function i_adaptParent(hSub, sParentId)
if isempty(sParentId)
    % no parent --> if one exists, remove its root node
    mxx_xmltree('delete_nodes', hSub, './ma:Parents');
else
    % add parent
    hParents = mxx_xmltree('get_nodes', hSub, './ma:Parents');
    if isempty(hParents)
        hParents = mxx_xmltree('add_node', hSub, 'Parents');
    end
    hSubRef = mxx_xmltree('get_nodes', hParents, './ma:SubsystemRef');
    if isempty(hSubRef)
        hSubRef = mxx_xmltree('add_node', hParents, 'SubsystemRef');
    end
    mxx_xmltree('set_attribute', hSubRef, 'refID', sParentId);
end
end


%%
function i_adaptChildren(hSub, casChildIds)
bIsRemoveMode = isempty(casChildIds);

% add children
hChildren = mxx_xmltree('get_nodes', hSub, './ma:Children');
if isempty(hChildren)
    if ~bIsRemoveMode
        hChildren = mxx_xmltree('add_node', hSub, 'Children');
    end
else
    % if there are some children, remove them before adding new ones
    mxx_xmltree('delete_nodes', hChildren, './ma:SubsystemRef');
    if bIsRemoveMode
        % if no children are to be added --> remove Children parent node if empty (== no ma:Block elements)
        if isempty(mxx_xmltree('get_nodes', hChildren, './*'))
            mxx_xmltree('delete_node', hChildren);
        end
    end
end
for i = 1:length(casChildIds)
    hSubRef = mxx_xmltree('add_node', hChildren, 'SubsystemRef');
    mxx_xmltree('set_attribute', hSubRef, 'refID', casChildIds{i});
end
end


%%
function ccasChildren = i_getChildrenIds(stHierarchy)
nSub = length(stHierarchy.astSubs);

ccasChildren = cell(1, nSub);
ccasChildren(:) = deal({{}}); % init cell-of-cells-array with empty cells
for i = 1:nSub
    sChildId = stHierarchy.astSubs(i).sId;
    sParentId = stHierarchy.astSubs(i).sParentId;
    if ~isempty(sParentId)
        iParentIdx = stHierarchy.jIdIndexMap.get(sParentId);
        ccasChildren{iParentIdx}{end + 1} = sChildId;
    end
end
end


%%
function jSet = i_createAndFillHashSet(casKeys)
jSet = java.util.HashSet(length(casKeys));
for i = 1:length(casKeys)
    jSet.add(casKeys{i});
end
end


%%
function sParentId = i_getParentId(hSub)
sParentId = '';
astParents = mxx_xmltree('get_attributes', hSub, './ma:Parents/ma:SubsystemRef', 'refID');
if ~isempty(astParents)
    if (length(astParents) > 1)
        % !ASSUMPTION: in Model UseCase only _one_ Parent expected
        error('ATGCV:API:WRONG_ASSUMPTION', 'Found subsystem with multiple parents.');
    end
    sParentId = astParents.refID;
end
end


%%
function stSubInfo = i_getInitSubInfo(sFuncName, sSubId, sSubPath)
if (nargin ~= 3)
    sFuncName = '';
    sSubId    = '';
    sSubPath  = '';
end
stSubInfo = struct( ...
    'sFuncName', sFuncName, ...
    'sSubId',    sSubId, ...
    'sSubPath',  sSubPath);
end


%%
function stVarInfo = i_getInitVarInfo(sVarName, sBlockPath, sSubPath)
if (nargin < 3)
    sVarName   = '';
    sBlockPath = '';
    sSubPath   = '';
end
stVarInfo = struct( ...
    'sVarName',   sVarName, ...
    'sBlockPath', sBlockPath, ...
    'sSubPath',   sSubPath);
end


%%
function [astRemovedCals, astRemovedDisps] = i_reduceVariables(hDoc, casVarIds)
if isempty(casVarIds)
    astRemovedCals  = repmat(i_getInitVarInfo(), 0, 0);
    astRemovedDisps = repmat(i_getInitVarInfo(), 0, 0);
else
    [astRemovedCals, astRemovedDisps] = i_removeVars(hDoc, casVarIds);
end
end


%%
function [astRemovedCals, astRemovedDisps] = i_removeVars(hDoc, casVarIds)
astRemovedCals  = repmat(i_getInitVarInfo(), 0, 0);
astRemovedDisps = repmat(i_getInitVarInfo(), 0, 0);

ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    sSubPath = mxx_xmltree('get_attribute', hSub, 'tlPath');
    
    % ! ASSUMPTION: number of Vars to be removed is small; otherwise the following algo is very inefficient
    abIsHandled = false(size(casVarIds));
    for k = 1:length(casVarIds)
        sVar = casVarIds{k};
        
        % assumption: at most one Cal for a specific VarID
        hCalVar = mxx_xmltree('get_nodes', hSub, ...
            sprintf('./ma:Interface/ma:Input/ma:Calibration/ma:Variable[@varid="%s"]', sVar));
        if ~isempty(hCalVar)
            abIsHandled(k) = true;
            
            hCal = mxx_xmltree('get_nodes', hCalVar, './..');
            sCalName = mxx_xmltree('get_attribute', hCal, 'name');
            if isempty(sCalName)
                sCalName = mxx_xmltree('get_attribute', hCalVar, 'globalName');
            end
            astRemovedCals(end + 1) = i_getInitVarInfo( ...
                sCalName, ...
                mxx_xmltree('get_attribute', hCal, 'tlBlockPath'), sSubPath); %#ok<AGROW>
            
            % delete the parent Input node
            mxx_xmltree('delete_nodes', hCal, './..');
            
            % assumption: if a CAL was found for VarID, there will be no DISP --> skip to next loop iteration
            continue;
        end
        
        % assumption: at most one Disp for a specific VarID
        hDispVar = mxx_xmltree('get_nodes', hSub, ...
            sprintf('./ma:Interface/ma:Output/ma:Display/ma:Variable[@varid="%s"]', sVar));
        if ~isempty(hDispVar)
            abIsHandled(k) = true;
            
            hDisp = mxx_xmltree('get_nodes', hDispVar, './..');
            
            astRemovedDisps(end + 1) = i_getInitVarInfo( ...
                mxx_xmltree('get_attribute', hDispVar, 'globalName'), ...
                mxx_xmltree('get_attribute', hDisp, 'tlBlockPath'), sSubPath); %#ok<AGROW>
            
            % delete the parent Output node
            mxx_xmltree('delete_nodes', hDisp, './..');
        end
    end
    % delete all Variables that have been handled already
    casVarIds(abIsHandled) = [];
end
end


%%
% evaluate Reduce options to check if reduction is needed
function bIsReductionNeeded = i_isReductionNeeded(stReduce)
bIsReductionNeeded = false;

casDefaultCellFields = { ...
    'casSubIds', ...
    'casVarIds'};

for i = 1:length(casDefaultCellFields)
    sField = casDefaultCellFields{i};
    
    if isfield(stReduce, sField)
        bIsReductionNeeded = bIsReductionNeeded || ~isempty(stReduce.(sField));
    end
end
end

%%
function sName = i_getModeNameFromScopePath(sScopePath)
aiIdx = regexp(sScopePath, '/');
sName = sScopePath(1:(aiIdx(1)-1));
end