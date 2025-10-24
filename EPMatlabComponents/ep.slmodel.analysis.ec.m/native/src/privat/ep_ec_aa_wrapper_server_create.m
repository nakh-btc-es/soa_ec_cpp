function stServerModel = ep_ec_aa_wrapper_server_create(stArgs, oWrapperData, oWrapperConfig)
% Creates the mock server model for the Adaptive Autosar wrapper model usecase
%
%  function ep_ec_aa_wrapper_server_create(stModel, oWrapperData, oWrapperConfig)
%
%  INPUT                        DESCRIPTION
%
%   - stModel                Information about the original model
%   - oWrapperData           Wrapper data dictionary object
%   - oWrapperConfig         Wrapper configuration data  object
%
%  OUTPUT                       DESCRIPTION
%    - stServerModel
%         .hModel           (string)  Handle of the created mock server model(might be empty if not successful)
%         .sModelFile       (string)  Full path to the created mock server model(might be empty if not successful)
%      .aoMockServerPorts   (array)   Information about the provider ports
%
%

%%
stServerModel = struct( ...
    'hModel',            [], ...
    'sName',             '', ...
    'sModelFile',        '', ...
    'aoMockServerPorts', []);

sServerModelName = ['W_server_', stArgs.sName];
stServerModel.sName = sServerModelName;
stServerModel.hModel = Eca.aa.wrapper.Utils.createModel(sServerModelName, Eca.aa.wrapper.Tag.Server);
try
    set_param(stServerModel.hModel, 'SetExecutionDomain', 'on');
    set_param(stServerModel.hModel, 'ExecutionDomainType', 'ExportFunction');

    i_setModelConfigAndDataDictionary(sServerModelName, oWrapperConfig, oWrapperData.getFileDD);
    stServerModel.aoMockServerPorts = ...
        i_createMockServer(sServerModelName, stArgs.aoRequiredMethods, oWrapperData);

    stServerModel.sModelFile = fullfile(stArgs.sPath, [sServerModelName, '.slx']);
    Eca.aa.wrapper.Utils.saveModel(sServerModelName, stServerModel.sModelFile);

catch oEx
    i_cleanupAfterAbort(stServerModel.hModel);
    rethrow(oEx);
end
end



%%
function i_setModelConfigAndDataDictionary(sModelName, oWrapperConfigSet, sFileDD)
oOwnConfigSet = copy(oWrapperConfigSet);
attachConfigSet(sModelName, oOwnConfigSet);
setActiveConfigSet(sModelName, get_param(oOwnConfigSet, 'Name'));

if ~isempty(sFileDD)
    [~, f, e] = fileparts(sFileDD);
    set_param(sModelName, 'DataDictionary', [f, e]);
end
end


%%
function i_cleanupAfterAbort(hModel)
if ~isempty(hModel)
    try %#ok<TRYNC>
        close_system(hModel, 0);
    end
end
end


%%
function oPortInfo = i_createMockServerFunctions(sWrapperModelName, oRequiredMethod, stPositions, oWrapperData, oPortNameMap)
oPortInfo = Eca.aa.wrapper.Port;

[sFunName, sPortName] = oRequiredMethod.getFunctionParts();
sSlFuncBlkName = ['Mock_' oRequiredMethod.getDisplayFunctionName()];

%Add Simulink Function block
sSlFunPath = i_addSLFuncBlk([sWrapperModelName '/' sSlFuncBlkName], stPositions, sFunName, oRequiredMethod.sArPortName);

% Add Function Element Call
[oPortInfo.sPortName, oPortInfo.nPortNum] = i_addFuncElemBlks(oPortNameMap, sPortName, sFunName, stPositions, sWrapperModelName);

% Call the server mock
sServerMockName = oRequiredMethod.getCodeGlobalFunction();
sFctCallBlockName = ['Call_' sServerMockName];
sFctCallBlkPath = [sWrapperModelName '/' sSlFuncBlkName '/' sFctCallBlockName];
hFctCallBlk= i_addServerMockCaller(sFctCallBlkPath, sSlFunPath, numel(oRequiredMethod.aoFunctionInArgs), numel(oRequiredMethod.aoFunctionOutArgs));

