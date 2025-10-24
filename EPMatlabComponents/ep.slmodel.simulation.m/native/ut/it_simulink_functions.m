function it_simulink_functions()
% Tests that simulink functions are correctly copied.

if verLessThan('matlab', '9.0') % 9.0 => ML2016a
    % in version smaller than 2016a, the local interface of SL functions
    % is not available.
    return;
end

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SimulinkFunctions', 'SL', 'SimulinkFunctions', 'HiddenBelow');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end