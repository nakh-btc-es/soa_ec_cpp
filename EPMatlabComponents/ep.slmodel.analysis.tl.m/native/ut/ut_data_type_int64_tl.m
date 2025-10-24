function ut_data_type_int64_tl
% Test the handling of Simulink built-in type int64
%

%%
if verLessThan('matlab', '9.6')
    MU_MESSAGE('TEST SKIPPED: built-in type int64 in only available since ML2019a.');
    return;
end
if ~verLessThan('matlab', '9.8')
    MU_MESSAGE('TEST SKIPPED: model is using int64 for parameter which is not valid anymore since ML2020a.');
    return;
end


%% cleanup
sltu_cleanup();


%% arrange
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), 'DataTypeInt64TL');

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('DataTypeInt64', 'tl', sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sTlModel',  sModel, ...
    'xEnv',      xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sErrorFile = ut_ep_model_analyse(stOpt);


%% assert
sExpectedTlArch = fullfile(sTestDataDir, 'TlArch.xml');
sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
sExpectedErrors = fullfile(sTestDataDir, 'messages.xml');
sExpectedCArch = fullfile(sTestDataDir, 'CArch.xml');

SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCArch, stOpt.sCResultFile);

SLTU_ASSERT_EQUAL_MESSAGES(sExpectedErrors, sErrorFile);
end