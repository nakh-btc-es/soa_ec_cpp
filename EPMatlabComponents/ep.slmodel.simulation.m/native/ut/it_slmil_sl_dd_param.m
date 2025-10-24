function it_slmil_sl_dd_param()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.7')
    MU_MESSAGE('Test skipped! Feature SubsystemReference is available since 9.7');
    return;
end
sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('sldd_param', 'UT_MIL_SL', 'sldd_param'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end