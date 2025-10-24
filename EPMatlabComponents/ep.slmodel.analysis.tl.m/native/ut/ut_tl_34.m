function ut_tl_34
% UPDATED LEGACY UT
% Check support for TL3.4 AUTOSAR feature "Activation Reason for Runnable".
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'tl34';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFileTL  = stTestData.sTlModelFile;
sInitScriptTL = stTestData.sTlInitScriptFile;
[~, sModelTL] = fileparts(sModelFileTL);

xOnCleanupCloseModel = sltu_load_models(xEnv,...
    {sModelFileTL, sInitScriptTL, true});
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
stOpt = struct( ...
    'sTlModel',      sModelTL, ...
    'bCalSupport',   false, ...
    'bDispSupport',  true, ...
    'bParamSupport', true, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
sMessageFile = ut_ep_model_analyse(stOpt);

%% assert

sExpectedTlArch = fullfile(sTestDataDir, 'TlArch.xml');
SLTU_ASSERT_VALID_TL_ARCH(stOpt.sTlResultFile);
SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArch, stOpt.sTlResultFile);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stOpt.sMappingResultFile);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stOpt.sMappingResultFile);

if i_isTlVersionWithBehaviorChange()
    sExpectedCodeModel = fullfile(sTestDataDir, 'tl51p3', 'CodeModel.xml');
else
    sExpectedCodeModel = fullfile(sTestDataDir, 'tl_base', 'CodeModel.xml');
end
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end


%%
function bWithBehaviorChange = i_isTlVersionWithBehaviorChange()
% boundaries for the ranges with included lower and excluded upper bound --> [lower, upper)
%
%  [TL5.1p3, ... TL5.2)
%  [TL5.2p2, ..., TL22.1)
%  [TL22.1, ..., ?)  <-- can be combined with last range!
%
ccasTlVersionRangeWithChange = {{'TL5.1p3', 'TL5.2'}, {'TL5.2p2', ''}};
    
bWithBehaviorChange = false;
for i = 1:numel(ccasTlVersionRangeWithChange)
    casVersionRange = ccasTlVersionRangeWithChange{i};
    
    if i_isInRange(casVersionRange{1}, casVersionRange{2})
        bWithBehaviorChange = true;
        break;
    end
end
end


%%
function bIsInRange = i_isInRange(sLowerIncludedVer, sUpperExcludedVer)
if isempty(sUpperExcludedVer)
    bIsInRange = atgcv_version_p_compare(sLowerIncludedVer) >= 0;
else
    bIsInRange = (atgcv_version_p_compare(sLowerIncludedVer) >= 0) && (atgcv_version_p_compare(sUpperExcludedVer) < 0);
end
end
