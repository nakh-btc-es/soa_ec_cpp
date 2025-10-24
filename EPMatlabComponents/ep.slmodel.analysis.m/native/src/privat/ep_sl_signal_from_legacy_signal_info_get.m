function oSig = ep_sl_signal_from_legacy_signal_info_get(astSigs, hResolverFunc)
% LEGACY: Only for temporary usage or as fallback! Transform legacy signal info structs into a signal object.
%
% function oSig = ep_sl_signal_from_legacy_signal_info_get(astSigs, hResolverFunc)
%
%   INPUT               DESCRIPTION
%     astSigs           (array)          signal info structs with info about all the leaf signals
%     hResolverFunc     (handle)         function for resolving symbols in model
%
%   OUTPUT              DESCRIPTION
%


%%
if isempty(astSigs)
    oSig = [];
    return;
end

%%
if (nargin < 2)
    hResolverFunc = atgcv_m01_generic_resolver_get();
end


[casRootNames, castSplitSigs] = i_splitSignalsByRootName(astSigs);
if (numel(casRootNames) ~= 1)
    error('EP:INTERNAL:ASSERT_FAILED', 'Expecting signals from the same root signal.');
end

oSig = i_createSignals(casRootNames, castSplitSigs, hResolverFunc);
end


%%
function aoSigs = i_createSignals(casRootNames, castSplitSigs, hResolverFunc)
aoSigs = [];
for i = 1:numel(casRootNames)
    sRootName = casRootNames{i};
    astSigs = castSplitSigs{i};
    
    bIsLeaf = (numel(astSigs) == 1) && isempty(astSigs.sName);
    if bIsLeaf
        oSig = i_createLeafSig(astSigs, hResolverFunc);
    
    else
        oSig = ep_sl.Signal.getTypelessBus();    
        [casSubRootNames, castSubSplitSigs] = i_splitSignalsByRootName(astSigs);
        oSig.aoSubSignals_ = i_createSignals(casSubRootNames, castSubSplitSigs, hResolverFunc);
    end
    oSig.sName_ = sRootName;
    
    if isempty(aoSigs)
        aoSigs = oSig;
    else
        aoSigs = [aoSigs, oSig]; %#ok<AGROW>
    end
end
end


%%
function oSig = i_createLeafSig(stSig, hResolverFunc)
oSig = ep_sl.Signal;

sType = stSig.sUserType;
if isempty(sType)
    sType = stSig.sType;
end

oSig.stTypeInfo_ = ep_sl_type_info_get(sType, hResolverFunc);
oSig.aiDim_      = stSig.aiDim;
oSig.sMin_       = stSig.sMin;
oSig.sMax_       = stSig.sMax;
oSig.xDesignMin_ = stSig.xDesignMin;
oSig.xDesignMax_ = stSig.xDesignMax;
end


%%
function [casRootNames, castSplitSignals] = i_splitSignalsByRootName(astSigs)
casRootNames = {};
castSplitSignals = {};
if isempty(astSigs)
    return;
end

mNameToIdx = containers.Map();
for k = 1:numel(astSigs)
    stSig = astSigs(k);
    
    [sRootName, sSubName] = i_splitSignalName(stSig.sName);
    stSig.sName = sSubName;
    if mNameToIdx.isKey(sRootName)
        iIdx = mNameToIdx(sRootName);
        castSplitSignals{iIdx} = [castSplitSignals{iIdx}, stSig]; %#ok<AGROW>
        
    else
        casRootNames{end + 1} = sRootName; %#ok<AGROW>
        castSplitSignals{end + 1} = stSig; %#ok<AGROW>
        
        mNameToIdx(sRootName) = numel(casRootNames);
    end
end
end

%%
function [sRootName, sSubName] = i_splitSignalName(sName)
if any(sName == '.')
    casFound = regexp(sName, '^(.*?)\.(.*)$', 'tokens', 'once');
    sRootName = casFound{1};
    sSubName = casFound{2};
else
    sRootName = sName;
    sSubName  = '';
end
end


%%
function xxx
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
    oSig = ep_sl.Signal.getTypelessBus();
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

