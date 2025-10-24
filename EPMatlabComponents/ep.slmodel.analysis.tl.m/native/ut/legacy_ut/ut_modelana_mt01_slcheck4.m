function ut_modelana_mt01_slcheck4
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
%   $Revision: 135234 $ 
%   Last modified: $Date: 2013-02-28 13:55:04 +0100 (Do, 28 Feb 2013) $ 
%   $Author: ahornste $


%% clean up first
ut_cleanup();


%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd               = pwd;
sRootDir           = fullfile(pwd, 'mt01_slcheck4');
sDataDir           = fullfile(ut_local_testdata_dir_get(), 'sl_tl_signal_types2');
sModelNameTl       = 'tl_model';
sModelNameSl       = 'sl_model';
sModelFileTl       = fullfile(sRootDir, [sModelNameTl, '.mdl']);
sModelFileSl       = fullfile(sRootDir, [sModelNameSl, '.mdl']);
sMaDtdFile         = ut_m01_get_ma_dtd();

sMaStored = fullfile(sRootDir, 'ModelAnalysis.xml');


%% create root_dir for test and copy testdata
try
    if exist(sRootDir, 'file')
        rmdir( sRootDir, 's');
    end
    ut_m01_copyfile(sDataDir, sRootDir);
    cd(sRootDir);
    
    stEnv = ut_messenger_env_create(pwd);
    ut_messenger_reset(stEnv.hMessenger);
    
catch
    stErr = atgcv_lasterror;
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% update/open TL and SL model
try
    ut_m01_tu_test_model_adapt(sModelFileSl);        
    %ut_m01_tu_test_model_adapt(sModelFileTl);        
    %load_system(sModelNameTl);
    load_system(sModelNameSl);
    
catch
    stErr = osc_lasterror();
    i_cleanup(sModelNameTl, sModelNameSl, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end

%% model_ana
try
%     stOpt = struct( ...
%         'sTlModel',      sModelNameTl, ...
%         'sTlModel',      sModelNameSl, ...
%         'sDdPath',       sDdFile, ...
%         'bCalSupport',   false, ...
%         'bDispSupport',  false, ...
%         'bParamSupport', false);
% 
%     ut_messenger_reset(stEnv.hMessenger);
%     stRes = atgcv_model_analysis(stEnv, stOpt);
%     sMaFile = fullfile(stEnv.sResultPath, stRes.sModelAnalysis);
%     MU_ASSERT_TRUE_FATAL(exist(sMaFile, 'file'), ...
%         sprintf('Missing output file: "%s".', sMaFile));
    
    sMaFile = fullfile(stEnv.sResultPath, 'ModelAnalysis.xml');
    copyfile(sMaStored, sMaFile)
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr == 0, sprintf('Invalid ModelAnalysis output: %s', sErr));
            
catch
    stErr = osc_lasterror();
    i_cleanup(sModelNameTl, sModelNameSl, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% SL check
try
    sErrFile = fullfile(pwd, 'tmp_error.xml');
    if exist(sErrFile, 'file')
        delete(sErrFile);
    end
    sMaFileNewName = 'ModelAnaNew.xml';
    sMaFileNew = fullfile(fileparts(sMaFile), sMaFileNewName);
    
    % function call
    ut_messenger_reset(stEnv.hMessenger);
    atgcv_m01_slcheck(stEnv, sMaFile, sMaFileNewName);    
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % checking outputs
    MU_ASSERT_TRUE( exist(sMaFileNew, 'file'), ...
        sprintf('Could not produce output file: "%s".', sMaFileNew) );
    MU_ASSERT_TRUE( exist(sErrFile, 'file'), ...
        sprintf('Could not produce error file: "%s".', sErrFile) );
    
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFileNew);
    MU_ASSERT_TRUE(nErr == 0, ...
        sprintf('Modified ModelAna file "%s" invalid: "%s".', sMaFileNew, sErr));
    
    astRes = mxx_xmltool(sMaFileNew, '//ma:Port//ma:ifName', ...
        'signalType', 'slSignalType');
    nExp = 20; %expecting 10 input signals
    MU_ASSERT_TRUE((length(astRes) == nExp), sprintf(...
        'Expected %d instead of %d input signals.', nExp, length(astRes)));
    for i = 1:length(astRes)
        MU_ASSERT_TRUE(~isempty(astRes(i).slSignalType), ...
            'Found signal with empty Simulink signal type.');
        
        MU_ASSERT_TRUE(~strcmpi(astRes(i).signalType, astRes(i).slSignalType), ...
            'Unexpected: Found signal with the same TL and SL type.');
    end
    
%     % get original number of Ports with SL-paths
%     sXpath = '//ma:Port[@slPath]';
%     astRes = mxx_xmltool(sMaCorrect, sXpath, 'tlPath');
%     nCorrectPortNum = length(astRes);
%     
%     % get new number of Ports with SL-paths
%     astRes = mxx_xmltool(sMaFile, sXpath, 'tlPath');
%     nFoundPortNum = length(astRes);
%     
%     % all should be found
%     MU_ASSERT_TRUE(nFoundPortNum == nCorrectPortNum, ...
%         'All ports should have been found in SL model.');
    
    % expecting no messages in error report
    nExpected = 20;
    astRes = mxx_xmltool(sErrFile, '//Message', 'type', 'msg');
    nFound = length(astRes);
    MU_ASSERT_EQUAL(nExpected, nFound, sprintf( ...
        'Expected %i but got %i warnings in messenger report.', ...
        nExpected, nFound));
    
catch
    stErr = osc_lasterror();
    i_cleanup(sModelNameTl, sModelNameSl, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% cleanup
i_cleanup(sModelNameTl, sModelNameSl, sRootDir, sPwd);
ut_cleanup();
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%% internal functions

%% i_cleanup
function i_cleanup(sModelTl, sModelSl, sTestRoot, sPwd)
cd(sPwd);
%close_system(sModelTl, 0);
close_system(sModelSl, 0);
dsdd('Close', 'Save', 'off');
clear mex; rmdir(sTestRoot, 's');
end

