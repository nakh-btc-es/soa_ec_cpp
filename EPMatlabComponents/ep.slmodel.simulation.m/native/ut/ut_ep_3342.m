function ut_ep_3342()
% Tests via ep_sim_harness_create the ep_simenv_callbacks_gen method.
% When the SLDD linked to the model references another SLDD and the
% referenced SLDD also references the main SLDD, then an infinite loop
% occurs.

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('EP_3342', 'UT_MIL_SL', 'EP_3342');

sOrgSimMode = 'SL MIL';

%% Test
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end