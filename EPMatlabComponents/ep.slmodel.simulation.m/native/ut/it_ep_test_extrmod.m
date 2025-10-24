function it_ep_test_extrmod()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SimpleBurner', 'SL', 'sbc', 'sbc'); %#ok

sOrgSimMode= 'SL MIL';
stExtractInfo = sltu_extract_model(stTestData, 'OriginalSimulationMode', sOrgSimMode);
[xOnCleanUpCloseExtrModel, stSimulationResult] = sltu_simulate_model(stTestData, stExtractInfo, ...
    'ExecutionMode', sOrgSimMode); %#ok


SLTU_ASSERT_SELF_CONTAINED_MODEL(stSimulationResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stSimulationResult.sSimulatedVector);
end
