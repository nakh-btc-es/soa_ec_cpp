function ut_ep_model_analysis_04
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_04
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


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'ma_04');

% for ML 2022a or higher use the updated model
if (atgcv_version_p_compare('ML9.12') >= 0)
    sBurnerDir = 'simple_burner_2022a';
else
    sBurnerDir = 'simple_burner';
end
sDataDir  = fullfile(ut_local_testdata_dir_get(), sBurnerDir);

sTlModel      = 'simplebc_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, 'simplebc_mdl.m');
sDdFile       = fullfile(sTestRoot, 'simplebc.dd');

sSlModel      = 'simplebc_sl';
sSlModelFile  = fullfile(sTestRoot, [sSlModel, '.mdl']);
sSlInitScript = sTlInitScript;


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

% open both SL and TL model at once
xOnCleanupCloseModels = ut_open_model(xEnv, {sSlModelFile, sSlInitScript, false}, {sTlModelFile, sTlInitScript});

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModels, xOnCleanupDoCleanupEnv}));

%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'sSlModel',      sSlModel, ...
    'sTlInitScript', sTlInitScript, ...
    'sSlInitScript', sSlInitScript, ...
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
    i_checkSlConstraints(stOpt.sSlArchConstrFile); 
catch oEx
    MU_FAIL(i_printException('SL Constraints', oEx)); 
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


%% SL
function i_checkSlConstraints(sSlConstraintsResultFile)
if ~exist(sSlConstraintsResultFile, 'file')
    MU_FAIL('SL constraints XML missing.');
    return;
end

hSlConstraintsResultFile = mxx_xmltree('load', sSlConstraintsResultFile);
xOnCleanupCloseDocSlConstr = onCleanup(@() mxx_xmltree('clear', hSlConstraintsResultFile));

casXPath = { ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/output_verification/sr_output_verification/sroutp_testcycletime"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/output_verification/sr_output_verification/sroutp_resptime"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_standby"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_prev2"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_prev1"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_preign"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_ign"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_heating"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/input_verification/sr_input_verificaton/srinp_testcycletime"]', ...
    '//scope[@path="burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/input_verification/sr_input_verificaton/srinp_resptime"]', ...
    '//scope[@path="burnercontroller/input_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/input_verification/sr_input_verificaton/srinp_testcycletime"]', ...
    '//scope[@path="burnercontroller/input_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/input_verification/sr_input_verificaton/srinp_resptime"]', ...
    '//scope[@path="burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_standby"]', ...
    '//scope[@path="burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_prev2"]', ...
    '//scope[@path="burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_prev1"]', ...
    '//scope[@path="burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_preign"]', ...
    '//scope[@path="burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_ign"]', ...
    '//scope[@path="burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/maincontroller/maincontroller/maxcnt_heating"]', ...
    '//scope[@path="burnercontroller/output_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/output_verification/sr_output_verification/sroutp_testcycletime"]', ...
    '//scope[@path="burnercontroller/output_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/output_verification/sr_output_verification/sroutp_resptime"]', ...
    };

