function ut_cal_settings_01
%


%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'lut_model';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel, 'ut_cal_settings_01');

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
for i = 1:32
    abCalSettings = bitget(i-1,1:5);
    sTestDataSubDir = fullfile(sTestDataDir, ['run' num2str(i)]);
    stOpt = struct( ...
        'sTlModel',                             sModel, ...
        'xEnv',                                 xEnv,   ...
        'bCalSupport',                          false,  ...
        'bDispSupport',                         false,  ...
        'bParamSupport',                        true,   ...
        'bIgnoreCalLutAxis',                    abCalSettings(1), ...
        'bIgnoreCalLut1DValues',                abCalSettings(2), ...
        'bIgnoreCalLut2DValues',                abCalSettings(3), ...
        'bIgnoreCalInterpolationValues',        abCalSettings(4), ...
        'bIgnoreCalArrays',                     abCalSettings(5) );

    stOpt = ut_prepare_options(stOpt, sResultDir);
    sMessageFile = ut_ep_model_analyse(stOpt);


    %% assert
    sExpectedTlArch = fullfile(sTestDataSubDir, 'TlArch.xml');
    SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
    SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

    sExpectedMapping = fullfile(sTestDataSubDir, 'Mapping.xml');
    SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
    SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

    sExpectedCodeModel = fullfile(sTestDataSubDir, 'CodeModel.xml');
    SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
    SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

    sExpectedTlConstraints = fullfile(sTestDataSubDir, 'TlConstr.xml');
    SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
    SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

    sExpectedMessageFile = fullfile(sTestDataSubDir, 'error.xml');
    SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end
end