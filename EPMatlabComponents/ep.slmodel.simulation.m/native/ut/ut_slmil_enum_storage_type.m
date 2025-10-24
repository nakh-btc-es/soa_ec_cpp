function ut_slmil_enum_storage_type()
% Tests a problem with the algorithm to copy Enum definitions to workspace

%with this small model the error is only reproduceable for Matlab 2022b, therefore it is skipped elsewhere
if verLessThan('matlab','9.13') || ~verLessThan('matlab','9.14')
    MU_MESSAGE('SKIPPING TEST: Test is only run for ML 2022b');
    return;
end

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('ar_wrapper_enum_storage_type', 'UT_EC',...
    'ar_wrapper_enum_storage_type', 'ar_wrapper_enum_storage_type');
sOrgSimMode = 'SL MIL';
open_system('ar_storage_type');
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sSimMessageFile);
end