function ut_toplevel_trigger_if
%

%%
if (sltu_version_compare('TL4.3') >= 0)
    MU_MESSAGE('TEST SKIPPED. Testdata seems to destabilize Matlab (seen for ML2017b) when run with TL4.3.');
    return;
end


%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'toplevel_trigger_if';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), [sUTSuite, '_', sUTModel]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% test for multiple toplevels
i_execTestForToplevel('top_A', false, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForToplevel('top_B', false, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForToplevel('top_C', true, sModel, xEnv, sResultDir, sTestDataDir);
end


%%
function i_execTestForToplevel(sTlSubsystem, bIsErrorExpected, sModel, xEnv, sResultDir, sTestDataDir)
% cleanup result dir and registered messages as precaution for multiple executions
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
    mkdir(sResultDir);
end
xEnv.clearMessages();

% act
stOpt = struct( ...
    'sTlModel',     sModel, ...
    'sTlSubsystem', sTlSubsystem, ...
    'xEnv',         xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
[sMessageFile, oEx] = ut_ep_model_analyse(stOpt);

% assert
if ~bIsErrorExpected
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
else
    SLTU_ASSERT_TRUE(~isempty(oEx), 'Missing the expected error.');
end

sExpectedMessageFile = fullfile(sTestDataDir, sTlSubsystem, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end