for ni=1:length(casXPath)
    MU_ASSERT_EQUAL(0, length(mxx_xmltree('get_nodes', hSlConstraintsResultFile, casXPath{ni})), ...
        ['SL Arch Constraint found: ', ' ''', casXPath{ni},'''']);
end
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
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/output_verification/sr_output_verification/sroutp_testcycletime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/output_verification/sr_output_verification/sroutp_resptime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_standby"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_prev2"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_prev1"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_preign"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_ign"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_heating"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/input_verification/sr_input_verificaton/srinp_testcycletime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/input_verification/sr_input_verificaton/srinp_resptime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/output_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/output_verification/sr_output_verification/sroutp_testcycletime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/output_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/output_verification/sr_output_verification/sroutp_resptime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_standby"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_prev2"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_prev1"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_preign"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_ign"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/maincontroller/maincontroller/maxcnt_heating"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/input_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/input_verification/sr_input_verificaton/srinp_testcycletime"]', ...
    '//scope[@path="burnercontroller/Subsystem/burnercontroller/input_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="burnercontroller/Subsystem/burnercontroller/input_verification/sr_input_verificaton/srinp_resptime"]', ...
    };

for ni=1:length(casXPath)
    MU_ASSERT_EQUAL(0, length(mxx_xmltree('get_nodes', hTlConstraintsResultFile, casXPath{ni})), ...
        ['TL Arch Constraint found: ', ' ''', casXPath{ni},'''']);
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
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca27_sroutp_testcycletime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca27_sroutp_resptime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca1_srinp_testcycletime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca1_srinp_resptime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa6_output_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca27_sroutp_testcycletime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa6_output_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca27_sroutp_resptime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_standby"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_prev2"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_prev1"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_preign"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_ign"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca18_maxcnt_heating"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa3_input_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca1_srinp_testcycletime"]', ...
    '//scope[@path="burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa3_input_verification"]/assumptions[@origin="cal:init"]/constSignalOverTime[@signal="Ca1_srinp_resptime"]', ...
    };

for ni=1:length(casXPath)
    MU_ASSERT_EQUAL(0, length(mxx_xmltree('get_nodes', hCConstraintsResultFile, casXPath{ni})), ...
        ['C Arch Constraint found: ', ' ''', casXPath{ni},'''']);
end
end


%***********************************************************************************************************************
% TL check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sTlResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_tl_arch(sTlResultFile)
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));

% Expect one model, which is root of the architecture.
ahModelNodes = i_get_nodes(hTlResultFile, '/tl:TargetLinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect this one model to be the root model of this architecture.
ahRootNode = i_get_node(hTlResultFile, '/tl:TargetLinkArchitecture/root');
sModelId = i_get_attribute(ahModelNodes(1), 'modelId');
sRootId = i_get_attribute(ahRootNode(1), 'refModelId');
MU_ASSERT_EQUAL(sRootId, sModelId, 'The root model id differs from the model id.');

i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="pwron"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="clk"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="gp"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="ap"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="flame"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="fs_m1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="fs_y1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="fs_ignition"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="lockout_reset"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/inport[@name="reg_ratio"]'], 'Expected port not found.');

i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="sroutp_testcycletime"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="sroutp_resptime"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="maxcnt_standby"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="maxcnt_prev2"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="maxcnt_prev1"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="maxcnt_preign"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="maxcnt_ign"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="maxcnt_heating"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="srinp_testcycletime"]'], 'Expected calibration not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/calibration[@name="srinp_resptime"]'], 'Expected calibration not found.');

i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/outport[@name="m1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/outport[@name="y1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/outport[@name="ignition"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller/Subsystem/burnercontroller"]', ...
    '/outport[@name="statusdisp"]'], 'Expected port not found.');
end

%***********************************************************************************************************************
% Sl check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sSlResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_sl_arch(sSlResultFile)
hSlResultFile = mxx_xmltree('load', sSlResultFile);
xOnCleanupCloseDocSl = onCleanup(@() mxx_xmltree('clear', hSlResultFile));

casExpectedValues = {'sroutp_testcycletime', 'sroutp_resptime', 'maxcnt_standby','maxcnt_prev2','maxcnt_prev1', ...
    'maxcnt_preign','maxcnt_ign','maxcnt_heating','srinp_testcycletime', 'srinp_resptime'};
for i=1:length(casExpectedValues)
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hSlResultFile, ...
        ['//parameter[@name="',casExpectedValues{i},'"]'])), ...
        ['Parameter ''', casExpectedValues{i},''' not extracted.']);
end


% Check number of parameters
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', hSlResultFile, '//subsystem[@subsysID="ss1"]/parameter')), 10, ...
    'Unexpected number of parameters in subsystem.');

% Check number of usageContext
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', hSlResultFile, '//subsystem[@subsysID="ss1"]/*/usageContext')), 10, ...
    'Unexpected number of parameters in subsystem.');

%Check Parameter 'sroutp_testcycletime'
hParameter = mxx_xmltree('get_nodes', hSlResultFile, ...
    '//subsystem[@subsysID="ss1"]/parameter[@name="sroutp_testcycletime"]');

sPath = mxx_xmltree('get_attribute', hParameter, 'path');
MU_ASSERT_EQUAL(sPath, 'burnercontroller/output_verification/sr_output_verification', ...
    'Unexpected parameter path.');

sInitValue = mxx_xmltree('get_attribute', hParameter, 'initValue');
MU_ASSERT_EQUAL(str2double(sInitValue), 3.0, 'Unexpected init value for parameter.');

sOrigin = mxx_xmltree('get_attribute', hParameter, 'origin');
MU_ASSERT_EQUAL(sOrigin, 'explicit_param', 'Unexpected paramter origin.');

sRestricted = mxx_xmltree('get_attribute', hParameter, 'restricted');
MU_ASSERT_EQUAL(sRestricted, 'false', 'Unexpected parameter restriction.');

sSfVar = mxx_xmltree('get_attribute', hParameter, 'workspace');
MU_ASSERT_EQUAL(sSfVar, 'sroutp_testcycletime', 'Unexpected stateflow variable for parameter.');


hUsageContext = mxx_xmltree('get_nodes', hParameter, './usageContext');

sPath = mxx_xmltree('get_attribute', hUsageContext, 'path');
MU_ASSERT_EQUAL(sPath, 'burnercontroller/output_verification/sr_output_verification', ...
    'Unexpected path for parameter usage.');

sSimulinkBlockType = mxx_xmltree('get_attribute', hUsageContext, 'simulinkBlockType');
MU_ASSERT_EQUAL(sSimulinkBlockType, 'SubSystem', 'Unexpected simulink block type for parameter usage.');

sBlockAttribute = mxx_xmltree('get_attribute', hUsageContext, 'blockAttribute');
MU_ASSERT_EQUAL(sBlockAttribute, 'sf_parameter', 'Unexpected block attribute for parameter usage.');

sStateflowVariable = mxx_xmltree('get_attribute', hUsageContext, 'stateflowVariable');
MU_ASSERT_EQUAL(sStateflowVariable, 'sroutp_testcycletime', 'Unexpected statflow variable for parameter usage.');

% Expect one model, which is root of the architecture.
ahModelNodes = i_get_nodes(hSlResultFile, '/sl:SimulinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect this one model to be the root model of this architecture.
ahRootNode = i_get_node(hSlResultFile, '/sl:SimulinkArchitecture/root');
sModelId = i_get_attribute(ahModelNodes(1), 'modelId');
sRootId = i_get_attribute(ahRootNode(1), 'refModelId');
MU_ASSERT_EQUAL(sRootId, sModelId, 'The root model id differs from the model id.');

i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="pwron"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="clk"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="gp"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="ap"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="flame"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="fs_m1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="fs_y1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="fs_ignition"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="lockout_reset"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/inport[@name="reg_ratio"]'], 'Expected port not found.');

i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="sroutp_testcycletime"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="sroutp_resptime"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="maxcnt_standby"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="maxcnt_prev2"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="maxcnt_prev1"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="maxcnt_preign"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="maxcnt_ign"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="maxcnt_heating"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="srinp_testcycletime"]'], 'Expected parameter not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/parameter[@name="srinp_resptime"]'], 'Expected parameter not found.');

i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/outport[@name="m1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/outport[@name="y1"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/outport[@name="ignition"]'], 'Expected port not found.');
i_expect_one(ahRootNode(1), ['//subsystem[@path="burnercontroller"]', ...
    '/outport[@name="statusdisp"]'], 'Expected port not found.');
end

%***********************************************************************************************************************
% C-Code check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sCResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_c_arch(sCResultFile)
% TODO add tests
end

%***********************************************************************************************************************
% Mapping check
%
%   PARAMETER(S)              DESCRIPTION
%    -  sMappingResultFile       (String)  Path to the file
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_check_mapping(sMappingResultFile)
hMappingResultFile = mxx_xmltree('load', sMappingResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hMappingResultFile));

% Is Tl Model available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture[@id="id0"]');
MU_ASSERT_EQUAL('simplebc_tl', mxx_xmltree('get_attribute', ahValues(1), 'name'), ...
    'No TargetLink model has been mapped.' );

% Is C Model available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture[@id="id1"]');
MU_ASSERT_EQUAL('simplebc_tl [C-Code]', mxx_xmltree('get_attribute', ahValues(1), 'name'), ...
    'No C-Code model has been mapped.' );

% Is Sl Model available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture[@id="id2"]');
MU_ASSERT_EQUAL('simplebc_sl', mxx_xmltree('get_attribute', ahValues(1), 'name'), ...
    'No Simulink model has been mapped.' );

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/ScopeMapping');
MU_ASSERT_EQUAL(5, length(ahValues), 'Not all scopes have been mapped');

%% ScopeMapping 1
ahScopeMapping = mxx_xmltree('get_nodes', hMappingResultFile, ['//Mappings/ArchitectureMapping/ScopeMapping/Path'...
    '[@refId="id0" and @path="burnercontroller/Subsystem/burnercontroller"]/..']);

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id0"]');
MU_ASSERT_EQUAL('burnercontroller/Subsystem/burnercontroller', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'TargetLink scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id1"]');
MU_ASSERT_EQUAL('burnercontroller.c:1:burnercontroller', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'C-Code scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id2"]');
MU_ASSERT_EQUAL('burnercontroller', mxx_xmltree('get_attribute', ahValues(1), 'path'), ...
    'Simulink scope has not been mapped.' );

%% ScopeMapping 2
ahScopeMapping = mxx_xmltree('get_nodes', hMappingResultFile, ['//Mappings/ArchitectureMapping/ScopeMapping/Path'...
    '[@refId="id0" and @path="burnercontroller/Subsystem/burnercontroller/fanspeedcontrol"]/..']);

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id0"]');
MU_ASSERT_EQUAL('burnercontroller/Subsystem/burnercontroller/fanspeedcontrol', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'TargetLink scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id1"]');
MU_ASSERT_EQUAL('burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa2_fanspeedcontrol', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'C-Code scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id2"]');
MU_ASSERT_EQUAL('burnercontroller/fanspeedcontrol', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'Simulink scope has not been mapped.' );

%% ScopeMapping 3
ahScopeMapping = mxx_xmltree('get_nodes', hMappingResultFile, ['//Mappings/ArchitectureMapping/ScopeMapping/Path'...
    '[@refId="id0" and @path="burnercontroller/Subsystem/burnercontroller/input_verification"]/..']);

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id0"]');
MU_ASSERT_EQUAL('burnercontroller/Subsystem/burnercontroller/input_verification', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'TargetLink scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id1"]');
MU_ASSERT_EQUAL('burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa3_input_verification', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'C-Code scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id2"]');
MU_ASSERT_EQUAL('burnercontroller/input_verification', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'Simulink scope has not been mapped.' );

%% ScopeMapping 4
ahScopeMapping = mxx_xmltree('get_nodes', hMappingResultFile, ['//Mappings/ArchitectureMapping/ScopeMapping/Path'...
    '[@refId="id0" and @path="burnercontroller/Subsystem/burnercontroller/maincontroller"]/..']);

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id0"]');
MU_ASSERT_EQUAL('burnercontroller/Subsystem/burnercontroller/maincontroller', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'TargetLink scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id1"]');
MU_ASSERT_EQUAL('burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa5_maincontroller', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'C-Code scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id2"]');
MU_ASSERT_EQUAL('burnercontroller/maincontroller', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'Simulink scope has not been mapped.' );

%% ScopeMapping 5
ahScopeMapping = mxx_xmltree('get_nodes', hMappingResultFile, ['//Mappings/ArchitectureMapping/ScopeMapping/Path'...
    '[@refId="id0" and @path="burnercontroller/Subsystem/burnercontroller/output_verification"]/..']);

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id0"]');
MU_ASSERT_EQUAL('burnercontroller/Subsystem/burnercontroller/output_verification', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'TargetLink scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id1"]');
MU_ASSERT_EQUAL('burnercontroller.c:1:burnercontroller/burnercontroller.c:1:Sa6_output_verification', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'C-Code scope has not been mapped.' );

ahValues = mxx_xmltree('get_nodes', ahScopeMapping, './Path[@refId="id2"]');
MU_ASSERT_EQUAL('burnercontroller/output_verification', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), 'Simulink scope has not been mapped.' );

end

%***********************************************************************************************************************
% Auxiliary method used to access XML structure
%
%   PARAMETER(S)       DESCRIPTION
%    - hNode            (handle) XML Node
%    - sAttributeName   (string) Attribute Name
%   OUTPUT
%    - sValue           (string) Return value
%***********************************************************************************************************************
function sValue = i_get_attribute(hNode, sAttributeName)
% Gets the attribute with the given sAttributeName from the hNode xml node.
sValue = mxx_xmltree('get_attribute', hNode, sAttributeName);
end

%***********************************************************************************************************************
% Auxiliary method used to access XML structure
%
%   PARAMETER(S)       DESCRIPTION
%    - hParent          (handle) XML Node
%    - sXpath           (string) X-Path expression
%   OUTPUT
%    - ahNodes          (array)  Return value
%***********************************************************************************************************************
function ahNodes = i_get_nodes(hParent, sXpath)
% Gets the child nodes below hParent that match the given sXpath xpath expression, e.g. node name.
ahNodes = mxx_xmltree('get_nodes', hParent, sXpath);
end

%***********************************************************************************************************************
% Auxiliary method used to access XML structure
%
%   PARAMETER(S)       DESCRIPTION
%    - hParent          (handle) Xml Node
%    - sNodeName        (String) Attribute Name
%   OUTPUT
%    - hParent          (handle) Return value
%***********************************************************************************************************************
function hParent = i_get_node(hParent, sNodeName)
% Gets and expects one child node below hParent that matches the given sXpath xpath expression, e.g. node name.
% Asserts only one exists.
ahNodes = mxx_xmltree('get_nodes', hParent, sNodeName);
MU_ASSERT_EQUAL(length(ahNodes), 1, ['expected one result ', sNodeName, ' node.']);
hParent = ahNodes(1);
end

%***********************************************************************************************************************
% Auxiliary method used to access XML structure
%
%   PARAMETER(S)       DESCRIPTION
%    - hParent           (handle) Xml Node
%    - sXpath            (string) XPath expression
%    - sMessage          (string) message
%   OUTPUT
%    -
%***********************************************************************************************************************
function i_expect_one(hParent, sXpath, sMessage)
ahNodes = mxx_xmltree('get_nodes', hParent, sXpath);
if nargin == 2
    MU_ASSERT_EQUAL(length(ahNodes), 1, sXpath);
else
    MU_ASSERT_EQUAL(length(ahNodes), 1, [sMessage, ' ', sXpath]);
end
end


