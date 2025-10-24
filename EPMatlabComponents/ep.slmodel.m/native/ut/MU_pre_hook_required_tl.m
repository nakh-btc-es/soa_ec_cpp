function MU_pre_hook_required_tl(sTmpDir)
% Define suites and tests for unit testing.
%

%%
hSuite = MU_add_suite('DD_Bugs', @sltu_codegen_int, @sltu_codegen_exit, sTmpDir);
MU_add_test(hSuite, 'DD_01',    @ut_mt02_dd_01);
MU_add_test(hSuite, 'EP-1415',  @ut_mt02_ep_1415);
MU_add_test(hSuite, 'BUG31433', @ut_mt02_bug_31433);
end