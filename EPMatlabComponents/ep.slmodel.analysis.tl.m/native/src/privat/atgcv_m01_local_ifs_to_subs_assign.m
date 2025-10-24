function stModel = atgcv_m01_local_ifs_to_subs_assign(stModel, astAllSubs, bDoRemap)
% Add links between subsystems and local interfaces (CAL, DISP, DSM).
if (nargin < 2)
    astAllSubs = [];
end
if (nargin < 3)
    bDoRemap = true;
end


bWithCal  = ~isempty(stModel.astCalVars);
bWithDisp = ~isempty(stModel.astDispVars);
bWithDsm  = ~isempty(stModel.astDsmVars);

if (bDoRemap && any([bWithCal, bWithDisp, bWithDsm]))
    if ~isempty(astAllSubs)
        astPreparedSubs = struct( ...
            'sModelPath', {astAllSubs(:).sPath}, ...
            'sTlPath',    {astAllSubs(:).sVirtualPath});
        astModelRefMap = i_getModelRefMap(astPreparedSubs);
    else
        astModelRefMap = i_getModelRefMap(stModel.astSubsystems);
    end
    if ~isempty(astModelRefMap)
        stModel.astCalVars  = i_remapVarsForModelRefs(stModel.astCalVars, astModelRefMap);
        stModel.astDispVars = i_remapVarsForModelRefs(stModel.astDispVars, astModelRefMap);
        stModel.astDsmVars  = i_remapVarsForModelRefs(stModel.astDsmVars, astModelRefMap);
    end
end

nSub = length(stModel.astSubsystems);
for i = 1:nSub
    if bWithCal
        stModel.astSubsystems(i).astCalRefs = ...
            i_getVarRefs(stModel.astSubsystems(i).sTlPath, stModel.astCalVars);
    else
        stModel.astSubsystems(i).astCalRefs = [];
    end
    if bWithDisp
        abSelectable = i_checkDispPorts(stModel.astSubsystems(i).sTlPath, stModel.astDispVars);
        stModel.astSubsystems(i).astDispRefs = ...
            i_getVarRefs(stModel.astSubsystems(i).sTlPath, stModel.astDispVars, abSelectable);
    else
        stModel.astSubsystems(i).astDispRefs = [];
    end
    if bWithDsm
        stModel.astSubsystems(i).astDsmRefs = i_getVarRefs(stModel.astSubsystems(i).sTlPath, stModel.astDsmVars);
    else
        stModel.astSubsystems(i).astDsmRefs = [];
    end
    stModel.astSubsystems(i).astDsmReaderRefs = [];
    stModel.astSubsystems(i).astDsmWriterRefs = [];
end
end


%%
function astMap = i_getModelRefMap(astSubsystems)
astMap = struct( ...
    'sSourcePath', {astSubsystems(:).sModelPath}, ...
    'sTargetPath', {astSubsystems(:).sTlPath});

% sort the map lexicographically on ModelPath (== SourcePath)
% needed for sorting out paths that have other paths as prefix
[casNotNeeded, aiSortIdx] = sort({astMap(:).sSourcePath}); %#ok cell not needed
astMap = astMap(aiSortIdx);

sPreviousPath = '';
abSelect = false(size(astMap));
for i = 1:length(astSubsystems)
    % the only relevant case for map: source deviates from target path
    if ~strcmp(astMap(i).sSourcePath, astMap(i).sTargetPath)
        
        % do not consider a path that has the previously selected path as prefix
        if (isempty(sPreviousPath) || ~i_isPrefix(astMap(i).sSourcePath, [sPreviousPath, '/']))
            abSelect(i) = true;
            sPreviousPath = astMap(i).sSourcePath;
        end
    end
end
astMap = astMap(abSelect);
end


%%
function bIsPrefix = i_isPrefix(sString, sPrefix)
nPrefixLen = length(sPrefix);
bIsPrefix = (nPrefixLen <= length(sString)) && strncmp(sString, sPrefix, nPrefixLen);
end


%%
function astVars = i_remapVarsForModelRefs(astVars, astMap)
casSourcePaths = {astMap(:).sSourcePath};

