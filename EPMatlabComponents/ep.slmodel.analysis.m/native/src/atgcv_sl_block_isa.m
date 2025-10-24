function bSuccess = atgcv_sl_block_isa(xBlock, sType)
% Check type of specific Simulink block.
%
% function bSuccess = atgcv_sl_block_isa(xBlock, sType)
%
%   INPUT               DESCRIPTION
%     xBlock            (string|handle)   either full block path or handle
%                                         of Subsystem block
%     sType             (string)         'stateflow'
%
%   OUTPUT              DESCRIPTION
%     bSuccess          (boolean)         true if check was successful,
%                                         othwerwise false
%
%   REMARKS
%     1) Currently only checking for Stateflow Chart supported.
%     2) If block does not exist, function throws exception.
%


%% check inputs
hBlock = i_checkAndNormalizeBlock(xBlock);


%% main
switch lower(sType)
    case 'stateflow'
        bSuccess = i_checkStateflow(hBlock);
        
    otherwise
        error('ATGCV:USAGE_ERROR', 'Unknown check type "%s".', sType);
end
end






%%
function hBlock = i_checkAndNormalizeBlock(xBlock)
try
    hBlock = get_param(xBlock, 'handle');
catch
    if ischar(xBlock)
        error('ATGCV:ERROR', 'Provided block path "%s" seems to be invalid.', xBlock);
    else
        error('ATGCV:ERROR', 'Provided block handle seems to be invalid.');
    end
end
end


%%
function bSuccess = i_checkStateflow(hBlock)
hChart = find_system(hBlock, ...
    'FollowLinks',    'on', ...
    'SearchDepth',    0, ...
    'LookUnderMasks', 'all', ...
    'MaskType',       'Stateflow');
bSuccess = ~isempty(hChart);
end
