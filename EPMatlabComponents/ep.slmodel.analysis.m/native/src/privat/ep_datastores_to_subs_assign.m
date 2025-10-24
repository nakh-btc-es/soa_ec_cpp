function astUsages = ep_datastores_to_subs_assign(xEnv, aoScopeContexts, astDsms, bDSReadWriteObservable)
% Evaluates how the provided datastores are connected to the list of subsystems.
%
% function astUsages = ep_datastores_to_subs_assign(xEnv, aoScopeContexts, astDsms, bDSReadWriteObservable)
%
%   INPUT               DESCRIPTION
%        ... TODO ...
%


%%
astUsages = arrayfun(@(x) i_getDsmUsagesInContext(xEnv, x, astDsms, bDSReadWriteObservable), aoScopeContexts); 
end


%%
function stUsage = i_getDsmUsagesInContext(xEnv, oScopeContext, astDsms, bDSReadWriteObservable)
stUsage.astDsmReaderRefs = repmat(i_createUsageRef([], []), 1, 0);
stUsage.astDsmWriterRefs = repmat(i_createUsageRef([], []), 1, 0);
for i = 1:numel(astDsms)
    stDsm = astDsms(i);
    
    if i_isVisibleInSubsystem(stDsm, oScopeContext.getAllPaths())
        [aiReaderBlocks, aiWriterBlocks] = i_getVisibleReadersAndWriters(stDsm.astUsingBlocks, oScopeContext);
        bIsReader = ~isempty(aiReaderBlocks);
        bIsWriter = ~isempty(aiWriterBlocks);
        if xor(bIsReader, bIsWriter)
            if bIsReader
                stUsage.astDsmReaderRefs = [stUsage.astDsmReaderRefs, i_createUsageRef(i, aiReaderBlocks)];
            else
                stUsage.astDsmWriterRefs = [stUsage.astDsmWriterRefs, i_createUsageRef(i, aiWriterBlocks)];
            end
        elseif (bIsReader && bIsWriter)
            if bDSReadWriteObservable 
                %if flag is set, make RW Datastore observable (make it a writer/output)
                stUsage.astDsmWriterRefs = [stUsage.astDsmWriterRefs, i_createUsageRef(i, aiWriterBlocks)];
            else
                %R/W datastores shall be ignored
                ep_env_message_add(xEnv, 'ATGCV:MOD_ANA:DS_USAGE_READWRITE', ...
                    'ds_name',   stDsm.sName, ...
                    'subsystem', oScopeContext.getPath());
            end
        end        
    end
end
end


%%
function [aiReaderBlocks, aiWriterBlocks] = i_getVisibleReadersAndWriters(astBlocks, oScopeContext)
aiReaderBlocks = [];
aiWriterBlocks = [];
for i = 1:numel(astBlocks)
    stBlock = astBlocks(i);
    
    if oScopeContext.contains(stBlock.sVirtualPath)
        if stBlock.bIsReader
            aiReaderBlocks(end + 1) = i; %#ok<AGROW>
        end
        if stBlock.bIsWriter
            aiWriterBlocks(end + 1) = i; %#ok<AGROW>
        end
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
function bIsVisible = i_isVisibleInSubsystem(stDsm, casContextPaths)
if isempty(stDsm.sPath)
    % DataStore is global 
    %   --> DS automatically visible in all models/susystems
    bIsVisible = true; 
else
    % DataStore is local 
    %   --> DataStoreMemory block has to be located in one of the parents of subsystem
    bIsVisible = i_isLocatedInAncestorSubsystem(stDsm, casContextPaths);
end
end


%%
function bIsInAncestor = i_isLocatedInAncestorSubsystem(stDsm, casContextPaths)
sParentDsmPath = i_getParentPath(stDsm.sPath);
bIsInAncestor = false;
for i = 1:numel(casContextPaths)
    bIsInAncestor = bIsInAncestor || i_isPrefixPath(sParentDsmPath, casContextPaths{i});
end
end


%%
function bIsPrefix = i_isPrefixPath(sPrefixPath, sPath)
sMatcher = ['^', regexptranslate('escape', [sPrefixPath, '/'])];
bIsPrefix = ~isempty(regexp(sPath, sMatcher, 'once'));
end


%%
function sParentPath = i_getParentPath(sPath)
if isempty(sPath)
    sParentPath = '';
else
    % Note: take care of escaped separators "//"
    % Example: path = "A/B/C//D" --> parent path == "A/B"
    sParentPath = regexprep(sPath, '(.*[^/])/[^/].*[^/]$',  '$1');
    if strcmp(sParentPath, sPath)
        sParentPath = '';
    end
end
end

