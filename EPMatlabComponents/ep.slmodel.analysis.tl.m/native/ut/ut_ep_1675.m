function ut_ep_1675
% Check fix for Bug EP-1675.
%
%  REMARKS
%       Bug: Issues when user is specifying an init function inside the LegacyCode.xml and the model already has more
%       than one init function (INIT and RESTART). Note: This particular case can happen frequently for AUTOSAR models.
%

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, ['tmp_', mfilename()]);
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'multi_init_func');

sTlModel     = 'multi_init_func';
sTlModelFile = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile      = fullfile(sTestRoot, [sTlModel, '.dd']);
sLegacyFile  = fullfile(sTestRoot, 'LegacyCode.xml');


%% arrange
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = sltu_prepare_local_env(sDataDir, sTestRoot);
sltu_local_model_adapt(sTlModelFile);
xOnCleanupCloseModelTL = sltu_load_models(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',              sDdFile, ...
    'sTlModel',             sTlModel, ...
    'sEnvironmentFileList', sLegacyFile, ...
    'xEnv',                 xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
sFileExp = 'btc__init_functions.c';
[sInitFuncFound, sInitFuncFile] = i_getInitFunctionAndFile(stOpt.sCResultFile, sFileExp);

sInitFuncExp = 'btc__init_func_1';
MU_ASSERT_TRUE(strcmp(sInitFuncFound, sInitFuncExp), ...
    sprintf('Found init function "%s" instead of "%s".', sInitFuncFound, sInitFuncExp));

if (~isempty(sInitFuncFile) && exist(sInitFuncFile, 'file'))
    sContent = fileread(sInitFuncFile);
    
    casExpectedLines = { ...
        'extern void dummy_init_func();', ...
        'extern void RESTART_Sa1_top_A();', ...
        'extern void INIT_Sa1_top_A();', ...
        'dummy_init_func();', ...
        'RESTART_Sa1_top_A();', ...
        'INIT_Sa1_top_A();'};
    
    casFoundLines = i_getTrimmedNonEmptyLines(sContent);
    casMissingLines = setdiff(casExpectedLines, casFoundLines);
    for i = 1:numel(casMissingLines)
        MU_FAIL(sprintf('Expected code line "%s" is missing.', casMissingLines{i}));
    end
else
    MU_FAIL(sprintf('Expected file %s not found.', sFileExp));
end
end


%%
function casLines = i_getTrimmedNonEmptyLines(sContent)
casLines = strtrim(regexp(sContent, '\n', 'split'));
casLines = casLines(~cellfun('isempty', casLines));
end


%%
function [sInitFunc, sFile] = i_getInitFunctionAndFile(sCResultFile, sFileName)

hDoc = mxx_xmltree('load', sCResultFile);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

astRes = mxx_xmltree('get_attributes', hDoc, '/CodeModel/Functions/Function', 'initFunc');
sInitFunc = astRes(1).initFunc;

sFile = '';
astRes = mxx_xmltree('get_attributes', hDoc, sprintf('/CodeModel/Files/File[@name="%s"]', sFileName), 'path');
if ~isempty(astRes)
    sFile = fullfile(astRes(1).path, sFileName);
end
end