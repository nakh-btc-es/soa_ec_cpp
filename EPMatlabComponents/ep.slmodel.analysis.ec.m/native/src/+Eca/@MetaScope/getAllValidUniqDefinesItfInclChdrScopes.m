function aoItfs = getAllValidUniqDefinesItfInclChdrScopes(oScope)
aoItfs = oScope.oaDefines;
if ~isempty(aoItfs)
    aoItfs = aoItfs([aoItfs(:).bMappingValid]);
end
if ~isempty(oScope.oaChildrenScopes)
    for k=1:numel(oScope.oaChildrenScopes)
        aoItfs = [aoItfs oScope.oaChildrenScopes(k).getAllValidUniqDefinesItfInclChdrScopes()];
        if ~isempty(aoItfs)
            %Unique regarding code variable
            casUniqueID = strcat({aoItfs(:).codeVariableName},':',...
                {aoItfs(:).codeStructComponentAccess},':',...
                {aoItfs(:).codeStructName});
            [~, idx] = unique(casUniqueID);
            aoItfs = aoItfs(idx);
        end
    end
end
end