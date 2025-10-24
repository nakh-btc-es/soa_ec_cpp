function ut_debug_nonVirtualBusLabel()
% Standard check for debug env.
%
if isunix && ~usejava('desktop')
    % The debug model has mask initialization commands to set the parameter of the s-function for the selected test
    % vector. Setting the output s-function parameter did not work if custom bus types are used.
    MU_MESSAGE('TEST SKIPPED: simulation of the debug model did not work in the nodisplay mode if custom bus types are in the s-function.');
    return
end

%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'nonVirtualBusLabel', 'UT_MIL_SL', 'nonVirtualBusLabel', 'sub', '', {'tc1', 'tc2'}); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

sSimDebugOutputMDF = stResult.casSimDebugOutputMDF{1};
SLTU_ASSERT_EQUAL_MDF(stTestData.sOutputsVectorFile, sSimDebugOutputMDF, 'MIL');
SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile);
end

