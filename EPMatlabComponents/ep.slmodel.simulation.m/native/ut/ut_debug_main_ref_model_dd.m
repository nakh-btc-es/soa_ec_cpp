function ut_debug_main_ref_model_dd()
% Standard check for debug env.
%

%%
if verLessThan('matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: Model only suited for Matlab versions equal and higher than ML2019a.');
    return;
end

%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'MainModelWithoutDD_RefModelWithParamsInDD', 'SL', 'main_no_dd_debug', 'main_no_dd', '', {'test_case_name'}); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

MU_MESSAGE('CHANGE:ME:ASAP -- This test is too weak and does not provide any expected output values to check against.');
%sSimDebugOutputMDF = stResult.casSimDebugOutputMDF{1};
%SLTU_ASSERT_EQUAL_MDF(stTestData.sOutputsVectorFile, sSimDebugOutputMDF, 'MIL');

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile);
end
