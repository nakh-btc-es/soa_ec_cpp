function stInfo = atgcv_m01_sfblock_variable_info_get(stEnv, varargin)
% get additional info for SF Chart variables
%
% two use cases:
%   1) via DD:   stInfo = atgcv_m01_sfblock_variable_info_get(stEnv, hBlockVar)
%   2) directly: stInfo = atgcv_m01_sfblock_variable_info_get(~, sChartPath, sVarName, sRelPath)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)      environment structure (not used for use case 2)
%
%     1) hBlockVar      (handle)      DD handle of variable (assumed to be part of Chart)
%
%     2) sChartPath     (string)      model path to chart
%     2) sVarName       (string)      name of the SF variable
%     2) sRelPath       (string)      optional: relative path in Chart (default = '')
%
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)     info data
%       .hSfVar          (string)     SF-handle as used in Chart (model)
%       .sSfName         (string)     name as used in Chart (model)
%       .sSfContext      (string)     ('in' | 'out' | 'var')
%       .sSfScope        (string)     Scope as defined in model
%                                     ('Input' | 'Output' | 'Local',
%                                      'Constant' | 'Data Store Memory', ...)
%       .iSfFirstIdx     (integer)    first index of variable
%       .sInitValue      (string)     Initial Value (migth be empty)
%


%% default output
stInfo = struct( ...
    'hSfBlock',      [], ...
    'hSfVar',        [], ...
    'sSfName',       '', ...
    'sSfAccess',     '', ...
    'sSfRelPath',    '', ...
    'sSfContext',    '', ...
    'sSfScope',      '', ...
    'iSfFirstIndex', [], ...
    'sInitValue',    '');


%% handle use cases 1 and 2
if (nargin < 3)
    hBlockVar = varargin{1};
    if ischar(hBlockVar)
        hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDObject');
    end

    % info only for BlockVariable
    sObjectKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind');
    if ~strcmpi(sObjectKind, 'BlockVariable')
        return;
    end
    
    stVar = i_getVariableInfo(stEnv, hBlockVar);
    if isempty(stVar.sName)
        return;
    end
    sChartPath = dsdd_get_block_path(hBlockVar);

else
    sChartPath = varargin{1};
    stVar = struct( ...
        'sName',    varargin{2}, ...
        'sAccess',  '', ...
        'sRelPath', '');
    
    if (numel(varargin) > 2)
        stVar.sRelPath = varargin{3};
    end
end

sVarPath = sChartPath;
if ~isempty(stVar.sRelPath)
    sVarPath = [sVarPath, '/', stVar.sRelPath];
end
stSfInfo = atgcv_m01_sf_data_info_get(sChartPath, {'Path', sVarPath, 'Name', stVar.sName});
if (numel(stSfInfo) == 1)
    sSfContext = i_getSfContext(stSfInfo.sScope);

    if ~isempty(stSfInfo)
        stInfo.hSfBlock = stSfInfo.hSfBlock;
        stInfo.hSfVar = stSfInfo.hSfData;
        stInfo.sSfName = stSfInfo.sName;
        stInfo.sSfAccess = stVar.sAccess;
        stInfo.sSfRelPath = stVar.sRelPath;
        stInfo.sSfContext = sSfContext;
        stInfo.sSfScope = stSfInfo.sScope;
        stInfo.iSfFirstIndex = stSfInfo.iFirstIndex;
        stInfo.sInitValue = stSfInfo.sInitValue;
    end
end
end


%%
function sSfContext = i_getSfContext(sSfScope)
sSfContext = '';
if isempty(sSfScope)
    return;
end
switch lower(sSfScope)
    case 'input'
        sSfContext = 'in';
        
    case 'output'
        sSfContext = 'out';
        
    otherwise
        sSfContext = 'var';
end
end


%%
function stVar = i_getVariableInfo(stEnv, hBlockVar)
hParentBlock = dsdd('GetAttribute', hBlockVar, 'hDDParent');
while ~isempty(hParentBlock)
    if strcmpi(dsdd('GetAttribute', hParentBlock, 'objectKind'), 'Block')
        break;
    end
    hParentBlock = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hParentBlock, 'hDDParent');
