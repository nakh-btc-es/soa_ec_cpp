function ut_modelRefLocals
% Simple generic check for EC.


%% act
stResult = ut_ec_ats_model_analyse('ModelRefLocals');


%% assert
sTestDataDir = fullfile(ut_get_testdata_dir(), 'ModelRefLocals');

sExpectedSlArch = fullfile(sTestDataDir, 'SlArch.xml');
SLTU_ASSERT_VALID_SL_ARCH(stResult.sSlArch);
SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArch, stResult.sSlArch);

sExpectedMapping = fullfile(sTestDataDir, 'Mapping.xml');
SLTU_ASSERT_VALID_MAPPING(stResult.sMapping);
SLTU_ASSERT_EQUAL_MAPPING(sExpectedMapping, stResult.sMapping);

if verLessThan('matlab', '9.6')
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2016b', 'CodeModel.xml');
else
    sExpectedCodeModelFile = fullfile(sTestDataDir, 'ml2019a', 'CodeModel.xml');
end
SLTU_ASSERT_VALID_CODE_MODEL(stResult.sCodeModel);
SLTU_ASSERT_EQUAL_CODE_MODEL(sExpectedCodeModelFile, stResult.sCodeModel);
i_checkIncludes(stResult.sCodeModel, { ...
    'ModelRefLocals_main_ert_rtw', ...
    'ModelRefLocals_sub1', ...
    'ModelRefLocals_sub2', ...
    'ModelRefLocals_sub3'});

ut_ec_assert_valid_message_file(stResult.sMessages, {'EP:SLC:INFO', 'EP:SLC:WARNING'});
end


%%
function i_checkIncludes(sCodeModel, casRequiredIncludeDirNames)
casFoundIncludeDirs = i_readAllIncludeDirNames(sCodeModel);
SLTU_ASSERT_STRINGSET_CONTAINS(casRequiredIncludeDirNames, casFoundIncludeDirs);
end


%%
function casIncludeDirNames = i_readAllIncludeDirNames(sCodeModel)
[hRoot, onCleanupCloseDoc] = i_openXml(sCodeModel); %#ok<ASGLU> onCleanup object

astRes = mxx_xmltree('get_attributes', hRoot, '/CodeModel/IncludePaths/IncludePath', 'path');
if ~isempty(astRes)
    casIncludeDirNames = cellfun(@i_getDirName, {astRes(:).path}, 'UniformOutput', false);
else
    casIncludeDirNames = {};
end
end


%%
function sDirName = i_getDirName(sDirFullPath)
[~, sDirName] = fileparts(sDirFullPath);
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end
