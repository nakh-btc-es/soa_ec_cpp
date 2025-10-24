% Common base class for Model (ComponentInterface) and Subsystem (SubsystemInterface)
classdef Scope < Eca.cd.Element
    methods
        function oObj = Scope(oScope, oCD)
            oObj = oObj@Eca.cd.Element(oScope, oCD);
        end
        
        function caoPorts = getInports(oObj)
            caoPorts = Eca.cd.Element.constructFromSequence(@Eca.cd.DataInterface, oObj.oElem_.Inports, oObj.oCD_);
        end

        function caoPorts = getOutports(oObj)
            caoPorts = Eca.cd.Element.constructFromSequence(@Eca.cd.DataInterface, oObj.oElem_.Outports, oObj.oCD_);
        end

        function caoParams = getParameters(oObj)
            caoParams = Eca.cd.Element.constructFromSequence(@Eca.cd.DataInterface, oObj.oElem_.Parameters, oObj.oCD_);
        end

        function caoFuncs = getInitializeFunctions(oObj)
            caoFuncs = Eca.cd.Element.constructFromSequence( ...
                @Eca.cd.Function, oObj.oElem_.InitializeFunctions, oObj.oCD_);
        end
        
        function caoFuncs = getOutputFunctions(oObj)
            caoFuncs = Eca.cd.Element.constructFromSequence( ...
                @Eca.cd.Function, oObj.oElem_.OutputFunctions, oObj.oCD_);
        end
        
        function caoFuncs = getUpdateFunctions(oObj)
            caoFuncs = Eca.cd.Element.constructFromSequence( ...
                @Eca.cd.Function, oObj.oElem_.UpdateFunctions, oObj.oCD_);
        end
        
        function caoFuncs = getTerminateFunctions(oObj)
            caoFuncs = Eca.cd.Element.constructFromSequence( ...
                @Eca.cd.Function, oObj.oElem_.TerminateFunctions, oObj.oCD_);
        end

        function caoTimings = getTimingProperties(oObj)
            caoTimings = Eca.cd.Element.constructFromSequence( ...
                @Eca.cd.TimingInterface, oObj.oElem_.TimingProperties, oObj.oCD_);
        end

    end    
end
