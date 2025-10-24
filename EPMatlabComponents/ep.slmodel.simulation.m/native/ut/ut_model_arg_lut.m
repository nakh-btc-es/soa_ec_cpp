function ut_model_arg_lut()
% Check simulation for Simulink.LookupTable and Simulink.Breakpoint

if verLessThan('matlab', '9.12')
    MU_MESSAGE('SKIPPING TEST: Test model only available for ML2022a and higher.');
    return;
end

sModelName   = 'model_arg_lut';
sSuite       = 'UT_SL';
sTestDataDir = 'model_arg_lut';
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataDir);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end