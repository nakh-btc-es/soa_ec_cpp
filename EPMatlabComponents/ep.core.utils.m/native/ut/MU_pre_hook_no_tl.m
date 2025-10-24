function MU_pre_hook_no_tl
% Define suites and tests for unit testing that do NOT depend on TargetLink.
%

%%
sTmpDir = tu_tmp_env;

%%
%============= Add only tests that do NOT depend on TL! ================================

hSuite = MU_add_suite('UT_Utils_noTL', 0, 0, sTmpDir);
MU_add_test(hSuite, 'TransformArgs', @ut_transform_args);
MU_add_test(hSuite, 'LegacyEnvGet', @ut_legacy_env_get);
MU_add_test(hSuite, 'ModelSolverSet', @ut_model_solver_set);
MU_add_test(hSuite, 'EPEnvironmentStaticMethods', @ut_epenvironment_static_methods);
MU_add_test(hSuite, 'EPEnvironmentMethods', @ut_epenvironment_methods);
MU_add_test(hSuite, 'EPVersionGet', @ut_version_get);
MU_add_test(hSuite, 'EPAbspathGet', @ut_abspath_get);
MU_add_test(hSuite, 'EPCompilerSettingsGetMSVC', @ut_compiler_settings_get_for_msvc);
MU_add_test(hSuite, 'EPMexCppCompilerToCCompilerAdaption', @ut_adapt_cpp_compiler);
MU_add_test(hSuite, 'EvalHook', @ut_eval_hook);
MU_add_test(hSuite, 'Storage', @ut_storage);
MU_add_test(hSuite, 'EPPathGet', @ut_path_get);
MU_add_test(hSuite, 'ToolCall', @ut_toolcall);
MU_add_test(hSuite, 'MDF', @ut_mdf);


%%
hBugs = MU_add_suite('Bugs', 0, 0, sTmpDir);
MU_add_test(hBugs, 'EM5698', @ut_compiler_settings_get_em5698);

end

