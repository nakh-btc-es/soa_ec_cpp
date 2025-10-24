classdef Argument < Eca.cd.Element
    methods
        function oObj = Argument(oArg, oCD)
            oObj = oObj@Eca.cd.Element(oArg, oCD);
        end
        
        function sName = getName(oObj)
            sName = oObj.oElem_.Name;
        end

        function oType = getType(oObj)
            oType = Eca.cd.Element.constructFromOptional(@Eca.cd.Type, oObj.oElem_.Type, oObj.oCD_);
        end
    end    
end

