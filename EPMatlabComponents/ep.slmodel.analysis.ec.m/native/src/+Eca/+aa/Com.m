classdef Com
    properties
        sComponentName  = '';
        sAutosarVersion = '';        

        % --- Interface related ---
        sInterfaceName = '';
        astEvents      = [];
        casNamespaces  = {};

        % --- Port related ---
        sPortType             = ''; % required | provided
        sPortName             = '';
        sInstanceKey          = '';
        sInstanceSpecifier    = '';
        sInstanceIdentifier   = '';
        sServiceDiscoveryMode = '';

        % --- Mapping to SL ---
        sMappedEventName = '';
        bAllocateMemory  = false;
    end

    methods 
        function bIsValid = isValid(oObj)
            bIsValid = ~isempty(oObj.sComponentName);
        end

    end
end