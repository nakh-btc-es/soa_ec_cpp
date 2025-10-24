function ut_ep_model_analysis_03
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_03
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
sTestRoot = fullfile(sPwd, 'model_ana_03');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'explicit_param');

sTlModel      = 'model1';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, [sTlModel, '_mdl.m']);
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
    i_checkTlConstraints(stOpt.sTlArchConstrFile);
catch oEx
    MU_FAIL(i_printException('TL Constraints', oEx)); 
end

try 
    i_checkCConstraints(stOpt.sCArchConstrFile);
catch oEx
    MU_FAIL(i_printException('C Constraints', oEx)); 
end

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
    i_check_mapping(stOpt.sMappingResultFile);
catch oEx
    MU_FAIL(i_printException('Mapping', oEx)); 
end
end


%%
function sException = i_printException(sContext, oEx)
sException = sprintf('Exception in context "%s".\n%s', sContext, oEx.message);
end


%% TL
function i_checkTlConstraints(sTlConstraintsResultFile)
if ~exist(sTlConstraintsResultFile, 'file')
    MU_FAIL('TL constraints XML missing.');
    return;
end

hTlConstraintsResultFile = mxx_xmltree('load', sTlConstraintsResultFile);
xOnCleanupCloseDocTlConstr = onCleanup(@() mxx_xmltree('clear', hTlConstraintsResultFile));

casXPath = { ...
    ['//scope[@path="top_A/Subsystem/top_A"]/assumptions[@origin="tl_ratelimiter:fslewrate"]/signalValue[@signal="top_A/Subsystem/top_A/sub_B3/limiter_B3/c_limiter_fall_B3" and @relation="leq" and @value="',i_double_str_2_str('0'),'"]'], ...
    ['//scope[@path="top_A/Subsystem/top_A"]/assumptions[@origin="tl_ratelimiter:rslewrate"]/signalValue[@signal="top_A/Subsystem/top_A/sub_B3/limiter_B3/c_limiter_rise_B3" and @relation="geq" and @value="', i_double_str_2_str('0'),'"]'], ...
    '//scope[@path="top_A/Subsystem/top_A"]/assumptions[@origin="tl_relay"]/signalSignal[@signal1="top_A/Subsystem/top_A/sub_B5/Relay/c_offswitch_B5" and @relation="leq" and @signal2="top_A/Subsystem/top_A/sub_B5/Relay/c_onswitch_B5"]', ...
    ['//scope[@path="top_A/Subsystem/top_A/sub_B3"]/assumptions[@origin="tl_ratelimiter:fslewrate"]/signalValue[@signal="top_A/Subsystem/top_A/sub_B3/limiter_B3/c_limiter_fall_B3" and @relation="leq" and @value="',i_double_str_2_str('0'),'"]'], ...
    ['//scope[@path="top_A/Subsystem/top_A/sub_B3"]/assumptions[@origin="tl_ratelimiter:rslewrate"]/signalValue[@signal="top_A/Subsystem/top_A/sub_B3/limiter_B3/c_limiter_rise_B3" and @relation="geq" and @value="',i_double_str_2_str('0'),'"]'], ...
    '//scope[@path="top_A/Subsystem/top_A/sub_B5"]/assumptions[@origin="tl_relay"]/signalSignal[@signal1="top_A/Subsystem/top_A/sub_B5/Relay/c_offswitch_B5" and @relation="leq" and @signal2="top_A/Subsystem/top_A/sub_B5/Relay/c_onswitch_B5"]', ...
    };

