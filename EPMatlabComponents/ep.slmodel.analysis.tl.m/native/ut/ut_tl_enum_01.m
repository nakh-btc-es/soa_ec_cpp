function ut_tl_enum_01
% Check TL enum support.
%


%% testdata only for TL4.2 and higher
if ep_core_version_compare('TL4.2') < 0
    MU_MESSAGE('TEST SKIPPED: Testdata with TL-Enums only for TL4.2 and higher.');
    return;
end

%% prepare test
ut_cleanup();

sPwd = pwd;
sTestRoot = fullfile(sPwd, 'tl_enum_01');
[xOnCleanupDoCleanupEnv, xEnv, sResultDir, stTestData] = sltu_prepare_ats_env('TLEnums', 'TL', sTestRoot);

[sModelPath, sTlModel]  = fileparts(stTestData.sTlModelFile);
sTlModelFile   = stTestData.sTlModelFile;
sDdFile        = fullfile(sModelPath, 'tlEnum.dd');
sTlInitScript  = stTestData.sTlInitScriptFile;

%% arrange
xOnCleanupCloseModelTL = ut_load_models(xEnv, sTlModelFile, sTlInitScript);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% act
stOpt = struct( ...
    'sDdPath',         sDdFile, ...
    'sTlModel',        sTlModel, ...
    'bAddEnvironment', true, ... % import as Closed-Loop
    'xEnv',            xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);
ut_ep_model_analyse(stOpt);


%% assert
oExpectedEnumsMIL = containers.Map;

% ------------------- MIL Enums ----------------------
oExpectedEnumsMIL('BasicColors') = struct( ...
    'Red',    0, ...
    'Yellow', 1, ...
    'Blue',   2);
oExpectedEnumsMIL('MyBasicColors') = struct( ...
    'MyRed',    0, ...
    'MyYellow', 1, ...
    'MyBlue',   2);
oExpectedEnumsMIL('OtherColors') = struct( ...
    'Black', 100, ...
    'White', 200, ...
    'Grey',  300);
oExpectedEnumsMIL('MyPseudoBasicColors') = struct( ...
    'MyPRed',    0, ...
    'MyPYellow', 1, ...
    'MyPBlue',   2);
oExpectedEnumsMIL('ChartModeType') = struct( ...
    'None',  0, ...
    'State', 1);

% ------------------- SIL Enums ----------------------
oExpectedEnumsSIL = containers.Map;
oExpectedEnumsSIL('BasicColors') = struct( ...
    'BASICCOLORS_RED',    0, ...
    'BASICCOLORS_YELLOW', 1, ...
    'BASICCOLORS_BLUE',   2);
oExpectedEnumsSIL('MyEnum') = struct( ...
    'MyRed',    0, ...
    'MyYellow', 1, ...
    'MyBlue',   2);
oExpectedEnumsSIL('OtherColors') = struct( ...
    'OTHERCOLORS_BLACK', 100, ...
    'OTHERCOLORS_WHITE', 200, ...
    'OTHERCOLORS_GREY',  300);
oExpectedEnumsSIL('MyPseudoEnum') = struct( ...
    'MyPRed',    0, ...
    'MyPYellow', 1, ...
    'MyPBlue',   2);
oExpectedEnumsSIL('ChartModeType') = struct( ...
    'CHARTMODETYPE_NONE',  0, ...
    'CHARTMODETYPE_STATE', 1);

% ------------------- Interface types ---------------------
oExpectedIfTypes = containers.Map;

% scope: my_frame
oExpectedIfTypes('in:my_frame/In1:1') = 'BasicColors|< >';
oExpectedIfTypes('in:my_frame/In2:2') = 'OtherColors|< >';
oExpectedIfTypes('in:my_frame/In3:3') = 'MyBasicColors|< >';
oExpectedIfTypes('out:my_frame/Out1:1') = 'OtherColors|< >';
oExpectedIfTypes('out:my_frame/Out2:2') = 'ChartModeType|< >';
oExpectedIfTypes('out:my_frame/Out3:3') = 'BasicColors|< >';
oExpectedIfTypes('out:my_frame/Out4:4') = 'MyBasicColors,MyPseudoBasicColors|< >';
oExpectedIfTypes('out:my_frame/Out5:5') = 'MyPseudoBasicColors|< >';

