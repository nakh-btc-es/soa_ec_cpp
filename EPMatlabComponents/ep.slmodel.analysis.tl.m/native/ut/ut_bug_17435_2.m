function ut_bug_17435_2
% UPDATED LEGACY UT
% Old name: ut_mt01_bug_17435
% checking fix for BTS/17435
%   REMARK
%    * testing fix for following problem:
%        - Variant DisplayVariable of TopSubsystem2 is analyzed
%        - DD is used by multiple models and TopSubsystems
%        - path TopSubsystem1 is substring of TopSubsystem2
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'bug_17435_2';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
stOpt = struct( ...
    'sTlModel',      sModel, ...
    'bCalSupport',   false, ...
    'bDispSupport',  true, ...
    'bParamSupport', false, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);

%% assert
if verLessThan('tl', '4.3')
    sTestDataSubDir = fullfile(sTestDataDir, 'tl41');
else
    sTestDataSubDir = fullfile(sTestDataDir, 'tl50');
end

sExpectedTlArch = fullfile(sTestDataSubDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataSubDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataSubDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataSubDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end