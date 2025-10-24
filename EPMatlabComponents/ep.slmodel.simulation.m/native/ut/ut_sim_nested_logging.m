function ut_sim_nested_logging()
% Tests the ep_sim_harness_create method

%%
if verLessThan('matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: Model only available for ML2019a and higher.');
    return;
end

%% prepare
sltu_clear_classes;

sModelName   = 'nested_logging';
sModelSuite  = 'UT_MIL_SL';
sTestDataDir = sModelName;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sModelSuite, sTestDataDir);


%% run
sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));


%% check
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end