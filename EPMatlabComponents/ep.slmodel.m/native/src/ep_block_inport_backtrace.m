function [hSrcPort, ahSkippedSrcPorts] = ep_block_inport_backtrace(hDstPort)
% Simple tracing in backward direction to find the non-virtual source block outport feeding the provided destination block inport.
%
%

%%
if ~strcmp(get_param(hDstPort, 'PortType'), 'inport')
    error('EP:INTERNAL:USAGE_ERROR', 'Provided handle must be the inport of a block.');
end

nMaxPropagations = 50;
nPropagCnt = 1;

ahSkippedSrcPorts = [];
hSrcPort = i_findSrcPort(hDstPort);
while ~isempty(hSrcPort)
    if (nPropagCnt >= nMaxPropagations)
        break;
    end
    nPropagCnt = nPropagCnt + 1;
    
    hDstPort = i_propagateSignalSrcToDst(hSrcPort);
    if isempty(hDstPort)
        break;
    end
    ahSkippedSrcPorts(end + 1) = hSrcPort; %#ok<AGROW>
    
    hSrcPort = i_findSrcPort(hDstPort);
end
end


%%
function hPortOut = i_findSrcPort(hPortIn)
hPortOut = [];

hLine = get_param(hPortIn, 'Line');
if ~isempty(hLine)
    hSrcPort = get_param(hLine, 'SrcPortHandle');
    if ((numel(hSrcPort) == 1) && (hSrcPort > 0))
        hPortOut = hSrcPort;
    end
end
end


%%
function hDstPort = i_propagateSignalSrcToDst(hSrcPort)
sSrcBlock = get_param(hSrcPort, 'Parent');
sBlockType = get_param(sSrcBlock, 'BlockType');
switch lower(sBlockType)
    case 'from'
        hDstPort = i_traceGotoDstPort(sSrcBlock);
        
    case 'inport'
        if i_isInportBlockSource(sSrcBlock)
            hDstPort = [];
        else
            hDstPort = i_traceSubsystemDstPort(sSrcBlock);
        end
        
    case 'subsystem'
        hDstPort = i_traceOutportDstPort(hSrcPort);
        
    case 'modelreference'
        hDstPort = i_traceModelRefOutportDstPort(hSrcPort);
        
    otherwise
        hDstPort = [];
end
end


%%
% note: the Inport block is a counted as the source of a signal if
%       A) it is the root Inport block of a model
%       B) it is the Inport block of a non-virtual subsystem
function bIsSrc = i_isInportBlockSource(sInportBlock)
sParent = get_param(sInportBlock, 'Parent');
bIsSrc = ~strcmpi(get_param(sParent, 'Type'), 'block') || strcmp(get_param(sParent, 'IsSubsystemVirtual'), 'off');
end


%%
function hDstPort = i_traceGotoDstPort(sFromBlock)
hDstPort = [];

sTag = get_param(sFromBlock, 'GotoTag');
casBlocks = ep_find_system(get_param(sFromBlock, 'Parent'), ...
    'Searchdepth', 1, ...
    'Blocktype',   'Goto', ...
    'GotoTag',     sTag);
if (numel(casBlocks) == 1)
    stPortHandles = get_param(casBlocks{1}, 'PortHandles');
    hDstPort = stPortHandles.Inport(1);
end
end


%%
function hDstPort = i_traceSubsystemDstPort(sInportBlock)
hDstPort = [];

sParent = get_param(sInportBlock, 'Parent');
if strcmpi(get_param(sParent, 'Type'), 'block') % make sure that the Port is not a root IO Port on model level
    stPortHandles = get_param(sParent, 'PortHandles');
    iPort = sscanf(get_param(sInportBlock, 'Port'), '%i');
    if (iPort <= numel(stPortHandles.Inport))
        hDstPort = stPortHandles.Inport(iPort);
    end
end
end


%%
function hDstPort = i_traceOutportDstPort(hSubSrcPort)
hDstPort = [];

iPort = get_param(hSubSrcPort, 'PortNumber');
casBlocks = ep_find_system(get_param(hSubSrcPort, 'Parent'), ...
    'Searchdepth', 1, ...
    'BlockType',   'Outport', ...
    'Port',        sprintf('%i', iPort));
if (numel(casBlocks) == 1)
    stPortHandles = get_param(casBlocks{1}, 'PortHandles');
    hDstPort = stPortHandles.Inport(1);
end
end



%%
function hDstPort = i_traceModelRefOutportDstPort(hSubSrcPort)
hDstPort = [];

sModelRefBlock = get_param(hSubSrcPort, 'Parent'); 
iPort = get_param(hSubSrcPort, 'PortNumber');
casBlocks = ep_find_system(get_param(sModelRefBlock, 'ModelName'), ...
    'Searchdepth', 1, ...
    'BlockType',   'Outport', ...
    'Port',        sprintf('%i', iPort));
if (numel(casBlocks) == 1)
    stPortHandles = get_param(casBlocks{1}, 'PortHandles');
    hDstPort = stPortHandles.Inport(1);
end
end
