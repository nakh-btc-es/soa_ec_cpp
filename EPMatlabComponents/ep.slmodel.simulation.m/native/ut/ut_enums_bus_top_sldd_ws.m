function ut_enums_bus_top_sldd_ws()
% Tests the ep_sim_harness_create method

% Parallel definition of type in SLDD and in WS is possible with ML2020a
% and newer.
if verLessThan('MATLAB', '9.8')
    return;
end

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('EnumBusSlddWSToplevel', 'SL', 'enums_bus_top_sldd_ws');

sOrgSimMode = 'SL MIL (Toplevel)';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode); 
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

bIgnoreLocals = true;
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector, bIgnoreLocals);
end
