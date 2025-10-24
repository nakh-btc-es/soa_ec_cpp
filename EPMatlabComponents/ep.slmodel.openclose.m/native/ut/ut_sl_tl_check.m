function ut_sl_tl_check
% checking model kind in atgcv_m_model_open/close
%
% function ut_sl_tl_check
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


%% prepare data
stEnv = struct( ...
    'sTmpPath',    pwd, ...
    'sResultPath', pwd, ...
    'hMessenger',  0);

bdclose all; dsdd('Close', 'Save', 'off');


sParentDir = fileparts(pwd);
sDataPath =  fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata');
sNewDataPath = fullfile(pwd, 'sl_tl_check');
if exist(sNewDataPath, 'dir')
    rmdir(sNewDataPath, 's');
end
copyfile(sDataPath, sNewDataPath);
sDataPath = sNewDataPath;

sTlModel  = fullfile(sDataPath, 'StandardModel_tl.mdl');
sSlModel  = fullfile(sDataPath, 'StandardModel_sl.mdl');
casInitScripts = {fullfile(sDataPath, 'standard_start.m')};

sTlModel2  = fullfile(sDataPath, 'log_map_tl.mdl');
sSlModel2  = fullfile(sDataPath, 'log_map_sl.mdl');
casInitScripts2 = {fullfile(sDataPath, 'logmap_start.m')};

% upgrade model
try
    tu_test_model_adapt(sTlModel, casInitScripts{1});
    tu_test_model_adapt(sSlModel, casInitScripts{1});
catch
    MU_FAIL_FATAL(lasterr);
end
% upgrade model
try
    tu_test_model_adapt(sTlModel2, casInitScripts2{1});
    tu_test_model_adapt(sSlModel2, casInitScripts2{1});
catch
    MU_FAIL_FATAL(lasterr);
end

bCheck = true;

sAllPath = path();
sNewPath = pwd;
while( ~isempty(sNewPath) && ~isempty(strfind(sAllPath, sNewPath)) )
    sNewPath = fileparts(sNewPath);
end
casAddPaths = {sNewPath};


%% regular open/close of TargetLink model
% check also possibility to provide an additional path:
%   make sure a previously not included path is added and removed 
sDdBefore = dsdd('GetEnv', 'ProjectFile');
try
%     stOpen = atgcv_m_model_open(stEnv, sTlModel, casInitScripts, ...
%         bCheck, casAddPaths);
    stArgs=util_prepare_struct(sTlModel, casInitScripts, casAddPaths);
    stOpen = ep_core_model_open(stEnv,stArgs);
    sAllPath1 = path();
    
    atgcv_m_model_close(stEnv, stOpen);
    sAllPath2 = path();
    MU_PASS('model open/close for TargetLink successfull');
catch
    stErr = atgcv_lasterror;
    MU_FAIL_FATAL(['unexpected exception: ', ...
        stErr.identifier, ' ', stErr.message]);
end
sDdAfter = dsdd('GetEnv', 'ProjectFile');
MU_ASSERT_STRING_EQUAL(sDdAfter, sDdBefore, 'DD changed during model open/close');
MU_ASSERT_FALSE(isempty(strfind(sAllPath1, sNewPath)), 'path was not added');
MU_ASSERT_TRUE(isempty(strfind(sAllPath2, sNewPath)), 'path was not removed');


%% regular open/close of Simulink model
% make sure an already existing path is not removed
addpath(sNewPath);
sDdBefore = dsdd('GetEnv', 'ProjectFile');
try
    bIsTl = false;
    stOpen = atgcv_m_model_open(stEnv, sSlModel, casInitScripts, bIsTl, ...
        bCheck, casAddPaths);
    sAllPath1 = path(); 
    atgcv_m_model_close(stEnv, stOpen);
    sAllPath2 = path();
    MU_PASS('model open/close for Simulink successfull');
catch
    stErr = atgcv_lasterror;
    rmpath(sNewPath);
    MU_FAIL_FATAL(['unexpected exception: ', ...
        stErr.identifier, ' ', stErr.message]);
end
rmpath(sNewPath);
sDdAfter = dsdd('GetEnv', 'ProjectFile');
MU_ASSERT_STRING_EQUAL(sDdAfter, sDdBefore, 'DD changed during model open/close');
MU_ASSERT_FALSE(isempty(strfind(sAllPath1, sNewPath)), 'path not in search path');
MU_ASSERT_FALSE(isempty(strfind(sAllPath2, sNewPath)), 'path was removed');


%% providing SL instead of TL
sDdBefore = dsdd('GetEnv', 'ProjectFile');
try
    bIsTl = true;
    stOpen = atgcv_m_model_open(stEnv, sSlModel, casInitScripts, bIsTl, bCheck);
    atgcv_m_model_close(stEnv, stOpen);
    MU_FAIL('missing expected exception: SL model instead of TL model');
