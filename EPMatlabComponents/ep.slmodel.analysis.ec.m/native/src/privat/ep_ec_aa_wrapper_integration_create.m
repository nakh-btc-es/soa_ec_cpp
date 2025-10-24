function stIntegModel = ep_ec_aa_wrapper_integration_create(stModel, oWrapperData, oWrapperConfig, casServerMockNames, casTriggerFunctionNames)
% Creates the integration model for the Adaptive Autosar wrapper model usecase
%
%  function ep_ec_aa_wrapper_integration_create(stModel, oWrapperData, oWrapperConfig)
%
%  INPUT                        DESCRIPTION
%
%   - stModel                Information about the original model
%   - oWrapperData           Wrapper data dictionary object
%   - oWrapperConfig         Wrapper configuration data  object
%
%  OUTPUT                       DESCRIPTION
%    - stIntegModel
%         .bSuccess            (boolean) True, if the integration model creation was successful
%         .hModel              (string)  Handle of the created integration model(might be empty if not successful)
%         .sIntegModelName     (string)  The integration model's name
%         .sModelFile          (string)  Full path to the created integration model(might be empty if not successful)
%         .stServerModel       (struct)  Struct containing information about the mock server  model
%         .stClientModel       (struct)  Struct containing information about the test client model
%         .casErrorMessages    (cell)    Cell containing warning/error messages.
%         .aoRootInports       (array)   Information about the root inports
%         .aoRootOutports      (array)   Information about the root  outports
%         .aoFuncCalls         (array)   Information about the function call ports
%
%

%%
stIntegModel = struct( ...
    'bSuccess',          false, ...
    'hModel',            [], ...
    'sIntegModelName',   '', ...
    'sModelFile',        '', ...
    'stServerModel',     [], ...
    'stClientModel',     [], ...
    'casErrorMessages',  {{}}, ...
    'aoRootInports',     [], ...
    'aoRootOutports',    [], ...
    'aoFuncCalls',       [], ...
    'casEventsScheduleEditor', {{}});

sIntegModelName = ['W_integ_', stModel.sName];
stIntegModel.sIntegModelName = sIntegModelName;
stIntegModel.hModel = i_createIntegrationModel(sIntegModelName, Eca.aa.wrapper.Tag.Integration);
try
    i_setModelConfigAndDataDictionary(sIntegModelName, oWrapperConfig, oWrapperData.getFileDD);

    if isempty(stModel.aoRequiredMethods)
        aoMockServerPorts = [];
    else
        stServerModelArgs = struct(...
            'sName', stModel.sName, ...
            'sPath', stModel.sPath, ...
            'aoRequiredMethods', stModel.aoRequiredMethods);
        stIntegModel.stServerModel = ep_ec_aa_wrapper_server_create(stServerModelArgs, oWrapperData, oWrapperConfig);
        aoMockServerPorts = stIntegModel.stServerModel.aoMockServerPorts;
    end

    if isempty(stModel.aoProvidedMethods)
        aoClientPorts = [];
    else
        stClientModelArgs = struct(...
            'sName', stModel.sName, ...
            'sPath', stModel.sPath, ...
            'aoProvidedMethods', stModel.aoProvidedMethods);
        stIntegModel.stClientModel = ep_ec_aa_wrapper_client_create(stClientModelArgs, oWrapperData, oWrapperConfig, casTriggerFunctionNames);
        aoClientPorts = stIntegModel.stClientModel.aoClientPorts;
    end

    stOrigModelInfoArgs = struct(...
        'sName', stModel.sName, ...
        'aoInports', stModel.aoInports, ...
        'aoOutports', stModel.aoOutports);
    [stIntegModel.aoRootInports, stIntegModel.aoRootOutports, stIntegModel.aoFuncCalls] = ...
        i_createAndWireTheIntegrationModel(sIntegModelName, stIntegModel, stOrigModelInfoArgs, ...
        aoMockServerPorts, aoClientPorts);

    i_layoutModel(stIntegModel);

    % save model
    stIntegModel.sModelFile = fullfile(stModel.sPath, [sIntegModelName, '.slx']);
    Eca.aa.wrapper.Utils.saveModel(sIntegModelName, stIntegModel.sModelFile);
    
catch oEx
    i_cleanupAfterAbort(stIntegModel.hModel);
    rethrow(oEx);
end
end


%%
function i_layoutModel(stIntegModel)
ep_ec_ui_create_label(stIntegModel.sIntegModelName, [820, 0], 'Read-only model - do not edit', '#aa0000');
ep_ec_ui_create_bordered_area([810, -10, 1000, 25], [0.67, 0, 0], stIntegModel.sIntegModelName, 5, '');
end