% Patterns for RegExp: try to match at beginning of path and include as last
% character a separator '/'
casPatterns = cell(size(casSourcePaths));
for i = 1:length(casPatterns)
    casPatterns{i} = ['^', regexptranslate('escape', casSourcePaths{i}), '/'];
end

for i = 1:length(astVars)
    nKnownBlocks = length(astVars(i).astBlockInfo);
    for j = 1:nKnownBlocks
        sTlPath = astVars(i).astBlockInfo(j).sTlPath;
        astVars(i).astBlockInfo(j).sModelPath = sTlPath;
        
        % match path against all Patterns at once
        ciFound = regexp(sTlPath, casPatterns, 'end', 'once');
        
        % get the index of the first non-empty match
        aiIdx = find(~cellfun(@isempty, ciFound));
        
        nTargetPaths = numel(aiIdx);
        casTargetPaths = cell(1, nTargetPaths);
        for k = 1:nTargetPaths
            iTargetIdx = aiIdx(k);
            iFirstCharAfterSource = ciFound{iTargetIdx};
            sTargetPath = astMap(iTargetIdx).sTargetPath;
            
            casTargetPaths{k} = [sTargetPath, sTlPath(iFirstCharAfterSource:end)];            
        end
        
        if ~isempty(casTargetPaths)
            astVars(i).astBlockInfo(j).sTlPath = casTargetPaths{1};
            for k = 2:nTargetPaths
                % if one model path maps to multiple target paths, we need to duplicate the block info
                stDuplicateBlockInfo = astVars(i).astBlockInfo(j);
                stDuplicateBlockInfo.sTlPath = casTargetPaths{k};
                
                astVars(i).astBlockInfo(end + 1) = stDuplicateBlockInfo;
            end
        end
    end
end
end


%%
function astVarRefs = i_getVarRefs(sSubPath, astVars, abSelectable)
sRootPath = [sSubPath, '/'];
nRootPath = length(sRootPath);

if (nargin < 3)
    % per default all vars are selectable
    abSelectable = true(size(astVars));
end

nVars = length(astVars);
astVarRefs = repmat( struct( ...
    'iVarIdx',    0, ...
    'aiBlockIdx', []), nVars, 1);
for i = 1:nVars
    if ~abSelectable(i)
        continue;
    end
    
    casBlockPaths = {astVars(i).astBlockInfo(:).sTlPath};
    abStartsWithRootPath = (strcmpi(sSubPath, casBlockPaths) | strncmpi(sRootPath, casBlockPaths, nRootPath));
    if any(abStartsWithRootPath)
        astVarRefs(i).iVarIdx = i;
        astVarRefs(i).aiBlockIdx = find(abStartsWithRootPath);
    end
end

% select only the indices of the real references
astVarRefs = astVarRefs([astVarRefs(:).iVarIdx] > 0);
end


%%
function abSelect = i_checkDispPorts(sSubPath, astDisp)
nSubPath = length(sSubPath);

abSelect = true(size(astDisp));
for i = 1:length(astDisp)
    % DO NOT select any DISP if used in multiple blocks (efficiently a MERGEABLE DISP)
    if (numel(astDisp(i).astBlockInfo) > 1)
        abSelect(i) = false;
        continue;
    end
    
    % assumption only one block_info per DISP (i.e. no mergeable-DISP)
    stBlockInfo = astDisp(i).astBlockInfo(1);
    
    % do not select DISP Block if identical to corresponding Subsystem
    if strcmpi(stBlockInfo.sTlPath, sSubPath)
        sUsage = stBlockInfo.sBlockUsage;
        if (isempty(sUsage) || any(strcmpi(sUsage, {'output', 'sf_output'})))
            abSelect(i) = false;
            continue;
        end
    end
    
    if any(strcmpi(stBlockInfo.sBlockKind, {'TL_Outport', 'TL_BusOutport'}))        
        % Idea: Outports are only permitted if they are nested deeper within a child of the subsystem
        %       --> check for an additional path seperator in the relative path
        
        % avoid problems with escaped slashes "//" --> they are not counted as path separators
        sRelPath = strrep(stBlockInfo.sTlPath(nSubPath+2:end), '//', 'xx');
        abSelect(i) = any(sRelPath == '/');
    end
end
end