catch
    stErr = atgcv_lasterror;
    MU_PASS(['expected exception: ', ...
        stErr.identifier, ' ', stErr.message]);
end
sDdAfter = dsdd('GetEnv', 'ProjectFile');
MU_ASSERT_STRING_EQUAL(sDdAfter, sDdBefore, 'DD changed during model open/close');


%% providing TL instead of SL
sDdBefore = dsdd('GetEnv', 'ProjectFile');
try
    bIsTl = false;
    stOpen = atgcv_m_model_open(stEnv, sTlModel, casInitScripts, bIsTl, bCheck);
    atgcv_m_model_close(stEnv, stOpen);
    MU_FAIL('missing expected exception: TL model instead of SL model');
catch
    stErr = atgcv_lasterror;
    MU_PASS(['expected exception: ', ...
        stErr.identifier, ' ', stErr.message]);
end
sDdAfter = dsdd('GetEnv', 'ProjectFile');
MU_ASSERT_STRING_EQUAL(sDdAfter, sDdBefore, 'DD changed during model open/close');


%% open TL1, TL2, SL, TL2 ---> close TL2, SL, TL2, TL1 ---> check DDs
util_close_all_dd;
sDdBefore0 = dsdd('GetEnv', 'ProjectFile');
try
    % open TL1
    bIsTl = true;
    stOpen1 = atgcv_m_model_open(stEnv, sTlModel, casInitScripts, bIsTl, bCheck);
    sDdBefore1 = dsdd('GetEnv', 'ProjectFile');
    
    % to raise cov modify the current DD of TL1:
    % in this case the modified DD has to reproduced by model open/close
    sDdBefore1Copy = [sDdBefore1, '_copy'];
    copyfile(sDdBefore1, sDdBefore1Copy);
    hNewObj = dsdd('Copy', 'Source', '/Pool/VariableClasses/CAL', ...
        'Destination', '/Pool/VariableClasses', 'AutoRename', 'on');
    
    % open TL2
    bIsTl = true;
    stOpen2 = atgcv_m_model_open(stEnv, sTlModel2, casInitScripts2, bIsTl, bCheck);
    sDdBefore2 = dsdd('GetEnv', 'ProjectFile');
    
    % open SL
    bIsTl = false;
    stOpen3 = atgcv_m_model_open(stEnv, sSlModel, casInitScripts, bIsTl, bCheck);
    sDdBefore3 = dsdd('GetEnv', 'ProjectFile');
    
    % open TL2 again
    bIsTl = true;
    stOpen4 = atgcv_m_model_open(stEnv, sTlModel2, casInitScripts2, bIsTl, bCheck);
    sDdBefore4 = dsdd('GetEnv', 'ProjectFile');
    

    % close TL2
    atgcv_m_model_close(stEnv, stOpen4);
    sDdAfter3 = dsdd('GetEnv', 'ProjectFile');
    
    % close SL
    atgcv_m_model_close(stEnv, stOpen3);
    sDdAfter2 = dsdd('GetEnv', 'ProjectFile');
    
    % close TL2
    atgcv_m_model_close(stEnv, stOpen2);
    sDdAfter1 = dsdd('GetEnv', 'ProjectFile');
    
    % check that the modified DD was loaded
    MU_ASSERT_TRUE(dsdd('Exist', hNewObj), ...
        'changes in DD have not been restored');
    
    % close TL1
    atgcv_m_model_close(stEnv, stOpen1);
    sDdAfter0 = dsdd('GetEnv', 'ProjectFile');
        
    % revert changes made to DD
    delete(sDdBefore1);
    movefile(sDdBefore1Copy, sDdBefore1);
    MU_PASS('model open/close for TL1, TL2, SL, TL2 successfull');
catch
    stErr = atgcv_lasterror;
    MU_FAIL_FATAL(['unexpected exception: ', ...
        stErr.identifier, ' ', stErr.message]);
end
MU_ASSERT_STRING_EQUAL(sDdBefore2, sDdBefore3, 'opening SL has changed DD');
MU_ASSERT_STRING_EQUAL(sDdBefore2, sDdBefore4, 'DDs for same model not equal');
MU_ASSERT_STRING_EQUAL(sDdAfter3, sDdBefore3,  'DD was not restored when closing TL2');
MU_ASSERT_STRING_EQUAL(sDdAfter2, sDdBefore2,  'DD was not restored when closing SL');
MU_ASSERT_STRING_EQUAL(sDdAfter1, sDdBefore1,  ...
    'DD was not restored when closing TL2 a second time');
MU_ASSERT_STRING_EQUAL(sDdAfter0, sDdBefore0,  'DD was not restored when closing TL1');


%%
i_cleanup(sDataPath);

end

%%
function i_cleanup(sTestDir)
bdclose all;
dsdd_free();
clear mex;
if exist(sTestDir, 'dir')
    rmdir(sTestDir, 's');
end
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
