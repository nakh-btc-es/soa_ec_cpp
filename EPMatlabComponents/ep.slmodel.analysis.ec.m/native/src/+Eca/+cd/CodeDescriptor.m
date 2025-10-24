% Entry class handling high-level info for all models inside the model-hierarchy.
classdef CodeDescriptor
    properties (SetAccess = private, Hidden = true)
        oCD_ = [];
    end

    methods
        function oObj = CodeDescriptor(xModel)
            oCD = coder.getCodeDescriptor(getfullname(xModel));
            oObj.oCD_ = oCD;
        end

        function oModel = getRootModel(oObj)
            oModel = i_createModel(oObj.oCD_);
        end
        
        function caoModels = getAllModels(oObj)
            mModelToCD = i_getMapModelToCD(oObj.oCD_);
            caoModels = cellfun(@i_createModel, mModelToCD.values, 'UniformOutput', false);
        end

        % NOTE: on this level we can have getAllParameters, getAllLocals, etc. for all models
    end    
end


%%
function oModel = i_createModel(oCD)
oCompIF = oCD.getFullComponentInterface;
oModel = Eca.cd.Model(oCompIF, oCD);
end


%%
function mModelToCD = i_getMapModelToCD(oCD, mModelToCD)
if (nargin < 2)
    mModelToCD = containers.Map();
end

sModelName = oCD.ModelName;
if ~mModelToCD.isKey(sModelName)
    mModelToCD(sModelName) = oCD;
end

casRefModels = oCD.getReferencedModelNames();
for i = 1:numel(casRefModels)
    oRefCD = oCD.getReferencedModelCodeDescriptor(casRefModels{i});
    mModelToCD = i_getMapModelToCD(oRefCD, mModelToCD);
end
end
