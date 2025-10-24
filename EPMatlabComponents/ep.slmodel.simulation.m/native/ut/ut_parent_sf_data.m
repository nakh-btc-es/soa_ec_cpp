function ut_parent_sf_data
% Test handling of global SF-data that is defined outside of SF-Chart boundaries

if ~verLessThan('matlab', '9.12')
    MU_MESSAGE('SKIPPING TEST: Test only suitable for versions lower than ML2022a.');
    return;
end

sModelName   = 'parent_sf_data';
sSuite       = 'UT_MIL_SL';
sTestDataDir = 'parent_sf_data/parent_sf_data';
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataDir);

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, ...
    'ModelRefMode',           ep_sl.Constants.BREAK_REFS, ...
    'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end