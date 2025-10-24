function ut_m_model_open_close
% Test of atgcv_m_model_open and atgcv_m_model_close.
%
% function ut_m_model_open_close
%
% #Further Descriptions#
%
%   PARAMETER(S)    DESCRIPTION
%   -
%
%   OUTPUT
%   -
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$

disp('Test of atgcv_m_model_open and atgcv_m_model_close');

if atgcv_version_compare('ML7.12') >= 0
    dos('copy "..\testdata\testdata_TL33\*.*" "."');
else
    dos('copy "..\testdata\*.*" "."');
end
bdclose all; dsdd('Close', 'Save', 'off');

% upgrad the data dictionary if the target link version greater
% or equal TL2.2
util_close_all_dd;
util_upgrade_all_dd;

% prepare directories
sPwd = pwd;
[bSuccess,sMsg] = atgcv_m_mkdir(sPwd,'tmp');
MU_ASSERT_TRUE(bSuccess);
sTmpPath = fullfile(sPwd,'tmp');
[bSuccess,sMsg] = atgcv_m_mkdir(sPwd,'result');
MU_ASSERT_TRUE(bSuccess);
sResultPath = fullfile(sPwd,'result');

stEnv.sTmpPath    = sTmpPath;
stEnv.sResultPath = sResultPath;
stEnv.hMessenger  = 0;

sTlModel = fullfile(pwd, 'sf_demo_tl30.mdl');
sDD      = fullfile(pwd, 'sf_demo_tl30.dd');
sInit    = fullfile(pwd, 'start_tl30.m');

% upgrade model
try
    tu_test_model_adapt(sTlModel, sInit);
catch
    MU_FAIL_FATAL(lasterr);
end
 

%******************************************************************************
%  Description: Test:.
%  Open model with start script, do init
try

    bIsTL = true;
    bCheck = true;
        caInitScripts{1} = fullfile(pwd,'start_tl30.m');
        dsdd_manage_project('Open','sf_demo_tl30.dd');

    stRes = atgcv_m_model_open( ...
        stEnv, ...
        fullfile(pwd,'sf_demo_tl30.mdl'), ...
        caInitScripts, ...
        bIsTL, ...
        bCheck);
catch
    MU_FAIL(lasterr);
end


%******************************************************************************
%  Description: Test:
%  close model
try
    atgcv_m_model_close(stEnv,stRes);
catch
    MU_FAIL(lasterr);
end


%******************************************************************************
%  Description: Test:.
%  Open model without start script, do init
try
    dsdd('Close', 'save', 'off');
        dsdd_manage_project('Open','sf_demo_tl30.dd');

    stRes = atgcv_m_model_open( ...
        stEnv, ...
        fullfile(pwd,'sf_demo_tl30.mdl'), ...
        {}, ...
        bIsTL, ...
        bCheck);
catch
    MU_FAIL(lasterr);
end


%******************************************************************************
%  Description: Test:.
%  close model
try
    atgcv_m_model_close(stEnv,stRes);
catch
    MU_FAIL(lasterr);
end
end

