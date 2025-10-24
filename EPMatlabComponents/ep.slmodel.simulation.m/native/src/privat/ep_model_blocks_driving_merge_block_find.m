function astDrivingPortBlocks = ep_model_blocks_driving_merge_block_find(xModel)
% Inside the model include model references find all blocks driving Merge blocks.
%
% function astDrivingPortBlocks = ep_model_blocks_driving_merge_block_find(xModel)
%
%   INPUTS               DESCRIPTION
%     xModel             (handle/string)   handle/name of model to be analyzed
%
%   OUTPUT               DESCRIPTION
%     astDrivingPortBlocks    (cell)       info structs:
%         .sBlockPath         (string)        path of blocks driving a merge block
%         .iPortNum           (integer)       number of the block outport the driving signal is coming from
%


%%
if (nargin < 1)
    sModel = bdroot(gcs);
else
    sModel = bdroot(getfullname(xModel));
end

casMergeBlocks = i_getAllMergeBlocks(sModel);
astDrivingPortBlocks = i_getAllDrivingBlocks(casMergeBlocks);
end


%%
function casMergeBlocks = i_getAllMergeBlocks(sModel)
casMergeBlocks = {};

casModels = ep_find_mdlrefs(sModel);
for i = 1:numel(casModels)
    casModelMergeBlocks = ep_find_system(casModels{i}, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks',    'on', ...
        'BlockType',      'Merge');
    casMergeBlocks = horzcat(casMergeBlocks, reshape(casModelMergeBlocks, 1, [])); %#ok<AGROW>
end
end


%%
function astDrivingBlockPorts = i_getAllDrivingBlocks(casMergeBlocks)
astDrivingBlockPorts = [];

for i = 1:numel(casMergeBlocks)
    sMergeBlock = casMergeBlocks{i};
    
    stPortHandles = get_param(sMergeBlock, 'PortHandles');
    for k = 1:numel(stPortHandles.Inport)
        astPartialDrivingBlockPorts = i_getAllDrivingBlockPortsOfInport(stPortHandles.Inport(k));
        
        astDrivingBlockPorts = horzcat(astDrivingBlockPorts, reshape(astPartialDrivingBlockPorts, 1, [])); %#ok<AGROW>
    end
end
end


%%
function astDrivingBlockPorts = i_getAllDrivingBlockPortsOfInport(hInport)
[hSrcPort, ahSkippedSrcPorts] = ep_block_inport_backtrace(hInport);
astDrivingBlockPorts = arrayfun(@i_srcPortHandleToBlockPort, [ahSkippedSrcPorts, hSrcPort]);
end


%%
function stBlockPort = i_srcPortHandleToBlockPort(hSrcPort)
stBlockPort = struct( ...
    'sBlockPath', get_param(hSrcPort, 'Parent'), ...
    'iPortNum',   get_param(hSrcPort, 'PortNumber'));
end

