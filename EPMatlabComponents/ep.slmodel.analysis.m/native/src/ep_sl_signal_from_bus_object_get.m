function oSig = ep_sl_signal_from_bus_object_get(xBus, hResolverFunc)
% Get signal info from a bus object.
%
% function oSig = ep_sl_signal_from_bus_object_get(xBus, hResolverFunc)
%
%   INPUT               DESCRIPTION
%     xBus              (string|object)  either the name of or the Simulink.Bus object itself
%                                        (if name, it is assumed that the object exists in the model context)
%     hResolverFunc     (handle)         function for resolving symbols in model
%
%   OUTPUT              DESCRIPTION
%


%%
if (nargin < 2)
    hResolverFunc = atgcv_m01_generic_resolver_get();
end


sBusObj = '';
if ischar(xBus)
    sBusObj = xBus;
    oBus = i_getBusObject(sBusObj, hResolverFunc);
else
    oBus = xBus;
end

oSig = ep_sl.Signal();
if isa(oBus, 'Simulink.Bus')
    oSig = ep_sl.Signal.getTypedBus(sBusObj);
    oSig.sBusType_   = 'NON_VIRTUAL_BUS';
    oSig.sBusObj_    = sBusObj;
    oSig.aiDim_      = [1 1];
    
    caoSigs = arrayfun(@(o) i_getElementSignal(o, hResolverFunc), oBus.Elements, 'uni', false);
    oSig.aoSubSignals_ = i_cell2mat(reshape(caoSigs, 1, []));
end
end


%%
function oBusObj = i_getBusObject(sObjectName, hResolverFunc)
oBusObj = [];

[xMaybeBusObj, nScope] = feval(hResolverFunc, sObjectName);
if (nScope > 0)
    bIsBus = isa(xMaybeBusObj, 'Simulink.Bus');
    if bIsBus
        oBusObj = xMaybeBusObj;
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
function oSig = i_getElementSignal(oBusElem, hResolverFunc)
stTypeInfo = ep_sl_type_info_get(oBusElem.DataType, hResolverFunc);
if stTypeInfo.bIsBus
    % note: bus types of elements have to correspond to bus objects
    oSig = ep_sl_signal_from_bus_object_get(stTypeInfo.sType, hResolverFunc);
else
    oSig = ep_sl.Signal;
    oSig.stTypeInfo_ = stTypeInfo;
end
oSig.sName_ = oBusElem.Name;
oSig.aiDim_      = i_transformElemDimToCompiledDim(oBusElem.Dimensions);
oSig.xDesignMin_ = oBusElem.Min;
oSig.xDesignMax_ = oBusElem.Max;
end


%%
% Note: Dimensions of BusElements behave differently from CompiledPortDimensions
%       --> adapt them to match the CompiledPortDimensions
function aiDim = i_transformElemDimToCompiledDim(aiElemDim)
aiDim = [length(aiElemDim), aiElemDim];
end

