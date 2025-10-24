function it_ep_input_constraints()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('InputModelConstraints', 'SL', 'input_restrictions', ...
    'input_restrictions'); %#ok

sOrgSimMode= 'SL MIL';
stExtractInfo = sltu_extract_model(stTestData, 'OriginalSimulationMode', sOrgSimMode);


[xOnCleanUpCloseExtrModel, stSimulationResult] = sltu_simulate_model(stTestData, stExtractInfo, ...
    'ExecutionMode', sOrgSimMode); %#ok


SLTU_ASSERT_SELF_CONTAINED_MODEL(stSimulationResult.sModelName)


SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stSimulationResult.sSimulatedVector);