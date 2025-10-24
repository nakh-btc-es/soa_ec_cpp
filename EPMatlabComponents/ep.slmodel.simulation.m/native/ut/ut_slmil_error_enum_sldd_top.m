function ut_slmil_error_enum_sldd_top()
% Tests the ep_sim_harness_create method


%%
if verLessThan('matlab' , '9.1')
    MU_MESSAGE('Test skipped! Enums in DD are supported starting with ML2016b');
    return;
end
sltu_clear_classes;

[xOnCleanUpCloseModel, stTestData] = ...
    sltu_prepare_simenv('SLDD_EnumerationParameter', 'SL', 'enum_sldd_top', 'enum_sldd_top'); %#ok<ASGLU>


% assert original model can be initialized before simulation
[~, sModelName] = fileparts(stTestData.sModelFile);
MU_ASSERT_TRUE(i_checkInit(sModelName), ...
    'Unexpected: Model cannot be initialized before the simulation.');

sOrgSimMode = 'SL MIL';

% create a mock to provoke an error during extraction
stMock = sltu_create_mock( ...
    'ep_sim_exec_post_extr_hook', ...
    'error(''X:X'', ''Just testing.'')'); %#ok<NASGU> return value contains onCleanup to remove the Mock

try
    sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
    MU_FAIL('Expected exception is missing');
    
catch oEx
    MU_ASSERT_TRUE(strcmp(oEx.identifier, 'X:X'), 'Found unexpected exception.')
end

% assert original model can be initialized after simulation
MU_ASSERT_TRUE(i_checkInit(sModelName), ...
    'Unexpected: Model cannot be initialized after the simulation attempt.');
end


%%
function [bSuccessful, oEx] = i_checkInit(sModelName)
oEx = [];
try
    feval(sModelName, [], [], [], 0);
    bSuccessful = true;
catch oEx
    bSuccessful = false;
end
end
