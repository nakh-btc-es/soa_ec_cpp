function casOriginSrcRefs = atgcv_m01_origin_srcref_get(stEnv, xDdVar, bIncludeSl)
% get origin src_ref of variable from (possibly) multiple source_refs in model
%
%  function casOriginSrcRefs = atgcv_m01_origin_srcref_get(stEnv, xDdVar, bIncludeSl)
%
%   INPUT           DESCRIPTION
%     stEnv            (struct)        environment structure
%     xDdVar           (handle|string) DD handle (or DD path to) to variable
%     bIncludeSl       (bool)          if true, include also pure SL blocks as
%                                      origins (default is "false")
%
%   OUTPUT          DESCRIPTION
%     casOriginSrcRefs (cell)    strings describing the origin(s) of the
%                                references in the model
%
%   REMARKS
%      !! internal function: no input checks !!
%
%   Specifally designed for the use case that a variable has multiple
%   SrcRefs in Model:
%      a) TL-function 'dsdd_block_path_get' is inadequate because
%         it returns the block_path of the first SrcRef found
%      b) this function returns the block_path of the SrcRef that is the origin
%         of the variable
%      c) in case there are more than one origin: multiple SrcRefs are returned
%


%% input check
if (nargin < 3)
    bIncludeSl = false;
end


%% main
% init value
casOriginSrcRefs = {};

% check existence and get handle for var
hVar = i_getVar(stEnv, xDdVar);
if isempty(hVar)
    return;
end

% get associated blocks in model
if dsdd('Exist', hVar, 'Property', {'Name', 'SrcRefs'})
    casSrcRefs = atgcv_mxx_dsdd(stEnv, 'GetSrcRefs', hVar);
else
    casSrcRefs = i_getDdBlockVars(stEnv, hVar);
end

% if we have no src_refs we cannot get the origin
if isempty(casSrcRefs)
    return;
end

% somethimes we get the same string over and over
% so reduce the set to unique items
casSrcRefs = unique(casSrcRefs);


% use only the sources of kind "BlockVariable" and fiter out "SourceSignals"
ahSrcRefObj = zeros(size(casSrcRefs));
abIdxSelect = false(size(casSrcRefs));
for i = 1:length(casSrcRefs)
    [bExist, hSrcRefObj] = dsdd('Exist', casSrcRefs{i});
    if bExist
        sPath = casSrcRefs{i};
        
        % 1) SrcSignals do not count
        if ~isempty(regexpi(sPath, 'SourceSignal$', 'once')) || ...
                ~isempty(regexpi(sPath, 'SourceSignal\(#\d+\)$', 'once'))
            continue;
        end
        
        % 2) has to be BlockVar
        sKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hSrcRefObj, 'objectKind');
        if strcmpi(sKind, 'BlockVariable')
            ahSrcRefObj(i) = hSrcRefObj;
            abIdxSelect(i) = true;
        end
    end
end
ahSrcRefObj = ahSrcRefObj(abIdxSelect);
casSrcRefs  = casSrcRefs(abIdxSelect);

nSrc = length(ahSrcRefObj);
if (nSrc < 1)
    % if no source found in model, return empty path
    return;
    
else
    if bIncludeSl
        abIdxSelect = true(size(ahSrcRefObj));
    else
        abIdxSelect = false(size(ahSrcRefObj));
        for i = 1:nSrc
            % exclude pure Simulink blocks (TODO maybe a better algo here)
            sPath = dsdd_get_block_path(ahSrcRefObj(i));
            % If the BlockType is e.g. StateflowMachine, then the returned
            % path will not correspond to a block in the model and has to
            % be excluded
            if i_isBlockPathValid(sPath)
                bIsTl = ds_isa(sPath, 'tlblock');
                if bIsTl
                    abIdxSelect(i) = true;
                else
                    % check for Statflow block
                    abIdxSelect(i) = atgcv_sl_block_isa(sPath, 'Stateflow');
                end
            end
        end
    end
    casOriginSrcRefs = casSrcRefs(abIdxSelect);
end
end


%%
function bIsValid = i_isBlockPathValid(sPath)
bIsValid = false;
try    
    % Starting with TL44p1 dsdd_get_block_path will return the model name
    % for the SF-Machine block, which is a block_diagram
    if ~isempty(get_param(sPath, 'Parent'))
        bIsValid = true;
    end
catch
    % nothing to do
end
end


%%
function hVar = i_getVar(stEnv, xDdVar)
[bExist, hVar] = dsdd('Exist', xDdVar);
if ~bExist
    hVar = [];
    return;
end

% for interface_vars get handle of corresponding var
sObjectKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'objectKind');
if strcmpi(sObjectKind, 'InterfaceVariable')
    hVar = i_getVariableOfInterface(stEnv, hVar);
end
end


%%
function hVar = i_getVariableOfInterface(stEnv, hInterfaceVar)

% Variable is non-optional but can be empty
hVar = atgcv_mxx_dsdd(stEnv, 'GetVariable', hInterfaceVar);

% if Variable is empty, try to get it through BlockVariable
if isempty(hVar) && dsdd('Exist', hInterfaceVar, 'Property', 'BlockVariable')
    hBlockVar = atgcv_mxx_dsdd('GetBlockVariable', hInterfaceVar);
    if dsdd('Exist', hBlockVar, 'Property', 'VariableRef')
        hVar = atgcv_mxx_dsdd('GetVariableRef', hBlockVar);
    end
end

% if Variable is still empty, use the original interface_var
if isempty(hVar)
    hVar = hInterfaceVar;
end
end


%%
function casSrcRefs = i_getDdBlockVars(stEnv, hVar)
casSrcRefs = {};

% TODO: for now introducing nLevel to check for the access hierarchy level; for nLevel > 0 we would need to introduce
% some kind of AccessPath that needs to be handled --> currently not possible --> Limitation
[hVarWithBlockRef, nLevel] = i_findVariableWithBlockAccess(hVar);
if (~isempty(hVarWithBlockRef) && nLevel == 0)
    ahBlockVars = atgcv_mxx_dsdd(stEnv, 'GetBlockVariables', hVarWithBlockRef);
    
    nBlockVars = numel(ahBlockVars);
    casSrcRefs = cell(1, nBlockVars);
    for i = 1:nBlockVars
        casSrcRefs{i} = atgcv_mxx_dsdd(stEnv, 'GetAttribute', ahBlockVars(i), 'Path');
    end
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
