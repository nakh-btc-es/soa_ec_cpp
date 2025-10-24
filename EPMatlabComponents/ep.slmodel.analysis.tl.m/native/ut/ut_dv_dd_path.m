function ut_dv_dd_path
%


%% bug in TL4.4p0
if (sltu_version_compare('TL4.4p0') == 0)
    fprintf('%s\n\n', 'TEST SKIPPED. TL4.4p0 has a bug in context of DataVariants ARRAY_OF_STRUCTS.');
    return;
end


%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'dv_dd_path';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), [sUTSuite, '_', sUTModel]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFileTL  = stTestData.sTlModelFile;
sInitScriptTL = stTestData.sTlInitScriptFile;
sModelFileSL  = stTestData.sSlModelFile;
sInitScriptSL = stTestData.sSlInitScriptFile;
[~, sModelTL] = fileparts(sModelFileTL);
[~, sModelSL] = fileparts(sModelFileSL);

xOnCleanupCloseModels = sltu_load_models(xEnv, ...
    {sModelFileTL, sInitScriptTL, true}, ...
    {sModelFileSL, sInitScriptSL, false});
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sTlModel', sModelTL, ...
    'sSlModel', sModelSL, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);


%% assert
sExpectedTlArch = fullfile(sTestDataDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stOpt.sSlResultFile);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stOpt.sSlResultFile);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile, {'ATGCV:MOD_ANA:STRICT_BUS_DIAG_SET'});
end

