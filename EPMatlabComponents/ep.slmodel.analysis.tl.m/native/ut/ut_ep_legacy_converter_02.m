function ut_ep_legacy_converter_02
% Check Legacy converter functionality.
%
%  ut_ep_legacy_converter_02
%


%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'legacy_conv_02');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'LegacyConverter', 'floatsWithLimits');
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

ahSilTypes = mxx_xmltree('get_nodes', hTlResultFile, '//siltype/*');

MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahSilTypes(1)), 'Float32', 'The type is not Float32');
MU_ASSERT_EQUAL(i_get_double_attribute(ahSilTypes(1), 'min'), 0.0, 'The lower bound is not correct');
MU_ASSERT_EQUAL(i_get_double_attribute(ahSilTypes(1), 'max'), 1.2e+02, 'The upper bound is not correct');

MU_ASSERT_EQUAL(mxx_xmltree('get_name', ahSilTypes(2)), 'Float64', 'The type is not Float64');
MU_ASSERT_EQUAL(i_get_double_attribute(ahSilTypes(2), 'min'), -1.0, 'The lower bound is not correct');
MU_ASSERT_EQUAL(i_get_double_attribute(ahSilTypes(2), 'max'), 1.0e+03, 'The upper bound is not correct');


hSubsystem = mxx_xmltree('get_nodes', hTlResultFile, '//subsystem');

sScopeKind = mxx_xmltree('get_attribute', hSubsystem, 'scopeKind');
MU_ASSERT_EQUAL(sScopeKind, 'DUMMY', ['The scopeKind is not "DUMMY" but "',sScopeKind,'"']);
end


%%
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));


end


%%
function sValue = i_get_attribute(hNode, sAttributeName)
sValue = mxx_xmltree('get_attribute', hNode, sAttributeName);
end

%%
function dValue = i_get_double_attribute(hNode, sAttributeName)
sValue = i_get_attribute(hNode, sAttributeName);
if isempty(sValue)
    dValue = [];
else
    dValue = str2double(sValue);
end
end

