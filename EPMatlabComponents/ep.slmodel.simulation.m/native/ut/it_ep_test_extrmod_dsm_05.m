function it_ep_test_extrmod_dsm_05()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('DSMInOut', 'UT_MIL_SL', 'dsm_in_out', 'dsm_in_out'); %#ok

sOrgSimMode= 'SL MIL';
stExtractInfo = sltu_extract_model(stTestData, 'OriginalSimulationMode', sOrgSimMode);


[xOnCleanUpCloseExtrModel, stSimulationResult] = sltu_simulate_model(stTestData, stExtractInfo, ...
    'ExecutionMode', sOrgSimMode); %#ok


SLTU_ASSERT_SELF_CONTAINED_MODEL(stSimulationResult.sModelName)


SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stSimulationResult.sSimulatedVector);