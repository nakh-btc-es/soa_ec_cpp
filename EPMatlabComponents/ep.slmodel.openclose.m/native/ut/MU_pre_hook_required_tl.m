function MU_pre_hook_required_tl(sTmpDir)
% Define suites and tests for unit testing that DO depend on TargetLink.
%

%%
% Note: stubs "tlds_init", "tlds_start", "tlds_stop" to make the tests faster!
sStubDir = fullfile(pwd, 'stubs');
if exist(sStubDir, 'dir')
    addpath(sStubDir);
end


%%
hSuite = MU_add_suite('IT_TL', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ModelOpenClose.001', @it_model_open_close_001);
MU_add_test(hSuite, 'atgcv_m_model_open_001',  @ut_m_model_open);
% TODO: testdata is broken; the test model contains inconsistent sample times and cannot be upgraded properly
% MU_add_test(hSuite, 'atgcv_m_model_open_002',  @ut_m_model_open_002);
% MU_add_test(hSuite, 'atgcv_m_model_open_003',  @ut_m_model_open_003);
MU_add_test(hSuite, 'atgcv_m_model_open_004',  @ut_m_sl_model_open);
MU_add_test(hSuite, 'dd_handling',        @ut_dd_handling);
MU_add_test(hSuite, 'sl_tl_check',        @ut_sl_tl_check);
end
