function it_slmil_array_of_buses_selector()
% Tests the ep_sim_harness_create method
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('array_of_buses_01', 'UT_MIL_SL', 'arrayOfBuses2', 'top');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