end
if isempty(hParentBlock)
    return;
end

sBlockType = dsdd('GetBlockType', hParentBlock);
if strcmpi(sBlockType, 'Stateflow')
    hSfNodes = atgcv_mxx_dsdd(stEnv, 'GetStateflowNodes', hParentBlock);
    stVar = i_getStateflowVariableInfo(stEnv, hSfNodes, hBlockVar);
else
    stVar = struct( ...
        'sName',    '', ...
        'sAccess',  '', ...
        'sRelPath', '');
end
end


%%
function stVar = i_getStateflowVariableInfo(stEnv, hSfNodes, hBlockVar)
stVar = struct( ...
    'sName',    '', ...
    'sAccess',  '', ...
    'sRelPath', '');

if (isempty(hSfNodes) || isempty(hBlockVar))
    return;
end

ahSfRefNodes = dsdd('Find', hSfNodes, 'Property', {'Value', hBlockVar});
if isempty(ahSfRefNodes)
    hMainBlockVar = i_tryToFindMainSfBlockVar(stEnv, dsdd('GetAttribute', hSfNodes, 'hDDParent'), hBlockVar);
    if ~isempty(hMainBlockVar)
        ahSfRefNodes = dsdd('Find', hSfNodes, 'Property', {'Value', hMainBlockVar});
        if ~isempty(ahSfRefNodes)
            stVar.sAccess = i_findAccessPathToOriginalBlockVar(hMainBlockVar, hBlockVar);
            if isempty(stVar.sAccess)
                return;
            end
            hBlockVar = hMainBlockVar;
        end
    end
end
hSfRefNode = i_getObjectWithShortestPath(ahSfRefNodes);
if isempty(hSfRefNode)
    return;
end

sObjRelPath = i_getDdRelPath(hSfNodes, hSfRefNode);
stVar.sRelPath = fileparts(sObjRelPath);

casVarNames = atgcv_mxx_dsdd(stEnv, 'GetPropertyNames', hSfRefNode);
for i = 1:length(casVarNames)
    hRefVar = dsdd('Get', hSfRefNode, casVarNames{i});
    if (hRefVar == hBlockVar)
        stVar.sName = casVarNames{i};
        break;
    end
end
end


%%
% Note: the original block variable is replaced by the main variable, which is some parent/root component of the same
% struct --> find the MIL access path from the main block variable to the block variable
function sAccess = i_findAccessPathToOriginalBlockVar(~, hBlockVar)
sAccess = '';

hParentVar = i_getParentOfComponent(hBlockVar);
while ~isempty(hParentVar)
    if dsdd('Exist', hBlockVar, 'Property', {'Name', 'SignalName'})
        sSignalName = dsdd('GetSignalName', hBlockVar);
    else
        sSignalName = 'signal1';
    end
    sAccess = ['.', sSignalName, sAccess]; %#ok<AGROW>
    
    hBlockVar = hParentVar;
    hParentVar = i_getParentOfComponent(hBlockVar);
end
end


%%
function hParentVar = i_getParentOfComponent(hBlockVar)
hParentVar = [];

hCandidateParentVar = dsdd('GetAttribute', hBlockVar, 'hDDParent');
bExist = dsdd('Exist', hCandidateParentVar, 'objectKind', 'BlockVariable');
if bExist
    hParentVar = hCandidateParentVar;
end
end


%%
function hMainBlockVar = i_tryToFindMainSfBlockVar(stEnv, hChartBlock, hBlockVar)
hMainBlockVar = [];
if ~i_isComponentBlockVar(hBlockVar)
    return;