% scope: my_frame/enums/Subsystem/enums
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/In1:1') = 'BasicColors|BasicColors';
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/InChart:2') = 'OtherColors|OtherColors';
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/InMatrix:3') = 'MyBasicColors|MyEnum';
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/InPseudo:4') = 'MyPseudoBasicColors|MyPseudoEnum';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/OutChart:1') = 'OtherColors|OtherColors';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/ChartMode:2') = 'ChartModeType|ChartModeType';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/OutBusBasic:3') = 'BasicColors|BasicColors';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/OutMatrix:4') = 'MyBasicColors|MyEnum';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/OutPseudo:5') = 'MyPseudoBasicColors|MyPseudoEnum';

% scope: my_frame/enums/Subsystem/enums/Matrix
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/Matrix/In1:1') = 'MyBasicColors|MyEnum';
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/Matrix/In2:2') = 'BasicColors|BasicColors';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/Matrix/Out1:1') = 'MyBasicColors|MyEnum';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/Matrix/Out2:2') = 'BasicColors|BasicColors';

% scope: my_frame/enums/Subsystem/enums/PseudoEnum
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/PseudoEnum/In1:1') = 'MyPseudoBasicColors|MyPseudoEnum';
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/PseudoEnum/In2:2') = 'MyPseudoBasicColors|MyPseudoEnum';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/PseudoEnum/Out1:1') = 'MyPseudoBasicColors|MyPseudoEnum';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/PseudoEnum/PseudoDisp:2') = 'MyPseudoBasicColors|MyPseudoEnum';

% scope: my_frame/enums/Subsystem/enums/Chart
oExpectedIfTypes('in:my_frame/enums/Subsystem/enums/Chart/inChart:1') = 'OtherColors|OtherColors';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/Chart/outChart:1') = 'OtherColors|OtherColors';
oExpectedIfTypes('out:my_frame/enums/Subsystem/enums/Chart/ChartMode:2') = 'ChartModeType|ChartModeType';

% global/shared interfaces
oExpectedIfTypes('cal:my_frame/enums/Subsystem/enums/PseudoCal:paramPseudo') = 'MyPseudoBasicColors|MyPseudoEnum';
oExpectedIfTypes('cal:my_frame/enums/Subsystem/enums/ConstScalarBasic:paramScalar') = 'BasicColors|BasicColors';
oExpectedIfTypes('cal:my_frame/enums/Subsystem/enums/ConstMatrixBasic:paramMatix') = 'BasicColors|BasicColors';
oExpectedIfTypes('cal:my_frame/enums/Subsystem/enums/Chart:paramChart') = 'OtherColors|OtherColors';

oExpectedIfTypes('disp:my_frame/enums/Subsystem/enums/ChartMode:ChartMode') = 'ChartModeType|ChartModeType';
oExpectedIfTypes('disp:my_frame/enums/Subsystem/enums/Matrix/Out2:Out2') = 'BasicColors|BasicColors';
oExpectedIfTypes('disp:my_frame/enums/Subsystem/enums/PseudoEnum/PseudoDisp:PseudoDisp') = 'MyPseudoBasicColors|MyPseudoEnum';
oExpectedIfTypes('disp:my_frame/enums/Subsystem/enums/Chart:localChart') = 'OtherColors|OtherColors';

i_checkTlArch(stOpt.sTlResultFile, oExpectedEnumsMIL, oExpectedEnumsSIL, oExpectedIfTypes);
end


%%
function i_checkTlArch(sTlArchFile, oExpectedEnumsMIL, oExpectedEnumsSIL, oExpectedIfTypes)
[oFoundEnumsMIL, oFoundEnumsSIL, oFoundIfTypes] = i_readEnumInfo(sTlArchFile);

i_compareResults('MIL Enum types', oExpectedEnumsMIL, oFoundEnumsMIL);
i_compareResults('SIL Enum types', oExpectedEnumsSIL, oFoundEnumsSIL);
i_compareResults('Interface Enum types', oExpectedIfTypes, oFoundIfTypes);
end


