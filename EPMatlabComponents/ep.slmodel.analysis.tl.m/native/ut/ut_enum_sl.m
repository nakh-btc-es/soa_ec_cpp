function ut_enum_sl
%

MU_MESSAGE('Test INACTIVE! Test not activated yet because TL/ML feature ENUM not supported yet!');
return;


%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'enum_sl';
sUTSuite = 'UT_TL';
sTopLevelSub = 'top_A';
sSLModel = 'enum_sl.mdl';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sTLModelFile = stTestData.sTlModelFile;

sInitScript = stTestData.sTlInitScriptFile;
[sPath, sTLModel] = fileparts(sTLModelFile);

sSLModelFile = [sPath '\' sSLModel];


xOnCleanupCloseModel = sltu_load_models(xEnv, {sTLModelFile, sInitScript, true}, {sSLModelFile, sInitScript, false});
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sTlModel',     sTLModel, ...
    'sSlModel',     sSLModel, ...
    'xEnv',         xEnv, ...
    'sTlSubsystem', sTopLevelSub, ...
    'bCalSupport',  false, ...
    'bDispSupport', false, ...
    'bParamSupport',true);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);


%% assert
sExpectedTlArch = fullfile(sTestDataDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

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
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end



