function it_ep_test_slmdl_error_sil_pil()
% Tests the ep_sim_* method
%
%  it_ep_test_slmdl_error_sil_pil()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

%% clean up first
ep_tu_cleanup();

dos('xcopy /k /r /i /c /y /s "..\data\adder\*.*" "."');

sPwd = pwd;
%% Test Case 
try
   
    xEnv = EPEnvironment();
    sSimEnvModel =  fullfile(sPwd,'adder_sl.mdl');
    stParam.sModelFile = sSimEnvModel;
    stParam.caInitScripts = {fullfile(sPwd,'adder_init.m')};
    stParam.bIsTL = false;
    stParam.bCheck = true;
    stParam.casAddPaths = {}; % TODO add by API
    stParam.bActivateMil = true;
    stOpenInfo = ep_core_model_open(xEnv, stParam);
    
    
    sSkeleton = fullfile(sPwd,'init_skeleton.xml' );
    sInitFile = fullfile(sPwd,'init.xml');
    nSteps = 3;
    dTime = 0.1;
    dValue = 1;
    util_bl_create_init_file(sSkeleton,sInitFile, nSteps, dTime, dValue);
    try
        nPILTimeout = int16(0);
        bUseTldsStubs = false;
        bEnableCleanCode = false;
        ep_simenv_init(xEnv, sSimEnvModel, ...
            sInitFile, 'SIL', 'accelerator', '', true, ...
            bUseTldsStubs, nPILTimeout, bEnableCleanCode);
    catch exception
        MU_ASSERT_EQUAL(exception.identifier,'EP:SIM:BUILD_FAILURE');
    end
    
    try
        nPILTimeout = int16(0);
        bUseTldsStubs = false;
        bStepByStep = true;
        bEnableCleanCode = false;
        ep_simenv_init(xEnv, sSimEnvModel, ...
            sInitFile, 'PIL', 'accelerator', '', bStepByStep, ...
            bUseTldsStubs, nPILTimeout, bEnableCleanCode);
    catch exception
        MU_ASSERT_EQUAL(exception.identifier,'EP:SIM:BUILD_FAILURE');
    end
    ep_simenv_close(xEnv,sSimEnvModel);
    ep_core_model_close(xEnv, stOpenInfo);
    
   
    
catch exception
     MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end


ep_tu_cleanup();

return;