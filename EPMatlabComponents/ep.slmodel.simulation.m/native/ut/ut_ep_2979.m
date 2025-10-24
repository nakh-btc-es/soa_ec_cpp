function ut_ep_2979()
% Tests the ep_sim_harness_create method.
% When an incorrect AliasType is present in the SLDD but not used in the model, it causes the SFunction to crash.
% Now AliasTypes that are not used by the model are filtered out in the HarnessIn/out.xml files.
% This bug was first observed in EP-2979.

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('EP_2979', 'UT_MIL_SL', 'EP_2979');

sOrgSimMode = 'SL MIL';

%% Test
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end