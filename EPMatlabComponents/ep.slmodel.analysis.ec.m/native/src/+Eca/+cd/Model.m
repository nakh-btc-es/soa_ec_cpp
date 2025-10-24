% Wrapper for coder.descriptor.ComponentInterface
classdef Model < Eca.cd.Scope
    methods
        function oObj = Model(oCompInterface, oCD)
            oObj = oObj@Eca.cd.Scope(oCompInterface, oCD);
        end
        
        function caoModels = getReferencedModels(oObj)
            caoModels = i_createRefModels(oObj.oCD_);
        end

        function caoSubs = getSubystems(oObj)
            caoSubs = Eca.cd.Element.constructFromSequence(@Eca.cd.Subsystem, oObj.oElem_.Subsystems, oObj.oCD_);
        end
    end    
end


%%
function caoModels = i_createRefModels(oCD)
casRefModels = oCD.getReferencedModelNames();
aoRefCDs = cellfun(@(s) oCD.getReferencedModelCodeDescriptor(s), casRefModels);
caoModels = arrayfun(@i_createModel, aoRefCDs, 'UniformOutput', false);
end


%%
function oModel = i_createModel(oCD)
oCompIF = oCD.getFullComponentInterface;
oModel = Eca.cd.Model(oCompIF, oCD);
end
