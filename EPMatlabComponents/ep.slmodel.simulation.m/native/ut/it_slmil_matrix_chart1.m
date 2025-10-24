function it_slmil_matrix_chart1()
% Tests the ep_sim_harness_create method
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('MatrixStateflowChart', 'SL', 'matrix_chart1', 'matrix_chart1'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end