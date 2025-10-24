function ut_bug_34765
% UPDATED LEGACY UT
% Old name: ut_mt01_bug_34765
% checking fix for BTS/34765
%
%   REMARK
%    * BTS/34765:
%      Info about Global Variables belonging to non-model generated Modules
%      (like DD-based, etc.) are strewn across the DD inside the root
%      TL-Subsystem nodes.
%      Example: CAL var from Module "GlobalVar.c" is used in top_A and
%      top_A/sub_B TL-Substem. Then the BlockInfo of CAL var is splitted in
%      both DD locations for higher TL-versions. 
%      For lower TL-versions another problem occurs: BlockInfo is sometimes
%      repeated in both locations. This latter problem is also the reason
%      for BTS/34765 (for version TL3.2).
%
%      So there are _two_ potential problems:
%
%        For all TL-versions:
%        1) BlockInfo of GlobalVariables is not properly merged by
%        ModelAnalysis (i.e. the same CAL/DISP var is placed at different
%        Model locations in ModelAnalysis and it is not detected that this
%        is a merged Var)
%
%        For lower TL-versions:
%        2) The same Variable is placed twice into the same ModelLocation.
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%


%% clean up first
ut_cleanup();

%% arrange
sUTModel = 'bug_34765';
sUTSuite = 'UT_TL';

sPwd = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);

sTestDataDir = fullfile(ut_testdata_dir_get(), sUTModel);

[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env(sUTModel, sUTSuite, sTestRoot);

sModelFile  = stTestData.sTlModelFile;
sInitScript = stTestData.sTlInitScriptFile;
[~, sModel] = fileparts(sModelFile);

xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% act
stOpt = struct( ...
    'sTlModel',      sModel, ...
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

sExpectedCodeModel = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stOpt.sCResultFile);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModel, stOpt.sCResultFile);

sExpectedTlConstraints = fullfile(sTestDataDir, 'TlConstr.xml');
SLTU_ASSERT_VALID_CONSTRAINTS(stOpt.sTlArchConstrFile);
SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedTlConstraints, stOpt.sTlArchConstrFile);

sExpectedMessageFile = fullfile(sTestDataDir, 'error.xml');
SLTU_ASSERT_EQUAL_MESSAGES(sExpectedMessageFile, sMessageFile);
end