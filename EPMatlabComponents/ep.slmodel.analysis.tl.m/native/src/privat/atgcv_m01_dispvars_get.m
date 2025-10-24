function [astVars, oOnCleanupClearInternalCaching] = atgcv_m01_dispvars_get(stEnv, hSubsys)
% get all DISP variables of subsystem
%
%  astVars = atgcv_m01_dispvars_get(stEnv, hSubsys)
%
%   INPUT           DESCRIPTION
%     stEnv            (struct)     environment structure
%     hSubsys          (handle)     DD handle to the current subsystem (DataDictionary->Subsystems->"TopLevelName")
%
%   OUTPUT          DESCRIPTION
%     astVars            (array)       array of struct with following data
%       .hVar            (handle)      DD variable of DISP var
%       .stInfo          (struct)      resulting info_struct from "atgcv_m01_variable_info_get"
%       .astBlockInfo    (array)       resulting info_structs from "atgcv_m01_variable_block_info_get"
%       .iPortNumber     (integer)     port number of outport (empty for SF-local)
%       .aiOutIdx        (array)       index of subsignals corresponding to variable (empty for SF-local)
%


%%
% clear used memoized function when leaving this function
sMemoizedFunc = 'atgcv_m01_block_output_signals_memget';
oOnCleanupClearInternalCaching = onCleanup(@() feval('clear', sMemoizedFunc));


%% main
astVars = i_getAllVars(stEnv, hSubsys);
astVars = i_addVariableInfoAndMergeSameVars(stEnv, astVars);
astVars = i_removeUnsupportedVars(stEnv, astVars, hSubsys);
astVars = i_addOutportInfo(stEnv, astVars);
end



%%
function stVarInfo = i_getInitVarInfo()
stVarInfo = struct( ...
    'hVar',         [], ...
    'stInfo',       [], ...
    'astBlockInfo', [], ...
    'iPortNumber',  [], ...
    'aiOutIdx',     []);
end


%%
function astVars = i_getAllVars(stEnv, hSubsys)
ahVars  = i_getAllDispCandidates(stEnv, hSubsys);
nVars   = length(ahVars);
astVars = repmat(i_getInitVarInfo(), 1, nVars);
if ~isempty(astVars)    
    abSelect = true(1, nVars);
    for i = 1:nVars
        astVars(i).hVar = ahVars(i);
        astVars(i).astBlockInfo = atgcv_m01_variable_block_info_get(stEnv, ahVars(i));
        
        % remove vars without reference in the model --> cannot access these during MIL simulations
        if isempty(astVars(i).astBlockInfo)
            abSelect(i) = false;
        end
    end
    astVars = astVars(abSelect);
end
end


%%
function ahVars = i_getAllDispCandidates(stEnv, hSubsys)
ahRawVars = atgcv_m01_global_vars_get(stEnv, hSubsys, 'disp');

ahVars = [];
for i = 1:numel(ahRawVars)
    hRawVar = ahRawVars(i);
    
    ahVars = [ahVars, i_getSuitableDispComponents(hRawVar)]; %#ok<AGROW>
end
ahVars = unique(ahVars, 'stable'); % avoid double entries
end


%%
% look if the Variable has sub-components that are directly linked to the model
% if yes, return these sub-components instead of the root var
function ahSuitableVars = i_getSuitableDispComponents(hVar)
[bExist, hComponents] = dsdd('Exist', 'Components', 'Parent', hVar);
if bExist
    ahSubLinks = dsdd('Find', hComponents, 'Name', 'BlockVariableRefs');
    if ~isempty(ahSubLinks)
        ahSuitableVars = arrayfun(@(h) dsdd('GetAttribute', h, 'hDDParent'), ahSubLinks);
        
        abHasLowerElementsLinked = arrayfun(@i_hasSublinks, ahSuitableVars);
        ahSuitableVars = ahSuitableVars(~abHasLowerElementsLinked);
        return;
    end
end
ahSuitableVars = hVar; % as default case return the variable itself as suitable
end


%%
function bHasSubLinks = i_hasSublinks(hVar)
bHasSubLinks = false;

