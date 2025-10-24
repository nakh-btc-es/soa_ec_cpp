function ut_bug_11643
% UPDATED LEGACY UT
% Old name: ut_mt01_bug_11643
% Bug: Problems with algo for model with multiple toplevels and 
% DispSupport="on".
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'bug_11643';
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

%% test for different top-level systems with different options
i_execTestForChangedOptions('top_A', {true, true, false}, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForChangedOptions('top_B', {false, true, true}, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForChangedOptions('top_C', {false, true, false}, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForChangedOptions('top_A_2', {false, false, false}, sModel, xEnv, sResultDir, sTestDataDir);
end

%%
function i_execTestForChangedOptions(sTlSubsystem, cabSettings, sModel, xEnv, sResultDir, sTestDataDir)
% cleanup result dir and registered messages as precaution for multiple executions
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
    mkdir(sResultDir);
end
xEnv.clearMessages();

sTlSubsystemCropped = strrep(sTlSubsystem,'_2','');

% act
stOpt = struct( ...
    'sTlModel',       sModel, ...
    'sTlSubsystem',   sTlSubsystemCropped, ...
    'bCalSupport',    cabSettings{1}, ...
    'bDispSupport',   cabSettings{2}, ...
    'bParamSupport',   cabSettings{3}, ...
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