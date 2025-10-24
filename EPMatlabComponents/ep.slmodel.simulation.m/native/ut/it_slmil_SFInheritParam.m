function it_slmil_SFInheritParam()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SFInheritParam', 'UT_MIL_SL', 'sf_inherit_param', 'sf_inherit_param'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
