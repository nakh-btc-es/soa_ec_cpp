function oSfBlock = atgcv_m01_sf_block_object_get(xSfBlock)
% If existing, returns the SF object to the provided SF block's model path.
%
% function oSfBlock = atgcv_m01_sf_block_object_get(xSfBlock)
%
%   INPUT               DESCRIPTION
%     xSfBlock            (string|handle)  model path to an SF block or block handle
%
%   OUTPUT              DESCRIPTION
%     oSfBlock            (handle)         SF object for SF block (might be empty if not found)
%


%%
oSfBlock = [];
if (nargin < 1)
    xSfBlock = gcbh;
end
if isempty(xSfBlock)
    return;
end

oSfBlock = i_getSfBlockObject(xSfBlock);
end


%%
function sReferenceBlock = i_getReferenceBlock(sBlock)
sReferenceBlock = i_getParamRobust(sBlock, 'ReferenceBlock');
end


%%
function bIsBlock = i_isBlock(sModelPath)
bIsBlock = ~isempty(i_getParamRobust(sModelPath, 'Parent'));
end


%%
% xBlock -- model path string or model block handle
function xParamVal = i_getParamRobust(xBlock, sParamName)
xParamVal = [];
try %#ok<TRYNC>
    xParamVal = get_param(xBlock, sParamName);
end
end


%%
function oSfBlock = i_getSfBlockObject(xBlock)
oSfBlock = [];
if i_isBlock(xBlock)
    sRefBlock = i_getReferenceBlock(xBlock);
    if ~isempty(sRefBlock)
        xBlock = sRefBlock;
    end
    oSfParentSub = i_getParamRobust(xBlock, 'Object');
    if ~isempty(oSfParentSub)
        oSfBlock = oSfParentSub.find( ...
            '-property', 'Id', ...
            '-property', 'Machine', ...
            '-depth', 1);
        
        % note: ensure valid data -- libs can have multiple SF-sub-entities in an "intermediate state"
        if (numel(oSfBlock) ~= 1)
            oSfBlock = [];
        end
    end
end
end

