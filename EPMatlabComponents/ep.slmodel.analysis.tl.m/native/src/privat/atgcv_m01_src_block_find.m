function stSrc = atgcv_m01_src_block_find(stEnv, stDest)
% get all non-virtual src blocks of block (i.e. blocks that feed an input signal to block)
%
% function stSrc = atgcv_m01_src_block_find(stEnv, stDest)
%
%   INPUT               DESCRIPTION
%     stEnv                 (struct)   environment struct
%
%     stDest                (struct)   data
%        .hBlock     (handle|string)   handle/path of model block
%        .sPort             (string)   inport of block (default = '1')
%        .iSigIdx           (string)   index of subsignal (default = 1)
%
%
%   OUTPUT              DESCRIPTION
%     stSrc                 (struct)   data
%        .hBlock            (handle)   handle/path of model src block
%        .sPort             (string)   outport of src block
%        .iSigIdx           (string)   index of subsignal
%        .ahInterPorts       (array)   handles of TL in/outport between 
%                                      destination and source block                                 
%        .ahInterBlocks      (array)   handles of other blocks between 
%                                      destination and source block                                 
%
%   REMARKS
%
%   Function operates on valid model handles/paths. This means the correponding 
%   model has to be open or loaded.
%
%   <et_copyright>


%%
if ischar(stDest.hBlock)
    stDest.hBlock = get_param(stDest.hBlock, 'handle');
end
if ~isfield(stDest, 'sPort')
    stDest.sPort = '1';
end
if ~isfield(stDest, 'iSigIdx')
    stDest.iSigIdx = 1;
end

%% main
ahTlPorts = [];
ahInterBlocks = [];
iCount = 0;

bIsSourceFound = false;
while ~bIsSourceFound
    iCount = iCount + 1;
    if (iCount > 1000)
        error('ATGCV:MOD_ANA:INTERNAL_ERROR', 'Infinite loop. Max count reached.');
    end
    
    bIsIntermediate = false;
    [stSrc, stDest] = atgcv_m01_dest_src_find(stEnv, stDest);     
    sBlockType = lower(get_param(stSrc.hBlock, 'BlockType'));
    switch sBlockType
        case {'subsystem', 'modelreference'}
            if strcmp(sBlockType, 'subsystem')
                bIsSourceFound = i_handleSubsystem(stSrc.hBlock);
            end
            
            % for TL3.0 we have to look at dest Outport
            hTlPort = i_handleOutport(stDest.hBlock);
            if ~isempty(hTlPort)
                ahTlPorts(end + 1) = hTlPort; %#ok<AGROW>
            end
        
        case 'inport'
            % for non-virtual subsystems
            [bIsSourceFound, hTlPort] = i_handleInport(stSrc.hBlock);
            if ~isempty(hTlPort)
                ahTlPorts(end + 1) = hTlPort; %#ok<AGROW>
            end
            
        otherwise
            % flag intermediate block
            bIsIntermediate = true;
    end
    
    if ~bIsSourceFound
        bIsSourceFound = (isempty(stDest) || isempty(stDest.sPort));
        if (~bIsSourceFound && bIsIntermediate)
            ahInterBlocks(end + 1) = stSrc.hBlock; %#ok<AGROW>
        end
    end
end
stSrc.ahInterPorts  = ahTlPorts;
stSrc.ahInterBlocks = ahInterBlocks;
end




%%
function bIsSource = i_handleSubsystem(hBlock)
bIsSource = false;

if atgcv_sl_block_isa(hBlock, 'Stateflow')
    % SF-Chart
    bIsSource = true;
elseif strcmpi('TargetLink Simulation Frame', get_param(hBlock, 'Tag'))
    % TL toplevel subsystem
    bIsSource = true;
end
end


%%
function [bIsSource, hTlPort] = i_handleInport(hBlock)
hTlPort   = [];
hSub      = get_param(get_param(hBlock, 'Parent'), 'handle');
if strcmp('MIL Subsystem', get_param(hSub, 'Tag'))
    bIsSource = true;
elseif (bdroot(hSub) == hSub)
    bIsSource = true;
else
    if ~strcmpi('on', get_param(hSub, 'IsSubsystemVirtual'))
        bIsSource = true;
    else
        % enabled or triggered subs
        aiPorts = get_param(hSub, 'Ports');
        bIsSource = ((aiPorts(3) > 0) || (aiPorts(4) > 0));
    end
end
if (~bIsSource && ds_isa(hBlock, 'tlblock'))
    hTlPort = hBlock;
end
end


%%
function hTlPort = i_handleOutport(hBlock)
if ds_isa(hBlock, 'tlblock')
    hTlPort = hBlock;
else
    hTlPort = [];
end
end

