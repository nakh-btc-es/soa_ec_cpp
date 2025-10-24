function ut_ep_model_analysis_01
% Basic test to check general export of model analysis info.
%
%  ut_ep_model_analysis_01
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
sTestRoot = fullfile(sPwd, 'model_ana_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'power_window_simple');

sTlModel      = 'powerwindow_tl_v01';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);
sTlInitScript = fullfile(sTestRoot, 'start.m');
sDdFile       = fullfile(sTestRoot, [sTlModel, '.dd']);

sSlModel      = 'powerwindow_sl';
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

ahModelNodes = i_get_nodes(hTlResultFile, '/tl:TargetLinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect this one model to be the root model of this architecture.
ahRootNode = i_get_node(hTlResultFile, '/tl:TargetLinkArchitecture/root');
sModelId = i_get_attribute(ahModelNodes(1), 'modelId');
sRootId = i_get_attribute(ahRootNode(1), 'refModelId');
MU_ASSERT_EQUAL(sRootId, sModelId, 'The root model id differs from the model id.');

% Expect to see one subsystem.
ahSubsystemNodes = i_get_nodes(ahModelNodes(1), 'subsystem');
MU_ASSERT_EQUAL(length(ahSubsystemNodes), 1, 'Expected one subsystem below the root model.');
MU_ASSERT_EQUAL(i_get_attribute(ahSubsystemNodes(1), 'name'), 'power_window_control', ...
    'Unexpected subsystem name.');

% Expectations about existing interfaces.
ahInports = i_get_nodes(ahSubsystemNodes(1), 'inport');
MU_ASSERT_EQUAL(length(ahInports), 8, 'Expected 8 inports.');

MU_ASSERT_EQUAL(i_get_attribute(ahInports(1), 'path'), ...
    'power_window_control/Subsystem/power_window_control/driver_neutral', ...
    'Wrong path for inport(1).');
MU_ASSERT_EQUAL(i_get_attribute(ahInports(1), 'portNumber'), '1', 'Wrong port number in inport(1)');
MU_ASSERT_EQUAL(i_get_attribute(ahInports(1), 'name'), 'driver_neutral', 'Wrong name in inport(1)');

ahCalibrations = i_get_nodes(ahSubsystemNodes(1), 'calibration');
MU_ASSERT_EQUAL(length(ahCalibrations), 4, 'Expected 4 calibrations.');

MU_ASSERT_EQUAL(i_get_attribute(ahCalibrations(3), 'path'), ...
    'power_window_control/Subsystem/power_window_control/Constant2', ...
    'Wrong path for calibration(2).');

ahOutports = i_get_nodes(ahSubsystemNodes(1), 'outport');
MU_ASSERT_EQUAL(length(ahOutports), 3, 'Expected 3 outports.');

MU_ASSERT_EQUAL(i_get_attribute(ahOutports(1), 'path'), ...
    'power_window_control/Subsystem/power_window_control/obstacle_detection', ...
    'Wrong path for ahOutports(1).');

ahDisplays = i_get_nodes(ahSubsystemNodes(1), 'display');
MU_ASSERT_EQUAL(length(ahDisplays), 2, 'Expected 2 displays.');

SLTU_ASSERT_STRINGSETS_EQUAL(i_get_attribute(ahDisplays, 'path'), ...
    {'power_window_control/Subsystem/power_window_control/obstacle_position', ...
    'power_window_control/Subsystem/power_window_control/window_position'});

% Expectations about data types.
hMiltypeNode = i_get_node(ahInports(1), 'miltype');
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'boolean');

hSiltypeNode = i_get_node(ahInports(1), 'siltype');
hActualTypeNode = i_get_node(hSiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'Bool');

% This is a MIL:double and should become a SIL:fixed-point type based on a UInt16.
hMiltypeNode = i_get_node(ahInports(7), 'miltype');
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'double');

hSiltypeNode = i_get_node(ahInports(7), 'siltype');
hActualTypeNode = i_get_node(hSiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'fixedPoint', ...
    'Expected fixed-point representation for double->UInt16+scaling MA.');
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'baseType'), 'UInt16');
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'lsb'), 0.001);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'offset'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'max'), 0.45);

