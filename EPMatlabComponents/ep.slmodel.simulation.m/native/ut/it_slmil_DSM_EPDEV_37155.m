function it_slmil_DSM_EPDEV_37155()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('DSM_EPDEV_37155', 'UT_MIL_SL', 'dsm1', 'dsm1');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
