function ut_tl_40_01
% UPDATED LEGACY UT
% Checking TL4.0 support
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'tl40_01';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFileTL  = stTestData.sTlModelFile;
sInitScriptTL = stTestData.sTlInitScriptFile;
[~, sModelTL] = fileparts(sModelFileTL);

xOnCleanupCloseModel = sltu_load_models(xEnv,...
    {sModelFileTL, sInitScriptTL, true});
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
stOpt = struct( ...
    'sTlModel',      sModelTL, ...
    'sTlSubsystem',  'TL_FuelsysController', ...
    'bCalSupport',   false, ...
    'bDispSupport',  true, ...
    'bParamSupport', true, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);

%% assert
if verLessThan('tl', '4.3')
    sTestDataSubDir = fullfile(sTestDataDir, 'tl41');
else
    % note: ML versions >= ML2021a are sometimes showing differences for CAL values because of changes in sprintf()
    if ut_util_printf_to_string_diff()
        sTestDataSubDir = fullfile(sTestDataDir, 'tl50');
    else
        sTestDataSubDir = fullfile(sTestDataDir, 'ml2021a_tl52');
    end
end

sExpectedTlArch = fullfile(sTestDataSubDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataSubDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end