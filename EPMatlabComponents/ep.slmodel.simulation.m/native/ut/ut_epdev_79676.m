function ut_epdev_79676()
% Testing fix for EPDEV-79676: Creating SL-Toplevel harness is failing because types from the SLDD are used that the
% algo responsible for harness generation is not accessing correctly.
%


%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('toplevel_many_types', 'UT_MIL_SL', 'epdev_79676');

sOrgSimMode = 'SL MIL (Toplevel)';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); 
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

bIgnoreLocals = true;
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector, bIgnoreLocals);
end
