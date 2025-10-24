function ut_sl_funcs_05()
% Checks if debug-model layout handles a lot of SL-Function-Blocks.
%


%%
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_debug_env( ...
    'sl_funcs_05', 'UT_SL', 'sl_funcs_05'); %#ok

casDebugSimModes = {'MIL'};
stResult = sltu_debug_exec(stTestData, 'DebugSimModes', casDebugSimModes);

SLTU_ASSERT_TRUE(exist(stResult.sModelFile, 'file'))
end

