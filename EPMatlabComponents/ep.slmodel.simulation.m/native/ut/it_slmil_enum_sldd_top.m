function it_slmil_enum_sldd_top()
% Tests the ep_sim_harness_create method
if verLessThan('matlab' , '9.1')
    MU_MESSAGE('Test skipped! Enums in DD are supported starting with ML2016b');
    return;
end
sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SLDD_EnumerationParameter', 'SL', 'enum_sldd_top', ...
    'enum_sldd_top');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end