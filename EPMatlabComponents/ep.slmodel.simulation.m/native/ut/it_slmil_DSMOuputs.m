function it_slmil_DSMOuputs()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('DSMOuputs', 'UT_MIL_SL', 'dsm_outputs', 'dsm_outputs'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