%%
function i_createNoEditMask(hBlock)
oMask = Simulink.Mask.create(hBlock);
oMask.addDialogControl( ...
    'Name',    'DescGroupVar', ...
    'Type',    'group', ...
    'Prompt',  'BTC Embedded Systems mocking block');
oMask.addDialogControl( ...
    'Name',    'DescTextVar', ...
    'Type',    'text', ...
    'Prompt',  'This is a BTC Embedded Systems mocking block. Do not edit its contents.', ...
    'Container', 'DescGroupVar');

oMask.Display = ['disp(''\color[rgb]{0.11,0.34,0.51}\bf Read-only model'', ''texmode'', ''on'');' ...
    'disp(''\color[rgb]{0.11,0.34,0.51}\newline\newline\rm\it Do not edit'', ''texmode'', ''on'');'];

set_param(hBlock, 'OpenFcn', 'open_system(gcb, ''mask'');');
end

%%
function hModel = i_createIntegrationModel(sIntegModelName, sTag)
hModel = Eca.aa.wrapper.Utils.createModel(sIntegModelName, sTag);
% Set the Export Function property
set_param(hModel, 'SetExecutionDomain', 'on');
set_param(hModel, 'ExecutionDomainType', 'ExportFunction');
end


%%
function [aoInports, aoOutports, aoFuncCalls] = i_createAndWireTheIntegrationModel(sIntegModelName, stIntegModel, ...
    stOrigModel, aoMockServerPorts, aoClientPorts)
aoFuncCalls = [];
aoInports   = [];
aoOutports  = [];

hModelRefOrigModel = i_createMainModelRefBlock(stIntegModel.hModel, stOrigModel.sName);
[mInportsConPort, mOutportsConPort] = i_getPortConnectionInfo(hModelRefOrigModel, stOrigModel.aoInports, stOrigModel.aoOutports);

% add and wire root ports
[~, aoUniqueRootInports] = i_filterDuplicatePortNames(stOrigModel.aoInports);
[~, aoUniqueRootOutports] = i_filterDuplicatePortNames(stOrigModel.aoOutports);
[aoRootInports, aoRootOutports, aoFuncCallInports] = i_addAndWireRootPorts(sIntegModelName, aoUniqueRootInports, aoUniqueRootOutports,...
    mInportsConPort, mOutportsConPort);
aoInports = [aoInports aoRootInports];
aoOutports = [aoOutports aoRootOutports];
aoFuncCalls = [aoFuncCalls aoFuncCallInports];

% add and wire the server mock
if ~isempty(stIntegModel.stServerModel)
    hModelRefServerMock = i_createModelRefBlock(stIntegModel.hModel, stIntegModel.stServerModel.sName);
    mSourceConInfo = i_getServerPortConnectionInfo(hModelRefServerMock, aoMockServerPorts);
    casUniqueServerPortNames = i_filterDuplicatePortNames(aoMockServerPorts);
    i_addAndWireServerPorts(sIntegModelName, hModelRefServerMock, hModelRefOrigModel, casUniqueServerPortNames, mSourceConInfo, mInportsConPort);
    i_createNoEditMask(hModelRefServerMock);
end

% add and wire the test client
if ~isempty(stIntegModel.stClientModel)
    hModelRefClientMock = i_createModelRefBlock(stIntegModel.hModel, stIntegModel.stClientModel.sName);
    mDestConInfo = i_getClientPortConnectionInfo(hModelRefClientMock, aoClientPorts);
    casUniqueClientPortNames = i_filterDuplicatePortNames(aoClientPorts);
    i_addAndWireClientPorts(sIntegModelName, hModelRefClientMock, hModelRefOrigModel, casUniqueClientPortNames, mOutportsConPort, mDestConInfo);
    i_createNoEditMask(hModelRefClientMock);
end
end


%%
function hMainModelRef = i_createMainModelRefBlock(hTopLevelModel, sMainModelName)
hMainModelRef = i_createModelRefBlock(hTopLevelModel, sMainModelName);
set(hMainModelRef, 'Tag', ep_ec_tag_get('AUTOSAR Main ModelRef'));
end


%%
function [casUniquePortNames, aoUniquePorts] = i_filterDuplicatePortNames(aoPorts)
iPortAmount = numel(aoPorts);
casUniquePortNames = cell(1, iPortAmount);
if iPortAmount == 0
    aoUniquePorts = Eca.aa.wrapper.Port.empty();
else
    aoUniquePorts(iPortAmount) = Eca.aa.wrapper.Port;
end
iIndexCounter = 0;

for i = 1:iPortAmount
    oPort = aoPorts(i);
    sPortName = oPort.sPortName;
    if ~any(strcmp(casUniquePortNames, sPortName))
        iIndexCounter = iIndexCounter + 1;
        casUniquePortNames{iIndexCounter} = sPortName;
        aoUniquePorts(iIndexCounter) = oPort;
    end
