function oSig = ep_sl_signal_from_value_prototype_get(xPrototypeValue)
% Transform a bus protoype struct (Simulink.Bus.createMATLABStruct) into a signal object.
%
% function oSig = ep_sl_signal_from_bus_prototype_get(stBus, sName)
%


%%
if isstruct(xPrototypeValue)
    oSig = ep_sl.Signal.getTypelessBus();
    
    stBus = xPrototypeValue;
    casFields = fieldnames(stBus);
    
    nSubSigs = numel(casFields);
    caoSubSigs = cell(1, nSubSigs);
    for i = 1:numel(casFields)
        sSubSigName = casFields{i};
        
        oSubSig = ep_sl_signal_from_value_prototype_get(stBus.(sSubSigName));
        oSubSig.sName_ = sSubSigName;
        
        caoSubSigs{i} = oSubSig;
    end
    oSig.aoSubSignals_ = i_cell2mat(caoSubSigs);
else
    oSig = i_getElementSignal(xPrototypeValue);
end
end


%%
function oSig = i_getElementSignal(xPrototypeValue)
oSig = ep_sl.Signal();

stTypeInfo = i_getTypeInfo(xPrototypeValue);
if ~stTypeInfo.bIsValidType
    return;
end
oSig.stTypeInfo_ = stTypeInfo;

aiElemDim = size(xPrototypeValue);
oSig.aiDim_ = i_transformSizeToCompiledDim(aiElemDim);
end


%%
function stTypeInfo = i_getTypeInfo(xPrototypeValue)
if islogical(xPrototypeValue)
    sType = 'boolean';
else
    sType = class(xPrototypeValue);
end
stTypeInfo = ep_sl_type_info_get(sType);
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
% Note: Dimensions of BusElements behave differently from CompiledPortDimensions
%       --> adapt them to match the CompiledPortDimensions
function aiDim = i_transformSizeToCompiledDim(aiSize)
if ((numel(aiSize) == 2) && (aiSize(end) == 1))
    aiSize = aiSize(1);
end
aiDim = [length(aiSize), aiSize];
end