[bExist, hComponents] = dsdd('Exist', 'Components', 'Parent', hVar);
if bExist
    ahSubLinks = dsdd('Find', hComponents, 'Name', 'BlockVariableRefs');
    bHasSubLinks = ~isempty(ahSubLinks);
end
end


%%
function astVars = i_addVariableInfoAndMergeSameVars(stEnv, astVars)
if isempty(astVars)
    return;
end
jVarHash = java.util.HashMap();
abSelect = true(size(astVars));
nVars = length(astVars);
for i = 1:nVars
    astVars(i).stInfo = atgcv_m01_variable_info_get(stEnv, astVars(i).hVar);
    
    sKey = i_getKeyFromVarInfo(astVars(i).stInfo);
    iIdx = jVarHash.get(sKey);
    if isempty(iIdx)
        jVarHash.put(sKey, i);        
    else
        abSelect(i) = false;
        astVars(iIdx).astBlockInfo = i_addExtraBlockInfos(astVars(iIdx).astBlockInfo, astVars(i).astBlockInfo);
    end
end
astVars = astVars(abSelect);
end


%%
% get one scalar value from a structure that is unique for a variable
function sKey = i_getKeyFromVarInfo(stVarInfo)
sKey = [stVarInfo.sModuleName, '|', stVarInfo.sRootName, stVarInfo.sAccessPath];
end


%% 
% add new block info only if it is not already part of the existing block info
function astBlockInfo = i_addExtraBlockInfos(astBlockInfo, astAddBlockInfo)
jInfoSet = java.util.HashSet();
for i = 1:length(astBlockInfo)
    jInfoSet.add(astBlockInfo(i).sTlPath);
end
for i = 1:length(astAddBlockInfo)
    if ~jInfoSet.contains(astAddBlockInfo(i).sTlPath)
        astBlockInfo(end + 1) = astAddBlockInfo(i); %#ok<AGROW>
    end
end
end


%% 
% Add signal indexes of the corresponding block outputs. Ignore Stateflow variables.
function astVars = i_addOutportInfo(stEnv, astVars)
if isempty(astVars)
    return;
end

abIsValid = true(size(astVars));
for i = 1:length(astVars)
    try
        stBlockInfo = astVars(i).astBlockInfo(1);
                
        astVars(i).iPortNumber = i_getOutportNumber(stEnv, stBlockInfo.hBlockVar);
        if ~i_isVarStruct(astVars(i))
            if ~isempty(astVars(i).iPortNumber)
                astVars(i).aiOutIdx = i_getOutputIndex(stEnv, astVars(i).hVar, stBlockInfo.hBlock, astVars(i).iPortNumber);
            else
                % assume that elements of a local/DISP variable hava a 1:1 mapping between MIL and SIL
                aiWidth = astVars(i).stInfo.aiWidth;
                if isempty(aiWidth)
                    aiWidth = 1;
                end
                iAllWidth = prod(aiWidth);
                astVars(i).aiOutIdx = 1:iAllWidth;
            end
            if isempty(astVars(i).aiOutIdx)
                % note: happens for DISP variables inside "reusable"/"incremental" Subsystems
                abIsValid(i) = false;
            end
        end
    catch
        abIsValid(i) = false;
    end
end
astVars = astVars(abIsValid);
end


%%
function bIsStruct = i_isVarStruct(stVar)
bIsStruct = ~isempty(stVar.stInfo) && strcmpi(stVar.stInfo.stVarType.sBase, 'Struct');
end


%%
function astVars = i_removeUnsupportedVars(stEnv, astVars, hSubsys)
if isempty(astVars)
    return;
end

casForbiddenBlocks = i_getBlocksConnectedToMerge(stEnv, hSubsys);