end
stStateflow = atgcv_m01_sfblock_blockvars_get(stEnv, hChartBlock);
switch i_getSfContextFromBlockVar(hChartBlock, hBlockVar)
    case 'in'
        hMainBlockVar = i_findSameVarReference(stEnv, hBlockVar, stStateflow.stInputs);
        
    case 'out'
        hMainBlockVar = i_findSameVarReference(stEnv, hBlockVar, stStateflow.stOutputs);
        
    case 'var'
        hMainBlockVar = i_findSameVarReference(stEnv, hBlockVar, stStateflow.stBlockVars);
        
    otherwise
        error('MOD_ANA:INTERNAL:ERROR', 'Unknown SF context.');
end
end


%%
function hMainBlockVar = i_findSameVarReference(stEnv, hBlockVar, stBlockVars)
hMainBlockVar = [];
sVarRefPath = i_getVariableRefPath(stEnv, hBlockVar);
if isempty(sVarRefPath)
    return;
end

casCandidateBlockVars = fieldnames(stBlockVars);
for i = 1:numel(casCandidateBlockVars)
    hCandidateBlockVar = stBlockVars.(casCandidateBlockVars{i});
    
    sCandidateVarRefPath = i_getVariableRefPath(stEnv, hCandidateBlockVar);
    if i_startsWith(sVarRefPath, sCandidateVarRefPath)
        hMainBlockVar = hCandidateBlockVar;
        return;
    end
end
end

%%
function sVarPath = i_getVariableRefPath(stEnv, hBlockVar)
sVarPath = '';
if dsdd('Exist', hBlockVar, 'Property', 'VariableRef')
    hVariableRef = atgcv_mxx_dsdd(stEnv, 'GetVariableRefTarget', hBlockVar);
    if ~isempty(hVariableRef)
        sVarPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVariableRef, 'path');
    end
end
end


%%
function bStartsWith = i_startsWith(sString, sPrefix)
sPattern = ['^', regexptranslate('escape', sPrefix)];
bStartsWith = i_isMatching(sString, sPattern);
end


%%
function sSfContext = i_getSfContextFromBlockVar(hChartBlock, hBlockVar)
sRelPath = i_getDdRelPath(hChartBlock, hBlockVar);

if i_isMatching(sRelPath, '^input$|^input\W+')
    sSfContext = 'in';
    
elseif i_isMatching(sRelPath, '^output$|^output\W+')
    sSfContext = 'out';
    
else
    sSfContext = 'var';
end
end


%%
function bIsMatching = i_isMatching(sString, sPattern)
bIsMatching = ~isempty(regexp(sString, sPattern, 'once'));
end


%%
function hRootVar = i_getRootVar(stEnv, hVar)
sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
sRootPath = regexprep(sPath, '(.*Variables/.*?)(/Components.*)', '$1');
hRootVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', sRootPath, 'hDDObject');
end


%%
% the BlockVariable is a component variable if its parent is also a BlockVariable
function bIsComponentBlockVar = i_isComponentBlockVar(hBlockVar)
hParent = dsdd('GetAttribute', hBlockVar, 'hDDParent');
bIsComponentBlockVar = strcmpi('BlockVariable', dsdd('GetAttribute', hParent, 'ObjectKind'));
end


%%
function hObj = i_getObjectWithShortestPath(ahObjects)
if ~isempty(ahObjects)
    ahLens = arrayfun(@i_getPathLen, ahObjects);
    [~, iMinIdx] = min(ahLens);
    hObj = ahObjects(iMinIdx);
    
else
    hObj = [];
end
end


%%
function iLen = i_getPathLen(hObj)
iLen = length(dsdd('GetAttribute', hObj, 'Path'));
end


%%
% returns the relative path between the root and the provided DD object
% special cases:
% 1) hRoot == hObject --> relPath == ''
% 2) hRoot is no ancestor of hObject --> relPath is the full path 
function sRelPath = i_getDdRelPath(hRoot, hObject)
if (hRoot == hObject)
    sRelPath = '';
else
    sRootPath = dsdd('GetAttribute', hRoot, 'Path');    
    sObjectPath = dsdd('GetAttribute', hObject, 'Path');
    
    sPrefixRegExp = ['^', regexptranslate('escape', [sRootPath, '/'])];
    sRelPath = regexprep(sObjectPath, sPrefixRegExp, '');
end
end

