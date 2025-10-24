function ut_modelref_break_layers()
% Test bugfix for EPDEV-60640: Model workspace parameters are not transferred correctly into self-contained model

%%
if verLessThan('matlab', '9.7')
    MU_MESSAGE('TEST SKIPPED: Subsystem references only available for ML2019b and higher.');
    return;
end

%%
sModelName   = 'modelref_break_layers';
sSuite       = 'UT_SL';
sTestDataDir = 'modelref_break_layers';
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataDir);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end