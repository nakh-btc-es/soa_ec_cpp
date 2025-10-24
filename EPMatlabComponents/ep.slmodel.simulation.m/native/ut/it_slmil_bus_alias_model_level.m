function it_slmil_bus_alias_model_level()
% Tests the ep_sim_harness_create method

if verLessThan('matlab' , '9.6')
    MU_MESSAGE('Test skipped! Linking a DD and the WS to a model is possible starting with ML2019a');
    return;
end

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('AliasType_WSAndDD', 'SL', 'virtualBusAliasType_modelLevel', ...
    'virtualBusAliasType_modelLevel');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end