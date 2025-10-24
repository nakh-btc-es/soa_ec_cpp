function MU_pre_hook_no_tl
% Define suites and tests for unit testing that do NOT depend on TargetLink.
%
%%
sTmpDir = tu_tmp_env;

%%
%============= Add only tests that do NOT depend on TL! ================================

%  suite MISC
hSuiteMisc = MU_add_suite('MISC', 0, 0, sTmpDir);
MU_add_test(hSuiteMisc, 'MT_MXX_003', @ut_mxx_003 );
MU_add_test(hSuiteMisc, 'MT_MXX_004', @ut_mxx_004 );
MU_add_test(hSuiteMisc, 'MT_MXX_005', @ut_mxx_005 );

end

