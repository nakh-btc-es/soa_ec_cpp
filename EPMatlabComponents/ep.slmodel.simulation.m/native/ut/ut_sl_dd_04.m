function ut_sl_dd_04()
% Tests the usage Lookup-Table Objects in SLDDs

if verLessThan('matlab' , '9.3')
    MU_MESSAGE('Test skipped! Lookup-Tables in SLDDs support started with ML2017b.');
    return;
end

%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('sl_dd_04', 'UT_SL', 'sl_dd_04_top');

sOrgSimMode = 'SL MIL (Toplevel)';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); 
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

bIgnoreLocals = true;
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector, bIgnoreLocals);
end
