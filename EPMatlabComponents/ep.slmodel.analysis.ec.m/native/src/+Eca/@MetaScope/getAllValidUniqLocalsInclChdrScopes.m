function aoItfs = getAllValidUniqLocalsInclChdrScopes(oScope)
aoItfs = oScope.getInterfaces({'local'}, true);
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