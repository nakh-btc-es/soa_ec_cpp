function ut_adaptive_autosar_tl_model_check
% Checking that TL Adaptive Autosar models are rejected for TL versions below 5.1 and that the bAdaptiveAutosar flag is
% set correctly
%
% EPDEV-60366 As a user, I want to import TargetLink Adaptive AUTOSAR models
%
%% testdata only for TL5.0 and higher
if ep_core_version_compare('TL5.0') < 0
    MU_MESSAGE('TEST SKIPPED: Testdata with "Adaptive AUTOSAR" only for TL5.0 and higher.');
    return;
end

%% prepare test and arrange
sltu_cleanup();

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

[xOnCleanupDoCleanupEnv, xEnv, ~, stTestData] = sltu_prepare_ats_env('AdaptiveAUTOSAR', 'TL', sTestRoot);

sTlModelFile  = stTestData.sTlModelFile;

xOnCleanupCloseModel = sltu_load_models(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

stEnvLegacy = ep_core_legacy_env_get(xEnv);
oEx = [];
stRes = [];

%% act
bIsAtleastTL51 = ep_core_version_compare('TL5.1') >= 0;
try
    stRes = atgcv_m01_model_check(stEnvLegacy, sTlModelFile);
catch oEx
end

%% assert
if (~bIsAtleastTL51)
    SLTU_ASSERT_TRUE(strcmp('ATGCV:MOD_ANA:TLAA_BELOW_SUPPORTED_VERSION', oEx.identifier), ...
    'Expected exception ID "%s" instead of "%s".', 'MOD_ANA:TLAA_BELOW_SUPPORTED_VERSION', oEx.identifier);
    SLTU_ASSERT_TRUE(isempty(stRes), 'Expected to return no structure as result.');
    return;
end

SLTU_ASSERT_TRUE(stRes.bAdaptiveAutosar, 'Expected the "bAdaptiveAutosar" flag to be true.');
SLTU_ASSERT_TRUE(isempty(oEx), 'Expected to not throw an exception');
end



