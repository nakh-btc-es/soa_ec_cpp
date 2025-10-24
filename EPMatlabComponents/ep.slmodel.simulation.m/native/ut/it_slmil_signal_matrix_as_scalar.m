function it_slmil_signal_matrix_as_scalar()
% Tests the ep_sim_harness_create method

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('signalMatrixAsScalar', 'UT_MIL_SL', 'signalMatrixAsScalar'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end