% Calibration(2) should have an init value. It does not provide a MIL type -- we therefore expect to see double
% type as MIL.
hMiltypeNode = i_get_node(ahCalibrations(4), 'miltype');
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'double');
MU_ASSERT_EQUAL(i_get_double_attribute(hMiltypeNode, 'initValue'), 100.0);

hSiltypeNode = i_get_node(ahCalibrations(4), 'siltype');
hActualTypeNode = i_get_node(hSiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'fixedPoint', ...
    'Expected fixed-point representation for double->UInt16+scaling MA.');
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'baseType'), 'UInt16');
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'lsb'), 1.0);
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'lsb'), sprintf('%.16e', 1.0));
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'offset'), 0.0);
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'offset'), sprintf('%.16e', 0.0));
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'min'), 0);
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'min'), sprintf('%.16e', 0));
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'max'), 500);
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'max'), sprintf('%.16e', 500));
MU_ASSERT_EQUAL(i_get_double_attribute(hSiltypeNode, 'initValue'), 100);

% Expect calibration origin and TL usage information.
MU_ASSERT_EQUAL(i_get_attribute(ahCalibrations(2), 'origin'), 'explicit_param');
MU_ASSERT_EQUAL(i_get_attribute(ahCalibrations(2), 'workspace'), 'auto_up_time');
MU_ASSERT_EQUAL(i_get_attribute(ahCalibrations(2), 'ddPath'), '//DD0/Pool/Variables/Parameter/auto_up_time');
MU_ASSERT_EQUAL(i_get_attribute(ahCalibrations(2), 'restricted'), 'false');
hCalibrationUsage = i_get_node(ahCalibrations(2), 'usageContext');
MU_ASSERT_EQUAL(i_get_attribute(hCalibrationUsage, 'path'), ...
    'power_window_control/Subsystem/power_window_control/Constant3');
MU_ASSERT_EQUAL(i_get_attribute(hCalibrationUsage, 'targetLinkBlockKind'), 'TL_Constant');
MU_ASSERT_EQUAL(i_get_attribute(hCalibrationUsage, 'blockAttribute'), 'output');

% Expect type information in outport.
hMiltypeNode = i_get_node(ahOutports(1), 'miltype');
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'boolean');

hSiltypeNode = i_get_node(ahOutports(1), 'siltype');
hActualTypeNode = i_get_node(hSiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'baseType'), 'Int16');
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'lsb'), 1.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'offset'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'min'), -32768);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'max'), 32767);

% Expect type information in display.
hMiltypeNode = i_get_node(ahDisplays(2), 'miltype');
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'double');

hSiltypeNode = i_get_node(ahDisplays(2), 'siltype');
hActualTypeNode = i_get_node(hSiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'fixedPoint', 'Expected fixedPoint type (double->UInt16+scaling)');
MU_ASSERT_EQUAL(i_get_attribute(hActualTypeNode, 'baseType'), 'UInt16');
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'lsb'), 0.001);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'offset'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hActualTypeNode, 'max'), 0.45);


% Expect Meta Data in architecture
ahArchNodes = mxx_xmltree('get_nodes', hTlResultFile, '/tl:TargetLinkArchitecture');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahArchNodes, 'modelVersion')), ...
    'Model version has not been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahArchNodes, 'modelCreationDate')), ...
    'Creation date has not been set.');

[~,sFile,sSuffix] = fileparts(mxx_xmltree('get_attribute', ahArchNodes, 'modelPath'));
MU_ASSERT_EQUAL('powerwindow_tl_v01.mdl', [sFile, sSuffix], 'Model path has not been set.');

[~,sFile,sSuffix] = fileparts(mxx_xmltree('get_attribute', ahArchNodes, 'initScript'));
MU_ASSERT_EQUAL('start.m', [sFile, sSuffix], 'Init script has not been set.');

MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hTlResultFile, '//toolInfo[@name="Matlab"]')), ...
    'Matlab Info not added.');
if ~isempty(ver('Simulink'))
    MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hTlResultFile, '//toolInfo[@name="Simulink"]')), ...
        'Simulink Info not added.');
end
if ~isempty(ver('TL'))
    MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hTlResultFile, '//toolInfo[@name="TargetLink"]')), ...
        'TagetLink Info not added.');
end

