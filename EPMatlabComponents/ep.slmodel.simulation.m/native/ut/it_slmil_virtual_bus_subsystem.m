function it_slmil_virtual_bus_subsystem()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.1')
    MU_MESSAGE('Test skipped! Enums in DD are supported starting with ML2016b');
    return;
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('VirtualBusSLDD', 'SL', 'virtualBus_subsystem', ...
    'virtualBus_subsystem');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end