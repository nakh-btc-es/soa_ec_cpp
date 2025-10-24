function ut_slmil_enums_and_alias_sldd()
[oOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('enum_03_sldd', 'UT_SL', 'enums_and_alias');

sOrgSimMode = 'SL MIL';
stExtractInfo = sltu_extract_model(...
    stTestData, ...
    'OriginalSimulationMode', sOrgSimMode, ...
    'EnableSubsystemLogging', true);

oOnCleanUpCloseExtrModel = sltu_simulate_model(...
    stTestData, ...
    stExtractInfo, ...
    'ExecutionMode', sOrgSimMode);
oCleanupTestEnv = onCleanup(@() cellfun(@delete, {oOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

if ep_core_version_compare('ML9.6') < 0
    SLTU_ASSERT_DERIVED_VECTOR(stTestData);
else
    SLTU_ASSERT_DERIVED_VECTOR(stTestData, 'ml2019a');
end
end