function it_slmil_MainModelWithoutDD_RefModelWithParamsInDD()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.6')
    MU_MESSAGE('Test skipped! Linking a DD and the WS to a model is possible starting with ML2019a.');
    return
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('MainModelWithoutDD_RefModelWithParamsInDD', 'SL', ...
    'main_no_dd', 'main_no_dd'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
