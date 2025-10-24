function [xCleanupTestEnv, stTestData] = sltu_prepare_da_env(sModelName, sSuite, sTestDataPath, sEnc)
% Utility function to prepare test environment for deviation analysis
%

%% optional inputs
if (nargin < 4)
    sEnc = '';
end

%%
[xCleanupTestEnv, stTestData] = sltu_prepare_da_base(sModelName, sSuite, sTestDataPath, sEnc);

% main directory where the test execution will take place
stTestData.sTestRootSim = fullfile(fileparts(stTestData.sTestRootData), 'da_root');
mkdir(stTestData.sTestRootSim);
oOnLeavingGoToSimDir = onCleanup(@() cd(stTestData.sTestRootSim));

stTestData.sMessageFile = fullfile(stTestData.sTestRootSim, 'msg.xml');
stTestData.sBlockOutGraphFile = fullfile(stTestData.sTestRootSim, 'block_out_graph.xml');

sTestVectorName = 'testVector.csv'; % Note: expected name for the existing testdata file!

casVectorDirs = i_findVectorDirs(stTestData.sTestRootData);
nVecs = numel(casVectorDirs);
astVec = repmat(struct( ...
    'sTestVectorFile',   '', ...
    'sInitVectorFile',   '', ...
    'sResultVectorFile', '', ...
    'sInputsVectorFile', '', ...
    'sParamsVectorFile', ''), 1, nVecs);

for i = 1:numel(casVectorDirs)
    sVecSubFolder = fullfile(stTestData.sTestRootData, casVectorDirs{i});
    
    astVec(i).sTestVectorFile = fullfile(sVecSubFolder, sTestVectorName);
    if ~exist(astVec(i).sTestVectorFile, 'file')
        error('SLTU:DA:TEST_VECTOR_NOT_FOUND', ...
            'Expected test vector "%s" not found in testdata.', astVec(i).sTestVectorFile);
    end
    
    astVec(i).sInitVectorFile    = fullfile(sVecSubFolder, 'vectorInit.xml');    
    astVec(i).sResultVectorFile  = fullfile(sVecSubFolder, 'vector_result.xml');
    astVec(i).sInputsVectorFile  = fullfile(sVecSubFolder, 'sim_i.mdf');
    astVec(i).sParamsVectorFile  = fullfile(sVecSubFolder, 'sim_p.mdf');
    
    cd(stTestData.sTestRootData);
    sltu_prepare_simulation_vectors( ...
        astVec(i).sTestVectorFile, ...
        astVec(i).sInitVectorFile, ...
        astVec(i).sResultVectorFile, ...
        stTestData.sExtractionModelFile, ...
        astVec(i).sParamsVectorFile, ...
        astVec(i).sInputsVectorFile, ...
        stTestData.sInputHarnessFile, ...
        stTestData.sOutputHarnessFile);
end
stTestData.astVec = astVec;
end


%%
function casVectorDirs = i_findVectorDirs(sVectorPath)
casVectorDirs = {};
astFiles = dir(fullfile(sVectorPath, 'V*'));
for i = 1:numel(astFiles)
    stFile = astFiles(i);
    
    if (stFile.isdir && i_isVectorDir(stFile.name))
        casVectorDirs{end + 1} = stFile.name; %#ok<AGROW>
    end
end
end


%%
function bIsVecDir = i_isVectorDir(sDirName)
bIsVecDir = ~isempty(regexp(sDirName, '^V\d+$', 'once'));
end
