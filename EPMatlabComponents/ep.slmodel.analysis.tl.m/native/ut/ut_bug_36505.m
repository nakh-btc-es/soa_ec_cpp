function ut_bug_36505
% UPDATED LEGACY UT
% Old name: ut_mt01_bug_36505
% checking fix for BTS/36505:
%       Wrong handling of CAL locations.
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'bug_36505';
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

%%test for multiple top-level selections
i_execTestForTopLevelSelection('top_A', sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForTopLevelSelection('top_B', sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForTopLevelSelection('top_C', sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForTopLevelSelection('top_D', sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForTopLevelSelection('top_E', sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForTopLevelSelection('bts_36505', sModel, xEnv, sResultDir, sTestDataDir);
end

%%
function i_execTestForTopLevelSelection(sTlSubsystem, sModel, xEnv, sResultDir, sTestDataDir)
% cleanup result dir and registered messages as precaution for multiple executions
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
    mkdir(sResultDir);
end
xEnv.clearMessages();

% act
stOpt = struct( ...
    'sTlModel',       sModel, ...
    'sTlSubsystem',   sTlSubsystem, ...
    'xEnv',           xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);

% assert
sExpectedTlArch = fullfile(sTestDataDir, sTlSubsystem, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataDir, sTlSubsystem, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataDir, sTlSubsystem, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, sTlSubsystem, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataDir, sTlSubsystem, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end