function ut_debug_model_workspace()
% Standard check for debug env for model workspace parameters.
%

%%
if verLessThan('matlab', '9.3')
    MU_MESSAGE('TEST SKIPPED: Model only suited for Matlab versions equal and higher than ML2017b.');
    return;
end

%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'model_workspace_params_02', 'UT_SL', 'model_workspace_params_02/Tc1', 'top', '', {'Tc1'}); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

sSimDebugOutputMDF = stResult.casSimDebugOutputMDF{1};
SLTU_ASSERT_EQUAL_MDF(stTestData.sOutputsVectorFile, sSimDebugOutputMDF, 'MIL');
SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile);
end

