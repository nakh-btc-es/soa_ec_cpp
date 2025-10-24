function it_slmil_enum_sldd_ws_top()
% Tests the ep_sim_harness_create method

if verLessThan('matlab' , '9.6')
    MU_MESSAGE('Test skipped! Linking a DD and the WS to a model is possible starting with ML2019a');
    return
end
sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SLDD_And_WS_EnumerationParameter', 'SL', 'enum_sldd_ws_top', ...
    'enum_sldd_ws_top'); %#ok

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end