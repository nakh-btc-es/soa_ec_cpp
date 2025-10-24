function ut_modelana_mt01_slcheck2
% test for SL consistency check
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
%   $Revision: 209521 $ 
%   Last modified: $Date: 2016-03-04 08:14:43 +0100 (Fr, 04 Mrz 2016) $ 
%   $Author: ahornste $


%% clean up first
ut_cleanup();


%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd               = pwd;
sRootDir           = fullfile(pwd, 'mt01_slcheck2');
sDataDir           = fullfile(ut_local_testdata_dir_get(), 'slcheck2');
sModelName         = 'slcheck2';
sModelFile         = fullfile(sRootDir, [sModelName, '.mdl']);
sMaCorrect         = fullfile(sRootDir, 'ModelAnalysis.xml');
sMaExtraOut        = fullfile(sRootDir, 'ModelAnalysis_extra_out.xml');
sMaExtraIn         = fullfile(sRootDir, 'ModelAnalysis_extra_in.xml');
sMaExtraInChart    = fullfile(sRootDir, 'ModelAnalysis_extra_in_chart.xml');
sMaWrongIn         = fullfile(sRootDir, 'ModelAnalysis_wrong_in.xml');
sMaWrongOut        = fullfile(sRootDir, 'ModelAnalysis_wrong_out.xml');
sMaWrongInNum      = fullfile(sRootDir, 'ModelAnalysis_wrong_in_num.xml');
sMaWrongOutNum     = fullfile(sRootDir, 'ModelAnalysis_wrong_out_num.xml');
sMaDtdFile         = ut_m01_get_ma_dtd();



%% create root_dir for test and copy testdata
try
    if exist(sRootDir, 'file')
        rmdir( sRootDir, 's');
    end
    ut_m01_copyfile(sDataDir, sRootDir);
    cd(sRootDir);
    
    stEnv = ut_messenger_env_create(pwd);
    ut_messenger_reset(stEnv.hMessenger);
    
    sMaNew   = 'modifed_ma.xml';
    sMaFile  = fullfile(stEnv.sResultPath, sMaNew);
    sErrFile = fullfile(pwd, 'tmp_error.xml');
catch
    stErr = atgcv_lasterror;
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% open SL model
try
    ut_m01_tu_test_model_adapt(sModelFile);        
    load_system(sModelName);
    
catch
    stErr = osc_lasterror();
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% SL check 1
% consistent with ModelAnalysis
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaCorrect);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaCorrect, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaCorrect, sMaNew);    
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % checking outputs
    MU_ASSERT_TRUE( exist(sMaFile, 'file'), sprintf('Could not produce output file: "%s".', sMaFile) );
    MU_ASSERT_TRUE( exist(sErrFile, 'file'), sprintf('Could not produce error file: "%s".', sErrFile) );
    
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr == 0, ...
        sprintf('Modified ModelAna file "%s" invalid: "%s".', sMaFile, sErr));
    
    % get original number of Ports with SL-paths
    sXpath = '//ma:Port[@slPath]';
    astRes = mxx_xmltool(sMaCorrect, sXpath, 'tlPath');
    nCorrectPortNum = length(astRes);
    
    % get new number of Ports with SL-paths
    astRes = mxx_xmltool(sMaFile, sXpath, 'tlPath');
    nFoundPortNum = length(astRes);
    
    % all should be found
    MU_ASSERT_TRUE(nFoundPortNum == nCorrectPortNum, 'All ports should have been found in SL model.');
    
catch
    stErr = osc_lasterror();
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end



%% SL check 2
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaExtraOut);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaExtraOut, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaExtraOut, sMaNew);    
    
    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end



%% SL check 3
% missing Inport should lead to exception
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaExtraIn);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaCorrect, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaExtraIn, sMaNew);    

    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end



%% SL check 4
% missing Inport in Chart should lead to exception
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaExtraInChart);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaExtraInChart, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaExtraInChart, sMaNew);    

    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end


%% SL check 5
% wrongly named Input should lead to exception
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaWrongIn);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaWrongIn, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaWrongIn, sMaNew);    

    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception for missing Inport.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end


%% SL check 6
% wrongly named Output should lead to exception
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaWrongOut);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaWrongOut, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaWrongOut, sMaNew);    

    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception for missing Outport.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
    
    % maybe check also the report
end


%% SL check 7
% wrong Input port number should lead to exception
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaWrongInNum);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaWrongInNum, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaWrongInNum, sMaNew);    

    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception for wrong Inport port number.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end


%% SL check 8
% wrong Output port number should lead to exception
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaWrongOutNum);
    MU_ASSERT_TRUE(nErr==0, sprintf('ModelAna input file "%s" invalid: "%s".', sMaWrongOutNum, sErr));
    if exist(sMaFile, 'file')
        delete(sMaFile);
    end
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaWrongOutNum, sMaNew);    

    % since expecting an exception, should never get here
    MU_FAIL('Missing expected exception for wrong Outport port number.');
    
catch
    stErr = osc_lasterror();
    ut_messenger_save(stEnv.hMessenger, sErrFile);
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end


%% end
i_cleanup(sModelName, sRootDir, sPwd);
ut_cleanup();
end





%%
function i_cleanup(sModel, sTestRoot, sPwd)
cd(sPwd);
close_system(sModel, 0);
dsdd('Close', 'Save', 'off');
dsdd_free;
clear mex; rmdir(sTestRoot, 's'); %#ok<CLMEX>
end

