% Base class for DataInterface subtypes, e.g. MessageDataInterface, ReadWriteDataInterface, ...
classdef DataInterface < Eca.cd.Element
    methods
        function oObj = DataInterface(oDataInterface, oCD)
            oObj = oObj@Eca.cd.Element(oDataInterface, oCD);
        end
        
        function sName = getName(oObj)
            sName = oObj.oElem_.GraphicalName;
        end
        
        function sSID = getSID(oObj)
            sSID = oObj.oElem_.SID;
        end

        function oType = getType(oObj)
            oType = Eca.cd.Element.constructFromOptional(@Eca.cd.Type, oObj.oElem_.Type, oObj.oCD_);
        end

        function oImpl = getImplementation(oObj)
            oImpl = Eca.cd.Element.constructFromOptional(@Eca.cd.Implementation, oObj.oElem_.Implementation, oObj.oCD_);
        end
    end    
end
