function aoItfs = getAllValidUniqParamInclChdrScopes(oScope, bExcludeParamsWithoutMapping)
if (nargin < 2)
    bExcludeParamsWithoutMapping = true;
end

aoItfs = oScope.getInterfaces({'param'}, true);
if ~isempty(aoItfs) && bExcludeParamsWithoutMapping
    aoItfs = aoItfs([aoItfs(:).bMappingValid]);
end
if ~isempty(aoItfs)
    casUniqueID = arrayfun(@i_getUniqueParamName, aoItfs, 'UniformOutput', false); 
    [~, aiIdx] = unique(casUniqueID);
    aoItfs = aoItfs(aiIdx);
end
end


%%
function sName = i_getUniqueParamName(oParamItf)
sModelPart = oParamItf.stParam_.sName;

sCodePart = sprintf('%s:%s:%s', ...
    oParamItf.codeVariableName, ...
    oParamItf.codeStructComponentAccess, ... ...
    oParamItf.codeStructName);

sName = sprintf('%s|%s', sModelPart, sCodePart);
end

