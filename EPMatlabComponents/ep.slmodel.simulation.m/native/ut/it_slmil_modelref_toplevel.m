function it_slmil_modelref_toplevel()
% Tests the ep_sim_harness_create method


%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('ModelReferences', 'SL', 'modelref_top_level', 'toplevel'); %#ok
i_setModelRefVersionDiagToError(stTestData.sModelFile);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end


%%
% EPDEV-65653 preparing condition in model to recreate bug situation --> switching on Diagnostics for ModelRefVersion
function i_setModelRefVersionDiagToError(sModelFile)
[~, sModel] = fileparts(sModelFile);
oConfig = getActiveConfigSet(sModel);
oDiag = oConfig.getComponent('Diagnostics');
oDiag.set('ModelReferenceVersionMismatchMessage', 'error');
save_system(sModel); % this does not change the original model, but the copy in the test dir
end