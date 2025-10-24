function it_ep_subsystem_reference()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.7')
    MU_MESSAGE('Test skipped! The usage of subsystem references is possible starting with ML2019b.');
    return
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SubsystemReference', 'SL', ...
    'sub_reference', 'sub_reference'); %#ok

sOrgSimMode= 'SL MIL';
stExtractInfo = sltu_extract_model(stTestData, 'OriginalSimulationMode', sOrgSimMode);


[xOnCleanUpCloseExtrModel, stSimulationResult] = sltu_simulate_model(stTestData, stExtractInfo, ...
    'ExecutionMode', sOrgSimMode); %#ok


SLTU_ASSERT_SELF_CONTAINED_MODEL(stSimulationResult.sModelName)


SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stSimulationResult.sSimulatedVector);