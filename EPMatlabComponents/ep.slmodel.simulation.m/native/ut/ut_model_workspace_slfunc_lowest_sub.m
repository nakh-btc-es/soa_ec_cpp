function ut_model_workspace_slfunc_lowest_sub()
% Test bugfix for EPDEV-60640: Model workspace parameters are not transferred correctly into self-contained model

sModelName   = 'ModelWorkspaceSlFunc';
sSuite       = 'UT_SL';
sTestDataDir = 'ModelWorkspaceSlFunc_lowest_sub';
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataDir);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end