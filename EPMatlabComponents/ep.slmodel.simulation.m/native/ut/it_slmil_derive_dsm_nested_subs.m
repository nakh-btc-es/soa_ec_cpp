function it_slmil_derive_dsm_nested_subs()
% Checks the derived test vectors

casScopeID  = {'28p'};
sOrgSimMode = 'SL MIL';

[oOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv(...
    'DataStoreMemory', ...
    'SL', ...
    'dsm_model', ...
    'top', ...
    [], ...
    casScopeID);

stExtractInfo = sltu_extract_model(...
    stTestData, ...
    'OriginalSimulationMode', sOrgSimMode, ...
    'EnableSubsystemLogging', true);

[oOnCleanUpCloseExtrModel, stSimulationResult] = sltu_derive_model(...
    stTestData, ...
    stExtractInfo, ...
    'ExecutionMode', sOrgSimMode);
oCleanupTestEnv = onCleanup(@() cellfun(@delete, {oOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));


% scan the extracted model for logging artefacts
nExpectedStateLoggers = 1;
casStateLoggers = i_findAllBlocksWithName(stSimulationResult.sModelName, 'btc_mem');
nFoundStateLoggers = numel(casStateLoggers);
MU_ASSERT_TRUE(nExpectedStateLoggers == nFoundStateLoggers, ...
    sprintf('Number of state loggers is "%d" instead of "%d".', nFoundStateLoggers, nExpectedStateLoggers));


nExpectedPortLoggers = 7;
casPortLoggers = i_findAllBlocksWithName(stSimulationResult.sModelName, 'btc_cast');
nFoundPortLoggers = numel(casPortLoggers);
MU_ASSERT_TRUE(nExpectedPortLoggers == nFoundPortLoggers, ...
    sprintf('Number of port loggers is "%d" instead of "%d".', nFoundPortLoggers, nExpectedPortLoggers));


SLTU_ASSERT_DERIVED_VECTOR(stTestData);
end


%%
function casBlocks = i_findAllBlocksWithName(sRootModelName, sBlockName)
casAllModels = find_mdlrefs(sRootModelName);
casBlocks = {};

for i = 1:numel(casAllModels)
    sModelName = casAllModels{i};
    
    casModelBlocks = find_system(sModelName, ...
        'LookUnderMasks', 'all', ...
        'Name',           sBlockName);
    casBlocks = horzcat(casBlocks, reshape(casModelBlocks, 1, [])); %#ok<AGROW>
end
end
