function hDstPort = ep_sl_port_src_to_dst_propagate(hSrcPort)
% Going back from a source port of a block to the destination port. If not possible an empty dst port is returned.
%
% Note: Propagation is only possible for certain block types. Currently support for: From, Inport, Subsystem
%


%%
sBlock = get_param(hSrcPort, 'Parent');
sParentBlockType = get_param(sBlock, 'BlockType');
switch lower(sParentBlockType)
    case 'from'
        hDstPort = i_traceGotoDstPort(sBlock);
        
    case 'inport'
        hDstPort = i_traceSubsystemDstPort(sBlock);
        
    case 'subsystem'
        hDstPort = i_traceOutportDstPort(hSrcPort);
        
    otherwise
        hDstPort = [];
end
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
    'LookUnderMasks','on', ...
    'Searchdepth', 1, ...
    'BlockType',   'Outport', ...
    'Port',        sprintf('%i', iPort));
if (numel(casBlocks) == 1)
    stPortHandles = get_param(casBlocks{1}, 'PortHandles');
    hDstPort = stPortHandles.Inport(1);
end
end
