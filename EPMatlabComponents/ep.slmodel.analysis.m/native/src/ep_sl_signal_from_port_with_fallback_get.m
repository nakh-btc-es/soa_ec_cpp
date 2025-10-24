function oSig = ep_sl_signal_from_port_with_fallback_get(stEnv, hPort)
% AVOID THIS FUNCTION! Subject to be removed. Use "ep_sl_signal_from_port" directly if possible.
%
% function oSig = ep_sl_signal_from_port_with_fallback_get(stEnv, hPort)
%
%   INPUT               DESCRIPTION
%     stEnv             (struct)       Legacy Environment struct containing the Messenger.
%     hPort             (string)       Port handle of a Block in model
%
%   OUTPUT              DESCRIPTION
%     oSig              (object )      ep_sl.Signal object
%
%   REMARK:
%     Note: The readout depends on the corresponding model being in "compiled" mode.
%

%%
try
    oSig = ep_sl_signal_from_port_get(hPort);
catch oEx %#ok<NASGU>
    oSig = i_useLegacyFallbackForSignal(stEnv, hPort);
end
end


%%
function oSig = i_useLegacyFallbackForSignal(stEnv, hPort)
[stInfo, sErrMsg] = atgcv_m01_port_signal_info_get(stEnv, hPort);
if isempty(sErrMsg)
    oSig = ep_sl_signal_from_legacy_signal_info_get(stInfo.astSigs);
    xDesignMin = get_param(hPort, 'CompiledPortDesignMin');
    xDesignMax = get_param(hPort, 'CompiledPortDesignMax');
    
    oSig = oSig.setDesignMinMax(xDesignMin, xDesignMax);
else
    oSig = ep_sl.Signal;
end
end
