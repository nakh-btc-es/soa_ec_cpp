% Wrapper for code.descriptor.SubsystemInterface
classdef Subsystem < Eca.cd.Scope
    properties (SetAccess = private)
        oCompIF_ = [];
    end
    
    methods
        function oObj = Subsystem(oSubsystemInterface, oCD)
            oObj = oObj@Eca.cd.Scope(oSubsystemInterface, oCD);
        end
        
        function sPath = getSubsystemBlockPath(oObj)
            sPath = oObj.oElem_.SubsystemBlockPath;
        end

        function sSID = getSID(oObj)
            sSID = oObj.oElem_.SID;
        end

        function sSubType = getSubsystemType(oObj)
            sSubType = oObj.oElem_.SubsystemType;
        end
    end    
end
