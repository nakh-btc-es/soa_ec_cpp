function ut_ep_legacy_converter_04
% Check Legacy converter functionality.
%
%  ut_ep_legacy_converter_04
%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'legacy_conv_04');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'LegacyConverter', 'signal_injection');
sModelAna = fullfile(sTestRoot, 'ModelAnalysis.xml');

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot); %#ok

%% execute test
[sTlResultFile, sSlResultFile] = i_execLegacyConverter(xEnv, sModelAna, sResultDir);


%% check test results
if ~isempty(sTlResultFile)
    try 
        i_check_tl_arch(sTlResultFile);
    catch oEx
        MU_FAIL(i_printException('TL Architecture', oEx)); 
    end
end

if ~isempty(sSlResultFile)
    try 
        i_check_sl_arch(sSlResultFile);
    catch oEx
        MU_FAIL(i_printException('SL Architecture', oEx)); 
    end
end
end


%%
function [sTlResultFile, sSlResultFile] = i_execLegacyConverter(xEnv, sModelAna, sResultDir)
sTlResultFile = fullfile(sResultDir, 'tlResult.xml');
ep_legacy_ma_model_arch_convert(xEnv, sModelAna, sTlResultFile, struct(), false);
if i_hasSlInfo(sModelAna)
    sSlResultFile = fullfile(sResultDir, 'slResult.xml');
    ep_legacy_ma_model_arch_convert(xEnv, sModelAna, sSlResultFile, struct(), true);
else
    sSlResultFile = '';
end
end


%%
function bHasSL = i_hasSlInfo(sModelAna)
bHasSL = ~isempty(mxx_xmltool(sModelAna, '/ma:ModelAnalysis/ma:Subsystem[@slPath]', 'id'));
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%%
function i_check_tl_arch(sTlResultFile)
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));

% Expect one model, which is root of the architecture.
ahDSMNodes = mxx_xmltree('get_nodes', hTlResultFile, '//dataStoreMemory');
MU_ASSERT_EQUAL(length(ahDSMNodes), 2, 'There are not two DSMs in the model');

hOwner1 = mxx_xmltree('get_nodes', hTlResultFile, '//inport[@name="DataStoreReadWithCustomCodeMask"]');
sPath1 = mxx_xmltree('get_attribute',hOwner1, 'path');
MU_ASSERT_EQUAL('controller/Subsystem/controller/SignalValidationFcnStub/DataStoreReadWithCustomCodeMask', sPath1);
hDsmNode = mxx_xmltree('get_nodes', hOwner1, './dataStoreMemory');
sSignalName1 = mxx_xmltree('get_attribute',hDsmNode, 'signalName');
MU_ASSERT_EQUAL(sSignalName1, 'StatusSignal');

% check structure of DSM inport
ahChildNodes = mxx_xmltree('get_nodes', hOwner1, './*');
MU_ASSERT_EQUAL(length(ahChildNodes), 3, 'Wrong number of child nodes in "inport[@name="DataStoreReadWithCustomCodeMask"]"');
MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahChildNodes(1)), 'miltype', 'Wrong first child in "inport[@name="DataStoreReadWithCustomCodeMask"]"');
MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahChildNodes(2)), 'siltype', 'Wrong second child in "inport[@name="DataStoreReadWithCustomCodeMask"]"');
MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahChildNodes(3)), 'dataStoreMemory', 'Wrong third child in "inport[@name="DataStoreReadWithCustomCodeMask"]"');

hOwner2 = mxx_xmltree('get_nodes', hTlResultFile, '//outport[@name="DataStoreWrite_withCustomCodeMask"]');
sPath2 = mxx_xmltree('get_attribute', hOwner2, 'path');
MU_ASSERT_EQUAL('controller/Subsystem/controller/Algorithm/DataStoreWrite_withCustomCodeMask', sPath2);
hDsmNode = mxx_xmltree('get_nodes', hOwner2, './dataStoreMemory');
sSignalName2 = mxx_xmltree('get_attribute',hDsmNode, 'signalName');
MU_ASSERT_EQUAL(sSignalName2, 'SystemState');

% check structure of DSM inport
ahChildNodes = mxx_xmltree('get_nodes', hOwner2, './*');
MU_ASSERT_EQUAL(length(ahChildNodes), 3, 'Wrong number of child nodes in "inport[@name="DataStoreWrite_withCustomCodeMask"]"');
MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahChildNodes(1)), 'miltype', 'Wrong first child in "inport[@name="DataStoreWrite_withCustomCodeMask"]"');
MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahChildNodes(2)), 'siltype', 'Wrong second child in "inport[@name="DataStoreWrite_withCustomCodeMask"]"');
MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahChildNodes(3)), 'dataStoreMemory', 'Wrong third child in "inport[@name="DataStoreWrite_withCustomCodeMask"]"');
end


%%
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));
end


