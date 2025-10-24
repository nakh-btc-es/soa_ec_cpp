function ut_ep_legacy_converter_06
% Check Legacy converter functionality.
%
%  ut_ep_legacy_converter_06
%


%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'legacy_conv_06');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'LegacyConverter', 'pseudo_bus');
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

% check first pseudo-bus having only a scalar
hInport = mxx_xmltree('get_nodes', hTlResultFile, ['//subsystem[@subsysID="ss2"]/', ...
    'inport[@path="TL_Controller/Subsystem/TL_Controller/Controller_Runnable/(ref)"]']);
nExpectedValue = 1;
nCurrentValue = length(mxx_xmltree('get_nodes', hInport, './miltype/double'));
MU_ASSERT_EQUAL(nExpectedValue, nCurrentValue, 'Unexpected number of miltypes.')
nCurrentValue = length(mxx_xmltree('get_nodes', hInport, './siltype/fixedPoint'));
MU_ASSERT_EQUAL(nExpectedValue, nCurrentValue, 'Unexpected number of siltypes.')

% check second pseudo-bus having only a scalar
hInport = mxx_xmltree('get_nodes', hTlResultFile, ['//subsystem[@subsysID="ss2"]/', ...
    'inport[@path="TL_Controller/Subsystem/TL_Controller/Controller_Runnable/(pos)"]']);
nExpectedValue = 1;
nCurrentValue = length(mxx_xmltree('get_nodes', hInport, './miltype/double'));
MU_ASSERT_EQUAL(nExpectedValue, nCurrentValue, 'Unexpected number of miltypes.')
nCurrentValue = length(mxx_xmltree('get_nodes', hInport, './siltype/fixedPoint'));
MU_ASSERT_EQUAL(nExpectedValue, nCurrentValue, 'Unexpected number of siltypes.')
end


%%
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));
end


