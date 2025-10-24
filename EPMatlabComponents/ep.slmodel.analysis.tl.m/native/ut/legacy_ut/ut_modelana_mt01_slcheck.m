function ut_modelana_mt01_slcheck
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
sRootDir           = fullfile(pwd, 'test_root_slcheck');
sDataDir           = fullfile(ut_local_testdata_dir_get(), 'logmap');
sModelName         = 'log_map_sl';
sModelFile         = fullfile(sRootDir, [sModelName, '.mdl']);
sInitCmd           = 'start_model';
sInitScript        = fullfile(sRootDir, [sInitCmd, '.m']);
sMaOrigFile        = fullfile(sRootDir, 'ModelAnalysis.xml');
sMaFakeFile        = fullfile(sRootDir, 'ModelAnalysis_fake.xml');
sMaMissingCalFile  = fullfile(sRootDir, 'ModelAnalysis_missing_CAL.xml');
sMaMissingCalFile2 = fullfile(sRootDir, 'ModelAnalysis_missing_CAL2.xml');
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
    stErr = atgcv_lasterror;
    cd(sPwd);
    MU_FAIL_FATAL(['could not create root_dir for test: ', stErr.message]);
end


%% open SL model
try
    ut_m01_tu_test_model_adapt(sModelFile, sInitScript);        
    load_system(sModelName);
    evalin('base', sInitCmd);
    
catch
    stErr = osc_lasterror();
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end



%% SL check 1
% two missing Diplay variables should be noted by SL-check
% one a TL-port and one a SF-variable
try
    % just checking prereq:
    % 1) MA should be valid
    % 2) Display TL-port with attribute slBlockPath
    % 3) Display SF variable with attribute slBlockPath
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaOrigFile);
    MU_ASSERT_TRUE(nErr==0, ['Orig MA file invalid: ', sErr]);
    astRes = mxx_xmltool(sMaOrigFile, ...
        ['//ma:Display[@slBlockPath and @tlBlockPath=', ...
        '"log_map_tl/log_map_synchro/Subsystem/log_map_synchro/In1_"]'], ...
        'tlBlockPath');
    MU_ASSERT_TRUE(length(astRes)==1, 'could not find expected Display port');
    astRes = mxx_xmltool(sMaOrigFile, ...
        ['//ma:Display[@slBlockPath and @tlBlockPath=', ...
        '"log_map_tl/log_map_synchro/Subsystem/log_map_synchro/useless_chart" ', ...
        'and @sfVariable="chart_internal2"]'], ...
        'tlBlockPath');
    MU_ASSERT_TRUE(length(astRes)==1, 'could not find expected Display SF-var');
    
    sNewMa = 'newModelAnalysis.xml';
    sErrFile = 'tmp_error.xml';
    ut_messenger_reset(stEnv.hMessenger);
    
    % function call
    atgcv_m01_slcheck(stEnv, sMaOrigFile, sNewMa);    
    ut_messenger_save(stEnv.hMessenger, sErrFile);

    % checking outputs
    sMaFile = fullfile(stEnv.sResultPath, sNewMa);
    MU_ASSERT_TRUE( exist(sMaFile, 'file'), ...
        ['could not produce output file: ', sMaFile] );
    
    % checking output
    % 1) new MA should be valid
    % 2) Display TL-port without attribute slBlockPath
    % 3) Display SF variable without attribute slBlockPath
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFile);
    MU_ASSERT_TRUE(nErr == 0, sErr);
    astRes = mxx_xmltool(sMaFile, ...
        ['//ma:Display[@slBlockPath and @tlBlockPath=', ...
        '"log_map_tl/log_map_synchro/Subsystem/log_map_synchro/In1_"]'], ...
        'tlBlockPath');
    MU_ASSERT_TRUE(isempty(astRes), 'Display port has still SL attribute');
    astRes = mxx_xmltool(sMaFile, ...
        ['//ma:Display[@tlBlockPath=', ...
        '"log_map_tl/log_map_synchro/Subsystem/log_map_synchro/In1_"]'], ...
        'tlBlockPath');
    MU_ASSERT_TRUE(length(astRes)==1, 'Display port not found at all');
    astRes = mxx_xmltool(sMaFile, ...
        ['//ma:Display[@slBlockPath and @tlBlockPath=', ...
        '"log_map_tl/log_map_synchro/Subsystem/log_map_synchro/useless_chart" ', ...
        'and @sfVariable="chart_internal2"]'], ...
        'tlBlockPath');
    MU_ASSERT_TRUE(isempty(astRes), 'Display SF-var has still SL attribute');
    astRes = mxx_xmltool(sMaFile, ...
        ['//ma:Display[@tlBlockPath=', ...
        '"log_map_tl/log_map_synchro/Subsystem/log_map_synchro/useless_chart" ', ...
        'and @sfVariable="chart_internal2"]'], ...
        'tlBlockPath');
    MU_ASSERT_TRUE(length(astRes)==1, 'Display SF-var not found at all');
    
    % expecting just 2 warnings in messenger report
    ut_assert_msg_count(sErrFile, 'ATGCV:MOD_ANA:SL_SFDISP_NOT_FOUND', 1, 'ATGCV:MOD_ANA:SL_DISP_NOT_FOUND', 1);
    
