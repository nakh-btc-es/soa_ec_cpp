function ut_message_virtual_bus()
% Checks simulation of Messages in conjunction with virtual buses

if verLessThan('matlab', '9.9')
    MU_MESSAGE('SKIPPING TEST: Test model only available for ML2020b and higher.');
    return;
end

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('message_bus', 'UT_SL', 'message_bus_SL');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);

end