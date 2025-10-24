function it_ec_slsil_lowermodelref()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.3')
    MU_MESSAGE('Test skipped! EC SL SIL is available starting with  ML2017b');
    return
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('lowermodelref_slsil', 'EC', 'slsil_lowermodelref', 'top'); %#ok

sOrgSimMode = 'SL SIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, ...
    'OriginalSimulationMode', sOrgSimMode, ...
    'SutAsModelRef',          true); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName, true);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
