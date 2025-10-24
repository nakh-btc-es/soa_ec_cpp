function oSig = ep_sl_port_signal_adapt(stPortSignalInfo, mTypeInfoMap)
% Adaptor for legacy signal info struct.
%
% function oSig = ep_sl_port_signal_adapt(stPortSignalInfo, mTypeInfoMap)
%
%   INPUT               DESCRIPTION
%     stPortSignalInfo   (struct)      info data (as returned by atgcv_m01_port_signal_info_get):
%      .aiDim            (array)       dimensions info of main signal (== CompiledPortDimensions)
%      .sBusType         (string)      'NOT_BUS' | 'VIRTUAL_BUS' | 'NON_VIRTUAL_BUS'
%      .sBusObj          (string)      name of corresponding Bus object (if available)
%      .astSigs          (array)       structs with following info 
%        .sName          (string)      name of subsignal
%        .sUserType      (string)      type of subsignal (might be an alias)
%        .sType          (string)      base type of subsignal (builtin or fixed-point-type)
%        .iWidth         (integer)     width of subsignal
%        .sMin           (string)      Min constraint of signal if available
%        .sMax           (string)      Max constraint of signal if available
%        .aiDim          (array)       integers representing dimension
%      .bIsInfoComplete  (bool)        flag telling if info is complete and valid
%
%     oTypeInfoMap       (map)         optional: map from types to type infos
%
%   OUTPUT              DESCRIPTION
%     oSig               (object)      ep_sl.Signal object
%

%%
% TODO: in this current state function could be inlined and then removed altogether


%%
oSig = stPortSignalInfo.oSig;
end