end

casUniquePortNames = casUniquePortNames(1:iIndexCounter);
aoUniquePorts = aoUniquePorts(1:iIndexCounter);
end


%%
function mConInfo = i_getServerPortConnectionInfo(hModel, aoMockServerPorts)
mConInfo = containers.Map();
stPortHandles = get_param(hModel, 'PortHandles');
for i = 1:numel(aoMockServerPorts)
    % memorize the destination port of the event
    hDPort = stPortHandles.Outport(aoMockServerPorts(i).nPortNum);
    mConInfo(aoMockServerPorts(i).sPortName) = hDPort;
end
end

%%
function mConInfo = i_getClientPortConnectionInfo(hModelRefClientMock, aoClientPorts)
mConInfo = containers.Map();
stPortHandles = get_param(hModelRefClientMock, 'PortHandles');
for i = 1:numel(aoClientPorts)
    % memorize the destination port of the event
    hDPort = stPortHandles.Inport(aoClientPorts(i).nPortNum);
    mConInfo(aoClientPorts(i).sPortName) = hDPort;
end
end

%%
function [mInportsConPort, mOutportsConPort] = i_getPortConnectionInfo(hModelRefOrigModel, aoInports, aoOutports)
mInportsConPort = containers.Map();
stPortHandles = get_param(hModelRefOrigModel, 'PortHandles');

for i = 1:numel(aoInports)
    oInPort = aoInports(i);
    % memorize the destination port of the event
    hDPort = stPortHandles.Inport(oInPort.nPortNum);
    mInportsConPort(oInPort.sPortName) = hDPort;
end

mOutportsConPort = containers.Map();
for i = 1:numel(aoOutports)
    oOutPort = aoOutports(i);
    hPort = stPortHandles.Outport(oOutPort.nPortNum);
    mOutportsConPort(oOutPort.sPortName) = hPort;
end
end


%%
function i_addAndWireServerPorts(sTargetSub, hModelRefServerMock, hModelRefOrigModel, casPortNames, mSourcePortConInfo, mDesPortConInfo)
i_adaptPosition(hModelRefServerMock, hModelRefOrigModel, 1);
for i = 1:numel(casPortNames)
    add_line(sTargetSub, mSourcePortConInfo(casPortNames{i}), mDesPortConInfo(casPortNames{i}), 'autorouting', 'on');
end
end


%%
function i_addAndWireClientPorts(sTargetSub, hModelRefClientMock, hModelRefOrigModel, casPortNames, ...
    mOutportsConPort, mDestConInfo)

i_adaptPosition(hModelRefClientMock, hModelRefOrigModel, 0);
for i = 1:numel(casPortNames)
    add_line(sTargetSub, mOutportsConPort(casPortNames{i}), mDestConInfo(casPortNames{i}), 'autorouting', 'on');
end
end


%%
function hModelRef = i_createModelRefBlock(hTargetSub, sModelName)
%Add TopLevel SUT subsytems
hModelRef = add_block('built-in/ModelReference', [getfullname(hTargetSub), '/', sModelName]);
set(hModelRef, 'ModelName', sModelName);
set(hModelRef, 'SimulationMode', 'Normal');

%Adapt positions
P1_MDLREFBLK = 500; P2_MDLREFBLK = 100; MDLREFBLK_WIDTH = 800;

anPortNumbers = get(hModelRef, 'Ports');
nMaxIOPorts = max(1, max(anPortNumbers(1), anPortNumbers(2)));
set(hModelRef, 'Position', [P1_MDLREFBLK, P2_MDLREFBLK, P1_MDLREFBLK + MDLREFBLK_WIDTH, P2_MDLREFBLK + 40*nMaxIOPorts]);
end


%%
function i_adaptPosition(hBlock, hBlockReference, bToTheLeft)
% common port block properties
dBlockDistance = 250;
dBlockWidth = 300;
anPortNumbers = get(hBlock, 'Ports');
nMaxIOPorts = max(1, max(anPortNumbers(1), anPortNumbers(2)));
dBlockHeight = 50 + 20 * nMaxIOPorts;

adPortPos = get_param(hBlockReference, 'Position');
if bToTheLeft
    dNewLeft = adPortPos(1) - (dBlockDistance + dBlockWidth);
    dNewTop = adPortPos(2) + adPortPos(4)/2+100;
else
    dNewLeft = adPortPos(3) + dBlockDistance;
    dNewTop = adPortPos(2);
end

set(hBlock, 'Position', [dNewLeft, dNewTop, dNewLeft + dBlockWidth, dNewTop+dBlockHeight])
end



%%
function [aoRootInports, aoRootOutports, aoFunCalls] = i_addAndWireRootPorts(sTargetSub, aoInports, aoOutports, ...
    mInportsConPort, mOutportsConPort)
