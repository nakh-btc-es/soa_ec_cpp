function it_slmil_subRef1()
% Tests the ep_sim_harness_create method

if verLessThan('matlab' , '9.7')
    MU_MESSAGE('Test skipped! The usage of subsystem references is possible starting with ML2019b.');
    return
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SubsystemReference', 'SL', ...
    'sub_reference1', 'sub_reference1');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