casArgInNames = arrayfun(@(o) o.sName, oRequiredMethod.aoFunctionInArgs, 'UniformOutput', false);
casArgOutNames = arrayfun(@(o) o.sName, oRequiredMethod.aoFunctionOutArgs, 'UniformOutput', false);

set_param(hFctCallBlk, 'FunctionPrototype', i_createPrototype(sServerMockName, casArgInNames, casArgOutNames));
set_param(hFctCallBlk, 'InputArgumentSpecifications', i_createArgSpec(oRequiredMethod.aoFunctionInArgs, oWrapperData));
set_param(hFctCallBlk, 'OutputArgumentSpecifications', i_createArgSpec(oRequiredMethod.aoFunctionOutArgs, oWrapperData));

i_addInFuncArgBlks(oRequiredMethod.aoFunctionInArgs, sSlFunPath, sFctCallBlockName);
i_addOutFuncArgBlks(oRequiredMethod.aoFunctionOutArgs, sSlFunPath, sFctCallBlockName);
end


%%
function hFctCallBlk = i_addServerMockCaller(sFctCallBlkPath, sSlFunPath, nFunctionInArgsSize, nFunctionOutArgsSize)

hFctCallBlk = add_block('simulink/User-Defined Functions/Function Caller', sFctCallBlkPath);

% set position
sDummyInLibBlk = i_getLibArgs(sSlFunPath, 'ArgIn');
nInPos = get_param(sDummyInLibBlk, 'Position');
nInPos = nInPos{1};
sDummyOutLibBlk = i_getLibArgs(sSlFunPath, 'ArgOut');
nOutPos = get_param(sDummyOutLibBlk, 'Position');
nOutPos = nOutPos{1};
width = 150;
h = max(nFunctionInArgsSize, nFunctionOutArgsSize)*30;
left = nInPos(1)+((nOutPos(1)-nInPos(1))/2-width/2) ;
top = nOutPos(2)-h;
right = left+width;
bottom = top+2*h;
nFctCallPos = [left, top, right, bottom] ;
set(hFctCallBlk, 'Position', nFctCallPos);
end


%%
function [sPortName, nPortNum, hMockServerPort] = i_addFuncElemBlks(oPortNameMap, sPortName, sFunName, stPositions, sWrapperModelName)
% EPDEV-71558 Function elements with identical PortName need a special treatment
if oPortNameMap.containsKey(sPortName)
    hMockServerPort = add_block(getfullname(oPortNameMap.get(sPortName)), ...
        [sWrapperModelName '/' 'FctElem'], ...
        'MakeNameUnique','on', ...
        'Element', sFunName);
else
    hMockServerPort = add_block('simulink/Ports & Subsystems/Function Element', ...
        [sWrapperModelName '/' 'FctElem'], ...
        'MakeNameUnique','on', ...
        'PortName', sPortName, ...
        'Element', sFunName);

    oPortNameMap.put(sPortName, hMockServerPort);
end
sPortNr = get_param(hMockServerPort, 'Port');
sPortName = get_param(hMockServerPort, 'PortName');
nPortNum = str2double(sPortNr);

i_setPosFromTopLeft(hMockServerPort, stPositions);
end


%%
function sSlFunPath = i_addSLFuncBlk(sSlFunBlkPath, stPositions, sFunName, sPortName)
hSlFunBlk = add_block('simulink/User-Defined Functions/Simulink Function', sSlFunBlkPath);
set(hSlFunBlk, 'ForegroundColor', 'Blue');

%Arrange positions
i_setPosFromTopLeft(hSlFunBlk, stPositions);

