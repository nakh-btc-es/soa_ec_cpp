function it_slmil_SL_LUT_BP()
% Tests the ep_sim_harness_create method

if verLessThan('matlab' , '9.1')
    MU_MESSAGE('Test skipped! Testing possible starting with ML2016b');
    return;
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('simple_lut_01', 'UT_SL', 'lut_bp', 'top'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
