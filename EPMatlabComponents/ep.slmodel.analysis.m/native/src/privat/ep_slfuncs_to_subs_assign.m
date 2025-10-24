function astUsages = ep_slfuncs_to_subs_assign(~, astSubs, astSlFuncs)
% Evaluates how the provided SL-Functions are connected to the list of subsystems.
%
% function astUsages = ep_slfuncs_to_subs_assign(xEnv, astSubs, astSlFuncs)
%
%   INPUT               DESCRIPTION
%        ... TODO ...
%


%%
astUsages = arrayfun(@(stSub) i_getSlFuncUsagesInContext(stSub, astSlFuncs), astSubs); 
end


%%
function stUsage = i_getSlFuncUsagesInContext(stSub, astSlFuncs)
stUsage.astUsageRefs = repmat(i_createUsageRef([], []), 1, 0);
for i = 1:numel(astSlFuncs)
    stSlFunc = astSlFuncs(i);
    
    % note: we are only interested in SL-Functions *outside* of the subsystem context (==> *external* dependency)
    if ~i_isFunctionInsideSubsystemContext(stSlFunc, stSub.sPath)
        aiCallerIdx = i_getRelevantCallerIdx(stSlFunc.astCallers, stSub.sVirtualPath);
        if ~isempty(aiCallerIdx)
            stUsage.astUsageRefs = [stUsage.astUsageRefs, i_createUsageRef(i, aiCallerIdx)];
        end        
    end
end
end


%%
function aiCallerIdx = i_getRelevantCallerIdx(astCallers, sSubVirtualPath)
aiCallerIdx = [];
for i = 1:numel(astCallers)
    stCaller = astCallers(i);
    
    if i_isPrefixPathOf(sSubVirtualPath, stCaller.sVirtualPath)
        aiCallerIdx(end + 1) = i; %#ok<AGROW>
    end
end
end


%%
function stRef = i_createUsageRef(iVarIdx, aiBlockIdx)
stRef = struct( ...
    'iVarIdx',    iVarIdx, ...
    'aiBlockIdx', aiBlockIdx);
end


%%
function bIsInsideContext = i_isFunctionInsideSubsystemContext(stSlFunc, sSubsystemVirtualPath)
bIsInsideContext = i_isPrefixPathOf(sSubsystemVirtualPath, stSlFunc.sVirtualPath);
end


%%
function bIsPrefix = i_isPrefixPathOf(sPrefixPath, sPath)
sMatcher = ['^', regexptranslate('escape', [sPrefixPath, '/'])];
bIsPrefix = ~isempty(regexp(sPath, sMatcher, 'once'));
end

