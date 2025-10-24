function ut_slmil_fxp_in_bus()
% Tests the ep_sim_harness_create method

if verLessThan('matlab' , '9.3')
    MU_MESSAGE('TEST SKIPPED! Model is using Buses&Enums in SL-DD and was created for ML2017b.');
    return
end

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('FxpInBus', 'UT_MIL_SL', 'FxpInBus');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end