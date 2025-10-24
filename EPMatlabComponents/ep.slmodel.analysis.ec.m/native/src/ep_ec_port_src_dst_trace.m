function hPortOut = ep_ec_port_src_dst_trace(hPortIn, nMaxPropagations)
% Simple tracing in forward or backward direction of a signal. Only single line connections considered (no split signals).
%
% Note: If the provided port is an "inport", the source port is traced (backward).
%       If the provided port is an "outport", the destination port is traced (forward).
%

%%
if (nargin < 2)
    nMaxPropagations = 50;
end

%%
if strcmp(get_param(hPortIn, 'PortType'), 'inport')
    hPortOut = i_findFinalSrcPort(hPortIn, nMaxPropagations);
else
    hPortOut = i_findFinalDstPort(hPortIn, nMaxPropagations);
end
end


%%
function hSrcPort = i_findFinalSrcPort(hDstPort, nMaxPropagations)
nPropag = 0;
hSrcPort = i_findSrcPort(hDstPort);
while ~isempty(hSrcPort)
    if (nPropag >= nMaxPropagations)
        break;
    end
    nPropag = nPropag + 1;
    
    hDstPort = i_propagateSignalSrcToDst(hSrcPort);
    if isempty(hDstPort)
        break;
    end
    hSrcPort = i_findSrcPort(hDstPort);
end
end


%%
function hDstPort = i_findFinalDstPort(hSrcPort, nMaxPropagations)
nPropag = 0;
hDstPort = i_findDstPort(hSrcPort);
while ~isempty(hDstPort)
    if (nPropag >= nMaxPropagations)
        break;
    end
    nPropag = nPropag + 1;

    hSrcPort = i_propagateSignalDstToSrc(hDstPort);
    if isempty(hSrcPort)
        break;
    end
    hDstPort = i_findDstPort(hSrcPort);
end
end


%%
function hPortOut = i_findSrcPort(hPortIn)
hPortOut = [];

hLine = get_param(hPortIn, 'Line');
if ~isempty(hLine) && hLine > 0
    hSrcPort = get_param(hLine, 'SrcPortHandle');
    if ((numel(hSrcPort) == 1) && (hSrcPort > 0))
        hPortOut = hSrcPort;
    end
end
end


%%
function hPortOut = i_findDstPort(hPortIn)
hPortOut = [];

hLine = get_param(hPortIn, 'Line');
if ~isempty(hLine) && hLine > 0
    hDstPort = get_param(hLine, 'DstPortHandle');
    if ((numel(hDstPort) == 1) && (hDstPort > 0))
        hPortOut = hDstPort;
    end
end
end


%%
function hDstPort = i_propagateSignalSrcToDst(hSrcPort)
sBlock = get_param(hSrcPort, 'Parent');
sParentBlockType = get_param(sBlock, 'BlockType');
switch lower(sParentBlockType)
    case 'from'
        hDstPort = i_traceGotoDstPort(sBlock);
        
    case 'inport'
        hDstPort = i_traceSubsystemDstPort(sBlock);
        
    case 'subsystem'
        if ~strcmp(get_param(sBlock, 'Variant'), 'on')
            hDstPort = i_traceOutportDstPort(hSrcPort);
        else
            if verLessThan('matlab', '9.6')
                sActivVariant = get_param(sBlock, 'ActiveVariantBlock');
            else
                sActivVariant = get_param(sBlock, 'CompiledActiveChoiceBlock');
            end
            stPortHandles = get_param(sActivVariant, 'PortHandles');
            iPort = get_param(hSrcPort, 'PortNumber');
            if (iPort <= numel(stPortHandles.Outport))
                hSrcPort = stPortHandles.Outport(iPort);
                if ((numel(hSrcPort) == 1) && (hSrcPort > 0))
                    hDstPort = i_traceInportSrcPort(hSrcPort);
                end
            end
        end
        
    case {'queue', 'send'}
        hDstPort = i_traceSingleInputBlockDstPort(sBlock);
        
    otherwise
        hDstPort = [];
end
end


%%
function hDstPort = i_traceSingleInputBlockDstPort(sBlock)
stPortHandles = get_param(sBlock, 'PortHandles');
hDstPort = stPortHandles.Inport(1);
if (numel(stPortHandles.Inport) > 1)
    warning('EP:INTERNAL_ERROR', 'Backtrace not possible. More than one inport found for block %s.', sBlock);
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
    iPort = sscanf('%i', get_param(sInportBlock, 'Port'));
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
function hSrcPort = i_propagateSignalDstToSrc(hDstPort)
sBlock = get_param(hDstPort, 'Parent');
sParentBlockType = get_param(sBlock, 'BlockType');
switch lower(sParentBlockType)
    case 'goto'
        hSrcPort = i_traceFromSrcPort(sBlock);

    case 'outport'
        hSrcPort = i_traceSubsystemSrcPort(sBlock);

    case 'subsystem'
        if ~strcmp(get_param(sBlock, 'Variant'), 'on')
            hSrcPort = i_traceInportSrcPort(hDstPort);
        else
            if verLessThan('matlab', '9.6')
                sActivVariant = get_param(sBlock, 'ActiveVariantBlock');
            else
                sActivVariant = get_param(sBlock, 'CompiledActiveChoiceBlock');
            end
            stPortHandles = get_param(sActivVariant, 'PortHandles');
            iPort = get_param(hDstPort, 'PortNumber');
            if (iPort <= numel(stPortHandles.Inport))
                hDstPort = stPortHandles.Inport(iPort);
                if ((numel(hDstPort) == 1) && (hDstPort > 0))
                    hSrcPort = i_traceInportSrcPort(hDstPort);
                end
            end
        end
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

