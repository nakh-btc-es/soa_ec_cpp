function ut_sl_dd_05()
% Tests the usage of referenced SLDDs

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('sl_dd_05', 'UT_SL', 'sl_dd_05_top');

sOrgSimMode = 'SL MIL (Toplevel)';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); 
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

bIgnoreLocals = true;
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector, bIgnoreLocals);
end
