function it_ep_extraction_multi_rated_runnables()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.3')
    MU_MESSAGE('Test skipped! Test model supported starting with ML2017b');
    return;
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('wrapper_ar_multi_rated_runnables', 'UT_MIL_SL', 'multi_rated');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end