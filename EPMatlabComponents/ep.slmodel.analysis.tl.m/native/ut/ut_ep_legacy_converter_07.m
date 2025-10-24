function ut_ep_legacy_converter_07
% Check Legacy converter functionality.
%
%  ut_ep_legacy_converter_07
%


%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'legacy_conv_07');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'LegacyConverter', 'model3');
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
ahModelNodes = mxx_xmltree('get_nodes', hTlResultFile, '/tl:TargetLinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect this one model to be the root model of this architecture.
ahRootNode = mxx_xmltree('get_nodes', hTlResultFile, '/tl:TargetLinkArchitecture/root');
sModelId = mxx_xmltree('get_attribute', ahModelNodes(1), 'modelId');
sRootId = mxx_xmltree('get_attribute', ahRootNode(1), 'refModelId');
MU_ASSERT_EQUAL(sRootId, sModelId, 'The root model id differs from the model id.');

% Expect two subsystems.
ahSubsystemNodes = mxx_xmltree('get_nodes', ahModelNodes(1), 'subsystem');
MU_ASSERT_EQUAL(length(ahSubsystemNodes), 2, 'Expected two subsystems in the root model.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahSubsystemNodes(1), 'name'), 'top_A', 'Unexpected subsystem name.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahSubsystemNodes(2), 'name'), 'sub_B', 'Unexpected subsystem name.');
% Expect one root subsystem, which should have id "ss1", which is the subsystem that does not have any root.
hRootSubsystem = mxx_xmltree('get_nodes', ahModelNodes(1), 'rootSystem');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hRootSubsystem, 'refSubsysID'), 'ss1');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahSubsystemNodes(1), 'subsysID'), 'ss1');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahSubsystemNodes(2), 'subsysID'), 'ss2');
% Expect subsystems(2) to be direct child of subsystem(1).
ahSubsystem1Children = mxx_xmltree('get_nodes', ahSubsystemNodes(1), 'subsystem');
MU_ASSERT_EQUAL(length(ahSubsystem1Children), 1, 'Expected one child of the root subsystem.');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahSubsystem1Children(1), 'refSubsysID'), 'ss2', 'Expected ss2 to be child of ss1.');
end


%%
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));

end


