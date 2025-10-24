function aoItfs = getAllAutosarComInterfaces(oEca, bCfgSwcStubAllRunItfs)
% Return Interface objects of Runnables available in model for further stub
% generation
%
% If Autosar Architecture Type is SWC_WRAPPER
%   Then All runnales Interfaces are returned
% EsleIf Autosar Architecture Type is SWC (i.e. One Runnable is the RootScope)
%   Then If ecacfg_analysis_autosar.General.bStubRteApiForNonTestedRunnables == TRUE
%           Then All Runnables interface objects are returned
%        Esle Only the interfaces of the Selected Runnable will be returned. In this case, 
%          the user can use the native Stub Code Generator to stub these interfaces 
%          rte functions not used for Testing.

bSwcStubAllRunItfs = (strcmp(oEca.sAutosarArchitectureType, 'SWC') && bCfgSwcStubAllRunItfs) || ...
                        strcmp(oEca.sAutosarArchitectureType, 'SWC_WRAPPER');
aoItfs = [];
for iRun = 1:numel(oEca.aoRunnableScopes)
    if bSwcStubAllRunItfs || oEca.aoRunnableScopes(iRun).bIsRootScope
        oScope = oEca.aoRunnableScopes(iRun);
        aoItfsTmp = [oScope.oaInputs, oScope.oaOutputs, oScope.oaParameters, oScope.oaLocals];
        if ~isempty(aoItfsTmp)
            nIdxFilter = [aoItfsTmp(:).bIsAutosarCom] & ...
                [aoItfsTmp(:).bMappingValid] & ...
                (~[aoItfsTmp(:).isBusElement] | ... % non-bus interfaces
                ([aoItfsTmp(:).isBusElement] & [aoItfsTmp(:).isBusFirstElement])); % Bus-interface -> Only first Bus interface element
            aoItfs = [aoItfs, aoItfsTmp(nIdxFilter)];
        end
    end
end
end