nVars = length(astVars);
abSelect = true(1, nVars);
for i = 1:nVars
    astVars(i).astBlockInfo = i_filterOutModelReferences(astVars(i).astBlockInfo);
    
    % -- remove multiple use (mergeable) DISP
    if (length(astVars(i).astBlockInfo) > 1)
        bIsMultiple = true;
        astBlockInfo = i_filterAcceptedMultiLocations(stEnv, astVars(i).astBlockInfo, astVars(i).hVar);
        if (length(astBlockInfo) == 1)
            astVars(i).astBlockInfo = astBlockInfo;
            bIsMultiple = false;
        end
        
        if bIsMultiple
            sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astVars(i).hVar, 'Name');
            osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:VARCHECK_DISP_MULTIPLE_USE', ...
                'variable',  sVarName, ...
                'blocks',    i_getBlockRefsForDisplay(astBlockInfo));
            abSelect(i) = false;            
            continue;
        end
    end
    if ~i_hasSupportedUsage(astVars(i).astBlockInfo(1))
        abSelect(i) = false;
        continue;
    end
    
    % from now on assume we have only one block_info
    
    % -- remove display signals that are directly connected to Merge blocks
    sBlock = astVars(i).astBlockInfo(1).sTlPath;
    iPortNumber = i_getOutportNumber(stEnv, astVars(i).astBlockInfo(1).hBlockVar);
    if ~isempty(iPortNumber)
        sPort = sprintf('%i', iPortNumber);
        sBlockPath = i_getMappingName(sPort, sBlock);
    elseif ~isempty(astVars(i).astBlockInfo(1).stSfInfo)
        sSfVar = astVars(i).astBlockInfo(1).stSfInfo.sSfName;
        sBlockPath = i_getMappingName(sSfVar, sBlock);
    else
        abSelect(i) = false;
        continue
    end
    
    if any(strcmpi(sBlockPath, casForbiddenBlocks))
        sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astVars(i).hVar, 'Name');
        sTlPath = astVars(i).astBlockInfo(1).sTlPath;
        osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:LIMITATION_DISP_MERGE', 'variable',  sVarName, 'tlblock', sTlPath);
        abSelect(i) = false;   
        continue;
    end    
end
astVars = astVars(abSelect);
end


%%
function sDispBlocks = i_getBlockRefsForDisplay(astBlockInfo)
if isempty(astBlockInfo)
    sDispBlocks = '...';
else
    casDispBlocks = {astBlockInfo(:).sTlPath};
    casUniqueDispBlocks = unique(casDispBlocks, 'stable');
    if (numel(casUniqueDispBlocks) > 1)
        casDispBlocks = casUniqueDispBlocks;
    end
    sDispBlocks = sprintf('%s; ', casDispBlocks{:});
    sDispBlocks(end-1:end) = [];
end
end


%%
function astBlockInfo = i_filterOutModelReferences(astBlockInfo)
abIsModelRef = arrayfun(@(stBlockInfo) strcmpi(stBlockInfo.sBlockKind, 'ModelReference'), astBlockInfo);
astBlockInfo = astBlockInfo(~abIsModelRef);
end


%%
% -- can only handle
%  1) outputs
%  2) SF-locals
function bSuccess = i_hasSupportedUsage(stBlockInfo)
% take care of DataStoreMemory blocks: here the internal Usage is set to
% "output" even though the DD usage is "variable"
if strcmpi(stBlockInfo.sBlockType, 'DataStoreMemory')
    bSuccess = false;
    return;
end
bSuccess = strcmp(stBlockInfo.sBlockUsage, 'output');
if bSuccess
    return;
end
bIsSF = i_isSfLocalOrOutput(stBlockInfo);
if bIsSF
    bSuccess = i_hasSupportedUsageSF(stBlockInfo.stSfInfo);
end
end


%%
function bSuccess = i_hasSupportedUsageSF(stSfInfo)
bSuccess = isempty(stSfInfo.sSfRelPath); % note: currently nested SF data (with rel. path) are not supported!
end


%%
function iPort = i_getOutportNumber(stEnv, hBlockVar)    
iPort = [];
hDdParent = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
while strcmpi('BlockVariable', atgcv_mxx_dsdd(stEnv, 'GetAttribute', hDdParent, 'objectKind'))
    hBlockVar = hDdParent;
    hDdParent = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
end
sSrcRefName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'name'); 
if ~isempty(regexpi(sSrcRefName, '^output$', 'once'))
    iPort = 1;
    return;
end

if ~isempty(regexpi(sSrcRefName, '^output\(#\d+\)$', 'once'))
    iPort = str2double(regexprep(sSrcRefName, 'output\(#(\d+)\)', '$1'));
    return;