catch
    stErr = osc_lasterror();
    i_cleanup(sModelName, sRootDir, sPwd);
    MU_FAIL_FATAL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% SL check 2
% wrong hierarchy should lead to exception here
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaFakeFile);
    MU_ASSERT_TRUE(nErr==0, ['Fake MA file invalid: ', sErr]);
    
    sNewMa = 'newModelAnalysis.xml';
    
    % function call
    atgcv_m01_slcheck(stEnv, sMaFakeFile, sNewMa);  
    
    % since expecting an exception, should never get here
    MU_FAIL('missing expected exception');
    
catch
    stErr = osc_lasterror();
    MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
end


%% SL check 3
% missing CAL (TL_block) variable should 
% a) for ExplicitParam lead to warnings
% b) for LimitedBlockset lead to exceptions 
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaMissingCalFile);
    MU_ASSERT_TRUE(nErr==0, ['Fake MA file invalid: ', sErr]);
    
    sTmpMa = fullfile(pwd, 'ma.xml');
    if exist(sTmpMa, 'file')
        delete(sTmpMa);
    end
    copyfile(sMaMissingCalFile, sTmpMa);
    i_changeCalUsage(sTmpMa, 'explicit_param');
    
    sNewMa = 'newModelAnalysis.xml';
    
    % function call
    atgcv_m01_slcheck(stEnv, sTmpMa, sNewMa);  
    
    try
        i_changeCalUsage(sTmpMa, 'const');
        atgcv_m01_slcheck(stEnv, sTmpMa, sNewMa);  
        
        % since expecting an exception, should never get here
        MU_FAIL('missing expected exception');
    catch
        stErr = osc_lasterror();
        MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
    end
    
catch
    stErr = osc_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% SL check 4
% missing CAL (SF_chart) variable should lead to exception here
try
    % just checking prereq
    [nErr, sErr] = atgcv_m_xmllint(stEnv, sMaDtdFile, sMaMissingCalFile2);
    MU_ASSERT_TRUE(nErr==0, ['Fake MA file invalid: ', sErr]);
    
    sTmpMa = fullfile(pwd, 'ma.xml');
    if exist(sTmpMa, 'file')
        delete(sTmpMa);
    end
    copyfile(sMaMissingCalFile2, sTmpMa);
    i_changeCalUsage(sTmpMa, 'explicit_param');
    
    sNewMa = 'newModelAnalysis.xml';
    
    % function call
    atgcv_m01_slcheck(stEnv, sTmpMa, sNewMa);  
    
    try
        i_changeCalUsage(sTmpMa, 'const');
        atgcv_m01_slcheck(stEnv, sTmpMa, sNewMa);  
        
        % since expecting an exception, should never get here
        MU_FAIL('missing expected exception');
    catch
        stErr = osc_lasterror();
        MU_PASS(sprintf('Expected exception: "%s".', stErr.message));
    end
    
catch
    stErr = osc_lasterror();
    MU_FAIL(sprintf('Unexpected exception: "%s".', stErr.message));
end


%% end
i_cleanup(sModelName, sRootDir, sPwd);
ut_cleanup();
end



%% i_cleanup
function i_cleanup(sModel, sTestRoot, sPwd)
cd(sPwd);
close_system(sModel, 0);
dsdd('Close', 'Save', 'off');
clear mex; rmdir(sTestRoot, 's');
end


%% i_changeCalUsage
function i_changeCalUsage(sMaFile, sUsage)
hDoc = mxx_xmltree('load', sMaFile);
try
    ahCal = mxx_xmltree('get_nodes', hDoc, '//ma:Calibration');
    for i = 1:length(ahCal)
        mxx_xmltree('set_attribute', ahCal(i), 'usage', sUsage);
    end
    mxx_xmltree('save', hDoc, sMaFile);
catch
end
mxx_xmltree('clear', hDoc);
end

