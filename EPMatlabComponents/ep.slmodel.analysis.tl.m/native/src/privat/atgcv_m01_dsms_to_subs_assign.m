function astUsages = atgcv_m01_dsms_to_subs_assign(stEnv, astSubs, astDsms)
% Analyse how the data stores are used in context of the provided subsystems.
%
% function  astUsages = atgcv_m01_dsms_to_subs_assign(stEnv, astSubs, astDsms)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)   environment structure
%     astSubs             (array)    array of subsystem strctures with following infos
%       .sPath            (string)      the real model path
%       .sVirtualPath     (string)      the virtual path (differs from the real path for refrerenced models)
%
%     astDsms             (array)    array of DataStore structures with following infos
%       .sPath            (string)      the real model path
%       .sVirtualPath     (string)      the virtual path (differs from the real path for refrerenced models)
%       .astUsingBlocks   (array)       array of DataStore accessor blocks with the following infos
%         .bIsReader      (boolean)       true, if the accessor block is a DS reader; otherwise false
%         .bIsWriter      (boolean)       true, if the accessor block is a DS writer; otherwise false
%         .sPath          (string)        the real model path
%         .sVirtualPath   (string)        the virtual path (differs from the real path for refrerenced models)
%
%  OUTPUT               DESCRIPTION
%     astUsages           (array)    array of usages corrsponding to the provided subsystems (same number and order)
%       .astDsmReaderRefs (array)       array of DS reader references with the following info
%           .iVarIdx      (num)           index of the referenced DataStore
%           .aiBlockIdx   (array)         array of indices of the using blocks
%       .astDsmWriterRefs (array)       array of DS writer references with the following info
%           .iVarIdx      (num)           index of the referenced DataStore
%           .aiBlockIdx   (array)         array of indices of the using blocks
%


%%
astUsages = arrayfun(@(stSub) i_getDsmUsagesInContext(stEnv, stSub, astDsms), astSubs); 
end


%%
function stUsage = i_getDsmUsagesInContext(stEnv, stSub, astDsms)
stUsage.astDsmReaderRefs = repmat(i_createVarRef([], []), 1, 0);
stUsage.astDsmWriterRefs = repmat(i_createVarRef([], []), 1, 0);
for i = 1:numel(astDsms)
    stDsm = astDsms(i);
    
    if i_isVisibleInSubsystem(stDsm, stSub.sPath)
        [aiReaderBlocks, aiWriterBlocks] = i_getVisbleReadersAndWriters(stDsm.astUsingBlocks, stSub.sVirtualPath);
        bIsReader = ~isempty(aiReaderBlocks);
        bIsWriter = ~isempty(aiWriterBlocks);
        if xor(bIsReader, bIsWriter)
            if bIsReader
                stUsage.astDsmReaderRefs = [stUsage.astDsmReaderRefs, i_createVarRef(i, aiReaderBlocks)];
            else
                stUsage.astDsmWriterRefs = [stUsage.astDsmWriterRefs, i_createVarRef(i, aiWriterBlocks)];
            end
        elseif (bIsReader && bIsWriter)
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:DS_USAGE_READWRITE', ...
                'ds_name',   stDsm.sName, ...
                'subsystem', stSub.sPath);
        end        
    end
end
end


%%
function [aiReaderBlocks, aiWriterBlocks] = i_getVisbleReadersAndWriters(astBlocks, sSubVirtualPath)
aiReaderBlocks = [];
aiWriterBlocks = [];
for i = 1:numel(astBlocks)
    stBlock = astBlocks(i);
    
    if i_isPrefixPath(sSubVirtualPath, stBlock.sVirtualPath)
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
function stRef = i_createVarRef(iVarIdx, aiBlockIdx)
stRef = struct( ...
    'iVarIdx',    iVarIdx, ...
    'aiBlockIdx', aiBlockIdx);
end


%%
function bIsVisible = i_isVisibleInSubsystem(stDsm, sSubsystemPath)
if isempty(stDsm.sPath)
    % DataStore is global 
    %   --> DS automatically visible in all models/susystems
    bIsVisible = true; 
else
    % DataStore is local 
    %   --> DataStoreMemory block has to be located in one of the parents of subsystem
    bIsVisible = i_isLocatedInAncestorSubsystem(stDsm, sSubsystemPath);
end
end


%%
function bIsInAncestor = i_isLocatedInAncestorSubsystem(stDsm, sSubsystemPath)
bIsInAncestor = i_isPrefixPath(i_getParentPath(stDsm.sPath), sSubsystemPath);
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

