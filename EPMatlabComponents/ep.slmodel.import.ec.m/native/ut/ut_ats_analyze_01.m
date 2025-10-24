function ut_ats_analyze_01
% Simple generic check for EC.
%
MU_MESSAGE('TEST SKIPPED: RALO: FIND SOLUTION FOR ACCESS TO RESOURCES IN THIS TEST ENV.');
return;

%%
if verLessThan('matlab', '8.6')
    MU_MESSAGE('TEST SKIPPED: Model only suited for Matlab ML2015b or higher.');
    return;
end


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, ~, sResultDir, stTestData] = ...
    sltu_prepare_ats_env('powerwindow', 'embeddedcoder', sTestRoot); %#ok<ASGLU> onCleanup object
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% act
stResult = ut_ec_model_analyse(sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = ep_core_canonical_path(fullfile(ut_testdata_dir_get(), 'powerwindow', 'with_filtering'));

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArchFile);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArchFile);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMappingFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMappingFile);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessageFile, {'EP:SLC:INFO', 'EP:SLC:WARNING', 'ATGCV:STD:SWITCH_DIAG_ELEM_NAME_MISMATCH'});
end

