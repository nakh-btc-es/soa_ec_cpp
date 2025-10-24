function ut_ar_multi_instance
% Simple generic check for EC.
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = ...
    sltu_prepare_ats_env('ar_multi_instance', 'UT_EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
if verLessThan('matlab', '9.6')
    sVerPath = 'ml2018b';
elseif verLessThan('matlab', '9.9')
    sVerPath = 'ml2019a';
else
    sVerPath = 'ml2020b';    
end
sTestDataDir = fullfile(ut_get_testdata_dir(), 'ar_multi_instance', sVerPath);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);
end

