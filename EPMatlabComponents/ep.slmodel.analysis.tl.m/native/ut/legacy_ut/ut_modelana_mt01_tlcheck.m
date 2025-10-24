function ut_modelana_mt01_tlcheck
% test for TL check
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
%   $Revision: 190068 $ 
%   Last modified: $Date: 2014-12-08 16:32:21 +0100 (Mo, 08 Dez 2014) $ 
%   $Author: ahornste $



%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd               = pwd;
sRootDir           = fullfile(pwd, 'test_root_tlcheck');
sDataDir           = fullfile(ut_local_testdata_dir_get(), 'crowded_interface');
sMaFile            = fullfile(sRootDir, 'ModelAnalysis.xml');
sMa_2manyInputs    = fullfile(sRootDir, 'ModelAnalysis_2many_inputs.xml');
sMa_2manyOutputs   = fullfile(sRootDir, 'ModelAnalysis_2many_outputs.xml');
sMaDtdFile         = ut_m01_get_ma_dtd();



%% create root_dir for test and copy testdata
try
    if exist(sRootDir, 'file')
        rmdir(sRootDir, 's');
    end
    ut_m01_copyfile(sDataDir, sRootDir);
    cd(sRootDir);
    
    stEnv = ut_messenger_env_create(pwd);
    ut_messenger_reset(stEnv.hMessenger);
catch
    stErr = atgcv_lasterror();
    cd(sPwd);
    MU_FAIL_FATAL(['could not create root_dir for test: ', stErr.message]);
end


%% TL check 1
% MA valid --> no exception, no warning
try
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr==0, ['MA file invalid: ', sErr]);
    
    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    atgcv_m01_tlcheck(stEnv, sMaFile);    
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % expecting 0 warning,errors in messenger report
    nExpected = 0;
    astRes = mxx_xmltool(sErrFile, '//Message', 'type', 'msg');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'expected %i but got %i warnings in messenger report', ...
        nExpected, nFound));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(['failed TL check: ', stErr.message]);
end


%% TL check 2
% too many inputs --> since ET2.2 not a warning any longer
try
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMa_2manyInputs);
    MU_ASSERT_TRUE(nErr==0, ['MA file invalid: ', sErr]);

    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    atgcv_m01_tlcheck(stEnv, sMa_2manyInputs);    
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % expecting 0 warning,errors in messenger report
    nExpected = 0;
    astRes = mxx_xmltool(sErrFile, '//Message', 'type', 'msg');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'expected %i but got %i errors in messenger report', ...
        nExpected, nFound));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(['failed TL check: ', stErr.message]);
end


%% TL check 3
% too many outputs --> since ET2.2 not a warning any longer
try
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMa_2manyOutputs);
    MU_ASSERT_TRUE(nErr==0, ['MA file invalid: ', sErr]);

    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    atgcv_m01_tlcheck(stEnv, sMa_2manyOutputs);    
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % expecting 0 warning,errors in messenger report
    nExpected = 0;
    astRes = mxx_xmltool(sErrFile, '//Message', 'type', 'msg');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'expected %i but got %i error in messenger report', ...
        nExpected, nFound));
    
catch
    stErr = atgcv_lasterror();
    MU_FAIL(['failed TL check: ', stErr.message]);
end


%% cleanup
try
    cd(sPwd);
    rmdir(sRootDir, 's');
catch
    stErr = atgcv_lasterror();
    MU_FAIL(['failed cleanup: ', stErr.message]);
end
end






