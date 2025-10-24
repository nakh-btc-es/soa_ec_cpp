function ut_message_function_call()
% Checks simulation of Messages serving as function callers

if verLessThan('matlab', '9.8')
    MU_MESSAGE('SKIPPING TEST: Test model only available for ML2020a and higher.');
    return;
end

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('message_functioncall', 'UT_SL', 'message_functioncall_SL');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);

end