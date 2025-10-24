function ut_ep_model_analysis_08
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_08
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
sTestRoot = fullfile(sPwd, 'model_ana_08');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'BusPorts');

sTlModel      = 'BusPorts';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, 'bus_obj.m');
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

sSlModel      = 'BusPorts_sl';
sSlModelFile  = fullfile(sTestRoot, [sSlModel, '.mdl']);
sSlInitScript = sTlInitScript;


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ...
    ut_open_model(xEnv, {sSlModelFile, sSlInitScript, false}, {sTlModelFile, sTlInitScript});

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sSlModel',      sSlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'sSlInitScript', sSlInitScript, ...
    'bCalSupport',   true, ...
    'bParamSupport', false, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% check test results
try 
    i_check_tl_arch(stOpt.sTlResultFile);
    ut_tl_arch_consistency_check(stOpt.sTlResultFile);
catch oEx
    MU_FAIL(i_printException('TL Architecture', oEx)); 
end

try 
    i_check_c_arch(stOpt.sCResultFile);
catch oEx
    MU_FAIL(i_printException('C Architecture', oEx)); 
end

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
function i_check_tl_arch(sTlResultFile)
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));

MU_ASSERT_EQUAL(1,length(mxx_xmltree('get_nodes', hTlResultFile,...
    '//calibration[@name="Constant2[const]" and @path="Sub_A/Subsystem/Sub_A/Constant2"]')), ...
    'Calibration "Sub_A/Subsystem/Sub_A/Constant2" not found.');
end


%%
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));

MU_ASSERT_EQUAL(1,length(mxx_xmltree('get_nodes', hSlResultFile,...
    '//parameter[@name="Constant2[const]" and @path="Sub_A/Constant2"]')), ...
    'Parameter "Sub_A/Constant2" not found.');
end


%%
function i_check_c_arch(sCResultFile)
% TODO add tests
end


%%
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));

ahInterfaceObject = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//*/ScopeMapping/Path[@path="Sub_A/Subsystem/Sub_A"]/../*/Path[@refId="id1" and contains(@path,''btc_bo1.bo1_b'')]/..');
MU_ASSERT_TRUE(length(ahInterfaceObject) == 1, 'Interface object path for ''btc_bo1.bo1_b'' not correctly set.');
MU_ASSERT_TRUE(length(mxx_xmltree('get_nodes', ahInterfaceObject, ...
    './SignalMapping/Path[@refId="id1" and @path=""]')) == 1, 'Wrong acess path for signal mapping added');

asSignalToBeChecked = {'.bus_inp_1.a','.bus_inp_1.b','.bus_inp_1.c', '.bus_inp_1.d', '.bus_inp_1.e'};
for nk = 1:length(asSignalToBeChecked);
    sXPath = ['//ScopeMapping/Path[@path="Sub_A"]/../InterfaceObjectMapping/Path[@path="in."]/', ...
        '../SignalMapping/Path[@path="', asSignalToBeChecked{nk}, '"]'];
    MU_ASSERT_EQUAL(2, length(mxx_xmltree('get_nodes', hMappingResultFile, sXPath)), ...
        ['Signal Mapping information for ' , asSignalToBeChecked{nk} ,' is not valid']);
end

MU_ASSERT_EQUAL(1,length(mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//InterfaceObjectMapping[@kind="Parameter"]')));

% Check SL parameter
MU_ASSERT_EQUAL(1,length(mxx_xmltree('get_nodes', hMappingResultFile,...
    ['//InterfaceObjectMapping[@kind="Parameter"]/Path[@refId="id2"', ...
    ' and @path="Sub_A/Constant2/Constant2[const]"]'])), ...
    'Parameter "Sub_A/Constant2[const]" not found.');

% Check TL parameter
MU_ASSERT_EQUAL(1,length(mxx_xmltree('get_nodes', hMappingResultFile,...
    ['//InterfaceObjectMapping[@kind="Parameter"]/Path[@refId="id0"', ...
    ' and @path="Sub_A/Subsystem/Sub_A/Constant2/Constant2[const]"]'])), ...
    'Parameter "Sub_A/Subsystem/Sub_A/Constant2/Constant2[const]" not found.');

% Check CCode parameter
MU_ASSERT_EQUAL(1,length(mxx_xmltree('get_nodes', hMappingResultFile,...
    ['//InterfaceObjectMapping[@kind="Parameter"]/Path[@refId="id1"', ...
    ' and contains(@path,''btc_cal1'')]'])), ...
    'Parameter "btc_cal1" not found.');
end