for ni=1:length(casXPath)
    MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hTlConstraintsResultFile, casXPath{ni})), ...
        ['TL Arch Constraint not found: ', ' ''', casXPath{ni},'''']);
end
end


%% C
function i_checkCConstraints(sCConstraintsResultFile)
if ~exist(sCConstraintsResultFile, 'file')
    MU_FAIL('C constraints XML missing.');
    return;
end

hCConstraintsResultFile = mxx_xmltree('load', sCConstraintsResultFile);
xOnCleanupCloseDocCConstr = onCleanup(@() mxx_xmltree('clear', hCConstraintsResultFile));

casXPath = { ...
    ['//scope[@path="top_A.c:1:Sa1_top_A"]/assumptions[@origin="tl_ratelimiter:fslewrate"]/signalValue[@signal="c_limiter_fall_B3" and @relation="leq" and @value="',i_double_str_2_str('0'),'"]'], ...
    ['//scope[@path="top_A.c:1:Sa1_top_A"]/assumptions[@origin="tl_ratelimiter:rslewrate"]/signalValue[@signal="c_limiter_rise_B3" and @relation="geq" and @value="',i_double_str_2_str('0'),'"]'], ...
    '//scope[@path="top_A.c:1:Sa1_top_A"]/assumptions[@origin="tl_relay"]/signalSignal[@signal1="c_offswitch_B5" and @relation="leq" and @signal2="c_onswitch_B5"]', ...
    ['//scope[@path="top_A.c:1:Sa1_top_A/top_A.c:1:Sa4_sub_B3"]/assumptions[@origin="tl_ratelimiter:fslewrate"]/signalValue[@signal="c_limiter_fall_B3" and @relation="leq" and @value="',i_double_str_2_str('0'),'"]'], ...
    ['//scope[@path="top_A.c:1:Sa1_top_A/top_A.c:1:Sa4_sub_B3"]/assumptions[@origin="tl_ratelimiter:rslewrate"]/signalValue[@signal="c_limiter_rise_B3" and @relation="geq" and @value="',i_double_str_2_str('0'),'"]'], ...
    '//scope[@path="top_A.c:1:Sa1_top_A/top_A.c:1:Sa6_sub_B5"]/assumptions[@origin="tl_relay"]/signalSignal[@signal1="c_offswitch_B5" and @relation="leq" and @signal2="c_onswitch_B5"]', ...
    };

for ni=1:length(casXPath)
    MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hCConstraintsResultFile, casXPath{ni})), ...
        ['C Arch Constraint not found: ', ' ''', casXPath{ni},'''']);
end
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


hCalibrationNode = mxx_xmltree('get_nodes', ahModelNodes(1), ...
    '//subsystem[@subsysID="ss1"]/calibration[@path="top_A/Subsystem/top_A/sub_B7/B7_prelook"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hCalibrationNode, 'name'), 'c_prelook_B7');
hSilTypeFixedPointInFirstArrayElem = mxx_xmltree('get_nodes', hCalibrationNode, ...
    './siltype/nonUniformArray[@size="7"]/signal[@index="1"]/fixedPoint');
MU_ASSERT_EQUAL(i_get_double_attribute(hSilTypeFixedPointInFirstArrayElem, 'lsb'), 3.90625e-03, 'wrong lsb');
MU_ASSERT_EQUAL(i_get_attribute(hSilTypeFixedPointInFirstArrayElem, 'lsb'), sprintf('%.16e', 3.90625e-03), 'wrong lsb (string representation)');
MU_ASSERT_EQUAL(i_get_double_attribute(hSilTypeFixedPointInFirstArrayElem, 'offset'), 0.0, 'wrong offset');
MU_ASSERT_EQUAL(i_get_attribute(hSilTypeFixedPointInFirstArrayElem, 'offset'), sprintf('%.16e', 0.0), 'wrong offset (string representation)');
MU_ASSERT_EQUAL(i_get_double_attribute(hSilTypeFixedPointInFirstArrayElem, 'min'), -1.28e+02, 'wrong min');
MU_ASSERT_EQUAL(i_get_attribute(hSilTypeFixedPointInFirstArrayElem, 'min'), sprintf('%.16e', -1.28e+02), 'wrong min (string representation)');
MU_ASSERT_EQUAL(i_get_double_attribute(hSilTypeFixedPointInFirstArrayElem, 'max'), 1.2799609375e+02, 'wrong max');
MU_ASSERT_EQUAL(i_get_attribute(hSilTypeFixedPointInFirstArrayElem, 'max'), sprintf('%.16e', 1.2799609375e+02), 'wrong max (string representation)');

ahThreshold_A = mxx_xmltree('get_nodes', hTlResultFile, '//calibration[@name="thresh_A"]');
MU_ASSERT_EQUAL(length(ahThreshold_A), 2, '2 calibrations with the name "thresh_A" are expected');
hThreshold_A = ahThreshold_A(1);
sThreshold_A_path = mxx_xmltree('get_attribute', hThreshold_A, 'path');
MU_ASSERT_TRUE(strcmp(sThreshold_A_path, 'top_A/Subsystem/top_A') ...
    || strcmp(sThreshold_A_path, 'top_A/Subsystem/top_A/chart_B10'), ...
    'Wrong path for thresh_A found');
hThreshold_A = ahThreshold_A(2);
sThreshold_A_path = mxx_xmltree('get_attribute', hThreshold_A, 'path');
MU_ASSERT_TRUE(strcmp(sThreshold_A_path, 'top_A/Subsystem/top_A') ...
    || strcmp(sThreshold_A_path, 'top_A/Subsystem/top_A/chart_B10'), ...
    'Wrong path for thresh_A found');
ahThreshold_B = mxx_xmltree('get_nodes', hTlResultFile, '//calibration[@name="thresh_B"]');
MU_ASSERT_EQUAL(length(ahThreshold_B), 2, '2 calibrations with the name "thresh_B" are expected');
hThreshold_B = ahThreshold_B(1);
sThreshold_B_path = mxx_xmltree('get_attribute', hThreshold_B, 'path');
MU_ASSERT_TRUE(strcmp(sThreshold_B_path, 'top_A/Subsystem/top_A') ...
    || strcmp(sThreshold_B_path, 'top_A/Subsystem/top_A/chart_B10'), ...
    'Wrong path for thresh_B found');
hThreshold_B = ahThreshold_B(2);
sThreshold_B_path = mxx_xmltree('get_attribute', hThreshold_B, 'path');
MU_ASSERT_TRUE(strcmp(sThreshold_B_path, 'top_A/Subsystem/top_A') ...
    || strcmp(sThreshold_B_path, 'top_A/Subsystem/top_A/chart_B10'), ...
    'Wrong path for thresh_B found');
end


%%
function i_check_c_arch(sCResultFile)
hCResultFile = mxx_xmltree('load', sCResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hCResultFile));

% TODO
end


%%
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));

% Check ScopeMapping of <ma:Subsystem id="ss1">
hScopeMapping = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//ScopeMapping/Path[@path="top_A/Subsystem/top_A"]/..');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hScopeMapping, ...
    './Path[@path="top_A/Subsystem/top_A" and @refId="id0"]')), ...
    'Path ''top_A/Subsystem/top_A'' for ScopeMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hScopeMapping, ...
    './Path[@path="top_A.c:1:Sa1_top_A" and @refId="id1"]')), ...
    'Path ''top_A.c:1:Sa1_top_A'' for ScopeMapping not found');

% Check IOMapping of <ma:Input id="ip1"> (Simple scalar)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[@path="in1"]/..');
MU_ASSERT_EQUAL('Input', mxx_xmltree('get_attribute', hIoMapping, 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[@path="in1" and @refId="id0"]')), ...
    'Path ''in1'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''Sa1_in1'') and @refId="id1"]')), ...
    'Path ''Sa1_in1'' for IoMapping not found');

% Check IOMapping of <ma:Output id="op1"> (Simple scalar)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[@path="out1"]/..');
MU_ASSERT_EQUAL('Output', mxx_xmltree('get_attribute', hIoMapping, 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[@path="out1" and @refId="id0"]')), ...
    'Path ''out1'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''Sa1_out1'') and @refId="id1"]')), ...
    'Path ''Sa1_out1'' for IoMapping not found');

% Check IOMapping of <ma:Input id="ip10"> (Simple scalar)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[contains(@path,''c_thresh_B7'')]/..');
MU_ASSERT_EQUAL('Parameter', mxx_xmltree('get_attribute', hIoMapping, 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_thresh_B7'')]/../Path[@refId="id0"]')), ...
    'Path ''c_thresh_B7'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_thresh_B7'') and @refId="id1"]')), ...
    'Path ''c_thresh_B7'' for IoMapping not found');

% Check IOMapping of <ma:Input id="ip11"> (Matrix)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[contains(@path,''c_var_M'')]/..');
MU_ASSERT_EQUAL('Parameter', mxx_xmltree('get_attribute', hIoMapping, 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_var_M'')]/../Path[@refId="id0"]')), ...
    'Path ''c_var_M'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_var_M'') and @refId="id1"]')), ...
    'Path ''c_var_M'' for IoMapping not found');

% Check IOMapping of <ma:Input id="ip12"> (Array)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[contains(@path,''c_var_P'')]/..');
MU_ASSERT_EQUAL('Parameter', mxx_xmltree('get_attribute', hIoMapping, 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_var_P'')]/../Path[@refId="id0"]')), ...
    'Path ''c_var_P'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_var_P'') and @refId="id1"]')), ...
    'Path ''c_var_P'' for IoMapping not found');

% Check IOMapping of <ma:Input id="ip65"> (Simple scalar sfVariable differs from name)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[contains(@path,''c_thresh_B'')]/..');
MU_ASSERT_EQUAL('Parameter', mxx_xmltree('get_attribute', hIoMapping(1), 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping(1), ...
    './Path[@path="top_A/Subsystem/top_A/chart_B10/thresh_B" and @refId="id0"]')), ...
    'Path ''top_A/Subsystem/top_A/chart_B10/thresh_B'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping(1), './Path[contains(@path,''c_thresh_B'') and @refId="id1"]')), ...
    'Path ''c_thresh_B'' for IoMapping not found');

% Check IOMapping of <ma:Input id="ip66"> (Simple scalar sfVariable differs from name)
hIoMapping = mxx_xmltree('get_nodes', hScopeMapping, './InterfaceObjectMapping/Path[contains(@path,''c_thresh_A'')]/..');
MU_ASSERT_EQUAL('Parameter', mxx_xmltree('get_attribute', hIoMapping, 'kind'), 'Wrong kind has been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, ...
    './Path[@path="top_A/Subsystem/top_A/chart_B10/thresh_A" and @refId="id0"]')), ...
    'Path ''top_A/Subsystem/top_A/chart_B10/thresh_A'' for IoMapping not found');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hIoMapping, './Path[contains(@path,''c_thresh_A'') and @refId="id1"]')), ...
    'Path ''c_thresh_A'' for IoMapping not found');
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

%%
function sVal = i_double_str_2_str(sValue)
sVal = eval(['sprintf(''%.16e'', ',sValue, ')']);
end
