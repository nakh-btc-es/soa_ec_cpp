function MU_pre_hook_no_tl(sTmpDir)
% Define suites and tests for unit testing.
%

%%
hSuite  = MU_add_suite('ModelContext', 0, 0, sTmpDir);
MU_add_test(hSuite, 'MC.01', @ut_model_context_01);


%%
hSuite = MU_add_suite('SimulinkTypes', [], [], sTmpDir);
MU_add_test(hSuite, 'SimTypes101', @ut_mt01_sim_types_101);
MU_add_test(hSuite, 'SimTypes102', @ut_mt01_sim_types_102);


%%
hSuite = MU_add_suite('Value', [], [], sTmpDir);
MU_add_test(hSuite, 'basic',   @ut_value_basic_checks);
MU_add_test(hSuite, 'compare', @ut_value_compare_checks);


%%
hSuite = MU_add_suite('CSourcesCollect', [], [], sTmpDir);
MU_add_test(hSuite, 'Predefined macros', @ut_predefined_macros);


%%
hSuite = MU_add_suite('ModelUtils', 0, 0, sTmpDir);
MU_add_test(hSuite, 'HighlightSlSystemWorks', @ut_highlight_sl_system);
end