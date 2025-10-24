classdef MetaBus
    %BUS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        busType = ''; % VIRTUAL_BUS | NON_VIRTUAL_BUS
        busObjectName = '';
        busSignalName = '';
        isVirtual = false;
        bFirstElmtMappingValid = false;
        stFirstElmtArComCfg = [];
        
        oSigSL_ = []; % ep_sl.Signal
    end
    
    methods
        function bIsVirtual = isEffectivelyVirtual(oObj)
            % effectively virtual == virtual or without reference to bus object
            bIsVirtual = oObj.bIsVirtual && isempty(oObj.busObjectName);
        end
    end    
end

