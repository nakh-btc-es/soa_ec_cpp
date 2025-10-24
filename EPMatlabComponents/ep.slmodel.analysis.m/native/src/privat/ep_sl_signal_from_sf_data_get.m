function oSig = ep_sl_signal_from_sf_data_get(hSfData, hResolverFunc)
% Get signal info from a Stateflow data handle.
%
% function oSig = ep_sl_signal_from_sf_data_get(hSfData, hResolverFunc)
%
%   INPUT               DESCRIPTION
%     hSfData           (handle)         SF data handle
%                                        (if name, it is assumed that the object exists in the model context)
%     hResolverFunc     (handle)         function for resolving symbols in model
%
%   OUTPUT              DESCRIPTION
%


%%
if (nargin < 2)
    hResolverFunc = atgcv_m01_generic_resolver_get();
end

oSig = ep_sl.Signal;

stTypeInfo = ep_sl_type_info_get(hSfData.CompiledType, hResolverFunc);
if stTypeInfo.bIsBus
    % first check if the bus object candidate is a real bus object
    sBusObjName = hSfData.Props.Type.BusObject;
    if isempty(sBusObjName)
        return;
    end
    
    oSig = ep_sl_signal_from_bus_object_get(sBusObjName, hResolverFunc);
    if ~oSig.isValid()
        return;
    end
    
else
    oSig.stTypeInfo_ = stTypeInfo;
    oSig.sMin_       = hSfData.Props.Range.Minimum;
    oSig.sMax_       = hSfData.Props.Range.Maximum;
end
oSig.aiDim_ = i_getCompiledDimensions(hSfData);
oSig.sName_ = hSfData.Name;
end




%%
function aiDim = i_getCompiledDimensions(hSfData)
sCompiledSize = hSfData.CompiledSize;
if ~isempty(sCompiledSize)
    aiSize = eval(sCompiledSize);
else
    aiSize = 1;
end
nDim = numel(aiSize);
aiDim = [nDim, reshape(aiSize(:), 1, [])];
end

