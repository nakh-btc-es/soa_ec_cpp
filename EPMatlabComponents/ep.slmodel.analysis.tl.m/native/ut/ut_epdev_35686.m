function ut_epdev_35686
% Check fix for Bug EPDEV-35686
%
%  REMARKS
%       Bug: InitFunction in LegacyCode XML is not correctly considered in Code result XML.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%% prepare test
ut_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, 'epdev-35686');
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('LegacyCode', 'TL', sTestRoot);

[~, sTlModel]  = fileparts(stTestData.sTlModelFile);
sTlModelFile   = stTestData.sTlModelFile;
sDdFile        = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript  = stTestData.sTlInitScriptFile;
% sLegacyCodeXml = stTestData.sEnvFile; 
sLegacyCodeXml = fullfile(sTestRoot,'LegacyCode.xml'); 


%% arrange
xOnCleanupCloseModelTL = ut_load_models(xEnv, sTlModelFile, sTlInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath', sDdFile, ...
    'sTlModel', sTlModel, ...
    'sEnvironmentFileList', sLegacyCodeXml, ...
    'xEnv', xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
try 
    i_check_code_model(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C-Code', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%% CodeModel
function i_check_code_model(sCodeModel)
if ~exist(sCodeModel, 'file')
    MU_FAIL('CodeModel XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sCodeModel);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

sExpectedInitFunc = 'my_init_func';
astFuncs = mxx_xmltree('get_attributes', hDoc, '/CodeModel/Functions/Function', 'initFunc');
if (length(astFuncs) == 3)
    casFoundInitFuncs = {astFuncs(:).initFunc};
    MU_ASSERT_TRUE(all(strcmp(casFoundInitFuncs, sExpectedInitFunc)), 'Unexpected init function name.');
else
    MU_FAIL('Unexpected number of functions.');
end
end