end
end


%%
function bIsSfLocalOrOutput = i_isSfLocalOrOutput(stBlockInfo)
bIsSfLocalOrOutput = ...
    strcmpi(stBlockInfo.sBlockKind, 'Stateflow') && any(strcmpi(stBlockInfo.stSfInfo.sSfScope, {'Output', 'Local'}));
end


%%
function aiOutIdx = i_getOutputIndex(stEnv, hVar, hBlock, iPortNumber)
astSignals = atgcv_m01_block_output_signals_memget(stEnv, hBlock, iPortNumber, true);

iStartIdx = 1;
aiOutIdx = i_findIndexRecur(stEnv, hVar, astSignals, iStartIdx);
end


%%
function [aiOutIdx, iStartIdx] = i_findIndexRecur(stEnv, hVar, astSignals, iStartIdx)
aiOutIdx = [];
for i = 1:length(astSignals)
    stSignal = astSignals(i);          
    if isempty(stSignal.astInstanceSigs)
        iWidth = stSignal.iWidth;
        if isempty(iWidth)
            iWidth = length(stSignal.stVarInfo.astProp);
        else
            iWidth = prod(iWidth); % TL4.0 -- MatrixSignal support
        end
        
        if (stSignal.hVariableRef == hVar)
            aiOutIdx = iStartIdx:(iStartIdx + iWidth - 1);
            return;
        end
        iStartIdx = iStartIdx + iWidth;
    else
        % UseCase can only happen for TL4.0 (<-- astInstanceSigs is used):
        % Check if we need to use only one Instance or all of them.
        iWidth = prod(stSignal.iWidth);        
        aiSubWidths = arrayfun(@(x) (prod(x.iWidth)), stSignal.astInstanceSigs);
        
        if (iWidth == sum(aiSubWidths))
            % use all of the Instance Sigs
            [aiOutIdx, iStartIdx] = i_findIndexRecur(stEnv, hVar, stSignal.astInstanceSigs, iStartIdx);
            
        elseif all(iWidth == aiSubWidths)
            % use only one of the InstanceSigs
            for k = 1:length(stSignal.astInstanceSigs)
                aiOutIdx = i_findIndexRecur(stEnv, hVar, stSignal.astInstanceSigs(k), iStartIdx);
                if ~isempty(aiOutIdx)
                    return;
                end               
            end
            iStartIdx = iStartIdx + iWidth;
            
        else
            % error case: we cannot determine which of the InstanceSigs to use
            error('ATGCV:MOD_AN:SIG_VAR_MAPPING_FAILED', ...
                'Cannot determine the Mapping between C-Variable "%s" and the Output of Block "%s".', ...
                dsdd('GetAttribute', hVar, 'Name'), ...
                dsdd_get_block_path(stSignal.hBlockVar));
        end
    end
end
end


%%
function casBlocks = i_getBlocksConnectedToMerge(stEnv, hSubsys)
hModelView = atgcv_mxx_dsdd(stEnv, 'Find', hSubsys, 'name', 'ModelView');
ahMerge = atgcv_mxx_dsdd(stEnv, ...
    'Find',       hModelView, ...
    'ObjectKind', 'Block', ...
    'Property',   {'name', 'BlockType', 'value', 'TL_Merge'});

casBlocks = {};
for i = 1:length(ahMerge)
    hModelBlock = get_param(dsdd_get_block_path(ahMerge(i)), 'handle');
    casBlocks = [casBlocks, i_getTlSourceBlocks(stEnv, hModelBlock)];     %#ok<AGROW>
end
casBlocks = unique(casBlocks);
end


%%
function casBlocks = i_getTlSourceBlocks(stEnv, hModelBlock)
casBlocks = {};

