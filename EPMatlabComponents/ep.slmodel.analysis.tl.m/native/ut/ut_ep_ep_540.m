function ut_ep_ep_540
% Check fix for Bug EP_540
%
%  REMARKS
%       Bug: Mapping for Pointer variables not correctly handled. The
%       pointer was directyl mapped which is not expected.
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%% prepare test
ut_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, 'ep-540');
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('ModelReferencesCalibration', 'TL', sTestRoot);

[~, sTlModel] = fileparts(stTestData.sTlModelFile);
sTlModelFile  = stTestData.sTlModelFile;
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);
sTlInitScript = stTestData.sTlInitScriptFile;


%% arrange
xOnCleanupCloseModelTL = ut_load_models(xEnv, sTlModelFile, sTlInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',  sDdFile, ...
    'sTlModel', sTlModel, ...
    'xEnv',     xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
try
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx));
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_check_mapping(sMappingResultFile)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

hScopeMapping = mxx_xmltree('get_nodes', hDoc, ...
    '//ScopeMapping/Path[@refId="id0" and  @path="CloseLoop/Subsystem/Subsystem/Subsystem"]/..');
hIOMapping = mxx_xmltree('get_nodes', hScopeMapping,...
    './InterfaceObjectMapping/Path[@refId="id1" and @path="Sa1_InPort"]/..');
hSignalMapping = mxx_xmltree('get_nodes', hIOMapping, './SignalMapping');
MU_ASSERT_FALSE(isempty(mxx_xmltree('get_nodes', hSignalMapping, './Path[@refId="id0" and @path=""]')));
MU_ASSERT_FALSE(isempty(mxx_xmltree('get_nodes', hSignalMapping, './Path[@refId="id1" and @path="->"]')));
end
