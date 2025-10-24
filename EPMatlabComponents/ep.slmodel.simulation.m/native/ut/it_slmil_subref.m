function it_slmil_subref()
% Tests the ep_sim_harness_create method

if verLessThan('matlab' , '9.7')
    MU_MESSAGE('Test skipped! Feature SubsystemReference is available since 9.7');
    return
end

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SubsystemReference', 'SL', 'sub_reference', 'sub_reference');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
