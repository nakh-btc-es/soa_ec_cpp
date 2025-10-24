function aoScopes = getChildrenScopes(oEca, oParentScope)
% Search for Scopes starting from the level below the top level

aoScopes = [];
%Get subsystems or modelblocks
[astBlockPaths, astModelRefBlockPaths] = oEca.searchLowerLevelSubsystemsAndModelblocks(oParentScope);
if ~isempty(astBlockPaths)
    [astBlockPaths, astModelRefBlockPaths] = i_filterOutChildrenOfChildren(astBlockPaths, astModelRefBlockPaths);
    aoScopes = i_evaluateChildren(oEca, astBlockPaths, oParentScope, false);
end
if ~isempty(astModelRefBlockPaths)
    aoScopes = [aoScopes, i_evaluateChildren(oEca, astModelRefBlockPaths, oParentScope, true)];
end
end


%%
function [astBlockPaths, astModelRefBlockPaths] = i_filterOutChildrenOfChildren(astBlockPaths, astModelRefBlockPaths)
if isempty(astBlockPaths)
    return;
end
if (numel(astBlockPaths) > 1)
    % sort blocks according to path length: shortest to longest 
    anPathLen = cellfun(@(p) length(p), {astBlockPaths(:).sPath});
    [~, aiSortedIdx] = sort(anPathLen);
    astBlockPaths = astBlockPaths(aiSortedIdx);
    
    casAcceptedPaths = {};
    abSelect = true(size(astBlockPaths));
    for k = 1:numel(astBlockPaths)
        bIsChildOfChild = false;
        
        for m = 1:numel(casAcceptedPaths)
            bIsChildOfChild = bIsChildOfChild || i_isSameOrAncestor(casAcceptedPaths{m}, astBlockPaths(k).sPath);
        end
        
        if bIsChildOfChild
            abSelect(k) = false;
        else
            casAcceptedPaths{end + 1} = astBlockPaths(k).sPath; %#ok<AGROW>
        end
    end
    astBlockPaths = astBlockPaths(abSelect);
end

if isempty(astModelRefBlockPaths)
    return;
end

abSelect = true(size(astModelRefBlockPaths));
for s = 1:numel(astBlockPaths)
    for k = 1:numel(astModelRefBlockPaths)
        if ~abSelect(k)
            break;
        end
        abSelect(k) = ~i_isSameOrAncestor(astBlockPaths(s).sPath, astModelRefBlockPaths(k).sPath);
    end
end
astModelRefBlockPaths = astModelRefBlockPaths(abSelect);
end


%%
function bIsRootPath = i_isSameOrAncestor(sSubPath1, sSubPath2)
bIsRootPath = isequal(sSubPath1, sSubPath2) || i_startsWithPrefix(sSubPath2, [sSubPath1, '/']);
end


%%
function bStartsWith = i_startsWithPrefix(sString, sPrefix)
bStartsWith = ~isempty(regexp(sString, ['^', regexptranslate('escape', sPrefix)], 'once'));
end


%%
function aoScopes = i_evaluateChildren(oEca, astBlockPaths, oParentScope, bIsModelRef)
if isempty(astBlockPaths)
    aoScopes = [];
    return;
end
aoLowScopes(numel(astBlockPaths)) = Eca.MetaScope;
for k = 1:numel(aoLowScopes)
    
    aoLowScopes(k).bIsRootScope = false;
    aoLowScopes(k).oParentScope = oParentScope;
    aoLowScopes(k).bIsSlFunction = oParentScope.bIsSlFunction;
    if bIsModelRef
        aoLowScopes(k).sSubSystemModelRef = astBlockPaths(k).sModelRef;
        aoLowScopes(k).bScopeIsSubsystem = false;
        aoLowScopes(k).nHandle = get_param(astBlockPaths(k).sModelRef, 'handle');
    else
        aoLowScopes(k).bScopeIsSubsystem = strcmp(get_param(astBlockPaths(k).sAccess, 'BlockType'), 'SubSystem');
        aoLowScopes(k).nHandle = get_param(astBlockPaths(k).sAccess, 'handle');
    end
    aoLowScopes(k).bScopeIsModelBlock = ~aoLowScopes(k).bScopeIsSubsystem;
    aoLowScopes(k).bIsAutosarRunnableChild = oParentScope.bIsAutosarRunnable || oParentScope.bIsAutosarRunnableChild;
    if aoLowScopes(k).bIsAutosarRunnableChild
        if oParentScope.bIsAutosarRunnable
            aoLowScopes(k).sParentRunnablePath = oParentScope.sSubSystemFullName;
        else
            aoLowScopes(k).sParentRunnablePath = oParentScope.sParentRunnablePath;
        end
    end
    
    %Subsystem info
    aoLowScopes(k).sSubSystemName = get_param(astBlockPaths(k).sAccess, 'Name');
    aoLowScopes(k).sSubSystemFullName = astBlockPaths(k).sPath;
    aoLowScopes(k).sSubSystemAccess = astBlockPaths(k).sAccess;
    
    aoLowScopes(k).nSampleTime = oEca.getSubsystemCompiledSampleTime(aoLowScopes(k).nHandle);
    
    %Sources files
    aoLowScopes(k).astCodegenSourcesFiles  = oParentScope.astCodegenSourcesFiles;
    aoLowScopes(k).casCodegenHeaderFiles   = oParentScope.casCodegenHeaderFiles;
    aoLowScopes(k).casCodegenIncludePaths  = oParentScope.casCodegenIncludePaths;
    
    %C-Functions
    stFuncInfo = [];
    if aoLowScopes(k).bScopeIsSubsystem
        %if Subsystem
        stFuncInfo = oEca.getCodeInfoSubsystem(aoLowScopes(k));
        
        %if Modelblock
    elseif aoLowScopes(k).bScopeIsModelBlock
        if ~aoLowScopes(k).isExportFuncModel
            stFuncInfo = oEca.getCodeInfoModelRef(aoLowScopes(k));
        end
    end
    if ~isempty(stFuncInfo)
        casAttributes = fieldnames(stFuncInfo);
        for m = 1:numel(casAttributes)
            sAttribute = casAttributes{m};
            aoLowScopes(k).(sAttribute) = stFuncInfo.(sAttribute);
        end
    end
    
    if oEca.bDiagMode
        sLink = sprintf('<a href = "matlab:open_system(''%s'');hilite_system(''%s'')">%s</a>',...
            oEca.sModelName,aoLowScopes(k).sSubSystemFullName,aoLowScopes(k).sSubSystemFullName);
        fprintf('\n## Scope %s has been detected \n',sLink);
    end
       
    %Interfaces
    aoLowScopes(k) = oEca.getInterfaces(aoLowScopes(k));
    
    %ChildrenScopes : recursive search starting from TopLevel-1 subsystems
    aoLowScopes(k).oaChildrenScopes = oEca.getChildrenScopes(aoLowScopes(k));
end
aoScopes = aoLowScopes;
end
