function MU_pre_hook_required_tl
% Define suites and tests for unit testing that DO depend on TargetLink.
%

%%
sTmpDir = tu_tmp_env;

%%
% Note: stubs "tlds_init", "tlds_start", "tlds_stop" to make the tests faster!
%%

hSuite = MU_add_suite('UT_Utils', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ExtendTlConfigPath', @ut_extend_tl_get_config_path);
%%

hSuite = MU_add_suite('IT_Utils', 0, 0, sTmpDir);
MU_add_test(hSuite, 'VersionCompare', @it_version_compare);

end