% Expect one model, which is root of the architecture.
ahModelNodes = mxx_xmltree('get_nodes', hTlResultFile, '/tl:TargetLinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect meta data for model node
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahModelNodes, 'modelVersion')), ...
    'Model version has not been set.');

MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahModelNodes, 'creationDate')), ...
    'Creation date has not been set.');
[~,sFile,sSuffix] = fileparts(mxx_xmltree('get_attribute', ahModelNodes, 'modelPath'));
MU_ASSERT_EQUAL('powerwindow_tl_v01.mdl', [sFile, sSuffix], 'Model path has not been set.');

[~,sFile,sSuffix] = fileparts(mxx_xmltree('get_attribute', ahModelNodes, 'initScript'));
MU_ASSERT_EQUAL('start.m', [sFile, sSuffix], 'Init script has not been set.');

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

% Expect one model, which is root of the architecture.
ahModelNodes = i_get_nodes(hSlResultFile, '/sl:SimulinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect this one model to be the root model of this architecture.
ahRootNode = i_get_node(hSlResultFile, '/sl:SimulinkArchitecture/root');
sModelId = i_get_attribute(ahModelNodes(1), 'modelId');
sRootId = i_get_attribute(ahRootNode(1), 'refModelId');
MU_ASSERT_EQUAL(sRootId, sModelId, 'The root model id differs from the model id.');

% Expect to see one subsystem.
ahSubsystemNodes = i_get_nodes(ahModelNodes(1), 'subsystem');
MU_ASSERT_EQUAL(length(ahSubsystemNodes), 1, 'Expected one subsystem below the root model.');
MU_ASSERT_EQUAL(i_get_attribute(ahSubsystemNodes(1), 'name'), 'power_window_control', ...
    'Unexpected subsystem name.');

% Expectations about existing interfaces.
ahInports = i_get_nodes(ahSubsystemNodes(1), 'inport');
MU_ASSERT_EQUAL(length(ahInports), 8, 'Expected 8 inports.');

MU_ASSERT_EQUAL(i_get_attribute(ahInports(1), 'path'), ...
    'power_window_control/driver_neutral', ...
    'Wrong path for inport(1).');
MU_ASSERT_EQUAL(i_get_attribute(ahInports(1), 'portNumber'), '1', 'Wrong port number in inport(1)');
MU_ASSERT_EQUAL(i_get_attribute(ahInports(1), 'name'), 'driver_neutral', 'Wrong name in inport(1)');

ahCalibrations = i_get_nodes(ahSubsystemNodes(1), 'parameter');
MU_ASSERT_EQUAL(length(ahCalibrations), 4, 'Expected 4 parameters.');

MU_ASSERT_EQUAL(i_get_attribute(ahCalibrations(2), 'path'), ...
    'power_window_control/Constant3', ...
    'Wrong path for calibration(2).');

ahOutports = i_get_nodes(ahSubsystemNodes(1), 'outport');
MU_ASSERT_EQUAL(length(ahOutports), 3, 'Expected 3 outports.');

MU_ASSERT_EQUAL(i_get_attribute(ahOutports(1), 'path'), ...
    'power_window_control/obstacle_detection', ...
    'Wrong path for ahOutports(1).');

ahDisplays = i_get_nodes(ahSubsystemNodes(1), 'display');
MU_ASSERT_EQUAL(length(ahDisplays), 2, 'Expected 2 displays.');

SLTU_ASSERT_STRINGSETS_EQUAL(i_get_attribute(ahDisplays, 'path'), ...
    {'power_window_control/obstacle_position', ...
    'power_window_control/window_position'});

% Expectations about data types.
hMiltypeNode = ahInports(1);
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'boolean');

% This is a MIL:double.
hMiltypeNode = ahInports(7);
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'double');

% Calibration(2) should have an init value. It does not provide a MIL type -- we therefore expect to see double
% type as MIL.
hMiltypeNode = ahCalibrations(2);
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', hMiltypeNode, 'child::*')), 2, ...
    ['expected two as result ', 'child::*'  , ' node.']);
hActualTypeNode = mxx_xmltree('get_nodes', hMiltypeNode, 'child::double');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'double');
MU_ASSERT_EQUAL(i_get_double_attribute(hMiltypeNode, 'initValue'), 100);

