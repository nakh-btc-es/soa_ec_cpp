function ut_ep_3091
% Testing bugfix for EP-3091.
%
%  Bug: EC Analysis is not robust because there is a variable inside the base workpace with the same name as a model
%       workspace parameter.
%
%  Fix: Check the source of the parameters before evaluating them. If it's from the "model workspace", evaluate it
%       accordingly in the model workspace and not in the base workspace.
%

%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end

%% arrange and act
sSuiteName = 'UT_EC';
sModelName = 'ar_mw_params_01';


%% prepare
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_ep3091_', sModelName]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sModelName, sSuiteName, sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% load the model to be analysed
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

% Prepare some artificial variables in the base workspace that have the same name as the model workspace parameters.
evalin('base', 'A=NaN;');
evalin('base', 'B=NaN;');
evalin('base', 'C=NaN;');


%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
if verLessThan('matlab', '9.6')
    sVersionDir = 'ml2018b';
elseif verLessThan('matlab', '9.9')
    sVersionDir = 'ml2019a';
else
    sVersionDir = 'ml2020b';
end
sTestDataDir = fullfile(ut_get_testdata_dir(), ['UT_EC_', sModelName], sVersionDir);

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

sExpectedSlConstr = fullfile(sTestDataDir, 'slConstr.xml');
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedSlConstr, stResult.sSlConstr);

sExpectedMessagesFile = fullfile(sTestDataDir, 'errors.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessagesFile, stResult.sMessages);
end
