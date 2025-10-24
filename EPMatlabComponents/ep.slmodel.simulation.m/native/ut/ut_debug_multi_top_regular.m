function ut_debug_multi_top_regular()
% Standard check for debug env.
%


%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'MultiTopRegular', 'SL', 'multiTopRegular', 'top', '', {'my|first|test', 'my|second|test'}); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

sSimDebugOutputMDF = stResult.casSimDebugOutputMDF{1};
SLTU_ASSERT_EQUAL_MDF(stTestData.sOutputsVectorFile, sSimDebugOutputMDF, 'MIL');
SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile);
end