%Set Function name and visibility
sSlFunPath = getfullname(hSlFunBlk);
sTriggerBlk = ep_find_system(sSlFunPath, 'BlockType', 'TriggerPort', 'IsSimulinkFunction', 'on');
set_param(char(sTriggerBlk), 'FunctionName', sFunName);
set_param(char(sTriggerBlk), 'ScopeName', sPortName);
set_param(char(sTriggerBlk), 'FunctionVisibility', 'port');
hTriggerBlk = get_param(sTriggerBlk{1}, 'Handle');
set_param(hTriggerBlk, 'Name', sFunName);

%-delete line in the added block
hLines = ep_find_system(sSlFunPath, 'FindAll', 'on', 'Type', 'Line');
for iL = 1:numel(hLines)
    delete_line(hLines(iL));
end
end


%%
function i_addInFuncArgBlks(aoFunctionInArgs, sSlFunPath, sFctCallBlockName)
cntArgIn = 0;
sDummyInLibBlk = i_getLibArgs(sSlFunPath, 'ArgIn');
nInPos = get_param(sDummyInLibBlk, 'Position');
nInPos = nInPos{1};

%-delete Argument Inport if no input arguments
if isempty(aoFunctionInArgs)
    delete_block(char(sDummyInLibBlk));
else
    %-else add as many needed and connect Function caller
    w = nInPos(3)-nInPos(1);
    h = nInPos(4)-nInPos(2);
    delete_block(char(sDummyInLibBlk));
    for iArg = 1:numel(aoFunctionInArgs)
        oArg = aoFunctionInArgs(iArg);

        cntArgIn = cntArgIn+1;
        sInFuncArgName = oArg.sName;
        sInPortName = ['argIn_' sInFuncArgName];
        nInPos = [nInPos(1)-100 nInPos(2)+h+(20)*iArg nInPos(1)+w-100 nInPos(2)+2*h+(20)*iArg];
        sArgInLibBlk=[sSlFunPath '/' sInPortName];
        hArgInBlk = add_block('built-in/ArgIn',sArgInLibBlk, 'ArgumentName', sInFuncArgName, 'Name', sInPortName);
        set(hArgInBlk, 'Position', nInPos);
        sArgInBlk = getfullname(hArgInBlk);
        sInArgsDT = oArg.sOutDataTypeStr;
        set_param(sArgInBlk, 'OutDataTypeStr', sInArgsDT);

        sDimForSetting = oArg.getDimForPortAttributeSetting;
        set_param(sArgInBlk, 'PortDimensions', sDimForSetting);

        add_line(sSlFunPath, [sInPortName '/1'], [sFctCallBlockName '/' num2str(iArg)], 'autorouting', 'on');
    end
end
end


%%
function i_addOutFuncArgBlks(aoFunctionOutArgs, sSlFunPath, sFctCallBlockName)
cntArgOut = 0;
sDummyOutLibBlk = i_getLibArgs(sSlFunPath, 'ArgOut');
nOutPos = get_param(sDummyOutLibBlk, 'Position');
nOutPos = nOutPos{1};

%-delete Argument Outport if not Output arguments
if isempty(aoFunctionOutArgs)
    delete_block(char(sDummyOutLibBlk)); %delete the signal ArgIn block provided with the library block
