function ut_simple_34
% Simple generic check for EC.
%


%%
if ~SLTU_ASSUME_EC_AUTOSAR
    return;
end


%% prepare test
sltu_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('wrapper_ar_complete', 'EC', sTestRoot);
sModelFile  = stTestData.sSlModelFile;
sInitScript = stTestData.sSlInitScriptFile;


%% arrange
xOnCleanupCloseModel = sltu_load_models(xEnv, sModelFile, sInitScript, false);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModel, xOnCleanupDoCleanupEnv}));

%% Copy hook file
sTestDataDir = ep_core_canonical_path(fullfile(ut_get_testdata_dir, 'simple_34'));

sHookFile = fullfile(sTestDataDir, 'ecahook_autosar_wrapper_function_info.m');
sltu_copy_file(sHookFile, fileparts(sResultDir));
%% act
stResult = ut_ec_model_analyse(xEnv, sModelFile, sInitScript, sResultDir);


%% assert
sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

sExpectedCodeModelFile = fullfile(sTestDataDir, 'CodeModel.xml');
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);

MU_ASSERT_TRUE(i_checkIfIncludePathFound(stResult.sCodeModel, ['A:' filesep 'BcD']));
MU_ASSERT_TRUE(i_checkIfIncludePathFound(stResult.sCodeModel, ['x:' filesep 'yZ']));

ut_ec_assert_valid_message_file(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end

%%
function bFound = i_checkIfIncludePathFound(sCodeModelFile, sExpPath)
bFound = false; 
[hRoot, oOnCleanupCloseDoc] = i_openXml(sCodeModelFile); %#ok<ASGLU> onCleanup object
oInclPathMap = i_getIncludePaths(hRoot);
casFoundInclPaths = oInclPathMap.keys;
idx = 1;
while ~bFound && idx <= length(casFoundInclPaths)
    sPath = casFoundInclPaths{idx};
    if strcmp(sPath, sExpPath)
        bFound = true;
    else
        idx = idx + 1;
    end
end
end

%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end

%%
function oInclPathMap = i_getIncludePaths(hRoot)
oInclPathMap = containers.Map;
astIncPaths = i_readAllIncludePaths(hRoot);
for i = 1:numel(astIncPaths)
    oInclPathMap(astIncPaths(i).path) = astIncPaths(i);
end
end


%%
function astIncPaths = i_readAllIncludePaths(hRoot)
ahInclPaths = mxx_xmltree('get_nodes', hRoot, '/CodeModel/IncludePaths/IncludePath');
astIncPaths = arrayfun(@(hInclPath) i_readIncludePath(hInclPath), ahInclPaths);
end


%%
function stFunc = i_readIncludePath(hInclPath)
stFunc = mxx_xmltree('get_attributes', hInclPath, '.', 'path');
end