%%
function [oEnumsMIL, oEnumsSIL, oIfTypes] = i_readEnumInfo(sTlArchFile)
oEnumsMIL = containers.Map;
oEnumsSIL = containers.Map;
oIfTypes = containers.Map;

if ~exist(sTlArchFile, 'file')
    MU_FAIL('TL architecture XML is missing.');
    return;
end
hDoc = mxx_xmltree('load', sTlArchFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahSubs = mxx_xmltree('get_nodes', hDoc, '/tl:TargetLinkArchitecture/model/subsystem');
for i = 1:numel(ahSubs)
    i_fillEnumInfos(ahSubs(i), oEnumsMIL, oEnumsSIL, oIfTypes);
end
end


%%
function i_fillEnumInfos(hSub, oEnumsMIL, oEnumsSIL, oIfTypes)

% --- port objects ----
ahIfs = mxx_xmltree('get_nodes', hSub, './*[self::inport]');
for i = 1:numel(ahIfs)
    i_fillEnumPortInfos(ahIfs(i), 'in', oEnumsMIL, oEnumsSIL, oIfTypes);
end
ahIfs = mxx_xmltree('get_nodes', hSub, './*[self::outport]');
for i = 1:numel(ahIfs)
    i_fillEnumPortInfos(ahIfs(i), 'out', oEnumsMIL, oEnumsSIL, oIfTypes);
end

% --- global/shared objects ---
ahIfs = mxx_xmltree('get_nodes', hSub, './*[self::calibration]');
for i = 1:numel(ahIfs)
    i_fillEnumGlobalVarInfos(ahIfs(i), 'cal', oEnumsMIL, oEnumsSIL, oIfTypes);
end
ahIfs = mxx_xmltree('get_nodes', hSub, './*[self::display]');
for i = 1:numel(ahIfs)
    i_fillEnumGlobalVarInfos(ahIfs(i), 'disp', oEnumsMIL, oEnumsSIL, oIfTypes);
end
end


%%
% hIf -- either "input" or "ouput" XML node
%
function i_fillEnumPortInfos(hIf, sKind, oEnumsMIL, oEnumsSIL, oIfTypes)
sIfKey = i_getPortIfKey(hIf, sKind);

if oIfTypes.isKey(sIfKey)
    MU_FAIL(sprintf('Found port "%s" multiple times. Ports should never be repeated.', sIfKey));
    return;
end

casEnumTypesMIL = i_findAndFillEnumTypes(mxx_xmltree('get_nodes', hIf, './miltype'), oEnumsMIL);
casEnumTypesSIL = i_findAndFillEnumTypes(mxx_xmltree('get_nodes', hIf, './siltype'), oEnumsSIL);

sConcatMilSil = i_joinStrings('|', i_concatTypes(casEnumTypesMIL), i_concatTypes(casEnumTypesSIL));
oIfTypes(sIfKey) = sConcatMilSil; %#ok<NASGU> has side-effects by filling Map
end


%%
% hIf -- either "calibration" or "display" XML node
%
function i_fillEnumGlobalVarInfos(hIf, sKind, oEnumsMIL, oEnumsSIL, oIfTypes)
sIfKey = i_getGlobalVarIfKey(hIf, sKind);

if oIfTypes.isKey(sIfKey)
    % Note: global vars are shared among the subsystems; so actually no need to check them twice
    % TODO: maybe check the consistency of the type info (should be equal!) for all occurrences in XML
    return;
end

casEnumTypesMIL = i_findAndFillEnumTypes(mxx_xmltree('get_nodes', hIf, './miltype'), oEnumsMIL);
casEnumTypesSIL = i_findAndFillEnumTypes(mxx_xmltree('get_nodes', hIf, './siltype'), oEnumsSIL);

sConcatMilSil = i_joinStrings('|', i_concatTypes(casEnumTypesMIL), i_concatTypes(casEnumTypesSIL));
oIfTypes(sIfKey) = sConcatMilSil; %#ok<NASGU> has side-effects by filling Map
end


%%
% hType -- either "miltype" or "siltype" XML node
%
function casEnumTypes = i_findAndFillEnumTypes(hType, oEnumsTypesMap)
casEnumTypes = {};
ahEnumTypes = mxx_xmltree('get_nodes', hType, './/enumType');
for i = 1:numel(ahEnumTypes)
    hEnumType = ahEnumTypes(i);
    
    sEnumName = mxx_xmltree('get_attribute', hEnumType, 'name');
    if ~oEnumsTypesMap.isKey(sEnumName)
        oEnumsTypesMap(sEnumName) = i_readEnumElements(hEnumType);
    end
    if ~any(strcmp(sEnumName, casEnumTypes))
        casEnumTypes{end + 1} = sEnumName; %#ok<AGROW> need unique names in order of occurrence in XML
    end
end
end


%%
function stEnumElems = i_readEnumElements(hEnumType)
stEnumElems = struct();

astRes = mxx_xmltree('get_attributes', hEnumType, './enumElement', 'name', 'value');
for i = 1:numel(astRes)
    stEnumElems.(astRes(i).name) = sscanf(astRes(i).value, '%d');
end
end


%%
function sConcatTypes = i_concatTypes(casTypes)
sConcatTypes = i_joinStrings(',', casTypes{:});
if isempty(sConcatTypes)
    sConcatTypes = '< >';
end
end


%%
% hIf -- either "input" or "ouput" XML node
%
function sIfKey = i_getPortIfKey(hIf, sKind)
sPath = mxx_xmltree('get_attribute', hIf, 'path');
sPortNum = mxx_xmltree('get_attribute', hIf, 'portNumber');
sIfKey = i_joinStrings(':',  sKind, sPath, sPortNum);
end


%%
% hIf -- either "calibration" or "display" XML node
%
function sIfKey = i_getGlobalVarIfKey(hIf, sKind)
sPath = mxx_xmltree('get_attribute', hIf, 'path');
sName = mxx_xmltree('get_attribute', hIf, 'name');
sIfKey = i_joinStrings(':',  sKind, sPath, sName);
end


%%
function sJoinedString = i_joinStrings(sSeparator, varargin)
if (nargin < 2)
    sJoinedString = '';
else
    % join strings and put separator behind each one
    sJoinedString = sprintf(['%s', sSeparator], varargin{:});
    
    % remove the last separator
    nSepLen = length(sSeparator);
    sJoinedString(end - nSepLen + 1:end) = [];
end
end


%%
function i_compareResults(sContext, oExpMap, oFoundMap)
casExpKeys = oExpMap.keys;
casFoundKeys = oFoundMap.keys;
i_assertSetsEqual(sContext, casExpKeys, casFoundKeys);

for i = 1:length(casExpKeys)
    sKey = casExpKeys{i};
    
    if oFoundMap.isKey(sKey)
        xExpObj = oExpMap(sKey);
        xFoundObj = oFoundMap(sKey);
        
        MU_ASSERT_TRUE(isequal(xExpObj, xFoundObj), i_failMessage([sContext, ' --- ' sKey], xExpObj, xFoundObj));
    end
end
end


%%
function sMsg = i_failMessage(sContext, xExpObj, xFoundObj) %#ok<INUSD> used implicitly in eval()
sExpObj = evalc('disp(xExpObj)');
sFoundObj = evalc('disp(xFoundObj)');
sMsg = sprintf('%s -----\n... Expected ...\n"%s"\n... Found ...\n"%s".', sContext, sExpObj, sFoundObj);
end


%%
function i_assertSetsEqual(sContext, casExpSet, casFoundSet)
casMissing = setdiff(casExpSet, casFoundSet);
casUnexpected = setdiff(casFoundSet, casExpSet);
for i = 1:length(casMissing)
    MU_FAIL(sprintf('%s:\nExpected object "%s" not found.', sContext, casMissing{i}));
end
for i = 1:length(casUnexpected)
    MU_FAIL(sprintf('%s:\nUnexpected object "%s" found.', sContext, casUnexpected{i}));
end
end


