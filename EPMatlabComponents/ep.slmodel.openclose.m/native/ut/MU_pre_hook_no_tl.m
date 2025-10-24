function MU_pre_hook_no_tl(sTmpDir)
% Define suites and tests for unit testing that do NOT depend on TargetLink.
%

%%
%============= Add only tests that do NOT depend on TL! ================================

%% UT
hSuite = MU_add_suite('UT', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ModelOpenClose', @ut_model_open_close);
MU_add_test(hSuite, 'ModelHandle', @ut_model_handle);

%% IT
hSuite = MU_add_suite('IT', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ModelOpenClose.001', @it_model_open_close_001);



end






