function ut_sl_dd_and_ws()
% Tests the usage of  both, base and SLDD workspaces in a model

if verLessThan('matlab' , '9.6')
    MU_MESSAGE('Test skipped! Similar base and SLDD workspace support started with ML2019a.');
    return;
end

%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SLDD_And_WS', 'SL', 'sl_dd_and_ws_top');

sOrgSimMode = 'SL MIL (Toplevel)';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); 
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

bIgnoreLocals = true;
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector, bIgnoreLocals);
end
