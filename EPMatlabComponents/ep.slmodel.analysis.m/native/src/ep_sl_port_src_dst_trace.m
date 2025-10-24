function hPortOut = ep_sl_port_src_dst_trace(hPortIn, bIgnoreCommented)
% Simple tracing in forward or backward direction of a signal.
%
%  function hPortOut = ep_sl_port_src_dst_trace(hPortIn, bIgnoreCommented)
%
% Note1: If the provided port is an "inport", the source port is traced (backward).
%        If the provided port is an "outport", the destination port is traced (forward).
%
% Note2: From/Goto blocks are traversed and not returned.
%
% Note3: For Dst ports only the first one found is returned.
%


%%
if (nargin < 2)
    bIgnoreCommented = false;
end

%%
nMaxPropagations = 10;
casTraversableBlockTypes = {'From', 'Goto'};

if strcmp(get_param(hPortIn, 'PortType'), 'inport')
    hPortOut = i_findFinalSrcPort(hPortIn, nMaxPropagations, casTraversableBlockTypes, bIgnoreCommented);
else
    hPortOut = i_findFinalDstPort(hPortIn, nMaxPropagations, casTraversableBlockTypes, bIgnoreCommented);
end
end


%%
function hSrcPort = i_findFinalSrcPort(hDstPort, nMaxPropagations, casTraversableBlockTypes, bIgnoreCommented)
nPropag = 0;
hSrcPort = i_findSrcPort(hDstPort);
while ~isempty(hSrcPort)
    if (nPropag >= nMaxPropagations)
        break;
    end
    nPropag = nPropag + 1;
    
    hDstPort = i_propagateSignalSrcToDst(hSrcPort, casTraversableBlockTypes, bIgnoreCommented);
    if isempty(hDstPort)
        break;
    end
    hSrcPort = i_findSrcPort(hDstPort);
end

if (~isempty(hSrcPort) && (bIgnoreCommented && i_isCommented(get_param(hSrcPort, 'Parent'))))
    hSrcPort = [];
end
end


%%
function hDstPort = i_findFinalDstPort(hSrcPort, nMaxPropagations, casTraversableBlockTypes, bIgnoreCommented)
nPropag = 0;
hDstPort = i_findFirstDstPort(hSrcPort);
while ~isempty(hDstPort)
    if (nPropag >= nMaxPropagations)
        break;
    end
    nPropag = nPropag + 1;

    hSrcPort = i_propagateSignalDstToSrc(hDstPort, casTraversableBlockTypes, bIgnoreCommented);
    if isempty(hSrcPort)
        break;
    end
    hDstPort = i_findFirstDstPort(hSrcPort);
end

if (~isempty(hDstPort) && (bIgnoreCommented && i_isCommented(get_param(hDstPort, 'Parent'))))
    hDstPort = [];
end
end


%%
function hPortOut = i_findSrcPort(hPortIn)
hPortOut = [];

hLine = get_param(hPortIn, 'Line');
bIsValidLineHandle = ~isempty(hLine) && (hLine > 0);
if bIsValidLineHandle
    hSrcPort = get_param(hLine, 'SrcPortHandle');
    if ((numel(hSrcPort) == 1) && (hSrcPort > 0))
        hPortOut = hSrcPort;
    end
else
    % some blocks don't have line connections, e.g. Outports in a Variant block
    % TODO: if this is required somewhen, add code here!
end
end


%%
function hDstPort = i_findFirstDstPort(hPortIn)
hDstPort = [];

ahDstPorts = i_findDstPorts(hPortIn);
if ~isempty(ahDstPorts)
    hDstPort = ahDstPorts(1);
end
end


%%
function ahDstPorts = i_findDstPorts(hPortIn)
ahDstPorts = [];

hLine = get_param(hPortIn, 'Line');
bIsValidLineHandle = ~isempty(hLine) && (hLine > 0);
if bIsValidLineHandle
    ahDstPorts = get_param(hLine, 'DstPortHandle');
    if ~isempty(ahDstPorts)
        ahDstPorts = ahDstPorts(ahDstPorts > 0);
    end
end
end


%%
function hDstPort = i_propagateSignalSrcToDst(hSrcPort, casTraversableBlockTypes, bIgnoreCommented)
hDstPort = [];

sBlock = get_param(hSrcPort, 'Parent');
if (bIgnoreCommented && i_isCommented(sBlock))
    hDstPort = i_getCorrespondingIO(hSrcPort);
    return;
end

sParentBlockType = get_param(sBlock, 'BlockType');
if ~any(strcmpi(sParentBlockType, casTraversableBlockTypes))
    return;
end

hDstPort = ep_sl_port_src_to_dst_propagate(hSrcPort);
end


%%
function bIsCommented = i_isCommented(xBlock)
bIsCommented = false;

try %#ok<TRYNC>
    bIsCommented = ~strcmp(get_param(xBlock, 'Commented'), 'off'); 
end
end


%%
% This function returns the counter port of the block with the same index
% Examples:    inport number two --> outport number two
%            outport number five --> inport number five
%
%  If no corresponding port exists, an empty array is returned.
%
function hCorrespondingPort = i_getCorrespondingIO(hPort)
if strcmp(get_param(hPort, 'PortType'), 'inport')
    sCorrepondingPortType = 'Outport';
else
    sCorrepondingPortType = 'Inport';
end

stPorts = get_param(get_param(hPort, 'Parent'), 'PortHandles');
iPortIdx = get_param(hPort, 'PortNumber');

ahCorrespondingPorts = stPorts.(sCorrepondingPortType);
if (iPortIdx > 0) && (numel(ahCorrespondingPorts) >= iPortIdx)
    hCorrespondingPort = ahCorrespondingPorts(iPortIdx);
else
    hCorrespondingPort = [];
end
end


%%
function hSrcPort = i_propagateSignalDstToSrc(hDstPort, casTraversableBlockTypes, bIgnoreCommented)
hSrcPort = [];

sBlock = get_param(hDstPort, 'Parent');
if (bIgnoreCommented && i_isCommented(sBlock))
    hSrcPort = i_getCorrespondingIO(hDstPort);
    return;
end

sParentBlockType = get_param(sBlock, 'BlockType');
if ~any(strcmpi(sParentBlockType, casTraversableBlockTypes))
    return;
end

switch lower(sParentBlockType)
    case 'goto'
        hSrcPort = i_traceFromSrcPort(sBlock);
        
    case 'outport'
        hSrcPort = i_traceSubsystemSrcPort(sBlock);
        
    case 'subsystem'
        hSrcPort = i_traceInportSrcPort(hDstPort);
        
    otherwise
        hSrcPort = [];
end
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
    iPort = sscanf(get_param(sOutportBlock, 'Port'), '%i');
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

