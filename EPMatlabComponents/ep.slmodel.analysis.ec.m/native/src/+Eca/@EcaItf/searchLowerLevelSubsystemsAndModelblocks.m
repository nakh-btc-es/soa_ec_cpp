function [astBlockPaths, astModelRefBlockPaths] = searchLowerLevelSubsystemsAndModelblocks(oEca, oParentScope)
% TODO: move this function outside of the Eca object context (i.e. normal function instead of method of object)

stScopeConfig = oEca.stActiveConfig.ScopeCfg;

if ((oParentScope.bScopeIsModel || oParentScope.bScopeIsModelBlock) && oEca.isExportFuncModel())
    astExpFuncSubs = oEca.getSubsystemsMappableToExportFuncs();
    if isempty(astExpFuncSubs)
        casExpFuncSubs = {};
    else
        casExpFuncSubs = {astExpFuncSubs.sSubsystem};
    end
    casExportFuncSubsysPaths = ...
        i_filterSubsFromModel(oParentScope.sSubSystemAccess, casExpFuncSubs);
else
    casExportFuncSubsysPaths = {};
end
[astBlockPaths, astModelRefBlockPaths] = ...
    i_getSubsystemAndModelRefBlocks(oParentScope, stScopeConfig, casExportFuncSubsysPaths);
end


%%
function casSubsFromModel = i_filterSubsFromModel(sModel, casSubs)
abSelect = cellfun(@(s) ~isempty(regexp(s, ['^', sModel, '/'], 'once')), casSubs);
casSubsFromModel = casSubs(abSelect);
end


%%
function [casSubsystemFilters, stExtendedSubsysFilters] = i_getSubsystemFilters(stScopeConfig)
casSubsystemFilters = {};
stExtendedSubsysFilters = struct();

for iPar = 1:numel(stScopeConfig.Subsys.PropFilter)
    sPropName = stScopeConfig.Subsys.PropFilter(iPar).BlockParameterName;
    sPropValue = stScopeConfig.Subsys.PropFilter(iPar).BlockParameterValue;
    
    if ischar(sPropValue)
        casSubsystemFilters{end + 1} = sPropName; %#ok<AGROW>
        casSubsystemFilters{end + 1} = sPropValue; %#ok<AGROW>
    elseif iscell(sPropValue)
        stExtendedSubsysFilters.(sPropName) = sPropValue;
    else
        error('EP:EC:WRONG_PROP_VALUE_TYPE', ...
            'Value of property "%s" needs to be either a string or a cell of string.', sPropValue);
    end
end
end


%%
function casSubsystems = i_getSubsystemsAccordingToConfig(sSearchRoot, stScopeConfig)
casSubsystems = {};

if isfield(stScopeConfig, 'LowerScope')
    if stScopeConfig.LowerScope.Subsys.Allow
        casSubsystems = i_getSubsystems(sSearchRoot, stScopeConfig);
    end
else
    casSubsystems = i_getSubsystems(sSearchRoot, stScopeConfig);
end
end


%%
function casSubsystems = i_getSubsystems(sSearchRoot, stScopeConfig)
[casSubsystemFilters, stExtendedSubsysFilters] = i_getSubsystemFilters(stScopeConfig);

casSubsystems = ep_core_feval('ep_find_system', sSearchRoot,...
    'FollowLinks',        'on',...
    'LookUnderMasks',     'all',...
    'IncludeCommented',   'off',...
    'BlockType',          'SubSystem', ...
    'IsSubsystemVirtual', 'off', ...
    casSubsystemFilters{:});

if ~isempty(casSubsystems)
    abDoSelect = true(size(casSubsystems));
    
    for i = 1:numel(casSubsystems)
        sSubsystem = casSubsystems{i};
        bIsFilterMatchingSC = i_applyFilterStateChart(sSubsystem);
        bIsFilterMatching = i_applyFilterProperties(sSubsystem, stExtendedSubsysFilters);
        abDoSelect(i) = bIsFilterMatchingSC & bIsFilterMatching; 
    end    
    casSubsystems = casSubsystems(abDoSelect);
end
end

% Filter statechart where TreatAsAtomicUnitOption is checked (see EP-2082)
% If not filtered and RTW code options have been set, a scope would have been generated with unvalid RTW options.
function bIsFilterMatching = i_applyFilterStateChart(sSubsystem)
bIsFilterMatching = true;
bIsAChart = strcmp(get_param(sSubsystem,'SFBlockType'),'Chart');
sValue = get_param(sSubsystem, 'TreatAsAtomicUnit');
if strcmp(sValue, 'off') && bIsAChart
    bIsFilterMatching = false;
end
end

%%
% checks it the model block matches all properties defined by the filter
function bIsFilterMatching = i_applyFilterProperties(xModelBlock, stFilter)
bIsFilterMatching = true;

casProperties = fieldnames(stFilter);
for i = 1:numel(casProperties)
    sProperty = casProperties{i};
    
    try
        sValue = get_param(xModelBlock, sProperty);
        casAllowedPropValues = stFilter.(sProperty);
        bIsFilterMatching = any(cellfun(@(x) isequal(x, sValue), casAllowedPropValues));
        if ~bIsFilterMatching
            break; % early return for the first invalid property value
        end
    catch
    end
end
end


