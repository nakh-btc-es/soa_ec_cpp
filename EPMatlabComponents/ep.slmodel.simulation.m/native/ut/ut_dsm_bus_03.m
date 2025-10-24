function ut_dsm_bus_03()
% Tests the ep_sim_harness_create method

if verLessThan('Matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: Test skipped. Datastore-Buses only supported for Matlab 2019a and higher.');
    return;
end

%%

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('ds_bus_01', 'UT_SL', 'ds_bus_01');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);

end