stPortHandles = get_param(hModelBlock, 'PortHandles');
for i = 1:length(stPortHandles.Inport)
    stDest = struct( ...
        'hBlock',   hModelBlock, ...
        'sPort',    sprintf('%i', i), ...
        'iSigIdx' , 1);
    
    % atgcv_m01_src_block_find is an "unsafe" function, therefore try ... catch
    try
        stSrc = atgcv_m01_src_block_find(stEnv, stDest);
    catch oEx
        % AH TODO: ignore for now, but maybe do something someday
        warning('ATGCV:MOD_ANA:INTERNAL_WARNING', 'Failed readout merge-connections: "%s".', oEx.message);
        continue;
    end
    
    % special case: if we find a Mux block, we search directly for source blocks of this Mux block
    if ~isempty(stSrc.ahInterBlocks)
        for j = 1:length(stSrc.ahInterBlocks)
            hInterBlock = stSrc.ahInterBlocks(j);
            if strcmpi(get_param(hInterBlock, 'BlockType'), 'Mux')
                casBlocks = [casBlocks, i_getTlSourceBlocks(stEnv, hInterBlock)]; %#ok<AGROW>
                
                % note: important to continue here to avoid multiple
                % searches of the same blocks (e.g. serial Mux blocks)
                continue;
            end
        end
    end
    
    if ~isempty(stSrc.hBlock)
        sBlockPath = getfullname(stSrc.hBlock);
        casBlocks{end + 1} = i_getMappingName(stSrc.sPort, sBlockPath); %#ok<AGROW>
    end
    for j = 1:length(stSrc.ahInterPorts)
        % TL-Port blocks have only one output port
        sPort = '1';
        sBlockPath = getfullname(stSrc.ahInterPorts(j));
        casBlocks{end + 1} = i_getMappingName(sPort, sBlockPath); %#ok<AGROW>
    end    
end
end


%%
function ahVars = i_getSrcVars(stEnv, hBlock)
ahSrc = atgcv_mxx_dsdd(stEnv, 'Find', hBlock, 'regexp', '^SourceSignal.*', 'property', {'name', 'BlockVariableRef'});
nSrc = length(ahSrc);
if (nSrc < 1)
    ahVars = [];
    return;
end

ahVars = zeros(1, nSrc);
for i = 1:nSrc
    if (atgcv_version_compare('TL3.5') >= 0)
        hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', ahSrc(i), 0);
    else
        hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', ahSrc(i));
    end
    if dsdd('Exist', hSrcBlockVar, 'property', {'name', 'VariableRef'})
        hVarRef = atgcv_mxx_dsdd(stEnv, 'GetVariableRef', hSrcBlockVar);
        if ~isempty(hVarRef)
            ahVars(i) = hVarRef;
        end
    end
    [hBlock, sBlockType] = i_getBlock(stEnv, hSrcBlockVar);
    if any(strcmpi(sBlockType, {'TL_Outport', 'TL_BusOutport'}))
        ahVars = [ahVars, i_getSrcVars(stEnv, hBlock)]; %#ok<AGROW>
    end
end
ahVars = ahVars(ahVars > 0);
end


%%
function [hBlock, sBlockType] = i_getBlock(stEnv, hBlockVar)
while strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind'), 'BlockVariable')
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
end
% kind should be Block here!
hBlock = hBlockVar;
sBlockType = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock);
end


%%
function astBlockInfo = i_filterAcceptedMultiLocations(stEnv, astBlockInfo, hVar)
casClasses = arrayfun(@(x) i_getBlockVarClassFromModel(stEnv, x, hVar), astBlockInfo, 'UniformOutput', false);

% remove all Blocks where the class is only implictly defined (== "default")
abImplictlyDefined = cellfun(@(x) strcmp(x, 'default'), casClasses);
if all(abImplictlyDefined)
    % Problem: --> all classes are implicitly defined --> give up and return
    return;
end
casClasses(abImplictlyDefined) = [];

% Special situation: if we have a block-usage with an unknown class (== ''), the variable can only be accepted
% as Local if we have a strong indicator that the veriable is a non-MERGEABLE DISP
% --> we need to find a class with the property DISP and
abIsEmpty = cellfun(@isempty, casClasses);
if all(abIsEmpty)
    return;
end

% if not all of the other classed are unknown (== ''), we can already filter out the blocks with the implicit class
astBlockInfo(abImplictlyDefined) = [];


