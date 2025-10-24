function aoScopes = getAllScopes(oEca)
% Returns the root scope and all child scope objects.

aoScopes = i_getScopeRecursively(oEca.oRootScope);
end


%%
function aoScopes = i_getScopeRecursively(oScope)
aoScopes = oScope;

for k = 1:numel(aoScopes.oaChildrenScopes)
    aoScopes = [aoScopes i_getScopeRecursively(oScope.oaChildrenScopes(k))]; %#ok<AGROW>
end
end
