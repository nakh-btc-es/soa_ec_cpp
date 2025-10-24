function MU_pre_hook
% Define suites and tests for unit testing.
%

%%
sTmpDir = sltu_tmp_env;


%% EC is not checked for ML versions lower ML2018b (9.5)
if verLessThan('matlab', '9.5')
    hSuite = MU_add_suite('simple', 0, 0, sTmpDir);
    MU_add_test(hSuite, 'Skipped', @i_issueSkippingMessage);
    return;
end

%%
hSuite = MU_add_suite('ATS', 0, 0, sTmpDir);
MU_add_test(hSuite, 'powerwindow',    @ut_ats_analyze_01);

%%
hSuite = MU_add_suite('local', 0, 0, sTmpDir);
MU_add_test(hSuite, 'virtual_parent',           @ut_local_analyze_01);
MU_add_test(hSuite, 'variantUnsupportedMode',   @ut_variant_unsupported_mode);

end

%%
function i_issueSkippingMessage()
MU_MESSAGE('EC functionality not checked for ML-versions lower ML2017b. Intentionally skipping all tests.');
end