% if we have no unknown classes at all, we can try to use shortcuts
bHasUnknowns = any(abIsEmpty);
if ~bHasUnknowns
    if (length(astBlockInfo) < 2)
        return;
    end
    
    % Try to filter out port blocks that are directly connected to other referenced blocks inside the list 
    %     --> if this filtering is successful, use the filtered list
    %     --> otherwise continue with the original list
    astFilteredBlockInfo = i_filterOutConnectedPorts(stEnv, astBlockInfo);
    if (length(astFilteredBlockInfo) == 1)
        astBlockInfo = astFilteredBlockInfo;
        return;
    end
end

% ALGO:
% if we still have multiple blocks, go deeper into checking the VariableClasses
%   1) check if any of the classes is MERGEABLE
%   1a) if yes --> do not accept the Variable (i.e. leave all locations as is)
%   1b) if no  --> goto 2)
%   2) ignore all ERASABLE classes; are there still DISP classes left?
%   2a) if yes --> use corresponding block if only one; else goto 3)
%   2b) if no  --> filter out blocks with non-DISP class and goto 3)
%   3) use the first left block (even though there may be more)
%
%   Note: special handling for MERGEABLE or "extern"
%            such a usage can be accepted iff
%           (1) there is no "unknown" class (== '') AND (2) there is just one such occurrence
abIsErasable  = false(size(astBlockInfo));
abIsDisp      = true(size(astBlockInfo));
bHaveEncounteredMergeable = false;
for i = 1:length(casClasses)
    sClass = casClasses{i};
    
    % assuming that we have just one class from here on --> get the info
    stInfo = i_getVarClassInfo(sClass);
    if isempty(stInfo)
        abIsErasable(i) = true;
        abIsDisp(i) = false;
    else
        if (stInfo.bIsMergeable || stInfo.bIsExtern)
            % MERGEABLE class found 
            % if we have "unknown" classes or if we have already encountered a MERGEABLE 
            %     --> give up and return without filtering
            if (bHasUnknowns || bHaveEncounteredMergeable)
                return;
            else
                bHaveEncounteredMergeable = true;
            end
        end
        
        abIsErasable(i) = stInfo.bIsErasable;
        abIsDisp(i) = stInfo.bIsDisp;
        
        % a non-DISP class that is not ERASABLE cannot be handled
        % --> give up and return
        if (~abIsDisp(i) && ~abIsErasable(i))
            return;
        end
    end
end

aiFindNonErase = find(~abIsErasable);
if isempty(aiFindNonErase)
    % Note: we have a problem if all known classes are ERASABLE but we still have unknown classes
    %       --> in this case, the unknown classes might be the relevant ones
    %       --> to be on the safe side, give up and return without filtering
    if bHasUnknowns
        return;
    end
    
    % all of the classes are ERASABLE (can be DISP or non-DISP)
    % --> use the first block with DISP class
    % --> if none found (should never happen) --> give up and return
    aiIdxDisp = find(abIsDisp);
    if ~isempty(aiIdxDisp)
        astBlockInfo = astBlockInfo(aiIdxDisp(1));
    end
    return;
end

if (length(unique(casClasses(aiFindNonErase))) > 1)
    % different classes that are non-ERASABLE (how can this happen?)
    % maybe a TL Bug --> give up and return
    return;
end

aiCandidateIdx = find(~abIsErasable & abIsDisp);
if isempty(aiCandidateIdx)
    % should never happen
    return;
end

% here we have one or multiple non-ERASABLE, DISP-Variables references
% --> TODO: what exactly does the multiple occurrence mean?? 
% --> anyway, for now just select the first one
iIdx = aiCandidateIdx(1);
astBlockInfo = astBlockInfo(iIdx);
end


%%
function astBlockInfo = i_filterOutConnectedPorts(stEnv, astBlockInfo)
nBlock = length(astBlockInfo);
ahBlockVars = [astBlockInfo(:).hBlockVar];
abSelect = true(size(astBlockInfo));
for i = 1:nBlock
    stBlockInfo = astBlockInfo(i);
    
    if ~any(strcmpi(stBlockInfo.sBlockKind, {'TL_Inport', 'TL_Outport', 'TL_BusInport', 'TL_BusOutport'}))
        continue;
    end
    
    ahSrcSigs = ...
        atgcv_mxx_dsdd(stEnv, 'Find', stBlockInfo.hBlock, 'RegExp', 'SourceSig.*', 'Property', 'BlockVariableRef');
    
    if ~isempty(ahSrcSigs)
        ahSrcBlockVars = arrayfun(@(x) (i_getBlockVarRef(stEnv, x)), ahSrcSigs);
        if ~isempty(intersect(ahSrcBlockVars, ahBlockVars))
            abSelect(i) = false;
        end
    end
