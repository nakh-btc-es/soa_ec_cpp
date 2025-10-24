function ut_ar_raname_fuelsys
%


%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'ar_rename_fuelsys';
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


%% act
stOpt = struct( ...
    'sTlModel',  sModel, ...
    'xEnv',      xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);


%% assert
sExpectedTlArch = fullfile(sTestDataDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end


function xxx
%% clean up first
ut_cleanup();

%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd     = pwd;
sRootDir = fullfile(pwd, 'mt01_autosar_01');

if verLessThan('tl', '5.2')
    sDataDir = fullfile(ut_local_testdata_dir_get(), 'AUTOSAR', 'tl41', 'ar_fuelsys');
else
    sDataDir = fullfile(ut_local_testdata_dir_get(), 'AUTOSAR', 'tl52', 'ar_fuelsys');
end
sModelName   = 'TL_Fuelsys';
sModelFile   = fullfile(sRootDir, [sModelName, '.mdl']);
sDdFile      = fullfile(sRootDir, [sModelName, '.dd']);
sInitCmd     = 'start';
sInitFile    = fullfile(sRootDir, [sInitCmd, '.m']);


%% create root_dir for test and copy testdata
try
    if exist(sRootDir, 'file')
        rmdir(sRootDir, 's');
    end
    ut_m01_copyfile(sDataDir, sRootDir);
    cd(sRootDir);
    
    stEnv = ut_messenger_env_create(pwd);
    ut_messenger_reset(stEnv.hMessenger);
    
catch oEx
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Could not create root_dir for test: "%s."', ...
        oEx.message));
end


%% update and open model
try
    ut_m01_tu_test_model_adapt(sModelFile, sInitFile);        
    load_system(sModelFile);
    evalin('base', sInitCmd);

catch oEx
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', oEx.message));
end


%% model_ana
try
    stOpt = struct( ...
        'sTlModel',      sModelName, ...
        'sDdPath',       sDdFile, ...
        'bCalSupport',   false, ...
        'bDispSupport',  true, ...
        'bParamSupport', true);
    
    [sMaFile, sErrFile] = ut_m01_model_analysis(stEnv, stOpt);

    % check that no IO variable is a Dummy Variable (BTS/16777)
    astRes = mxx_xmltool(sMaFile, '//ma:Variable[@isDummy="yes"]', 'varid');
    MU_ASSERT_TRUE(isempty(astRes), 'Unexpected: Dummy variable found.');
    
    astRes = mxx_xmltool(sMaFile, '//ma:Variable[@typeName="struct SensorsStruct_tag"]', 'varid');
    astRes2 = mxx_xmltool(sMaFile, '//ma:Variable[@typeName="SensorsStruct"]', 'varid');
    if(atgcv_version_p_compare('TL3.4') >= 0)
        MU_ASSERT_TRUE(isempty(astRes) && length(astRes2) == 12, ...
            'TL3.4 produces Struct typedefs without the according Struct-Tag.')
    else
        MU_ASSERT_TRUE(isempty(astRes2) && length(astRes) == 12, ...
            'TargetLink produces Struct typedefs with the according Struct-Tag.')
    end
    
    sModuleName = 'Rte.c';
    sProxyName  = 'Task_Run_AirflowCalculation';
    if (atgcv_version_p_compare('TL4.1') >= 0)
        sProxyName = 'Task_Run_AirflowCalculation_Wrapper';
        sModuleName = 'TL_FuelRateController_ARfrm.c';
    end
    sStepFct = 'Run_AirflowCalculation';
    stExp = struct( ...
        'kind',    'proxyStep', ...
        'name',    sProxyName, ...
        'module',  sModuleName, ...
        'storage', 'global');
    i_checkProxy(sMaFile, sStepFct, stExp);
    
    sProxyName = 'Task_Run_AirflowCorrection';
    if (atgcv_version_p_compare('TL4.1') >= 0)
        sProxyName = 'Task_Run_AirflowCorrection_Wrapper';
    end
    sStepFct = 'Run_AirflowCorrection';
    stExp = struct( ...
        'kind',    'proxyStep', ...
        'name',    sProxyName, ...
        'module',  sModuleName, ...
        'storage', 'global');
    i_checkProxy(sMaFile, sStepFct, stExp);
    
catch oEx
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', oEx.message));
end


%% test
try
    nExpectedSub = 8;
    
    astRes = mxx_xmltool(sMaFile, '//ma:Subsystem', 'tlPath');
    nFound = length(astRes);
    MU_ASSERT_TRUE(nFound == nExpectedSub, sprintf( ...
        'Expected %d subsystems instead of %d.', nExpectedSub, nFound));
        
catch oEx
    mxx_xmltree('clear', hDoc);
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', oEx.message));
end

%% end
i_cleanup(sModelName, sRootDir, sPwd);
ut_cleanup();
end


%%
function i_checkProxy(sMaFile, sStepFct, stExp)
casProps = fieldnames(stExp);
astFound = mxx_xmltool(sMaFile, ...
    sprintf('//ma:Subsystem[@stepFct="%s"]/ma:Function', sStepFct), ...
    casProps{:});
if(atgcv_version_p_compare('TL3.4') >= 0)
    if (length(astFound) == 1)
        MU_ASSERT_TRUE(isequal(astFound, stExp), sprintf( ...
            'Properties are not as expected for Function "%s".', sStepFct));
    else
        MU_FAIL(sprintf('Proxy not found for Function "%s".', sStepFct));
    end
else
    MU_ASSERT_TRUE(isempty(astFound), ...
        'There are no Proxy Functions expected for TL below TL3.4.');
end
end




%% i_cleanup
function i_cleanup(sModel, sTestRoot, sPwd)
cd(sPwd);
try
    close_system(sModel, 0);
    dsdd('Close', 'Save', 'off');    
    rmdir(sTestRoot, 's');
catch oEx
    warning('UT:ERROR', 'Cleanup failed: %s', oEx.message);
end
end

