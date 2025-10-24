function astUsages = ep_params_to_subs_assign(xEnv, astSubs, astParams)
% Evaluates how the provided parameters are connected to the list of subsystems.
%
% function astUsages = ep_params_to_subs_assign(xEnv, astSubs, astParams)
%
%   INPUT               DESCRIPTION
%        ... TODO ...
%


%%
astUsages = arrayfun(@(stSub) i_getParamUsagesInContext(xEnv, stSub, astParams), astSubs); 
end


%%
function stUsage = i_getParamUsagesInContext(~, stSub, astParams)
stUsage.astUsageRefs = repmat(i_createUsageRef([], []), 1, 0);
for i = 1:numel(astParams)
    stParam = astParams(i);
    
    % if the parameter is a model argument, the subsystem needs physically to be part of the model where the
    % parameter is defined; otherwise the parameter cannot be accessed later by the harness
    if stParam.bIsModelArg && ~i_isSubsystemInsideSourceModel(stSub.sPath, stParam.sSource)
        aiContextBlocks = [];
    else
        aiContextBlocks = i_filterBlocksInContext(stParam.astBlockInfo, stSub.sVirtualPath);
    end
    if ~isempty(aiContextBlocks)
        stUsage.astUsageRefs = [stUsage.astUsageRefs, i_createUsageRef(i, aiContextBlocks)];
    end
end
end


%%
function aiContextBlocks = i_filterBlocksInContext(astBlockInfos, sSubVirtualPath)
aiContextBlocks = [];
for i = 1:numel(astBlockInfos)
    stBlockInfo = astBlockInfos(i);
    
    % the block is virtually part of the subsystem if the virtual path of the subsystem is a prefix of the virtual path
    % of the block
    % note: special treatment for model reference blocks; they need to be real part of the subsystem and not the
    %       subsystem itself
    if i_isModelReferenceBlock(stBlockInfo.sPath)
        bBlockIsVirtuallyInSubsystem = i_isPrefixPath(sSubVirtualPath, stBlockInfo.sVirtualPath);
    else
        bBlockIsVirtuallyInSubsystem = i_isPrefixPathOrSame(sSubVirtualPath, stBlockInfo.sVirtualPath);
    end
    if bBlockIsVirtuallyInSubsystem
        aiContextBlocks(end + 1) = i; %#ok<AGROW>
    end
end
end


%%
function bIsInsideModel = i_isSubsystemInsideSourceModel(sSubPath, sModel)
bIsInsideModel = i_isPrefixPathOrSame(sModel, sSubPath); % "subsystem" can also be the model itself in this context
end


%%
function stRef = i_createUsageRef(iVarIdx, aiBlockIdx)
stRef = struct( ...
    'iVarIdx',    iVarIdx, ...
    'aiBlockIdx', aiBlockIdx);
end


%%
function bIsPrefixOrSame = i_isPrefixPathOrSame(sPrefixPath, sPath)
bIsPrefixOrSame = strcmp(sPrefixPath, sPath) || i_isPrefixPath(sPrefixPath, sPath);
end


%%
function bIsPrefix = i_isPrefixPath(sPrefixPath, sPath)
sMatcher = ['^', regexptranslate('escape', [sPrefixPath, '/'])];
bIsPrefix = ~isempty(regexp(sPath, sMatcher, 'once'));
end


%%
function bIsModelRef = i_isModelReferenceBlock(sPath)
bIsModelRef = strcmp(get_param(sPath, 'Type'), 'block') && strcmp(get_param(sPath, 'BlockType'), 'ModelReference');
end
