function ut_m_sl_model_open
% Test of atgcv_m_model_open and atgcv_m_model_close for a Simulink model.
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

%% free resources
bdclose all; dsdd_free();

%% main variables 
% assumption: pwd == .../m/tst/tmpdir
sPwd         = pwd;
sRootDir     = fullfile(pwd, 'mxx_sl_model_open');
sDataDir     = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata', 'tiny_sl_model');
sModel1      = 'tiny_sl_model';
sModel2      = 'tiny_sl_model_copy';
sModelFile1  = fullfile(sRootDir, [sModel1, '.mdl']);
sModelFile2  = fullfile(sRootDir, [sModel2, '.mdl']);


%% create root_dir for test and copy testdata
try
    if exist(sRootDir, 'file')
        rmdir(sRootDir, 's');
    end
    copyfile(sDataDir, sRootDir);
    cd(sRootDir);
    
    sTmpDir = fullfile(pwd(), 'tmp');
    atgcv_m_mkdir(sTmpDir);
    sResDir = fullfile(pwd(), 'res');
    atgcv_m_mkdir(sResDir);
    
    stEnv = struct();
    stEnv.sTmpPath    = sTmpDir;
    stEnv.sResultPath = sResDir;
    stEnv.hMessenger  = 0;
catch
    stErr = atgcv_lasterror();
    cd(sPwd);
    MU_FAIL_FATAL(sprintf('Could not create root_dir for test: "%s."', ...
        stErr.message));
end


%% upgrade models
try
    tu_test_model_adapt(sModelFile1);
    tu_test_model_adapt(sModelFile2);
    
    bdclose all; dsdd_free();
catch
    MU_FAIL_FATAL(lasterr);
end

%% stub
try
    bdclose all; dsdd_free();
    i_stubUseTl();
    i_stubDsdd();
catch
    MU_FAIL_FATAL(lasterr);
end


%%
stOpen1 = [];
try
    stOpen1 = atgcv_m_model_open(stEnv, sModelFile1, {}, false);
catch
    MU_FAIL(lasterr);
end

%%
stOpen2 = [];
try
    stOpen2 = atgcv_m_model_open(stEnv, sModelFile2, {}, false);
    
    MU_ASSERT_TRUE(isempty(stOpen2.sDdFile), ...
        'Wrong info by model_open: SL model should have _no_ DD file.');
catch
    MU_FAIL(sprintf('BTS/33010 not fixed: %s.', lasterr()));
end


%%
try
    if ~isempty(stOpen1)
        atgcv_m_model_close(stEnv, stOpen1);
    end
catch
    MU_FAIL(lasterr);
end


%%
try
    if ~isempty(stOpen2)
        atgcv_m_model_close(stEnv, stOpen2);
    end
catch
    MU_FAIL(lasterr);
end


%% !! revert !! very important because of stubs
try
    cd(sPwd);
    bdclose all; dsdd_free(); clear mex;
    rmdir(sRootDir, 's');
catch
    stErr = lasterror();
    MU_FAIL(sprintf( ...
        'Cleanup failed! Test might have side-effects because of stubbing. %s', ...
        stErr.message));
end
end





%%
% emulate that TL does not exist
function i_stubUseTl()
fileID = fopen('atgcv_use_tl.m', 'w');
fprintf(fileID, 'function bOut = atgcv_use_tl()\n');
fprintf(fileID, 'bOut = false;\n');
fclose(fileID);
MU_ASSERT_FALSE(~exist('atgcv_use_tl.m', 'file'), 'Sometimes the file creation is not fast enough.')
end


% emulate that TL does not exist
function i_stubDsdd()
fileID = fopen('dsdd.m', 'w');
fprintf(fileID, 'function varargout = dsdd(varargin)\n');
fprintf(fileID, 'error(''should never be called for TL-free environment'');\n');
fclose(fileID);
MU_ASSERT_FALSE(~exist('dsdd.m', 'file'), 'Sometimes the file creation is not fast enough.')
end


%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
