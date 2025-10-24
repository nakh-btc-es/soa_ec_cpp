function MU_pre_hook
% Define suites and tests for unit testing.
%

%%
%  Add path to unit test sources.
path_ut = fileparts(cd); % one directory up
path_ut = fullfile(path_ut, 'ut');
addpath(path_ut);


%%
sTmpDir = sltu_tmp_env;


%%
hSuite = MU_add_suite('basics', 0, 0, sTmpDir);
MU_add_test(hSuite, 'import',      @ut_sl_import);
MU_add_test(hSuite, 'pre_analyse', @ut_sl_pre_analyse);




%% ----------------- old stuff --------------------------------
%
hSuite = MU_add_suite('IT_ArchitectureImportAl', 0, 0, sTmpDir);
MU_add_test(hSuite, 'EpArchPreAnalyzeSlModel', @it_ep_arch_pre_analyze_sl_model);

%
hSuite = MU_add_suite('UT', 0, 0, sTmpDir);
MU_add_test(hSuite, 'ParameterHandlingOff', @ut_ep_arch_pre_analyze_sl_model_parameter_handling);
MU_add_test(hSuite, 'SubsystemHierarchy',   @ut_ep_arch_get_subsystem_hierarchy);
end