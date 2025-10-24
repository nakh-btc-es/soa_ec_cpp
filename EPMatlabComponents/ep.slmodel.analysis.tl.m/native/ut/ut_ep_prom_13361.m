function ut_ep_prom_13361
% Check fix for Bug PROM-13361.
%
%  REMARKS
%       Bug: Mapping does not handle DataStoreMemory blocks as interfaces
%

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $

%%
if (atgcv_version_p_compare('TL3.5') < 0)
    MU_MESSAGE('Test skipped. TL versions lower than TL3.5 not supported.');
    return;
end

if (atgcv_version_p_compare('ML7.14') < 0)
    sSimulinkExt = '.mdl';
else
    sSimulinkExt = '.slx';
end

%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'prom_13361');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'signal_injection');

sTlModel      = 'signal_injection';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, sSimulinkExt]);
sTlInitScript = fullfile(sTestRoot, 'start.m');
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);

ut_ep_model_analyse(stOpt);


%% check test results
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


%% Mapping
function i_check_mapping(sMappingResultFile)
if ~exist(sMappingResultFile, 'file')
    MU_FAIL('Mapping XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

casExpectedInputs = { ...
    'REF', ...
    'POS', ...
    'controller/Subsystem/controller/SignalValidationFcnStub/DataStoreReadWithCustomCodeMask'};
sXPath = '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Input"]/Path[@refId="id0"]';
astIns = mxx_xmltree('get_attributes', hDoc, sXPath, 'path');
casFound = {astIns(:).path};
casMissing = setdiff(casExpectedInputs, casFound);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('Missing expected Input "%s".', casMissing{i}));
end
casUnexpected = setdiff(casFound, casExpectedInputs);
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('Found uxpected Input "%s".', casUnexpected{i}));
end

casExpectedOutputs = { ...
    'UPI', ...
    'controller/Subsystem/controller/Algorithm/DataStoreWrite_withCustomCodeMask'};
sXPath = '/Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Output"]/Path[@refId="id0"]';
astOuts = mxx_xmltree('get_attributes', hDoc, sXPath, 'path');
casFound = {astOuts(:).path};
casMissing = setdiff(casExpectedOutputs, casFound);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('Missing expected Output "%s".', casMissing{i}));
end
casUnexpected = setdiff(casFound, casExpectedOutputs);
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('Found uxpected Output "%s".', casUnexpected{i}));
end
end