end
astBlockInfo = astBlockInfo(abSelect);
end


%%
function hSrcBlockVar = i_getBlockVarRef(stEnv, hSrcSig)
if (atgcv_version_compare('TL3.5') >= 0)
    hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', hSrcSig, 0);
else
    hSrcBlockVar = atgcv_mxx_dsdd(stEnv, 'GetBlockVariableRef', hSrcSig);
end
end


%%
function stInfo = i_getVarClassInfo(sVarClassRef)
stInfo = [];
if isempty(sVarClassRef)
    return;
end
try
    [bExist, hVarClass] = dsdd('Exist', sVarClassRef, ...
        'Parent', dsdd('GetDefaultPath', 'VariableClass'), ...
        'ObjectKind', 'VariableClass');
    if bExist
        bIsDisp = strcmpi(dsdd('GetInfo', hVarClass), 'readonly');
        casOpt = dsdd('GetOptimization', hVarClass);
        bIsMergeable = any(strcmpi(casOpt, 'MERGEABLE'));
        bIsErasable  = any(strcmpi(casOpt, 'ERASABLE'));
        bIsExtern    = strcmpi(dsdd('GetStorage', hVarClass), 'extern');
        stInfo = struct( ...
            'bIsDisp',      bIsDisp, ...
            'bIsMergeable', bIsMergeable, ...
            'bIsErasable',  bIsErasable, ...
            'bIsExtern',    bIsExtern);
    end
catch
end
end


%%
function sClass = i_getClassFromVar(hVar)
sClass = '';
try
    hVarClass = dsdd('GetClass', hVar);
    sDDPath = dsdd('GetAttribute', hVarClass, 'path');
    sClass = regexprep(sDDPath, '^.+/VariableClasses/', '');
catch
end
end


%%
function sClass = i_getBlockVarClassFromModel(stEnv, stBlockInfo, hVar)
sClass = '';
if ~isempty(stBlockInfo.stSfInfo)
    sClass = i_getSfVarClass(stBlockInfo.stSfInfo.hSfVar);
else
    if strcmpi(stBlockInfo.sBlockUsage, 'output')
        if i_isAutosarPort(stBlockInfo.sTlPath)
            sClass = i_getClassFromVar(hVar);
        else
            sClass = i_getClassFromBlockOutport(stEnv, stBlockInfo);
        end
    elseif strcmpi(stBlockInfo.sBlockUsage, 'state')
        sClass = i_getClassFromBlockState(stBlockInfo);
    end
end
end


%%
function sClass = i_getClassFromBlockState(stBlockInfo)
sClass = '';

if strcmpi(stBlockInfo.sBlockType, 'UnitDelay')
    sClass = i_getUsageClass(stBlockInfo.sTlPath, 'state');
end
end


%%
function sClass = i_getClassFromBlockOutport(stEnv, stBlockInfo)
sClass = '';
iIdx = i_getOutputUsageIndex(stBlockInfo.hBlockVar);

if strcmpi(stBlockInfo.sBlockType, 'PreLookup')
    if (iIdx < 2)
        sBlockUsage = 'index';
    else
        sBlockUsage = 'fraction';
    end
    sClass = i_getUsageClass(stBlockInfo.sTlPath, sBlockUsage);
    if ~isempty(sClass)
        return;
    end
end
if i_isSomeKindOfFlipFlopBlock(stBlockInfo.sBlockKind)
    if (iIdx > 1)
        sBlockUsage = 'noutput';
        sClass = i_getUsageClass(stBlockInfo.sTlPath, sBlockUsage);
        if ~isempty(sClass)
            return;
        end
    end
