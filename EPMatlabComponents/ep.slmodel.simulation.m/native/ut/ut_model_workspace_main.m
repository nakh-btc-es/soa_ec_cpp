function ut_model_workspace_main()
% Test bugfix for EPDEV-60640: Model workspace parameters are not transferred correctly into self-contained model

sModelName   = 'ModelWorkspace';
sSuite       = 'SL';
sTestDataDir = 'ModelWorkspace_main';

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataDir);
i_setModelRefVersionDiagToError(stTestData.sModelFile);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

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