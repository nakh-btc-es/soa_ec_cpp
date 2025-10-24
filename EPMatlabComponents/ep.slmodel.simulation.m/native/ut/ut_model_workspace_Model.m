function ut_model_workspace_Model()
% Test bugfix for EPDEV-60640: Model workspace parameters are not transferred correctly into self-contained model

sModelName   = 'ModelWorkspace';
sSuite       = 'SL';
sTestDataDir = 'ModelWorkspace_Model';
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataDir);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end