function ut_simple_lut_01
% handling of Simulink.LookupTable and Simulink.Breakpoint as parameters


%%
if verLessThan('matlab', '9.1')
    MU_MESSAGE('SKIPPING TEST: Simulink.LookupTable and Simulink.Breakpoint only for ML2016b and higher.');
    return;
end


%% arrange and act
sSuiteName = 'UT_SL';
sModelKey  = 'simple_lut_01';

stResult = ut_pool_model_analyze(sSuiteName, sModelKey);


%% assert
sTestDataDir = fullfile(ut_testdata_dir_get(), [sSuiteName, '_', sModelKey]);

sExpectedSlArch = fullfile(sTestDataDir, 'slArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessages = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessages, stResult.sMessages);
end



