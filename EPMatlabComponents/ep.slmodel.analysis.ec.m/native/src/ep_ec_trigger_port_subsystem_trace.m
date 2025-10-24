function [sTriggeredSubsystem, ahLines, ahBlocks] = ep_ec_trigger_port_subsystem_trace(sTriggerInport, nMaxPropagations)
% Simple tracing in forward direction from a root trigger inport to the triggered subsystem.
%
%

%%
if (nargin < 2)
    nMaxPropagations = 50;
end

%%
hSrcPort = i_getBlockSrcPort(sTriggerInport);

[hDstPort, ahLines, ahConnectedBlocks] = i_findFinalDstPort(hSrcPort, nMaxPropagations);
if (~isempty(hDstPort) && strcmp(get(hDstPort, 'PortType'), 'trigger'))
    sTriggeredSubsystem = get_param(hDstPort, 'Parent');
    ahBlocks = [get_param(sTriggerInport, 'handle'), reshape(ahConnectedBlocks, 1, [])];
else
    sTriggeredSubsystem = '';
    ahLines  = [];
    ahBlocks = [];
end
end


%%
function [hDstPort, ahLines, ahConnectedBlocks] = i_findFinalDstPort(hSrcPort, nMaxPropagations)
ahLines = [];
ahConnectedBlocks = [];

nPropag = 0;
[hDstPort, hLine] = i_findDstPort(hSrcPort);
while ~isempty(hDstPort)
    if (nPropag >= nMaxPropagations)
        break;
    end
    nPropag = nPropag + 1;
    
    ahLines(end + 1) = hLine; %#ok<AGROW>
    ahConnectedBlocks(end + 1) = get_param(get_param(hDstPort, 'parent'), 'handle'); %#ok<AGROW>
    
    hSrcPort = i_propagateSignalDstToSrc(hDstPort);
    if isempty(hSrcPort)
        break;
    end
    [hDstPort, hLine] = i_findDstPort(hSrcPort);
end
end


%%
function [hPortOut, hLine] = i_findDstPort(hPortIn)
hPortOut = [];

hLine = get_param(hPortIn, 'Line');
if ~isempty(hLine)
    hDstPort = get_param(hLine, 'DstPortHandle');
    if ((numel(hDstPort) == 1) && (hDstPort > 0))
        hPortOut = hDstPort;
    end
end
end


%%
function hSrcPort = i_propagateSignalDstToSrc(hDstPort)
sBlock = get_param(hDstPort, 'Parent');
sParentBlockType = get_param(sBlock, 'BlockType');
switch lower(sParentBlockType)
    case 'goto'
        hSrcPort = i_traceFromSrcPort(sBlock);
        
    case 'outport'
        hSrcPort = i_traceSubsystemSrcPort(sBlock);

    case 'subsystem'
        hSrcPort = i_traceInportSrcPort(hDstPort);
        
    case 'variantsource'
        hSrcPort = i_getBlockSrcPort(sBlock); % tracing is easy: block-type has just on single src port
        
    otherwise
        hSrcPort = [];
end
end


%%
function hSrcPort = i_getBlockSrcPort(sBlock)
stPortHandles = get_param(sBlock, 'PortHandles');
hSrcPort = stPortHandles.Outport(1);
end


%%
function hSrcPort = i_traceFromSrcPort(sGotoBlock)
hSrcPort = [];

sTag = get_param(sGotoBlock, 'GotoTag');
casBlocks = ep_find_system(get_param(sGotoBlock, 'Parent'), ...
    'Searchdepth', 1, ...
    'Blocktype',   'From', ...
    'GotoTag',     sTag);
if (numel(casBlocks) == 1)
    stPortHandles = get_param(casBlocks{1}, 'PortHandles');
    hSrcPort = stPortHandles.Outport(1);
end
end


%%
function hSrcPort = i_traceSubsystemSrcPort(sOutportBlock)
hSrcPort = [];

sParent = get_param(sOutportBlock, 'Parent');
if strcmpi(get_param(sParent, 'Type'), 'block') % make sure that the Port is not a root IO Port on model level
    stPortHandles = get_param(sParent, 'PortHandles');
    iPort = sscanf('%i', get_param(sOutportBlock, 'Port'));
    if (iPort <= numel(stPortHandles.Outport))
        hSrcPort = stPortHandles.Outport(iPort);
    end
end
end


%%
function hSrcPort = i_traceInportSrcPort(hSubDstPort)
hSrcPort = [];

iPort = get_param(hSubDstPort, 'PortNumber');
casBlocks = ep_find_system(get_param(hSubDstPort, 'Parent'), ...
    'Searchdepth', 1, ...
    'BlockType',   'Inport', ...
    'Port',        sprintf('%i', iPort));
if (numel(casBlocks) == 1)
    stPortHandles = get_param(casBlocks{1}, 'PortHandles');
    hSrcPort = stPortHandles.Outport(1);
end
end

