function ut_w_enums_clientServer
% This UT checks the bug found while analyzing EP-2217, without the fix
% wrapper creation fails with the following output:
% Error using autosar.api.getAUTOSARProperties/findObjByPartialOrFullPathForNamedElement
% Found more than one AUTOSAR element at the partially qualified path 'COLOR_SWC',
% please specify a fully qualified path instead. Valid fully qualified paths are
%'/interfaces_cs_pkg/interfaces_cs_swc/COLOR_SWC', '/Timing/COLOR_SWC'.


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'EC';
sModelName = 'AR_enums_clientServer';
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

if verLessThan('matlab', '9.4')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2017b', 'CodeModel.xml');
if verLessThan('matlab', '23.2')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2018a', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2023b', 'CodeModel.xml');
end
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);


ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'EP:SLC:WARNING', ...
    'ATGCV:MOD_ANA:GLOBAL_DS_UNSUPPORTED_TYPE'});
end
