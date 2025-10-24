function ut_debug_wrapper_ar_multi_rated_runnables()
% Standard check for debug env.
%

%%
if verLessThan('matlab' , '9.3')
    MU_MESSAGE('Test skipped! EC AUTOSAR test model supported starting with ML2017b.');
    return;
end

%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'wrapper_ar_multi_rated_runnables', 'EC', 'wrapper_ar_multi_rated_runnables', 'sub', '', {'tc1', 'tc2'}); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

sSimDebugOutputMDF = stResult.casSimDebugOutputMDF{1};
SLTU_ASSERT_EQUAL_MDF(stTestData.sOutputsVectorFile, sSimDebugOutputMDF, 'MIL');
SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile);
end

