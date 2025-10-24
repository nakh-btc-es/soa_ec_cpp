% Wrapper for coder.descriptor.FunctionInterface
classdef Function < Eca.cd.Element
    properties (SetAccess = private, Hidden = true)
        oProto_ = [];
    end
    
    methods
        function oObj = Function(oFuncInterface, oCD)
            oObj = oObj@Eca.cd.Element(oFuncInterface, oCD);
            oObj.oProto_ = oFuncInterface.Prototype;       
        end
        
        function sName = getName(oObj)
            sName = oObj.oProto_.Name;
        end
        
        function oArg = getReturn(oObj)
            oArg = Eca.cd.Element.constructFromOptional(@Eca.cd.Argument, oObj.oProto_.Return, oObj.oCD_);
        end
       
        function caoArgs = getArguments(oObj)
            caoArgs = Eca.cd.Element.constructFromSequence(@Eca.cd.Argument, oObj.oProto_.Arguments, oObj.oCD_);
        end

        function oArg = getActualReturn(oObj)
            oArg = Eca.cd.Element.constructFromOptional(@Eca.cd.Argument, oObj.oElem_.ActualReturn, oObj.oCD_);
        end
       
        function caoArgs = getActualArguments(oObj)
            caoArgs = Eca.cd.Element.constructFromSequence(@Eca.cd.Argument, oObj.oElem_.ActualArgs, oObj.oCD_);
        end

        function caoReads = getDirectReads(oObj)
            caoReads = Eca.cd.Element.constructFromSequence(@Eca.cd.DataInterface, oObj.oElem_.DirectReads, oObj.oCD_);
        end

        function caoWrites = getDirectWrites(oObj)
            caoWrites = Eca.cd.Element.constructFromSequence(@Eca.cd.DataInterface, oObj.oElem_.DirectWrites, oObj.oCD_);
        end
    end    
end

