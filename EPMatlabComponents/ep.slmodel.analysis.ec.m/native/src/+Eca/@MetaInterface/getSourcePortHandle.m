function oItf = getSourcePortHandle(oItf, bIsModelBlock)
if strcmpi(oItf.kind, 'IN')
    if bIsModelBlock
        [stInternal, stExternal] = i_getInternalAndExternalPortHandles(oItf.handle, oItf.sParentScopeModelRef);
    else
        [stInternal, stExternal] = i_getInternalAndExternalPortHandles(oItf.handle);
    end
    % Source port is the output port of the Inport block
    oItf.internalSourcePortHandle = stInternal.Outport(1);
    % External source port handle
    if ~isempty(stExternal)
        oItf.externalSourcePortHandle = stExternal.Inport(oItf.ioPortNumber);
    end
    %Source Port Handle
    oItf.sourcePortHandle = oItf.internalSourcePortHandle;
    
elseif strcmpi(oItf.kind, 'OUT')
    if bIsModelBlock
        [stInternal, stExternal] = i_getInternalAndExternalPortHandles(oItf.handle, oItf.sParentScopeModelRef);
    else
        [stInternal, stExternal] = i_getInternalAndExternalPortHandles(oItf.handle);
    end
    % Source port is the output port of the Subsystem
    if ~isempty(stExternal)
        oItf.externalSourcePortHandle = stExternal.Outport(oItf.ioPortNumber);
    end
    % Internal source port handle
    oItf.internalSourcePortHandle = stInternal.Inport(1);
    
    % source port handle
    if ~isempty(oItf.externalSourcePortHandle)
        oItf.sourcePortHandle = oItf.externalSourcePortHandle;
    else
        oItf.sourcePortHandle = oItf.internalSourcePortHandle;
    end
    
elseif strcmpi(oItf.kind, 'LOCAL')
    %Source port is the output port of the Subsystem
    extPh = get_param(oItf.handle,'PortHandles');
    oItf.externalSourcePortHandle = extPh.Outport(oItf.sourceBlockPortNumber);
    oItf.internalSourcePortHandle = oItf.externalSourcePortHandle;
    %source port handle
    oItf.sourcePortHandle = oItf.externalSourcePortHandle;
end

%Line name outside of the subsystem
lh = get(oItf.internalSourcePortHandle, 'Line');
if (lh > 0)
    oItf.sInternLineName = get(lh, 'Name'); 
end

if ~isempty(oItf.externalSourcePortHandle)
    lh = get(oItf.externalSourcePortHandle, 'Line');
    if (lh > 0)
        oItf.sExternLineName = get(lh, 'Name');
        if isempty(oItf.sExternLineName)
            hOriginPortHandle = ep_core_feval('ep_ec_port_src_dst_trace', oItf.externalSourcePortHandle, 1);
            xSignalName = get(hOriginPortHandle, 'PropagatedSignals');
            if ~isempty(xSignalName) && ischar(xSignalName)
                oItf.sExternLineName = xSignalName;
            end
        end
    end
end

oItf.hRootIOSrcBlk = oItf.findRootIOSourceBlk();
oItf.bIsRootIO = ~isempty(oItf.hRootIOSrcBlk);
%For subscopes inside runnables subsystems -> further analysis as Ar IRV
if oItf.bParentScopeIsRunnableChild
    oItf.hParentRunExtIOPort = oItf.findParentRunnableExternalPort();
end
end


%%
function [stInternal, stExternal] = i_getInternalAndExternalPortHandles(hBlock, sParentScope)
if (nargin < 2)
    sParentScope = '';
end
stInternal = get(hBlock, 'PortHandles');

if isempty(sParentScope)
    hBlockParent = get_param(hBlock, 'Parent');
else
    hBlockParent = get_param(sParentScope, 'handle');
end
if strcmpi(get_param(hBlockParent, 'Type'), 'block_diagram')
    stExternal = []; % we are on root level --> there is no "external"
else
    stExternal = get_param(hBlockParent, 'PortHandles');
end
end
