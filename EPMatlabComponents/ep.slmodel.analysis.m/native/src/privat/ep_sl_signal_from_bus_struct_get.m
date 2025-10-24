function aoSigs = ep_sl_signal_from_bus_struct_get(astBusStruct, hResolverFunc)
% Transform a bus struct (get_param(..., 'BusStruct') into an array of signal information.
%
% function aoSigs = ep_sl_signal_from_bus_struct_get(astBusStruct, hResolverFunc)
%


%%
caoSigs = arrayfun(@(st) i_getSignalFromStruct(st, hResolverFunc), astBusStruct, 'uni', false);
aoSigs = i_cell2mat(caoSigs);
end


%%
function oSig = i_getSignalFromStruct(stBus, hResolverFunc)
hSrcPort = i_getBlockPortHandle(stBus.src, stBus.srcPort);
bIsBus = ~isempty(stBus.signals) || ~isempty(stBus.busObjectName);
aiSrcDim = get_param(hSrcPort, 'CompiledPortDimensions');
bIsValid = ~isempty(aiSrcDim);
if bIsValid
    bIsSrcVirtual = bIsBus && ((aiSrcDim(1) < 0) || strcmp(get_param(hSrcPort, 'CompiledBusType'), 'VIRTUAL_BUS'));
    
    % note:
    % 1) every non-bus source is consistent
    % 2) every *virtual* bus source with consistent parent-child info is consistent
    bIsSrcConsistent = ~bIsBus || (bIsSrcVirtual && i_hasConsistentParentChildInfo(stBus));
    if bIsSrcConsistent
        oSig = ep_sl_signal_from_port_get(hSrcPort);
        if (oSig.isBus && ~bIsBus)
            oSig = i_selectSubsignal(oSig, stBus.name);
        end
    else
        % if the source is not consistent, try bus object or the child signals
        if ~isempty(stBus.busObjectName)
            oSig = ep_sl_signal_from_bus_object_get(stBus.busObjectName, hResolverFunc);
        else
            if bIsSrcVirtual
                oSig = ep_sl.Signal.getTypelessBus();
                oSig.aoSubSignals_ = ep_sl_signal_from_bus_struct_get(stBus.signals, hResolverFunc);
            else
                oSig = ep_sl_signal_from_port_get(hSrcPort);
            end
        end
    end
    
else
    if bIsBus 
        if ~isempty(stBus.busObjectName)
            oSig = ep_sl_signal_from_bus_object_get(stBus.busObjectName, hResolverFunc);
        else
            oSig = ep_sl.Signal.getTypelessBus();
            oSig.aoSubSignals_ = ep_sl_signal_from_bus_struct_get(stBus.signals, hResolverFunc);
        end
    else           
        oSig = ep_sl.Signal; % note: can only return an invalid empty signal
    end
end
if oSig.isValid
    % note: check for inconsistencies and return invalid signal if found
    if (bIsBus ~= oSig.isBus)
        oSig = ep_sl.Signal; % note: can only return an invalid empty signal
    end
end
oSig.sName_ = stBus.name;
end


%%
function oSig = i_selectSubsignal(oSig, sLeafName)
aoLeafSignals = oSig.getLeafSignals();
for i = 1:numel(aoLeafSignals)
    if strcmp(aoLeafSignals.getName(), sLeafName)
        oSig = aoLeafSignals(i);
        return;
    end
end
end


%%
function bIsConsistent = i_hasConsistentParentChildInfo(stBus)
bIsConsistent = true;
if isempty(stBus.signals)
    return;
end

% Note: source and children cannot originate from the same source
sSrcOrigin = sprintf('%g:%d', stBus.src, stBus.srcPort);
for i = 1:numel(stBus.signals)
    sChildOrigin = sprintf('%g:%d', stBus.signals(i).src, stBus.signals(i).srcPort);
    bIsConsistent = bIsConsistent && ~strcmp(sSrcOrigin, sChildOrigin);
    
    if ~bIsConsistent
        return;
    end
end
end


%%
function axElem = i_cell2mat(caxElem)
if isempty(caxElem)
    axElem = [];
else
    nElem = numel(caxElem);
    axElem = caxElem{1};
    axElem = repmat(axElem, 1, nElem); 
    for i = 2:nElem
        axElem(i) = caxElem{i};
    end
end
end


%%
function hPort = i_getBlockPortHandle(hBlock, iPort)
stPortHandles = get_param(hBlock, 'PortHandles');
if (iPort > 0)
    hPort = stPortHandles.Outport(iPort);
 else 
    hPort = stPortHandles.Inport(abs(iPort));
end
end
