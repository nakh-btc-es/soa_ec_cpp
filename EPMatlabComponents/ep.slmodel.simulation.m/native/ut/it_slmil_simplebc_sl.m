function it_slmil_simplebc_sl()
% Tests the ep_sim_harness_create method

[oOnCleanUpCloseTestModel, stTestData] = sltu_prepare_simenv('SimpleBurner', 'SL', 'sbc', 'sbc'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
