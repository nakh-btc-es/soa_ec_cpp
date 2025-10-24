function ut_ar_server_as_sl_function
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
    sltu_prepare_ats_env('AR_ServerAsSLFunction', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

%% expected default folder for the stub generate
[~, sModelName] = fileparts(sModelFile);
sDefaultStubResultDir = fullfile(sTestRoot, strcat(sModelName, '_ep_stubs'));


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'AR_ServerAsSLFunction');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

if verLessThan('matlab', '9.4')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2016b', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2018a', 'CodeModel.xml');
end
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'EP:SLC:WARNING'});

%% check after first model analyse (default values)
SLTU_ASSERT_EXIST_DIR(sDefaultStubResultDir);

%% prepare config file for second model analyse
sRelativePath = fullfile('..', 'ownDirectory');
i_createEcacfgAnalysisAutosarFile(sTestRoot, sRelativePath);

%% expected folder for stub generate
sStubRoot = fullfile(sTestRoot, sRelativePath);
sStubRelativeResultDir = fullfile(sStubRoot, strcat(sModelName, '_ep_stubs'));

%% act two
ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);

%% check after second model analyse (configured values)
SLTU_ASSERT_EXIST_DIR(sStubRelativeResultDir);
end


%%
function i_createEcacfgAnalysisAutosarFile(sTestRoot, sRelativePath)
fid = fopen(fullfile(sTestRoot, 'ecacfg_analysis_autosar.m'),'w');
o = onCleanup(@() fclose(fid));
fprintf(fid,'function stConfig = ecacfg_analysis_autosar(stConfig, stAdditionalInfo)\n');
fprintf(fid,'stConfig.General.sStubCodeFolderPath = ''%s''\n', sRelativePath);
fprintf(fid,'end\n');
end

