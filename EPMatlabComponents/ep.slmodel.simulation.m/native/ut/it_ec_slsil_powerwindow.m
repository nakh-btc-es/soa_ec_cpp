function it_ec_slsil_powerwindow()
% Tests the ep_sim_harness_create method
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('powerwindow_explicit_slsil', 'EC', 'slsil_pw', 'top'); %#ok

sOrgSimMode= 'SL SIL';
stExtractInfo = sltu_extract_model(stTestData, 'OriginalSimulationMode', sOrgSimMode, 'SutAsModelRef', true);
[xOnCleanUpCloseExtrModel, stSimulationResult] = sltu_simulate_model(stTestData, stExtractInfo, ...
    'ExecutionMode', sOrgSimMode); %#ok


SLTU_ASSERT_SELF_CONTAINED_MODEL(stSimulationResult.sModelName, true);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stSimulationResult.sSimulatedVector);
end
