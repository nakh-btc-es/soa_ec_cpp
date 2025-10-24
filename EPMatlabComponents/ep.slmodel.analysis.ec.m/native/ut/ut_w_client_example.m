function ut_w_client_example
% AUTOSAR CS wrapper creation check for EC.
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sAtsName = 'ClientExample';

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sAtsName, 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%%
% Extra check for EPDEV-53349:
% Faking error scenario: Original model contains inconsistencies in settings thay may result from a buggy upgrade
% of an EC model from an older ML version to ML2019b or higher. --> In this case the Custom symbol for the model
% function gets scrambled from "$R$N" to "$N".
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false); %#ok<NASGU>
i_setConfigSetting(sModelFile, 'CustomSymbolStrModelFcn', '$N');
clear xOnCleanupCloseModel;

%% act
% (1) create wrapper
stResultWrapper = ep_ec_model_wrapper_create( ...
    'ModelFile',    sModelFile, ...
    'InitScript',   sInitScript);
if ~stResultWrapper.bSuccess
    MU_FAIL_FATAL(sprintf('Creating wrapper failed: %s', strjoin(stResultWrapper.casErrorMessages, '; ')));
end
evalin('base', 'clear all;')

sModelFile = stResultWrapper.sWrapperModel;
sInitScript = stResultWrapper.sWrapperInitScript;

% (2) do full analysis
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

% extra check for EPDEV-53349
sWrapperModelNameSymbol = i_getConfigSetting(sModelFile, 'CustomSymbolStrModelFcn');

stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
% Special assert for bugfix EPDEV-53349
sExpected = '$R$N';
SLTU_ASSERT_TRUE(strcmp(sWrapperModelNameSymbol, sExpected), ...
    'Bugfix for EPDEV-53349: Expected custom identifier ''CustomSymbolStrModelFunc'' to be "%s" instead of "%s".', ...
    sExpected, ...
    sWrapperModelNameSymbol);

% note: the fixed wrapper inside the testdata was built differently on purpose (e.g. is using Cals in Wrapper)
% --> for this reason extra expected values are needed
sTestDataDir = fullfile(ut_get_testdata_dir(), ['W_', sAtsName]);

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

if verLessThan('matlab', '9.5')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2017b', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2018b', 'CodeModel.xml');
end

bCheckCompilable = true;
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel, bCheckCompilable);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

ut_ec_assert_valid_message_file(stResult.sMessages, { ...
    'EP:SLC:INFO', ...
    'EP:SLC:WARNING'});
end


%%
function sSetting = i_getConfigSetting(sModelFile, sSettingName)
[~, sModel] = fileparts(sModelFile);
oConfigSet = getActiveConfigSet(sModel);
sSetting = oConfigSet.getProp(sSettingName);
end


%%
function i_setConfigSetting(sModelFile, sSettingName, sSettingValue)
[~, sModel] = fileparts(sModelFile);
oConfigSet = getActiveConfigSet(sModel);
oConfigSet.setProp(sSettingName, sSettingValue);
save_system(sModel);
end
