function astBlockInfo = atgcv_m01_variable_block_info_get(stEnv, hVar, bWithParamInfo)
% Get info about the corresponding block(s) of the variable.
%
% function astBlockInfo = atgcv_m01_variable_block_info_get(stEnv, hVar, bWithParamInfo)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)    error messenger environment
%     hVar              (handle)    DD handle of variable
%     bWithParamInfo    (bool)      optional: read out also Parameter properties (sParamValue, sRestriction)
%                                   (default ==> false)
%   
%   OUTPUT              DESCRIPTION
%     astBlockInfo       (array)    structs with following data
%        .hBlockVar      (handle)   DD handle of BlockVariable
%        .sSignalName    (string)   signal name for block (if any)
%        .hBlock         (handle)   handle of corresponding block
%        .sTlPath        (string)   TL model path to block
%        .sBlockKind     (string)   TL block kind (often == MaskType)
%        .sBlockType     (string)   SL block type
%        .sBlockUsage    (string)   usage of variable inside the block
%        .stSfInfo       (struct)   struct with additional Stateflow info ---> atgcv_m01_sfblock_info_get
%                                   (non-empty only for sBlockKind=="Stateflow")
%        .sParamValue    (string)   Matlab value inside the Block mask
%                                   (empty if bWithParamInfo==false OR if not available/set)
%        .sRestriction   (string)   restriction ID for block variable
%                                   (empty if bWithParamInfo==false OR if not restricted)
%


%% optional inputs
if (nargin < 3)
    bWithParamInfo = false;
end

%% get all block_variable references in model
bDoFilterOutNonTL = true;
bHandleStructRecursively = false;
ahBlockVars = ep_dd_variable_blockvars_get(hVar, bDoFilterOutNonTL, bHandleStructRecursively);
nSrc = length(ahBlockVars);
if (nSrc < 1)
    astBlockInfo = [];
else
    astBlockInfo = arrayfun(@(x) atgcv_m01_block_variable_info_get(stEnv, x, bWithParamInfo), ahBlockVars);
    
    % EP-2696:
    % for Stateflow we sometimes get incomplete information about block variables (seems like a bug in TL)
    % Pattern: two block variables from the same SF-Chart block -- one is valid the other invalid
    % --> in this case, try to filter out the invalid info and keep the valid one
    %
    if (numel(astBlockInfo) > 1)
        abIsBlockInfoValid = arrayfun(@i_isBlockInfoValid, astBlockInfo);
        if ~all(abIsBlockInfoValid)
            ahPotentialReplacementBlocks = [astBlockInfo(abIsBlockInfoValid).hBlock];
            
            for i = 1:numel(astBlockInfo)
                if ~abIsBlockInfoValid(i)
                    bHasReplacementBlock = any(astBlockInfo(i).hBlock == ahPotentialReplacementBlocks);
                    if ~bHasReplacementBlock
                        return;
                    end
                end
            end
            astBlockInfo = astBlockInfo(abIsBlockInfoValid);
        end
    end
end
end


%%
function bIsValid = i_isBlockInfoValid(stBlockInfo)
if strcmp(stBlockInfo.sBlockKind, 'Stateflow')
    bIsValid = ~isempty(stBlockInfo.sBlockUsage);
else
    bIsValid = true;
end
end