else
    %-else add as many needed and connect Function caller
    w = nOutPos(3)-nOutPos(1);
    h = nOutPos(4)-nOutPos(2);
    nOutPos(1) = nOutPos(1) + 100; %shift block further more on right side
    nOutPos(3) = nOutPos(3) + 100;
    delete_block(char(sDummyOutLibBlk));
    for iArg = 1:numel(aoFunctionOutArgs)
        oArg = aoFunctionOutArgs(iArg);

        cntArgOut = cntArgOut+1;
        sOutFuncArgName = oArg.sName;
        sOutPortName = ['argOut_' sOutFuncArgName];
        nOutPos = [nOutPos(1)+100 nOutPos(2)+h+(20)*(iArg) nOutPos(1)+w+100 nOutPos(2)+2*h+(20)*(iArg) ];
        sArgOutLibBlk= [sSlFunPath '/' sOutPortName];
        hArgOutBlk = add_block('built-in/ArgOut', sArgOutLibBlk, 'ArgumentName', sOutFuncArgName, 'Name', sOutPortName);
        set(hArgOutBlk, 'Position', nOutPos);
        sArgOutBlk = getfullname(hArgOutBlk);
        sOutArgsDT = oArg.sOutDataTypeStr;
        set_param(sArgOutBlk, 'OutDataTypeStr', sOutArgsDT);

        sDimForSetting = oArg.getDimForPortAttributeSetting;
        set_param(sArgOutBlk, 'PortDimensions', sDimForSetting);

        add_line(sSlFunPath, [sFctCallBlockName '/' num2str(iArg)], [sOutPortName '/1'], 'autorouting', 'on');
    end
end
end


%%
function i_setPosFromTopLeft(hdl_or_sys, stPositions)
cntSLFBlk = stPositions.cnt; %used to shift position
stPositions.P2_Min=stPositions.P2_Min+stPositions.VSHIFT;
SLFUNBLK_WIDTH =floor(stPositions.AREA_WIDTH/stPositions.HQTY) - stPositions.HSHIFT;
pt1 = stPositions.P1_Min + (stPositions.HSHIFT + SLFUNBLK_WIDTH)*(mod(cntSLFBlk-1, stPositions.HQTY));
pt2 = stPositions.P2_Min + floor((cntSLFBlk-1)/stPositions.HQTY)*(stPositions.SLFUNBLK_HEIGHT+stPositions.VSHIFT);
l = SLFUNBLK_WIDTH;
h = stPositions.SLFUNBLK_HEIGHT;
nPos = [pt1, pt2, pt1+l, pt2+h];
if ischar(hdl_or_sys)
    set_param(hdl_or_sys,'Position', nPos);
else
    set(hdl_or_sys,'Position', nPos);
end
end


%%
function sArgLibBlk = i_getLibArgs(hFunCallerBlk, sType)
sArgLibBlk = ep_find_system(hFunCallerBlk, 'BlockType', sType);
end


%%
function aoServerPorts = i_createMockServer(sServerModelName, aoRequiredMethods, oWrapperData)
aoServerPorts = [];
stPositions = struct( ...
    'AREA_WIDTH',      1000, ...
    'SLFUNBLK_HEIGHT', 80, ...
    'HSHIFT',          100, ...
    'VSHIFT',          30, ...
    'HQTY',            3, ...
    'P1_Min',          -500, ...
    'cnt',             0, ...
    'P2_Min',          -500);

% Portname -> Blockhandle
jPortNameMap = java.util.HashMap();
for i = 1:numel(aoRequiredMethods)
    oServerPort = i_createMockServerFunctions(sServerModelName, aoRequiredMethods(i), stPositions, oWrapperData, jPortNameMap);
    aoServerPorts = [aoServerPorts oServerPort]; %#ok
end
try %#ok<TRYNC>
    Simulink.BlockDiagram.arrangeSystem(sServerModelName, 'FullLayout', true);
end
end


%%
function sResult = i_createArgSpec(aoFuncArgs, oWrapperData)
casInstances = arrayfun(@(o) oWrapperData.getTypeInstance(o.sDataType, o.aiDim), aoFuncArgs, 'UniformOutput', false);
sResult = strjoin(casInstances, ', ');
end


%%
function sPrototype = i_createPrototype(sFunctionName, casArgInNames, casArgOutNames)
if isempty(casArgOutNames)
    sOutParts = '';
else
    if numel(casArgOutNames) == 1
        sOutParts = [casArgOutNames{1} ' = '];
    else
        sOutParts = sprintf('[%s] = ', strjoin(casArgOutNames, ', '));
    end
end

sInParts = sprintf('(%s)', strjoin(casArgInNames, ', '));
sPrototype = [sOutParts sFunctionName sInParts];
end
