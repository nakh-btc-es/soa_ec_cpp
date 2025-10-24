function ut_matrix_01
% UPDATED LEGACY UT
% Old name: ut_mt01_matrix_01
% Checking handling of Matrix Signals in TL UseCase.
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'matrix01';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFileTL  = stTestData.sTlModelFile;
sInitScriptTL = stTestData.sTlInitScriptFile;
sModelFileSL =  stTestData.sSlModelFile;
sInitScriptSL = stTestData.sSlInitScriptFile;
[~, sModelTL] = fileparts(sModelFileTL);
[~, sModelSL] = fileparts(sModelFileSL);

xOnCleanupCloseModel = sltu_load_models(xEnv,...
    {sModelFileTL, sInitScriptTL, true},...
    {sModelFileSL, sInitScriptSL, false});
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
stOpt = struct( ...
    'sTlModel',      sModelTL, ...
    'sSlModel',      sModelSL, ...
    'bCalSupport',   false, ...
    'bDispSupport',  true, ...
    'bParamSupport', true, ...
    'xEnv',          xEnv);

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
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end