aoRootInports = [];
aoRootOutports = [];
aoFunCalls = [];

% add the root inports and the function call inports
for i = 1:numel(aoInports)
    oInPort = aoInports(i);
    if  ~oInPort.bIsClientServer
        if oInPort.bIsFunctionCall
            hPortBlock = add_block('built-in/Inport', [sTargetSub '/' oInPort.sPortName],...
                'MakeNameUnique',        'on',...
                'Position',              i_getIdealPortBlockPosition(mInportsConPort(oInPort.sPortName)), ...
                'PortDimensions',        oInPort.getDimForPortAttributeSetting, ...
                'BusOutputAsStruct',     oInPort.sOutputAsVirtualBus, ...
                'showname',             'on', ...
                'OutputFunctionCall',   'on');
            oInPort.nPortNum = str2double(get_param(hPortBlock, 'Port'));
            stPortHandles = get_param(hPortBlock, 'PortHandles');
            add_line(sTargetSub, stPortHandles.Outport, mInportsConPort(oInPort.sPortName));
            aoFunCalls= [aoFunCalls oInPort]; %#ok
        else  % normal inport
            % handle bus element ports
            sOutDataTypeStr = oInPort.sOutDataTypeStr;
            if ~isempty(oInPort.sElement)
                ex = MException('EP:ECAA_WRAPPER:BUS_ELEM_PORT_NOT_SUPPORTED', 'Bus element ports are not supported.');
                throw(ex);
            end
            hPortBlock = add_block('built-in/Inport', [sTargetSub '/' oInPort.sPortName],...
                'Position',             i_getIdealPortBlockPosition(mInportsConPort(oInPort.sPortName)), ...
                'PortDimensions',       oInPort.getDimForPortAttributeSetting, ...
                'BusOutputAsStruct',    oInPort.sOutputAsVirtualBus, ...
                'OutDataTypeStr',       sOutDataTypeStr, ...
                'showname',             'on', ...
                'BackgroundColor',      'lightBlue');

            oInPort.nPortNum = str2double(get_param(hPortBlock, 'Port'));
            stPortHandles = get_param(hPortBlock, 'PortHandles');
            add_line(sTargetSub, stPortHandles.Outport, mInportsConPort(oInPort.sPortName), 'autorouting', 'on');
            aoRootInports= [aoRootInports oInPort]; %#ok
        end
    end
end

for i = 1:numel(aoOutports)
    oOutPort = aoOutports(i);
    if oOutPort.bIsClientServer
        continue;
    end
    % handle bus element ports
    sOutDataTypeStr = oOutPort.sOutDataTypeStr;
    if ~isempty(oOutPort.sElement)
        ex = MException('EP:ECAA_WRAPPER:BUS_ELEM_PORT_NOT_SUPPORTED', 'Bus element ports are not supported.');
        throw(ex);
    end
    hPortBlock = add_block('built-in/Outport', [sTargetSub '/' oOutPort.sPortName],...
        'Position',             i_getIdealPortBlockPosition(mOutportsConPort(oOutPort.sPortName)), ...
        'PortDimensions',       oOutPort.getDimForPortAttributeSetting, ...
        'BusOutputAsStruct',    oOutPort.sOutputAsVirtualBus, ...
        'OutDataTypeStr',       sOutDataTypeStr, ...
        'showname',             'on', ...
        'BackgroundColor',      'lightBlue');

    oOutPort.nPortNum = str2double(get_param(hPortBlock, 'Port'));
    stPortHandles = get_param(hPortBlock, 'PortHandles');
    add_line(sTargetSub, mOutportsConPort(oOutPort.sPortName), stPortHandles.Inport, 'autorouting', 'on');
    aoRootOutports= [aoRootOutports oOutPort]; %#ok
end
end


%%
function adBlockPos = i_getIdealPortBlockPosition(hPort)

% common port block properties
dBlockDistance = 70;
dBlockWidth = 30;
dHalfBlockHeight = 7;
dBlockHeight = dHalfBlockHeight + dHalfBlockHeight;

adPortPos = get_param(hPort, 'Position');
bIsInport = strcmpi(get_param(hPort, 'PortType'), 'inport');
if bIsInport
    adLeftUpper = adPortPos - [(dBlockDistance + dBlockWidth), dHalfBlockHeight];
else
    adLeftUpper = adPortPos + [dBlockDistance, -dHalfBlockHeight];
end
adRightLower = adLeftUpper + [dBlockWidth, dBlockHeight];
adBlockPos = [adLeftUpper, adRightLower];
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
function i_cleanupAfterAbort(ahModels)
for i = 1:numel(ahModels)
    hModel = ahModels(i);
    if ~isempty(hModel)
        try %#ok<TRYNC>
            close_system(hModel, 0);
        end
    end
end
end
