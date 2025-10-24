function ut_modelana_mt01_tlcheck5
% test for TL check in context of inconsistent enum definitions


%% checking TL3.5 feature
if (atgcv_version_p_compare('TL3.5') < 0)
    MU_MESSAGE('Test skipped. Only TL versions higher-equal TL3.5 supported.');
    return;
end

%% clean up first
ut_cleanup();

%% predefined values
sPwd     = pwd();
sRootDir = fullfile(pwd, 'tlPseudoEnums');
sDataDir = fullfile(ut_local_testdata_dir_get(), 'tl35_tlPseudoEnums');

sModel     = 'tlEnumsPseudo';
sModelFile = fullfile(sRootDir, [sModel, '.mdl']);
sInitFile  = fullfile(sRootDir, 'start.m');
sErrFile = 'tmp_error.xml';

%% prepare env
[xOnCleanupDoCleanup, stEnv] = ut_prepare_legacy_env(sDataDir, sRootDir);
xEnv = stEnv.hMessenger;

xOnCleanupCloseModel = ut_open_model(xEnv, sModelFile, sInitFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanup}));


%% import fails with inconsistent data types
try
    ut_messenger_reset(stEnv.hMessenger);
    i_setMismatchAccept(false)
    stOpt = struct('sTlModel', sModel);
    stOpt.bAdaptiveAutosar = false;
    
    sMaFile = ut_m01_model_analysis(stEnv, stOpt);
    atgcv_m01_tlcheck(stEnv, sMaFile);
    
    MU_FAIL('Exception expected.');
catch oEx
    sExpected = 'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT';
    MU_ASSERT_TRUE(strcmpi(oEx.identifier, sExpected), sprintf( ...
        'Expected Exception %s instead of %s.', ...
        sExpected, oEx.identifier));
    
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    ut_assert_msg_count(sErrFile, ...
        'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT', 1, ...
        'ATGCV:MOD_ANA:CAL_TYPE_INCONSISTENT', 1);
end


%% import works with inconsistent data types
try
    ut_messenger_reset(stEnv.hMessenger);
    i_setMismatchAccept(true)
    stOpt = struct('sTlModel', sModel);
    stOpt.bAdaptiveAutosar = false;
    
    sMaFile = ut_m01_model_analysis(stEnv, stOpt);
    atgcv_m01_tlcheck(stEnv, sMaFile);
    
    nExpected = 0;
    astRes = mxx_xmltool(sErrFile, '//Message', 'msg');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'Expected %i but got %i messages in messenger report.', ...
        nExpected, nFound));
    
    nExpected = 3;
    astRes = mxx_xmltool(sMaFile, '//ma:Subsystem ', 'tlPath');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'Expected %i but got %i subsystems in model analysis.', ...
        nExpected, nFound));
    
    nExpected = 2;
    astRes = mxx_xmltool(sMaFile, '//ma:Calibration ', 'tlBlockPath');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'Expected %i but got %i calibrations in model analysis.', ...
        nExpected, nFound));
catch oEx
    MU_FAIL(sprintf('Unexpected exception: "%s".', oEx.message));
end
end


%%
function i_setMismatchAccept(bDoAccept)
if bDoAccept
    atgcv_global_property_set('accept_inport_type_inconsistent', 'on');
else
    atgcv_global_property_set('accept_inport_type_inconsistent', 'off');
end
end