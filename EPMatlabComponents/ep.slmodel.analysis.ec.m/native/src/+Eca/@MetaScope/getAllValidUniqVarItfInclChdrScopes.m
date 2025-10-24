function aoItfs = getAllValidUniqVarItfInclChdrScopes(oScope)

aoItfs = oScope.getInterfaces({'in', 'out', 'param', 'local'}, true);
if ~isempty(aoItfs)
    aoItfs = aoItfs([aoItfs(:).bMappingValid]);
end
if ~isempty(aoItfs)
    casUniqueID = strcat( ...
        {aoItfs(:).codeVariableName}, ':', {aoItfs(:).codeStructComponentAccess}, ':', {aoItfs(:).codeStructName});
    [~, idx] = unique(casUniqueID);
    aoItfs = aoItfs(idx);
end
end