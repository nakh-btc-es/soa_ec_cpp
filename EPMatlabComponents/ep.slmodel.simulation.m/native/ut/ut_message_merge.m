function ut_message_merge()
% Checks simulation of Message Merge blocks

if verLessThan('matlab', '9.10')
    MU_MESSAGE('SKIPPING TEST: Test model only available for ML2021a and higher.');
    return;
end

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('message_merge', 'UT_SL', 'message_merge_SL');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);

end