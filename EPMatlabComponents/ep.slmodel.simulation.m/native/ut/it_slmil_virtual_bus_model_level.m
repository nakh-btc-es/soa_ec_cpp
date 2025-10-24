function it_slmil_virtual_bus_model_level()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.1')
    MU_MESSAGE('Test skipped! Enums in DD are supported starting with ML2016b');
    return;
end

% use clear classes in context Enums
sltu_clear_classes();

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('VirtualBusSLDD', 'SL', 'virtualBus_modelLevel', ...
    'virtualBus_modelLevel');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end