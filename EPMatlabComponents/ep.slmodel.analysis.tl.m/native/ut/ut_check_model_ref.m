function ut_check_model_ref
%

%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'model_ref';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), [sUTSuite, '_check_', sUTModel]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));



%% act
[stResult, oEx] = ut_ep_model_check(xEnv, sModelFile, 'TlInitScript', sInitScript);    


%% assert
MU_ASSERT_TRUE(isempty(oEx), 'No error expected.');

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, stResult.sMessageFile);

casExpectedModules = {'model:model_ref', 'model_ref:sub1', 'model_ref:sub2', 'model_ref:sub4'};
casFoundModules = arrayfun(@i_getModuleKey, stResult.astTlModules, 'uni', false); 
SLTU_ASSERT_STRINGSETS_EQUAL(casExpectedModules, casFoundModules);
end



%%
function sKey = i_getModuleKey(stModule)
[~, sName] = fileparts(stModule.sFile);
sKey = [stModule.sKind, ':', sName];
end