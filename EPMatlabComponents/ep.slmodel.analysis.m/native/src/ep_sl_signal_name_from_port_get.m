function sSigName = ep_sl_signal_name_from_port_get(hPort)
% Get name of the Signal running through provided BlockPort.
%
% function sSigName = ep_sl_signal_name_from_port_get(hPort)
%
%   INPUT               DESCRIPTION
%     hPort             (string)       Port handle of a Block in model
%
%   OUTPUT              DESCRIPTION
%     sSigName          (string)       signal name
%
%   REMARK:
%     Note: The readout depends on the corresponding model being in "compiled" mode and 
%           on the BusStrictMode being active.
%


%%
if verLessThan('matlab', '9.12')
    oPort = handle(hPort);
else
    oPort = findobj(hPort);
end

if ~isa(oPort, 'Simulink.Port')
    error('EP:SL:USAGE_ERROR', 'Function requires a valid port handle.');
end

%%
hBlock = i_getParentBlock(hPort);
% NOTE: if something went wrong, hBlock is empty! be prepared for this!

sSigName = i_getPortSigName(hPort, hBlock);
end




%%
function bIsPropag = i_isPropagatingBlock(hBlock)
casPropagBlocks = { ...
    'Inport', ...
    'Outport', ...
    'SubSystem', ...
    'From', ...
    'Goto'};
bIsPropag = any(strcmpi(get_param(hBlock, 'BlockType'), casPropagBlocks));
end


%%
function bCanPropagateName = i_canPropagateNameBlock(hBlock)
bCanPropagateName = strcmpi(get_param(hBlock, 'BlockType'), 'BusSelector');
bCanPropagateName = bCanPropagateName || i_isPropagatingBlock(hBlock);
end


%%
function sName = i_getPortSigName(hPort, hBlock)
sName = i_getCleanName(get_param(hPort, 'Name'));
if isempty(sName)
    if strcmpi(get_param(hPort, 'PortType'), 'outport')
        if ~isempty(hBlock) && i_canPropagateNameBlock(hBlock)
            sName = i_getPropagatedSignalRootName(hPort);
        end
    else
        % special case: for root-level Outports the signal name can be directly specified inside the block 
        % Note: Only possible for ML >= ML2016b.
        if (~verLessThan('matlab', '9.1') && i_isRootLevelOutport(hBlock))
            sName = get_param(hBlock, 'SignalName');
            if ~isempty(sName)
                return;
            end
        end

        hLine = get_param(hPort, 'Line');
        if (hLine > 0)
            hSrcBlock = get_param(hLine, 'SrcBlockHandle');
            % negative hSrcBlock means an _unconnected_ line
            if ((hSrcBlock > 0) && i_canPropagateNameBlock(hSrcBlock))
                hSrcPort = get_param(hLine, 'SrcPortHandle');
                sName = i_getPropagatedSignalRootName(hSrcPort);
            end
        end
    end
end
end


%%
function hBlock = i_getParentBlock(hPortHandle)
hBlock = [];
try
    sParentBlock = get_param(hPortHandle, 'Parent'); 
    hBlock = get_param(sParentBlock, 'Handle');
catch oEx %#ok<NASGU>
    % Note: sometimes SL is behaving in a weird way by providing the path to the
    %       Parent Block but also saying that the path is invalid!
    % --> UT in com.btc.model_analysis.m: 'Matrix.SL11'
    % --> QA model WABCO-2 ASM (ML2010bSP2, TL3.3) is displaying this behavior
end
end


%%
function bIsValid = i_isPortHandleValid(hPort)
bIsValid = ~isempty(i_getParentBlock(hPort));
end


%%
% try to determine the Name:
% - sometimes we get an empty SignalName from hierarchy but the Port is
%   nevertheless propagating a name
% - however, the propagated Name is not always the right one, since it could
%   also be the name of one of the child elements
% --> try to use a heuristic that is right most of the time
function sName = i_getPropagatedSignalRootName(hPort)
% 1) check hierarchy root name
[sName, bIsValid] = i_getNameFromSignalHierarchy(hPort);
if (bIsValid && ~isempty(sName))
    return;
end

% 2) hierarchy name turned out to be invalid or empty, try to use propagated name(s)
sName = i_getPropagatedName(hPort);
end


%%
function bIsRootLevelOutport = i_isRootLevelOutport(hBlock)
bIsRootLevelOutport = ...
    strcmpi(get_param(hBlock, 'BlockType'), 'Outport') ...
    && strcmpi(get_param(get_param(hBlock, 'Parent'), 'Type'), 'block_diagram');
end


%%
function sPropagName = i_getPropagatedName(hPort)
sPropagName = '';
% first check, if the Port is valid --> otherwise just return an empty name
if ~i_isPortHandleValid(hPort)
    return;
end

% Note: the propagated name could be really the name of the root signal or the
% name of the child elements --> try to differentiate here and just return
% something if it is probably the root name

% 1) if the propagated name has a "comma" --> name of the child elements --> do not use it!
sPropagName = get_param(hPort, 'PropagatedSignals');
if any(sPropagName == ',')
    sPropagName = '';
else
    % 2) the name has no commas but could still be a child name if the signal has only one child --> check this
    sPropagName = i_getCleanName(sPropagName);
    if ~isempty(sPropagName)
        casNames = i_getChildNames(hPort);
        if ((numel(casNames) == 1) && strcmp(sPropagName, casNames{1}))
            % just one child element with same name
            % --> most proably the propagated name is referring to child
            % --> do not use it
            sPropagName = '';
        end
    end
end
end


%%
function casNames = i_getChildNames(hPort)
casNames = {};
try
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if ~isempty(stSignalHierarchy)
        if ~isempty(stSignalHierarchy.Children)
            casNames = {stSignalHierarchy.Children(:).SignalName};
        end
    end
catch %#ok<CTCH>
end
end


%%
function [sName, bIsValid] = i_getNameFromSignalHierarchy(hPort)
sName = '';
bIsValid = false;
try
    sType = get_param(hPort, 'CompiledBusType');
    if strcmpi(sType, 'NOT_BUS')
        return;
    end
    stSignalHierarchy = get_param(hPort, 'SignalHierarchy');
    if ~isempty(stSignalHierarchy)
        sName = stSignalHierarchy.SignalName;
        bIsValid = true;
    end
catch %#ok<CTCH>
end
end


%%
function sName = i_getCleanName(sName)
sName = regexprep(sName, '^<(.*)>$', '$1');
end
