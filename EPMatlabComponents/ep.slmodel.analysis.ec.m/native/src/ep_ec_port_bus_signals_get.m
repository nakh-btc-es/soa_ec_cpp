function [oSig, oMetaBus, aoMetaBusSignals] = ep_ec_port_bus_signals_get(stEnv, hPort, sTopSignalName)
%
%

%%
oSig = ep_sl_signal_from_port_with_fallback_get(stEnv, hPort);
if (nargin > 2)
    [oMetaBus, aoMetaBusSignals] = ep_ec_sl_signal_to_meta_adapt(oSig, sTopSignalName);
else
    [oMetaBus, aoMetaBusSignals] = ep_ec_sl_signal_to_meta_adapt(oSig);
end
end

