function it_slmil_invalid_input_constraints()

% Tests the ep_sim_harness_create method
if verLessThan('matlab', '9.6')
    MU_MESSAGE('Test skipped! Linking a DD and the WS to a model is possible starting with ML2019a.');
    return
end
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('InputModelConstraints', 'SL', 'input_restrictions1', ...
    'input_restrictions1'); %#ok

sOrgSimMode= 'SL MIL';
stExtractInfo = sltu_extract_model(stTestData, 'OriginalSimulationMode', sOrgSimMode);

try
    [xOnCleanUpCloseExtrModel, stSimulationResult] = sltu_simulate_model(stTestData, stExtractInfo, ...
        'ExecutionMode', sOrgSimMode); %#ok
    MU_FAIL('An error during simulation is expected, but did not occur!')
catch oEx
    bMonotonicError = ~isempty(strfind(oEx.message, 'monotonically increasing'));
    MU_ASSERT_TRUE(bMonotonicError, sprintf('Unexpected exception:\n%s', oEx.message));
end
end