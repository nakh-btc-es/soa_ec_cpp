function [oItf, aoBusSigs] = analyzeBusForDataStore(oItf)
sCompiledBusType = oItf.stDsmInfo.oSig.sBusType_;
bIsBus = ~isempty(sCompiledBusType) && ~strcmp(sCompiledBusType, 'NOT_BUS');
if bIsBus
    oItf.isBusElement  = true;
    oItf.oSigSL_ = oItf.stDsmInfo.oSig;

    [oMetaBus, aoBusSigs] = ep_core_feval('ep_ec_sl_signal_to_meta_adapt', oItf.stDsmInfo.oSig, oItf.name);
    oItf.metaBus = oMetaBus;
        
else
    oItf.metaBus.busType = 'NOT_BUS';
    oItf.isBusElement    = false;
    
    aoBusSigs = [];
end
end

