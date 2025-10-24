function ut_ep_model_analysis_05
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_05
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
sTestRoot = fullfile(sPwd, 'model_ana_05');

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
    'bCalSupport',   true, ...
    'bParamSupport', false, ...
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
        ['SL Arch Constraint not found: ', ' ''', casXPath{ni},'''']);
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
        ['C Arch Constraint not found: ', ' ''', casXPath{ni},'''']);
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

casExpectedValues = {'sroutp_testcycletime', 'sroutp_resptime', 'maxcnt_standby','maxcnt_prev2','maxcnt_prev1', ...
    'maxcnt_preign','maxcnt_ign','maxcnt_heating','srinp_testcycletime', 'srinp_resptime'};
for i=1:length(casExpectedValues)
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hTlResultFile, ...
        ['//calibration[@name="',casExpectedValues{i},'"]'])), ...
        ['Calibration ''', casExpectedValues{i},''' not extracted.']);
end
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
MU_ASSERT_EQUAL(sOrigin, 'sf_const', 'Unexpected paramter origin.');

sRestricted = mxx_xmltree('get_attribute', hParameter, 'restricted');
MU_ASSERT_EQUAL(sRestricted, 'false', 'Unexpected parameter restriction.');

sStateflowVariable = mxx_xmltree('get_attribute', hParameter, 'stateflowVariable');
MU_ASSERT_EQUAL(sStateflowVariable, 'sroutp_testcycletime', 'Unexpected stateflow variable for parameter.');

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
% TODO add tests
end

