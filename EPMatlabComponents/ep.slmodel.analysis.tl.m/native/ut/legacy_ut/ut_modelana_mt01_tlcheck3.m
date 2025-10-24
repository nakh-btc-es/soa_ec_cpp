function ut_modelana_mt01_tlcheck3
% test for TL check in context BTS/35114
%
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Alexander.Hornstein@osc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 86015 $ 
%   Last modified: $Date: 2011-04-26 10:06:58 +0200 (Di, 26 Apr 2011) $ 
%   $Author: ahornste $



%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd       = pwd();
sRootDir   = fullfile(sPwd, 'mt01_tlcheck3');
sDataDir   = fullfile(ut_local_testdata_dir_get(), 'bug_35114');
sMaFile    = fullfile(sRootDir, 'ModelAnalysis.xml');
sMaDtdFile = ut_m01_get_ma_dtd();


bDoAcceptOrig = i_getMismatchAccept();

%% FIXTURE
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
    MU_FAIL_FATAL(sprintf('Failed creating TestEnv: %s', oEx.message));
end


%% TEST (Do not accept Mismatches)
try
    i_setMismatchAccept(false);
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr==0, sprintf( ...
        'PreReq failed: Input ModelAnalysis file invalid: %s', sErr));
    
    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    try
        atgcv_m01_tlcheck(stEnv, sMaFile); 
        MU_FAIL('Missing expected exception.');
        
    catch oEx
        sExpected = 'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT';
        MU_ASSERT_TRUE(strcmpi(oEx.identifier, sExpected), sprintf( ...
            'Expected Exception %s instead of %s.', ...
            sExpected, oEx.identifier));
    end
    ut_messenger_save(stEnv.hMessenger, sErrFile);    
    ut_assert_msg_count(sErrFile, 'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT', 2);
    
catch oEx
    cd(sPwd);
    MU_FAIL(sprintf('Unexpected exception during Test: %s', oEx.message));
end


%% TEST (Accept Mismatches)
% expect that Errors are entered into Report but do not lead to an Exception
try
    i_setMismatchAccept(true);
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr==0, sprintf( ...
        'PreReq failed: Input ModelAnalysis file invalid: %s', sErr));
    
    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    atgcv_m01_tlcheck(stEnv, sMaFile); 
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    ut_assert_msg_count(sErrFile, 'ATGCV:MOD_ANA:INPORT_TYPE_INCONSISTENT', 0);
    
catch oEx
    cd(sPwd);
    MU_FAIL(sprintf('Unexpected exception during Test: %s', oEx.message));
end


%% CLEANUP
try
    i_setMismatchAccept(bDoAcceptOrig);
    cd(sPwd);
    rmdir(sRootDir, 's');
catch oEx
    cd(sPwd);
    MU_FAIL(sprintf('Unexpected exception CLEANUP: %s', oEx.message));
end
end



%%
function bDoAccept = i_getMismatchAccept()
try
    sFlag = atgcv_global_property_get('accept_inport_type_inconsistent');
catch
    sFlag = 'off';
end
if any(strcmpi(sFlag, {'1', 'on', 'true', 'yes'}))
    bDoAccept = true;
else
    bDoAccept = false;
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



