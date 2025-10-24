function ut_w_ar_multiRunnable
% Simple generic check for EC.
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'EC';
sModelName = 'AR_multi_runnable';
bWithWrapperCeation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCeation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['W_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'EP:SLC:WARNING', ...
    'ATGCV:MOD_ANA:LIMITATION_UNSUPPORTED_TYPE_INTERFACE', ...
    'EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION'});
end

