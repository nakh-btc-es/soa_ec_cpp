function stClientModel = ep_ec_aa_wrapper_client_create(stClientModelArgs, oWrapperData, oWrapperConfig, casTriggerFunctionNames)
% Creates the mock client model for the Adaptive Autosar wrapper model usecase
%
%  function ep_ec_aa_wrapper_client_create(stModel, oWrapperData, oWrapperConfig)
%
%  INPUT                        DESCRIPTION
%
%   - stModel                Information about the original model
%   - oWrapperData           Wrapper data dictionary object
%   - oWrapperConfig         Wrapper configuration data  object
%
%  OUTPUT                       DESCRIPTION
%    - stClientModel
%         .hModel              (handle)  Handle of the created mock server model(might be empty if not successful)
%         .sModelFile          (string)  Full path to the created mock server model(might be empty if not successful)
%         .aoTriggerPorts      (array)   Information about the trigger ports
%         .aoClientPorts       (array)   Information about the function element call ports
%
%


%%
stClientModel = struct( ...
    'hModel',           [], ...
    'sName',            ['W_client_', stClientModelArgs.sName], ...
    'sModelFile',       '', ...
    'aoTriggerPorts',   [], ...
    'aoClientPorts',    []);

stClientModel.hModel = i_createModel(stClientModel.sName);
try
    i_setModelConfigAndDataDictionary(stClientModel.sName, oWrapperConfig, oWrapperData.getFileDD);

    [stClientModel.aoTriggerPorts, stClientModel.aoClientPorts] = ...
        i_addContent(stClientModel.hModel, stClientModelArgs.aoProvidedMethods, oWrapperData, casTriggerFunctionNames);

    stClientModel.sModelFile = fullfile(stClientModelArgs.sPath, [stClientModel.sName, '.slx']);
    Eca.aa.wrapper.Utils.saveModel(stClientModel.sName, stClientModel.sModelFile);

catch oEx
    i_cleanupAfterAbort(stClientModel.hModel);
    rethrow(oEx);
end
end


%%
function hModel = i_createModel(sModelName)
hModel = Eca.aa.wrapper.Utils.createModel(sModelName, Eca.aa.wrapper.Tag.Server);
set_param(hModel, 'SetExecutionDomain', 'on');
set_param(hModel, 'ExecutionDomainType', 'ExportFunction');
end


%%
function [aoTriggerPorts, aoClientPorts] = i_addContent(hModel, aoProvidedMethods, oWrapperData, casTriggerFunctionNames)
nMethods = numel(aoProvidedMethods);
aoTriggerPorts = repmat(Eca.aa.wrapper.Port, 1, nMethods);
for i = 1:nMethods
    i_addMethodCallingSubsys(hModel, aoProvidedMethods(i), oWrapperData, casTriggerFunctionNames{i});
end

aoClientPorts = repmat(Eca.aa.wrapper.Port, 1, nMethods);

% Portname -> Blockhandle
oPortNameMap = java.util.HashMap();
for i = 1:nMethods
    aoClientPorts(i) = i_addFunctionElementCall(hModel, aoProvidedMethods(i), i, oPortNameMap);
end
end


%%
function hSlFunBlk = i_addMethodCallingSubsys(hModel, oProvidedMethod, oWrapperData, sTriggerFunctionName)
cntArgIn = 0;
cntArgOut = 0;
%Add Simulink function
hSlFunBlk = add_block('simulink/User-Defined Functions/Simulink Function', [get_param(hModel, 'Name') '/' ['sut_', oProvidedMethod.getDisplayFunctionName()]]);
sSlFunPath = getfullname(hSlFunBlk);
%-rename the trigger port 
hTriggerPort = ep_find_system(sSlFunPath, 'FindAll', 'on', 'BlockType', 'TriggerPort');
set_param(hTriggerPort, 'Name', sTriggerFunctionName);
set_param(hTriggerPort, 'FunctionName', sTriggerFunctionName);
set_param(hTriggerPort, 'FunctionVisibility', 'global');
%-delete line in the added block
hLines = ep_find_system(sSlFunPath, 'FindAll', 'on', 'Type', 'Line');
for iL = 1:numel(hLines)
    delete_line(hLines(iL));
end
% Add Function Caller
[~, sFctCallBlockName] = i_addFunctionCallBlock(sSlFunPath, oProvidedMethod, oWrapperData);

sDummyInLibBlk = i_getLibArgs(sSlFunPath, 'ArgIn');
nInPos = get_param(sDummyInLibBlk, 'Position');
nInPos = nInPos{1};
sDummyOutLibBlk = i_getLibArgs(sSlFunPath, 'ArgOut');
nOutPos = get_param(sDummyOutLibBlk, 'Position');
nOutPos = nOutPos{1};

