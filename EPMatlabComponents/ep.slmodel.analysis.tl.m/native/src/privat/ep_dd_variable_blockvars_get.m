function ahBlockVars = ep_dd_variable_blockvars_get(xVar, bDoFilterOutNonTL, bHandleStructRecursively)
% Get all BlockVariables references of the provided Variable.
%
%  function ahBlockVars = ep_dd_variable_blockvars_get(xVar, bDoFilterOutNonTL, bHandleStructRecursively)
%
%   INPUT           DESCRIPTION
%     xVar                     (handle/path) DD handle (or DD path to) of Variable
%     bDoFilterOutNonTL        (bool)        if true, do not return BlockVariables contained inside pure SL blocks, 
%                                            that are not relevant for TL code generation (default == true)
%     bHandleStructRecursively (bool)        if true, struct variables are handled by also following the refrences of
%                                            the child components (default == false) 
%
%   OUTPUT          DESCRIPTION
%     ahBlockVars       (handles)     all BlockVariables referenced by the provided Variable
%
%


%%
if (nargin < 2)
    bDoFilterOutNonTL = true;
end
if (nargin < 3)
    bHandleStructRecursively = false;
end

ahBlockVars = [];
hVar = ep_dd_variable_normalize(xVar);
if isempty(hVar)
    return;
end

ahBlockVars = i_getBlockVars(hVar, bDoFilterOutNonTL);
if (isempty(ahBlockVars) && bHandleStructRecursively)
    [bIsStruct, hComp] = dsdd('Exist', 'Components', 'Parent', hVar);
    if bIsStruct
        ahFieldVars = dsdd('GetChildren', hComp);
        for i = 1:numel(ahFieldVars)
            hFieldVar = ahFieldVars(i);
            
            ahFieldBlockVars = ep_dd_variable_blockvars_get(hFieldVar, bDoFilterOutNonTL, bHandleStructRecursively);
            ahBlockVars = [ahBlockVars, reshape(ahFieldBlockVars, 1, [])]; %#ok<AGROW>
        end
    end
end
end


function ahBlockVars = i_getBlockVars(hVar, bDoFilterOutNonTL)
ahBlockVars = i_getDdBlockVars(hVar);
if ~isempty(ahBlockVars)
    abIdxSelect = false(size(ahBlockVars));
    for i = 1:numel(ahBlockVars)
        [sPath, bIsValid] = i_getValidBlockPath(ahBlockVars(i));
        
        abIdxSelect(i) = bIsValid && (~bDoFilterOutNonTL || i_hasRelevanceForTL(sPath));
    end
    ahBlockVars = ahBlockVars(abIdxSelect);
end
end


%%
% Note: Info is provided by "ds_isa" except for SF Charts, which are nevertheless relevant for TL code generation.
function bHasRelevance = i_hasRelevanceForTL(sModelPath)
bHasRelevance = ds_isa(sModelPath, 'tlblock') || atgcv_sl_block_isa(sModelPath, 'Stateflow');
end


%%
% Returns the model path of the DD block variable and checks if it is valid.
%
%  Note1: the model path is "valid for this use case" if
%     A) not accepted by the SL API (get_param)
%     B) a model path (has no parent SL object)
%
%  Note2: Criterion B) is needed because starting with TL44p1 dsdd_get_block_path will return the model name
%  for the SF-Machine block, which is a block_diagram.
%
function [sPath, bIsValid] = i_getValidBlockPath(hBlockVariable)
sPath = dsdd_get_block_path(hBlockVariable);
bIsValid = false;

% SrcSignals are not valid in our context
% Note: in DD the paths look like ".../x/y/SourceSignal" or with an optional renaming index ".../x/y/SourceSignal(#666)"
sPathDD = dsdd('GetAttribute', hBlockVariable, 'path');
if ~isempty(regexpi(sPathDD, '/SourceSignal(\(#\d+\))?$', 'once'))
    return;
end

try    
    if ~isempty(get_param(sPath, 'Parent'))
        bIsValid = true;
    end
catch
    % nothing to do
end
end


%%
function ahBlockVars = i_getDdBlockVars(hVar)
ahBlockVars = [];

% TODO: for now introducing nLevel to check for the access hierarchy level; for nLevel > 0 we would need to introduce
% some kind of AccessPath that needs to be handled --> currently not possible --> Limitation
[hVarWithBlockRef, nLevel] = i_findVariableWithBlockAccess(hVar);
if (~isempty(hVarWithBlockRef) && nLevel == 0)
    ahBlockVars = dsdd('GetBlockVariables', hVarWithBlockRef);
end
end


%%
function [hVarWithBlockRef, nLevel] = i_findVariableWithBlockAccess(hVar)
hVarWithBlockRef = [];
nLevel = -1;

while ~isempty(hVar)
    nLevel = nLevel + 1;
    
    if dsdd('Exist', 'BlockVariableRefs', 'Parent', hVar)
        hVarWithBlockRef = hVar;
        return;
    end
    
    hVar = i_getParentVarOfVar(hVar);
end
end


%%
% for accessing the next highests parent node for struct variables
function hParentVar = i_getParentVarOfVar(hVar)
hParentVar = [];
sPath = dsdd('GetAttribute', hVar, 'path');
if ~isempty(regexp(sPath, '/Components\W+', 'once'))
    hParentVar = dsdd('GetAttribute', dsdd('GetAttribute', hVar, 'hDDParent'), 'hDDParent');
end
end
