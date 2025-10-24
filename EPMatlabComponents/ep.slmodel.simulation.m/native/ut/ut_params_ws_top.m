function ut_params_ws_top()
% Tests the ep_sim_harness_create method

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('params_02', 'UT_SL', 'params_02_top');

sOrgSimMode = 'SL MIL (Toplevel)';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); 
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

bIgnoreLocals = true;
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector, bIgnoreLocals);
end
