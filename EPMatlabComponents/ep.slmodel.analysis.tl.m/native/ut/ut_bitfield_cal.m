function ut_bitfield_cal
%
%   BTS/36065:
%     Type "Bitfield" is not officially supported by the TL-online-API for
%     TL-PIL. For this reason CALs with this type need to be filtered out.
%
%   Also static Cals cannot be accessed by TL-online-API and need to be filtered
%   out.
%

%% cleanup
sltu_cleanup();

%% arrange
sUTModel = 'bitfield_cal';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), [sUTSuite, '_', sUTModel]);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));


%% test for multiple cal workflows
i_execTestForCalIgnored(false, false, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForCalIgnored(true, false, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForCalIgnored(false, true, sModel, xEnv, sResultDir, sTestDataDir);
i_execTestForCalIgnored(true, true, sModel, xEnv, sResultDir, sTestDataDir);
end


%%
function i_execTestForCalIgnored(bIgnoreStatic, bIgnoreBitfield, sModel, xEnv, sResultDir, sTestDataDir)
% cleanup result dir and registered messages as precaution for multiple executions
if exist(sResultDir, 'dir')
    rmdir(sResultDir, 's');
    mkdir(sResultDir);
end
xEnv.clearMessages();


% act
stOpt = struct( ...
    'sTlModel',            sModel, ...
    'bIgnoreStaticCal',    bIgnoreStatic, ...
    'bIgnoreBitfieldCal',  bIgnoreBitfield, ...
    'xEnv',                xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);

% diff-key
if bIgnoreStatic
    if bIgnoreBitfield
        sCalIgnore = 'ignore_static_bitfield';
    else
        sCalIgnore = 'ignore_static';
    end
else
    if bIgnoreBitfield
        sCalIgnore = 'ignore_bitfield';
    else
        sCalIgnore = 'ignore_none';
    end
end

% assert
sExpectedTlArch = fullfile(sTestDataDir, sCalIgnore, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataDir, sCalIgnore, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

sExpectedCodeModel = fullfile(sTestDataDir, sCalIgnore, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, sCalIgnore, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataDir, sCalIgnore, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end