% Expect type information in outport.
hMiltypeNode = ahOutports(1);
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'boolean');

% Expect type information in display.
hMiltypeNode = ahDisplays(2);
hActualTypeNode = i_get_node(hMiltypeNode, 'child::*');
MU_ASSERT_EQUAL(i_get_name(hActualTypeNode), 'double');

ahArchNodes = mxx_xmltree('get_nodes', hSlResultFile, '/sl:SimulinkArchitecture');

MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahArchNodes, 'modelVersion')), 'Model version has not been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahArchNodes, 'modelCreationDate')), ...
    'Creation date has not been set.');

[~, sFile, sSuffix] = fileparts(mxx_xmltree('get_attribute', ahArchNodes, 'modelPath'));
MU_ASSERT_EQUAL('powerwindow_sl.mdl', [sFile, sSuffix], 'Model path has not been set.');

[~, sFile, sSuffix] = fileparts(mxx_xmltree('get_attribute', ahArchNodes, 'initScript'));
MU_ASSERT_EQUAL('start.m', [sFile, sSuffix], 'Init script has not been set.');

MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes', hSlResultFile, '//toolInfo[@name="Matlab"]')), ...
    'Matlab Info not added.');
if ~isempty(ver('Simulink'))
    MU_ASSERT_EQUAL(1, length(mxx_xmltree('get_nodes',hSlResultFile, '//toolInfo[@name="Simulink"]')), ...
        'Simulink Info not added.');
end

% Expect one model, which is root of the architecture.
ahModelNodes = mxx_xmltree('get_nodes',hSlResultFile, '/sl:SimulinkArchitecture/model');
MU_ASSERT_EQUAL(length(ahModelNodes), 1, 'There is no model node.');

% Expect meta data for model node
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahModelNodes, 'modelVersion')), 'Model version has not been set.');
MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', ahModelNodes, 'creationDate')), 'Creation date has not been set.');

[~,sFile,sSuffix] = fileparts(mxx_xmltree('get_attribute', ahModelNodes, 'modelPath'));
MU_ASSERT_EQUAL('powerwindow_sl.mdl', [sFile, sSuffix], 'Model path has not been set.');

[~,sFile,sSuffix] = fileparts(mxx_xmltree('get_attribute', ahModelNodes, 'initScript'));
MU_ASSERT_EQUAL('start.m', [sFile, sSuffix], 'Init script has not been set.');

% Check number of parameters
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', hSlResultFile, '//subsystem[@subsysID="ss1"]/parameter')), 4, ...
    'Unexpected number of parameters in subsystem.');

% Check number of usageContext
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', hSlResultFile, '//subsystem[@subsysID="ss1"]/*/usageContext')), 4, ...
    'Unexpected number of parameters in subsystem.');

%Check Parameter 'sroutp_testcycletime'
hParameter = mxx_xmltree('get_nodes', hSlResultFile, '//subsystem[@subsysID="ss1"]/parameter[@name="auto_down_time"]');

sPath = mxx_xmltree('get_attribute', hParameter, 'path');
MU_ASSERT_EQUAL(sPath, 'power_window_control/Constant1', 'Unexpected parameter path.');

MU_ASSERT_EQUAL(i_get_double_attribute(hParameter, 'initValue'), 100, 'Unexpected init value for parameter.');

sOrigin = mxx_xmltree('get_attribute', hParameter, 'origin');
MU_ASSERT_EQUAL(sOrigin, 'explicit_param', 'Unexpected paramter origin.');

sRestricted = mxx_xmltree('get_attribute', hParameter, 'restricted');
MU_ASSERT_EQUAL(sRestricted, 'false', 'Unexpected parameter restriction.');

sWorkspace = mxx_xmltree('get_attribute', hParameter, 'workspace');
MU_ASSERT_EQUAL(sWorkspace, 'auto_down_time', 'Unexpected workspace variable for parameter.');

hUsageContext = mxx_xmltree('get_nodes', hParameter, './usageContext');

sPath = mxx_xmltree('get_attribute', hUsageContext, 'path');
MU_ASSERT_EQUAL(sPath, 'power_window_control/Constant1', 'Unexpected path for parameter usage.');
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
hCResultFile = mxx_xmltree('load', sCResultFile);
xOnCleanupCloseDocMap = onCleanup(@() mxx_xmltree('clear', hCResultFile));

