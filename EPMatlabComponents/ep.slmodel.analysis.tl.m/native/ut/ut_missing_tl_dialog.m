function ut_missing_tl_dialog
% Checks if a non TL model is rejected

%% cleanup
sltu_cleanup();


%% arrange
sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, ~, stTestData] = sltu_prepare_ats_env('MinMax', 'TL', sTestRoot);

sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% act and assert
stEnvLegacy = ep_core_legacy_env_get(xEnv);
try    
    atgcv_m01_model_check(stEnvLegacy, sModelFile);
    MU_FAIL('Missing expected exception for invalid TL model".');
catch oEx
    SLTU_ASSERT_TRUE(strcmp('ATGCV:MOD_ANA:CHECK_MODEL_INVALID', oEx.identifier), ...
        'Expected exception ID "%s" instead of "%s".', 'ATGCV:MOD_ANA:CHECK_MODEL_INVALID', oEx.identifier);
end
end