%%
function casModelRefBlockPaths = i_getModelRefPaths(sSearchRoot)
casModelRefBlockPaths = ep_core_feval('ep_find_system', sSearchRoot, ...
    'FollowLinks',      'on',...
    'LookUnderMasks',   'all',...
    'IncludeCommented', 'off',...
    'BlockType',        'ModelReference');
end


%%
function sString = i_replacePrefix(sString, sPrefix, sNewPrefix)
sString = regexprep(sString, ['^', regexptranslate('escape', sPrefix)], sNewPrefix);
end


%%
function [astBlockPaths, astModelRefBlockPaths] = i_getSubsystemAndModelRefBlocks(oParentScope, stScopeConfig, casPreselectedSubs)
sParentSubSys = oParentScope.sSubSystemAccess;
sParentVirtualPath = oParentScope.sSubSystemFullName;

casSubsysPaths = i_getSubsystemsAccordingToConfig(sParentSubSys, stScopeConfig);
if ~isempty(casPreselectedSubs)
    casPreselectedSubs = reshape(casPreselectedSubs, 1, []);
    casSubsysPaths = reshape(casPreselectedSubs, 1, []);
    casSubsysPaths = [casPreselectedSubs, setdiff(casSubsysPaths, casPreselectedSubs)];
end
casModelRefBlockPaths = i_getModelRefPaths(sParentSubSys);

% filter out nested elements because they will be part of the next step inside a *recursive* search
[casSubsysPaths, casModelRefBlockPaths] = i_filterOutNestedElements(sParentSubSys, casSubsysPaths, casModelRefBlockPaths);

casAdaptedSubsysPaths = cellfun(...
    @(p) i_replacePrefix(p, sParentSubSys, sParentVirtualPath), casSubsysPaths, ...
    'UniformOutput', false);
casAdaptedModelRefBlockPaths = cellfun(...
    @(p) i_replacePrefix(p, sParentSubSys, sParentVirtualPath), casModelRefBlockPaths, ...
    'UniformOutput', false);

if ~isempty(casSubsysPaths)
    astBlockPaths = struct( ...
        'sPath',   casAdaptedSubsysPaths, ...
        'sAccess', casSubsysPaths);
else
    astBlockPaths = struct( ...
        'sPath',   {}, ...
        'sAccess', {});
end

if ~isempty(casModelRefBlockPaths)
    casRefModel = get_param(casModelRefBlockPaths, 'ModelName');
    if isempty(casRefModel)
        casRefModel = cell(0, 1);
    end
    
    astModelRefBlockPaths = struct( ...
        'sPath',     casAdaptedModelRefBlockPaths, ...
        'sModelRef', casModelRefBlockPaths, ...
        'sAccess',   casRefModel);
else
    astModelRefBlockPaths = struct( ...
        'sPath',     {}, ...
        'sModelRef', {}, ...
        'sAccess',  {});
end
end


%%
function [casSubsysPaths, casModelRefBlockPaths] = i_filterOutNestedElements(sParentPath, casSubsysPaths, casModelRefBlockPaths)
% first of all: fiter out the parent path if present
if ismember(sParentPath, casSubsysPaths)
    casSubsysPaths = setxor(sParentPath, casSubsysPaths)';
end
if ismember(sParentPath, casModelRefBlockPaths)
    casModelRefBlockPaths = setxor(sParentPath, casModelRefBlockPaths)';
end
if isempty(casSubsysPaths)
    return;
end

% now filter out children of elements inside the list
if (numel(casSubsysPaths) > 1)
    % sort blocks according to path length: shortest to longest
    anPathLen = cellfun(@(p) length(p), casSubsysPaths);
    [~, aiSortedIdx] = sort(anPathLen);
    casSubsysPaths = casSubsysPaths(aiSortedIdx);
    
    casAcceptedPaths = {};
    abSelect = true(size(casSubsysPaths));
    for k = 1:numel(casSubsysPaths)
        sSubPath = casSubsysPaths{k};
        bIsChildOfChild = false;
        
        for m = 1:numel(casAcceptedPaths)
            bIsChildOfChild = bIsChildOfChild || i_isSameOrAncestor(casAcceptedPaths{m}, sSubPath);
        end
        
        if bIsChildOfChild
            abSelect(k) = false;
        else
            casAcceptedPaths{end + 1} = sSubPath; %#ok<AGROW>
        end
    end
    casSubsysPaths = casSubsysPaths(abSelect);
end

if isempty(casModelRefBlockPaths)
    return;
end

abSelect = true(size(casModelRefBlockPaths));
for s = 1:numel(casSubsysPaths)
    for k = 1:numel(casModelRefBlockPaths)
        if ~abSelect(k)
            break;
        end
        abSelect(k) = ~i_isSameOrAncestor(casSubsysPaths{s}, casModelRefBlockPaths{k});
    end
end
casModelRefBlockPaths = casModelRefBlockPaths(abSelect);
end


%%
function bIsRootPath = i_isSameOrAncestor(sSubPath1, sSubPath2)
bIsRootPath = isequal(sSubPath1, sSubPath2) || i_startsWithPrefix(sSubPath2, [sSubPath1, '/']);
end


%%
function bStartsWith = i_startsWithPrefix(sString, sPrefix)
bStartsWith = ~isempty(regexp(sString, ['^', regexptranslate('escape', sPrefix)], 'once'));
end
