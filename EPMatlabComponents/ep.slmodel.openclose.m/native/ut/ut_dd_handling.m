function ut_dd_handling
% checking DD handling during atgcv_m_model_open/close
%



%% prepare data
stEnv = struct( ...
    'sTmpPath',    pwd, ...
    'sResultPath', pwd, ...
    'hMessenger',  0);

sParentDir = fileparts(pwd);
sDataPath =  fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata');
sNewDataPath = fullfile(pwd, 'dd_handling');
if exist(sNewDataPath, 'dir')
    rmdir(sNewDataPath, 's');
end
copyfile(sDataPath, sNewDataPath);
sDataPath = sNewDataPath;

sTlModel = fullfile(sDataPath, 'StandardModel_tl.mdl');
sDDFile = fullfile(sDataPath, 'StandardModel.dd');
casInitScripts = {fullfile(sDataPath, 'standard_start.m')};
bCheck = false;
bIsTl = true;

aiLoadedIdx  = [3, 4, 7];
aiCreatedIdx = [6, 9, 67, 68, 69, 89];

% upgrade model
try
    tu_test_model_adapt(sTlModel, casInitScripts{1});
catch
    MU_FAIL_FATAL(lasterr);
end


%% check with model closed
try
    i_clearAllDDs();
    dsdd('Open', sDDFile);
    i_extendDD(sDDFile, aiLoadedIdx, aiCreatedIdx);
    
    astBefore = i_getAllDDs();
    stOpen = atgcv_m_model_open(stEnv, sTlModel, casInitScripts, bIsTl, ...
        bCheck, {});
    
    astDuring = i_getAllDDs();
    MU_ASSERT_TRUE(length(astDuring) == 1, 'Only the main DD should be open.');
    MU_ASSERT_TRUE(strcmpi(sDDFile, astDuring(1).sFile), ...
        sprintf('Found main DD "%s" instead of expected "%s".', ...
        astDuring(1).sFile, sDDFile));

    atgcv_m_model_close(stEnv, stOpen);
    
    % expecting that all non-temporary DDs are open after ModelClose
    astAfter = i_getAllDDs();
    astExpected = astBefore(arrayfun(@(x) i_isInIdxSet(x, [aiLoadedIdx, 0]), astBefore));
    if (length(astAfter) == length(astExpected))
        for i = 1:length(astExpected)
            MU_ASSERT_TRUE(strcmpi(astExpected(i).sFile, astAfter(i).sFile), ...
                sprintf('Found main DD file "%s" instead of expected "%s".', ...
                astAfter(i).sFile, astExpected(i).sFile));

            MU_ASSERT_TRUE(eq(astExpected(i).iIdx, astAfter(i).iIdx), ...
                sprintf('Found main DD idx "%d" instead of expected "%d".', ...
                astAfter(i).iIdx, astExpected(i).iIdx));
        end
    else
        MU_FAIL('Unexpected number of open DDs.');
    end
    
catch oEx
    MU_FAIL(sprintf('Unexpected exception.\n%s', oEx.message));
end



%% check with model open
try
    i_clearAllDDs();
    dsdd('Open', sDDFile);
    i_extendDD(sDDFile, aiLoadedIdx, aiCreatedIdx);
    load_system(sTlModel);

    astBefore = i_getAllDDs();
    stOpen = atgcv_m_model_open(stEnv, sTlModel, casInitScripts, bIsTl, ...
        bCheck, {});
    
    astDuring = i_getAllDDs();
    MU_ASSERT_TRUE(length(astDuring) == 1, 'Only the main DD should be open.');
    MU_ASSERT_TRUE(strcmpi(sDDFile, astDuring(1).sFile), ...
        sprintf('Found main DD "%s" instead of expected "%s".', ...
        astDuring(1).sFile, sDDFile));

    atgcv_m_model_close(stEnv, stOpen);
    
    % expecting that all non-temporary DDs are open after ModelClose
    astAfter = i_getAllDDs();
    astExpected = astBefore(arrayfun(@(x) i_isInIdxSet(x, [aiLoadedIdx, 0]), astBefore));
    if (length(astAfter) == length(astExpected))
        for i = 1:length(astExpected)
            MU_ASSERT_TRUE(strcmpi(astExpected(i).sFile, astAfter(i).sFile), ...
                sprintf('Found main DD file "%s" instead of expected "%s".', ...
                astAfter(i).sFile, astExpected(i).sFile));

            MU_ASSERT_TRUE(eq(astExpected(i).iIdx, astAfter(i).iIdx), ...
                sprintf('Found main DD idx "%d" instead of expected "%d".', ...
                astAfter(i).iIdx, astExpected(i).iIdx));
        end
    else
        MU_FAIL('Unexpected number of open DDs.');
    end
    
catch oEx
    MU_FAIL(sprintf('Unexpected exception.\n%s', oEx.message));
end


%%
i_cleanup(sDataPath);
end



%%
function bIsInSet = i_isInIdxSet(stInfo, aiIdxSet)
bIsInSet = any(stInfo.iIdx == aiIdxSet);
end



%%
function i_clearAllDDs()
bdclose all; dsdd('Close', 'Save', 'off'); dsdd_free();
end


%%
function astInfo = i_getAllDDs()
astDDs = dsdd('GetAllDDs');

astInfo = struct( ...
    'sFile',   {astDDs(:).fileName}, ...
    'iIdx',    {astDDs(:).treeIdx}, ...
    'bIsTemp', []);
for i = 1:length(astInfo)
    iIsTemp = dsdd('GetAttribute', sprintf('//DD%d', astInfo(i).iIdx), 'temporary');
    astInfo(i).bIsTemp = logical(iIsTemp);
end
end


%%
function i_extendDD(sDDFile, aiIdx, aiTempIdx)
[p, f, e] = fileparts(sDDFile);
for i = 1:length(aiIdx)
    iIdx = aiIdx(i);
    
    sCopy = fullfile(p, [f, num2str(iIdx), e]);
    copyfile(sDDFile, sCopy);
    dsdd('AutoLoad', 'file', sCopy, 'DDIdx', iIdx);
    
    if (mod(i, 2) == 0)
        % adapt every second DD as modified
        dsdd('AddUserData', sprintf('//DD%d', iIdx), 'justChecking');
    end
end
for i = 1:length(aiTempIdx)
    iIdx = aiTempIdx(i);
    
    dsdd('CreateDD', iIdx);
    if (mod(i, 2) == 0)
        % adapt every second DD as modified
        dsdd('AddUserData', sprintf('//DD%d', iIdx), 'justChecking');
    end
    if (mod(i, 3) == 0)
        % adapt every third temp DD as modified
        dsdd('SetAttribute', sprintf('//DD%d', iIdx), 'temporary', true);
    end
end
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
