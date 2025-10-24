function [xCleanupTestEnv, stTestData] = sltu_prepare_debug_env(sModelName, sSuite, sTestDataPath, sTestRootSuffix, sTVName, casDebugVecNames)
% Utility function to prepare test environment for debug workflow.
%


%%
sPwd = pwd;
oOnCleanupReturn = onCleanup(@() cd(sPwd));

%% optional inputs
if (nargin < 4)
    sTestRootSuffix = '';
end
if (nargin < 5) || isempty(sTVName)
    sTestVectorName = 'testVector.csv';
else
    sTestVectorName = sTVName;
end
if (nargin < 6)
    casDebugVecNames = {'MyFirstTestCase', 'MySecondTestCase'};
end

[xCleanupTestEnv, stTestData] = sltu_prepare_simenv_base(sModelName, sSuite, sTestDataPath, sTestRootSuffix);

stTestData.sTestRootDebugData = fullfile(fileparts(stTestData.sTestRootData), 'debug_data');
mkdir(stTestData.sTestRootDebugData);

% main dir where test execution will be done
stTestData.sTestRootDebugExec = fullfile(fileparts(stTestData.sTestRootData), 'debug_exec');
mkdir(stTestData.sTestRootDebugExec);

stTestData.sTestVectorFile = fullfile(stTestData.sTestRootData, sTestVectorName);
stTestData.sDebugModelFile = fullfile(stTestData.sTestRootDebugData, 'debug_model.xml');
stResult = sltu_create_debug_vectors( ...
    stTestData.sTestVectorFile, ...
    stTestData.sExtractionModelFile, ...
    stTestData.sDebugModelFile, ...
    casDebugVecNames);

stTestData.casDebugVectorFiles = {stResult.astVecs(:).sDebugVectorFile};
stTestData.stValues            = stResult.stValues;

% for checking outputs later preserve the outputs MDF (note: will be moved during creation of debug env)
stTestData.sOutputsVectorFile = fullfile(stTestData.sTestRootDebugData, 'outputs_for_checking.mdf');
copyfile(stResult.astVecs(1).sOutputsMDFFile, stTestData.sOutputsVectorFile);

stTestData.sMessageFile = fullfile(stTestData.sTestRootDebugData, 'msg.xml');
end
