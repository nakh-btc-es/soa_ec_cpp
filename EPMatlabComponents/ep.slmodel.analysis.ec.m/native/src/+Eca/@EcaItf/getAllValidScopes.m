function aoScopes = getAllValidScopes(oEca, sMode)

if (nargin < 2)
    sMode = 'Model';
end

[aoScopes, astEval] = oEca.getAllScopesWithEvaluatedValidity();
if ~isempty(aoScopes)
    switch lower(sMode)
        case 'model'
            aoScopes = aoScopes([astEval(:).bIsValid]);
            
        case 'code'
            aoScopes = aoScopes([astEval(:).bIsValidForCode] & [astEval(:).bIsValid]);
            
        case 'mapping'
            aoScopes = aoScopes([astEval(:).bIsValidForMapping] & [astEval(:).bIsValid]);
            
        otherwise
            error('EP:EC:INTERNAL_ERROR', 'Unknown validity mode "%s".', sMode);
    end
end
end
