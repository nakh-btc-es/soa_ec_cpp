function ut_modelana_mt01_tlcheck4
% check fix for BTS/35382
%
%   Boolean signal type is found in Model for which the TL Code Variable is a
%   dummy variable. --> be robust here and do not show any messages
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
sRootDir   = fullfile(sPwd, 'mt01_tlcheck4');
sDataDir   = fullfile(ut_local_testdata_dir_get(), 'bug_35382');
sMaFile    = fullfile(sRootDir, 'ModelAnalysis.xml');
sMaDtdFile = ut_m01_get_ma_dtd();



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


%% TEST
try
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr==0, sprintf( ...
        'PreReq failed: Input ModelAnalysis file invalid: %s', sErr));
    
    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call should not throw and also not create any Error messages!
    atgcv_m01_tlcheck(stEnv, sMaFile);         
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    nExpected = 0;
    astRes = mxx_xmltool(sErrFile, '//Message', 'msg');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'Expected %i but got %i errors in messenger report.', ...
        nExpected, nFound));
    
catch oEx
    cd(sPwd);
    MU_FAIL(sprintf( ...
        'BTS/35382 maybe not fixed. Unexpected exception: %s', oEx.message));
end



%% CLEANUP
try
    cd(sPwd);
    rmdir(sRootDir, 's');
catch oEx
    cd(sPwd);
    MU_FAIL(sprintf('Unexpected exception CLEANUP: %s', oEx.message));
end
end

