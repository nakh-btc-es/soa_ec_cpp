function [oMetaBus, aoMetaBusSignals] = ep_ec_sl_signal_to_meta_adapt(oSig, sTopSignalName)
% Translates an SL signal object into the meta signal objects used by the EC analysis.
%

%%
if (nargin < 2)
    sTopSignalName = oSig.getName();
end

if oSig.isBus()
    oMetaBus = i_getMetaBus(oSig, sTopSignalName);

    oMetaBusRootSig = Eca.MetaBusSignal.createMetaBusSignal(oSig, sTopSignalName);
    aoMetaBusSignals = oMetaBusRootSig.getFlatSignals();
else
    oMetaBus = Eca.MetaBus;
    aoMetaBusSignals = [];
end
end


%%
function oMetaBus = i_getMetaBus(oSig, sTopSignalName)
oMetaBus = Eca.MetaBus;
oMetaBus.oSigSL_ = oSig;
oMetaBus.busSignalName = i_getRawSignalName(sTopSignalName);
oMetaBus.busType = oSig.getBusType();
oMetaBus.isVirtual = strcmp(oMetaBus.busType, 'VIRTUAL_BUS');
oMetaBus.busObjectName = oSig.getBusObjectName();
end


%%
function sRawName = i_getRawSignalName(sSignalName)
if strcmp(sSignalName, '<signal1>') % <signal1> is a flag for a signal without a name
    sRawName = '';
else
    sRawName = sSignalName;
end
end


