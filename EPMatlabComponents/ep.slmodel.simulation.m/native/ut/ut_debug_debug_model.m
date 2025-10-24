function ut_debug_debug_model()
% Standard check for debug env.
%


%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'debugModel', 'UT_MIL_SL', 'debugModel', 'top', '', {'tc1', 'tc2'}); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

sSimDebugOutputMDF = stResult.casSimDebugOutputMDF{1};
SLTU_ASSERT_EQUAL_MDF(stTestData.sOutputsVectorFile, sSimDebugOutputMDF, 'MIL');
SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile);
end