% Check Functions node
ahFunctionsNode = mxx_xmltree('get_nodes', hCResultFile, '//Functions');
MU_ASSERT_EQUAL(length(ahFunctionsNode), 1);
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahFunctionsNode, 'archName'), 'powerwindow_tl_v01 [C-Code]');

% Check Function node
ahFunctionNode = mxx_xmltree('get_nodes', hCResultFile, '//Function');
MU_ASSERT_EQUAL(length(ahFunctionNode), 1);
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahFunctionNode, 'name'), 'power_window_control');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', ahFunctionNode, 'sampleTime'), '0.01');

%Interface check
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="driver_neutral"]')), 1)
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="driver_up"]')), 1)
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="driver_down"]')), 1)
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="passenger_neutral"]')), 1)
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="passenger_up"]')), 1)
MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="passenger_down"]')), 1)

MU_ASSERT_EQUAL(length(mxx_xmltree('get_nodes', hCResultFile, '//InterfaceObj')), 17);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="obstacle_position"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID1');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 0.45);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="in" and @var="window_position"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID1');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 0.45);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="cal" and @var="position_endstop_top"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID1');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.35);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 0.45);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'initVal'), 0.4);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="cal" and @var="auto_up_time"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID2');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 500);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'initVal'), 100);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="cal" and @var="emergency_down_time"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID2');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 500);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'initVal'), 100);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="cal" and @var="auto_down_time"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID2');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 500);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'initVal'), 100);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="out" and @var="Sa1_obstacle_detection"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID2');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'min'), []);
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'max'), []);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="out" and @var="Sa1_move_up"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID2');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'min'), []);
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'max'), []);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="out" and @var="Sa1_move_down"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID2');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'min'), []);
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'max'), []);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="disp" and @var="obstacle_position"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID1');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 0.45);

hInterfaceObj = mxx_xmltree('get_nodes', ahFunctionNode, './Interface/InterfaceObj[@kind="disp" and @var="window_position"]');
MU_ASSERT_EQUAL(mxx_xmltree('get_attribute', hInterfaceObj, 'scaling'), 'scID1');
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'min'), 0.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hInterfaceObj, 'max'), 0.45);

hScalingNode = mxx_xmltree('get_nodes', ahFunctionNode, '//Scaling[@id="scID1"]');
MU_ASSERT_EQUAL(i_get_double_attribute(hScalingNode, 'lsb'), 0.001);
MU_ASSERT_EQUAL(i_get_double_attribute(hScalingNode, 'offset'), 0.0);

hScalingNode = mxx_xmltree('get_nodes', ahFunctionNode, '//Scaling[@id="scID2"]');
MU_ASSERT_EQUAL(i_get_double_attribute(hScalingNode, 'lsb'), 1.0);
MU_ASSERT_EQUAL(i_get_double_attribute(hScalingNode, 'offset'), 0.0);
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

% ArchitectureMapping checks
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture');
MU_ASSERT_EQUAL(3, length(ahValues), 'Not all architectures have been mapped');

% Is Tl Model available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture[@id="id0"]');
MU_ASSERT_EQUAL('powerwindow_tl_v01', mxx_xmltree('get_attribute', ahValues(1), 'name'), ...
    'No TargetLink model has been mapped.' );

% Is C Model available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture[@id="id1"]');
MU_ASSERT_EQUAL('powerwindow_tl_v01 [C-Code]', mxx_xmltree('get_attribute', ahValues(1), 'name'), ...
    'No C-Code model has been mapped.' );

% Is Sl Model available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/Architecture[@id="id2"]');
MU_ASSERT_EQUAL('powerwindow_sl', mxx_xmltree('get_attribute', ahValues(1), 'name'), ...
    'No Simulink model has been mapped.' );

% ScopeMapping checks
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/ScopeMapping');
MU_ASSERT_EQUAL(1, length(ahValues), 'Not all scopes have been mapped');

% Is Tl Scope available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/ScopeMapping/Path[@refId="id0"]');
MU_ASSERT_EQUAL('power_window_control/Subsystem/power_window_control', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), ...
    'No TargetLink scope has been mapped.' );