end
casClasses = i_getBlockOutputVarClasses(stBlockInfo.sTlPath);
if (length(casClasses) > 1)
    % special case: BusSignal --> Idx must be re-computed
    if ~isempty(strfind(lower(stBlockInfo.sBlockKind), 'bus'))
        iIdx = i_findBusIndex(stEnv, stBlockInfo);
    end
end
if (~isempty(iIdx) && (iIdx <= length(casClasses)))
    sClass = casClasses{iIdx};
end
end


%%
function bIsFlipFlop = i_isSomeKindOfFlipFlopBlock(sBlockType)
bIsFlipFlop = any(strcmpi(sBlockType, { ...
    'TL_DLatch', ...
    'TL_SRFlipFlop', ...
    'TL_JKFlipFlop', ...
    'TL_DFlipFlop'}));
end


%%
function sClass = i_getSfVarClass(hSfVar)
sClass = '';
try
    [sClass, nErr] = tl_get(hSfVar.Id, 'class');
    if (nErr ~= 0)
        sClass = '';
    end
    % Note: for Inputs we have to check the 'createinputvariable' Flag
    %       --> if not set, the Class info is not valid and will be interpreted as "default"
    if strcmpi(hSfVar.scope, 'Input')
        [nFlag, nErr] = tl_get(hSfVar.Id, 'createinputvariable');
        if (nErr == 0) 
            if ~logical(nFlag)
                sClass = 'default';
            end
        end
    end
catch
end
end


%%
function iIdx = i_getOutputUsageIndex(hBlockVar)
iIdx = 1;

sDDPath = dsdd('GetAttribute', hBlockVar, 'path');
casFoundIdx = regexp(sDDPath, '/output\(#(\d+)\)$', 'tokens', 'once');
if ~isempty(casFoundIdx)
    iIdx = str2double(casFoundIdx{1});
end
end


%%
function iIdx = i_findBusIndex(stEnv, stBlockInfo)
iIdx = [];
if isempty(stBlockInfo.hBlock)
    return;
end
try
    astOutSigs = atgcv_m01_block_output_signals_get(stEnv, stBlockInfo.hBlock);
    if ~isempty(astOutSigs)
        iIdx = find(stBlockInfo.hBlockVar == [astOutSigs(:).hBlockVar]);
        if (length(iIdx) > 1)
            iIdx = iIdx(1);
        end
    end
catch
end
end


%%
function bIsAUTOSAR = i_isAutosarPort(sBlockPath)
bIsAUTOSAR = false;
try
    if verLessThan('tl', '5.2')
        [iFlag, nErr] = tl_get(sBlockPath, 'autosar.useautosarcommunication');
        if (nErr == 0)
            bIsAUTOSAR = logical(iFlag);
        end
    else
        bIsAUTOSAR = (tl_get(sBlockPath, 'autosarmode') > 1);
    end
catch
end
end


%%
function casClasses = i_getBlockOutputVarClasses(sBlockPath)
casClasses = {};
if ~ds_isa(sBlockPath, 'tlblock')
    return;
end
try
    [nOut, nErr] = tl_get(sBlockPath, 'numoutputs');
    if (nErr ~= 0)
        nOut = 1;
    end
    if (~isempty(nOut) && (nOut > 1))
        casClasses = arrayfun(@(x) i_getOutputClass(sBlockPath, x), 1:nOut, 'UniformOutput', false);
    else
        casClasses = {i_getOutputClass(sBlockPath)};
    end
catch
end
end


%%
function sClass = i_getOutputClass(sBlockPath, iIdx)
if ((nargin < 2) || (iIdx < 2))
    [sClass, nErr] = tl_get(sBlockPath, 'output.class');
else
    [sClass, nErr] = tl_get(sBlockPath, sprintf('output(%d).class', iIdx));
end
if (nErr ~= 0)
    sClass = '';
end
end


%%
function sClass = i_getUsageClass(sBlockPath, sBlockUsage)
[sClass, nErr] = tl_get(sBlockPath, [lower(sBlockUsage), '.class']);
if (nErr ~= 0)
    sClass = '';
end
end


%%
function sMappingName = i_getMappingName(sPrefix, sBlock)
sMappingName = [sPrefix, ';', sBlock];
end