%-delete Argument Inport if no input arguments
if isempty(oProvidedMethod.aoFunctionInArgs)
    delete_block(char(sDummyInLibBlk));
else
    %-else add as many needed and connect Function caller
    w = nInPos(3)-nInPos(1);
    h = nInPos(4)-nInPos(2);
    delete_block(char(sDummyInLibBlk));
    for iArg = 1:numel(oProvidedMethod.aoFunctionInArgs)
        oArg = oProvidedMethod.aoFunctionInArgs(iArg);

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
%-delete Argument Outport if not Output arguments
if isempty(oProvidedMethod.aoFunctionOutArgs)
    delete_block(char(sDummyOutLibBlk)); %delete the signal ArgIn block provided with the library block
else
    %-else add as many needed and connect Function caller
    w = nOutPos(3)-nOutPos(1);
    h = nOutPos(4)-nOutPos(2);
    nOutPos(1) = nOutPos(1) + 100; %shift block further more on right side
    nOutPos(3) = nOutPos(3) + 100;
    delete_block(char(sDummyOutLibBlk));
    for iArg = 1:numel(oProvidedMethod.aoFunctionOutArgs)
        oArg = oProvidedMethod.aoFunctionOutArgs(iArg);

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
function [hFunctionCallBlock, sFctCallBlockName] = i_addFunctionCallBlock(sSubsystemPath, oProvidedMethod, oWrapperData)
sFctCallBlockName = oProvidedMethod.getMethodName();

%TODO: Make block larger depending on interface amount
hFunctionCallBlock = add_block('simulink/User-Defined Functions/Function Caller', ...
    [sSubsystemPath  '/' sFctCallBlockName], ...
    'MakeNameUnique', 'on', ...
    'Position', [150 90 300 135]);

set_param(hFunctionCallBlock, 'FunctionPrototype', oProvidedMethod.sFunctionPrototype);

sInArgSp = i_createArgSpec(oProvidedMethod.aoFunctionInArgs, oWrapperData);
set_param(hFunctionCallBlock, 'InputArgumentSpecifications', sInArgSp)

sOutArgSp = i_createArgSpec(oProvidedMethod.aoFunctionOutArgs, oWrapperData);
set_param(hFunctionCallBlock, 'OutputArgumentSpecifications', sOutArgSp)
end


%%
function sResult = i_createArgSpec(aoFuncArgs, oWrapperData)
casInstances = arrayfun(@(o) oWrapperData.getTypeInstance(o.sDataType, o.aiDim), aoFuncArgs, 'UniformOutput', false);
sResult = strjoin(casInstances, ', ');
end


%%
function oClientPort = i_addFunctionElementCall(hModel, oProvidedMethod, iOrdinance, oPortNameMap)
[sElement, sPortName] = oProvidedMethod.getFunctionParts();

if oPortNameMap.containsKey(sPortName)
    % EPDEV-71558 Function element calls with identical PortName need a special treatment
    hFctElemCall = add_block(getfullname(oPortNameMap.get(sPortName)), ...
        [get_param(hModel, 'Name') '/Function Element Call'], ...
        'MakeNameUnique', 'on', ...
        'Element', sElement, ...
        'Position', [150 20+((iOrdinance-1)*150) 160 30+((iOrdinance-1)*150)]);

else
    hFctElemCall = add_block('simulink/Ports & Subsystems/Function Element Call', ...
        [get_param(hModel, 'Name') '/Function Element Call'], ...
        'MakeNameUnique', 'on', ...
        'PortName', sPortName, ...
        'Element', sElement, ...
        'Position', [150 20+((iOrdinance-1)*150) 160 30+((iOrdinance-1)*150)]);

    oPortNameMap.put(get_param(hFctElemCall, 'PortName'), hFctElemCall);
end
oClientPort = i_createClientPortObj(hFctElemCall);
end

%%
function oClientPort = i_createClientPortObj(hFctElemCall)
oClientPort = Eca.aa.wrapper.Port;

oClientPort.sPortName = get_param(hFctElemCall, 'PortName');
oClientPort.nPortNum = str2double(get_param(hFctElemCall, 'Port'));
oClientPort.bIsClientServer = true;
oClientPort.sElement = get_param(hFctElemCall, 'Element');
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
function sArgLibBlk = i_getLibArgs(hFunCallerBlk, sType)
sArgLibBlk = ep_find_system(hFunCallerBlk, 'BlockType', sType);
end