% Is C Scope available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/ScopeMapping/Path[@refId="id1"]');
MU_ASSERT_EQUAL('power_window_control.c:1:power_window_control', ...
    mxx_xmltree('get_attribute', ahValues(1), 'path'), ...
    'No C-Code scope has been mapped.' );

% Is Sl Scope available
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, '//Mappings/ArchitectureMapping/ScopeMapping/Path[@refId="id2"]');
MU_ASSERT_EQUAL('power_window_control', mxx_xmltree('get_attribute', ahValues(1), 'path'), ...
    'No Simulink scope has been mapped.' );

% Interface object check
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Input"]');
MU_ASSERT_EQUAL(8, length(ahValues), 'Not all inputs have been mapped');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Output"]');
MU_ASSERT_EQUAL(3, length(ahValues), 'Not all outputs have been mapped');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Parameter"]');
MU_ASSERT_EQUAL(4, length(ahValues), 'Not all parameters have been mapped');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]');
MU_ASSERT_EQUAL(2, length(ahValues), 'Not all locals have been mapped');

% Input checks
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path, ''driver_neutral'')]');
MU_ASSERT_EQUAL(3, length(ahValues), 'Input ''driver_neutral'' has not been mapped completely.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[@path="driver_up" and @refId="id0"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'TL-Input driver_up has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path, ''driver_up'') and @refId="id1"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'C-Input driver_up has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[@path="driver_up" and @refId="id2"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'SL-Input driver_up has not been mapped.');

% Output checks
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path, ''obstacle_detection'') or contains(@path,''Sa1_obstacle_detection'')]');
MU_ASSERT_EQUAL(3, length(ahValues), 'Output ''obstacle_detection'' has not been mapped completely.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[@path="move_up" and @refId="id0"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'TL-output move_up has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path, ''Sa1_move_up'') and @refId="id1"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'C-output move_up has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[@path="move_up" and @refId="id2"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'SL-output move_up has not been mapped.');

% Parameters checks
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path,''position_endstop_top'')]/../Path');
MU_ASSERT_EQUAL(3, length(ahValues), 'Parameter ''position_endstop_top'' has not been mapped completely.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path,''auto_up_time'')]/../Path[@refId="id0"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'TL-Parameter auto_up_time has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path,''auto_up_time'')]/../Path[@refId="id1"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'C-Parameter auto_up_time has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping/Path[contains(@path,''auto_up_time'')]/../Path[@refId="id2"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'SL-Parameter auto_up_time has not been mapped.');

% Locals checks
ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]/Path[contains(@path,''obstacle_position'')]/../Path');
MU_ASSERT_EQUAL(3, length(ahValues), 'Parameter ''obstacle_position'' has not been mapped completely.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]/Path[contains(@path,''window_position'')]/../Path[@refId="id0"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'TL-Local window_position has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]/Path[contains(@path,''window_position'')]/../Path[@refId="id1"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'C-Local window_position has not been mapped.');

ahValues = mxx_xmltree('get_nodes', hMappingResultFile, ...
    '//Mappings/ArchitectureMapping/ScopeMapping/InterfaceObjectMapping[@kind="Local"]/Path[contains(@path,''window_position'')]/../Path[@refId="id2"]');
MU_ASSERT_EQUAL(1, length(ahValues), 'SL-Local window_position has not been mapped.');
end


%%
function sValue = i_get_attribute(hNode, sAttributeName)
if (numel(hNode) > 1)
    % NOTE: returning actually a cell-array of strings here!
    sValue = arrayfun(@(h) mxx_xmltree('get_attribute', h, sAttributeName), hNode, 'UniformOutput', false); 
else
    sValue = mxx_xmltree('get_attribute', hNode, sAttributeName);
end
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
function ahNodes = i_get_nodes(hParent, sXpath)
ahNodes = mxx_xmltree('get_nodes', hParent, sXpath);
end


%%
function hParent = i_get_node(hParent, sNodeName)
ahNodes = mxx_xmltree('get_nodes', hParent, sNodeName);
MU_ASSERT_EQUAL(length(ahNodes), 1, ['expected one result ', sNodeName, ' node.']);
hParent = ahNodes(1);
end


%%
function sName = i_get_name(hNode)
sName = mxx_xmltree('get_name', hNode);
end

