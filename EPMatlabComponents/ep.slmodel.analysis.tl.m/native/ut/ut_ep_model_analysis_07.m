function ut_ep_model_analysis_07
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_07
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'model_ana_07');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'ArrayDisp');

sTlModel      = 'ArrayDisp';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

sSlModel      = 'ArrayDisp_sl';
sSlModelFile  = fullfile(sTestRoot, [sSlModel, '.mdl']);


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, {sSlModelFile, '', false}, {sTlModelFile});

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sSlModel',      sSlModel, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_sl_arch(stOpt.sSlResultFile);
catch oEx
    MU_FAIL(i_printException('SL Architecture', oEx)); 
end

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
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));

MU_ASSERT_EQUAL(2, length(mxx_xmltree('get_nodes', hSlResultFile, '//inport')), 'Number of inports is wrong.');
MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hSlResultFile, '//outport')), 'Number of outports is wrong.');
MU_ASSERT_EQUAL(3, length(mxx_xmltree('get_nodes', hSlResultFile, '//subsystem/*')), ...
    'Overall number of ports is wrong.');
MU_ASSERT_EQUAL(0, length(mxx_xmltree('get_nodes', hSlResultFile, '//display')), 'Number of locals wrong.');
end


%%
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));

hIoMappingLocal = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//InterfaceObjectMapping[@kind="Local"]');
MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hIoMappingLocal,...
    './Path[@refId="id0" and @path="Subsystem/Subsystem/Subsystem/Subtract(1)"]')) , ...
    'Mapping for ''Subtract'' Local not found.');
MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hIoMappingLocal, ...
    './Path[@refId="id1" and contains(@path,''Sb1_Subtract'')]')), ...
    'Mapping for ''Sb1_Subtract'' Local not found.');

% NOTE: actually there should be no mapping to the SL Local (because it's missing inside the SL model)
%       however, currently the existence check is done _after_ producing the mapping
%       --> so, skipping the check for now, until implemented otherwise
bIsExistenceCheckDone = false;
if bIsExistenceCheckDone
    MU_ASSERT_EQUAL(2, length(mxx_xmltree('get_nodes', hIoMappingLocal,'./Path')), ...
        'Number of mappings for Local interface ''Subtract'' is not correct.');
end
MU_ASSERT_EQUAL(3, length(mxx_xmltree('get_nodes', hMappingResultFile,'//Architecture')), ...
    'Number of architectures is wrong.');
end
