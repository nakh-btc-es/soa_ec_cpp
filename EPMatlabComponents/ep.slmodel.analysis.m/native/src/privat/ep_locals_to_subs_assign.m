function astUsages = ep_locals_to_subs_assign(xEnv, astSubs, astLocals)
% Evaluates how the provided locals are connected to the list of subsystems.
%
% function astUsages = ep_locals_to_subs_assign(xEnv, astSubs, astLocals)
%
%   INPUT               DESCRIPTION
%        ... TODO ...
%


%%
astUsages = arrayfun(@(stSub) i_getLocalUsagesInContext(xEnv, stSub, astLocals), astSubs); 
end


%%
function stUsage = i_getLocalUsagesInContext(~, stSub, astLocals)
stUsage.astUsageRefs = repmat(i_createUsageRef([], []), 1, 0);
for i = 1:numel(astLocals)
    stLocal = astLocals(i);
    
    bIsInnerLocal = ~isempty(stLocal.stSfInfo) && isempty(stLocal.aiPorts);
    if i_isLocalInContext(stLocal, stSub.sVirtualPath, bIsInnerLocal)
        stUsage.astUsageRefs = [stUsage.astUsageRefs, i_createUsageRef(i, 1)];
    end
end
end


%%
function bIsInContext = i_isLocalInContext(stLocal, sSubVirtualPath, bIsInnerLocal)
bIsInContext = i_isPrefixPath(sSubVirtualPath, stLocal.sVirtualPath) || ...
    (bIsInnerLocal && strcmp(sSubVirtualPath, stLocal.sVirtualPath));
end


%%
function stRef = i_createUsageRef(iVarIdx, aiBlockIdx)
stRef = struct( ...
    'iVarIdx',    iVarIdx, ...
    'aiBlockIdx', aiBlockIdx);
end


%%
function bIsPrefix = i_isPrefixPath(sPrefixPath, sPath)
sMatcher = ['^', regexptranslate('escape', [sPrefixPath, '/'])];
bIsPrefix = ~isempty(regexp(sPath, sMatcher, 'once'));
end
