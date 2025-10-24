function ut_many_stubs_bus()
% Checking stubbing for bus signals.
%


%% arrange and act
sModelUT = 'many_stubs_bus'; 
stResult = ut_ec_ut_model_analyse(sModelUT);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelUT]);

% for full stubbing check, check also if compilable
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, {'EP:SLC:INFO','EP:SLC:WARNING'});
end
