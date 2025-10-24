function [xCleanupTestEnv, stTestData] = sltu_prepare_simenv(sModelName, sSuite, sTestDataPath, sTestRootSuffix, sTVName, casScopeIDs)
% Utility function to prepare test environment for simulation
%

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
    casScopeIDs = {};
end

%%
[xCleanupTestEnv, stTestData] = sltu_prepare_simenv_base(sModelName, sSuite, sTestDataPath, sTestRootSuffix);

% main directory where the test execution will take place
stTestData.sTestRootSim = fullfile(fileparts(stTestData.sTestRootData), 'sim');
mkdir(stTestData.sTestRootSim);
oOnLeavingGoToSimDir = onCleanup(@() cd(stTestData.sTestRootSim));

stTestData.sMessageFile = fullfile(stTestData.sTestRootSim, 'msg.xml');


stTestData.sInitVectorFile = fullfile(stTestData.sTestRootData, 'initVector.xml');
stTestData.sTestVectorFile = fullfile(stTestData.sTestRootData, sTestVectorName);

stTestData.sResultVectorFile  = fullfile(stTestData.sTestRootSim, 'resultVector.xml');
stTestData.sInputsVectorFile  = fullfile(stTestData.sTestRootSim, 'v_i.mdf');
stTestData.sParamsVectorFile  = fullfile(stTestData.sTestRootSim, 'v_p.mdf');
stTestData.sOutputsVectorFile = fullfile(stTestData.sTestRootSim, 'v_o.mdf');
stTestData.sLocalsVectorFile  = fullfile(stTestData.sTestRootSim, 'v_l.mdf');

cd(stTestData.sTestRootData);
sltu_prepare_simulation_vectors( ...
    stTestData.sTestVectorFile, ...
    stTestData.sInitVectorFile, ...
    stTestData.sResultVectorFile, ...
    stTestData.sExtractionModelFile, ...
    stTestData.sParamsVectorFile, ...
    stTestData.sInputsVectorFile, ...
    stTestData.sInputHarnessFile, ...
    stTestData.sOutputHarnessFile);

stTestData.castLoggedSubsystems = [];
if ~isempty(casScopeIDs)
    hExtrFile = mxx_xmltree('load', stTestData.sExtractionModelFile);
    xOnCleanUpCloseExtr = onCleanup(@() mxx_xmltree('clear', hExtrFile));
    
    stTestData.castLoggedSubsystems = cell(1, length(casScopeIDs));
    for i = 1:length(casScopeIDs)
        sScopeUID = casScopeIDs{i};
        
        sFolderName = ['derive_', sScopeUID];
        sDerivedSimFolder = fullfile(stTestData.sTestRootSim, sFolderName);
        mkdir(sDerivedSimFolder);
        stLoggedSubsystem = struct( ...
            'sScopeUID',   sScopeUID, ...
            'sInputsMDF',  fullfile(sDerivedSimFolder, ['di_', sScopeUID, '.mdf']), ...
            'sParamsMDF',  fullfile(sDerivedSimFolder, ['dp_', sScopeUID, '.mdf']), ...
            'sOutputsMDF', fullfile(sDerivedSimFolder, ['do_', sScopeUID, '.mdf']),...
            'sLocalsMDF',  fullfile(sDerivedSimFolder, ['dl_', sScopeUID, '.mdf']));
        stTestData.castLoggedSubsystems{i} = stLoggedSubsystem;
        
        hScope = mxx_xmltree('get_nodes', hExtrFile, ['//Scope[@uid="', sScopeUID, '"]']);
        if isempty(hScope)
            error('UT:INTERNAL_ERROR', 'Scope with uid="%s" not found in extraction model.', sScopeUID);
        end
        mxx_xmltree('set_attribute', hScope, 'subsystemLogging', 'on');
    end
    mxx_xmltree('save', hExtrFile, stTestData.sExtractionModelFile);
end
end
