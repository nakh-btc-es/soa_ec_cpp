function aoItfs = getDefinesParameters(oEca, oScope)
% Finds among the modelwize already analysis parameters list, the ones
% used in this scope (subsystem);

abIsPartOfScope = i_isPartOfScope(oEca.aoModelWiseDefineParams, oScope);
aoItfs = oEca.aoModelWiseDefineParams(abIsPartOfScope);

for i = 1:numel(aoItfs)
    aoItfs(i).sParentScopePath = oScope.sSubSystemFullName;
    aoItfs(i).sParentScopeAccess = oScope.sSubSystemAccess;
    aoItfs(i).sParentScopeModelRef = oScope.sSubSystemModelRef;
    aoItfs(i).bParentScopeIsRunnable = oScope.bIsAutosarRunnable;
    aoItfs(i).bParentScopeIsRunnableChild = oScope.bIsAutosarRunnableChild;
    aoItfs(i).sParentRunnablePath = oScope.sParentRunnablePath;
end
end


%%
function abIsPartOfScope = i_isPartOfScope(aoParams, oScope)
abIsPartOfScope = false(size(aoParams));
casPrefixPatterns = i_getContainedPathPrefixPatterns(oScope);

for p = 1:numel(aoParams)
    for b = 1:numel(aoParams(p).userBlocks)        
        bIsBlockContained = any(~cellfun('isempty', regexp(aoParams(p).userBlocks{b}, casPrefixPatterns, 'once')));
        if bIsBlockContained
            abIsPartOfScope(p) = true;
            break; % break out of the inner loop
        end
    end
end
end


%%
function casPrefixPatterns = i_getContainedPathPrefixPatterns(oScope)
sSubsysPath = oScope.sSubSystemAccess;

casContainedPaths = reshape(ep_core_feval('ep_find_mdlrefs', sSubsysPath), 1, []);
casContainedPaths{end} = sSubsysPath; % note: replace main model containing the subsystem with full subsystem path

casPrefixPatterns = cell(size(casContainedPaths));
for i = 1:numel(casContainedPaths)
    casPrefixPatterns{i} = ['^', regexptranslate('escape', casContainedPaths{i})];
end
end
