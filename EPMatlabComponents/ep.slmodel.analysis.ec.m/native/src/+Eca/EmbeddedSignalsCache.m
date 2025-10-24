classdef EmbeddedSignalsCache < handle
    
    properties (Access = private)
        mModelToEmbeddedSignals
    end

    methods (Access = private)
        function oObj = EmbeddedSignalsCache()
            oObj.mModelToEmbeddedSignals = containers.Map;
        end
    end

    methods (Static = true)
        function oObj = getInstance()
            persistent p_oInstance;

            if isempty(p_oInstance)
                p_oInstance = Eca.EmbeddedSignalsCache;
            end
            oObj = p_oInstance;
        end
    end

    methods
        function reset(oObj)
            oObj.mModelToEmbeddedSignals = containers.Map;
        end

        function oSignalsInModel = getSignalsInModel(oObj, sModelName)
            if oObj.mModelToEmbeddedSignals.isKey(sModelName)
                oSignalsInModel = oObj.mModelToEmbeddedSignals(sModelName);
            else
                oSignalsInModel = Eca.EmbeddedSignalsInModel(sModelName);
                oObj.mModelToEmbeddedSignals(sModelName) = oSignalsInModel;
            end
        end
    end
end
