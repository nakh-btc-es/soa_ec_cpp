function oSig = ep_sl_dsm_signal_adapt(stDsmSignalInfo)
% Adaptor for DSM signal info struct.
%
% function oSig = ep_sl_dsm_signal_adapt(stDsmSignalInfo)
%
%   INPUT               DESCRIPTION
%     stDsmSignalInfo   (struct)      info data for DSMs:
%      .bIsSupported     (bool)        flag telling if DSM signal is even supported
%      .aiDimensions     (array)       dimensions of DSM signal (== CompiledPortDimensions *without* first element!!)
%      .stTypeInfo       (struct)      type info struct (as returned by ep_sl_typ_info_get)
%      .dMin             (struct)      min threshold value as double
%      .dMax             (struct)      max threshold value as double
%
%     oTypeInfoMap       (map)         optional: map from types to type infos
%
%   OUTPUT              DESCRIPTION
%     oSig               (object)      ep_sl.Signal object
%

%%
if stDsmSignalInfo.stTypeInfo.bIsBus
    sBusType = 'NON_VIRTUAL_BUS';
else
    sBusType = 'NOT_BUS';
end

oSig = i_createRootSigObj( ...
    i_translateDimensions(stDsmSignalInfo.aiDimensions), ...
    sBusType, ...
    '', ...
    stDsmSignalInfo.bIsSupported);
if ~stDsmSignalInfo.bIsSupported
    return;
end

% note: currently, no support for Bus signals!
if strcmp(sBusType, 'NOT_BUS')
    oSig.stTypeInfo_ = stDsmSignalInfo.stTypeInfo;
    oSig.xDesignMin_ = stDsmSignalInfo.dMin;
    oSig.xDesignMax_ = stDsmSignalInfo.dMax;
else
    error('BUS_SUPPORT:MISSING', 'DSM bus signals not supported yet!');
end
end


%%
% translate Simulink.Signal "dimensions" to CompiledPortDimensions:
% trafo for 2-dim: [x, y] --> [2 x y] and trafo for 1-dim: [x] --> [1 x]
function aiCompiledDim = i_translateDimensions(aiDimensions)
nDim = numel(aiDimensions);
aiCompiledDim = [nDim, reshape(aiDimensions(:), 1, [])];

% special case: treat 1x1 matrix always as scalar
if isequal(aiCompiledDim, [2 1 1])
    aiCompiledDim = [1 1];
end
end


%%
function oSig = i_createRootSigObj(aiDim, sBusType, sBusObj, bIsComplete)
oSig = ep_sl.Signal;
if ~bIsComplete
    return;
end
oSig.aiDim_    = aiDim;
oSig.sBusType_ = sBusType;
oSig.sBusObj_  = sBusObj;
end
