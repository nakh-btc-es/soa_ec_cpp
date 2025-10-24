function ut_w_ep_3333
% Checking fix for EP-3333.
%
% EP-3333:
%   * AUTOSAR model M is defining an Enum type E with a default Value that is not zero.
%   * E is referenced by an Inport P of AR component. However, the signal running through through P is not really used 
%     and ends in a terminator.
%   * The EC Code generator is not generating any #define expressions for the individual Enum values for E.
%   * Wrapper is generated for M.
%   * Since the Inport of the Wrapper is also referencing E and here the signal is actually used, the EC code generator
%     is creating a variable for the Inport and is initializing it with the default Enum value.
%   * --> The whole code base is not compilable since the used default value for E is not defined anywhere in the code.
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();


%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_enum_nonzero';
bWithWrapperCeation = true;
stResult = ut_ec_pool_model_analyse(sSuiteName, sModelName, bWithWrapperCeation);


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

% for full stubbing check, check also if compilable
sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

SLTU_ASSERT_VALID_MESSAGE_FILE(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end