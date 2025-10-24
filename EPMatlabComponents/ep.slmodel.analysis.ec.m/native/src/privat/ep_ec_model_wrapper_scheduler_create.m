function stResult = ep_ec_model_wrapper_scheduler_create(varargin)
% Creates a scheduler block.
%
% function stResult = ep_ec_model_wrapper_scheduler_create(varargin)
%
%  INPUT              DESCRIPTION
%    varargin           ([Key, Value]*)  Key-value pairs with the following possibles values
%
%    Allowed Keys:            Meaning of the Value:
%    - Location                 (string)*         target where to place the scheduler block
%    - SchedulerSubName         (string)          optional: name of wrapper scheduler subsystem (default = 'Scheduler')
%    - SchedulerSfName          (string)          optional: name of inner scheduler SF chart (default = 'SF_Scheduler')
%    - Calls                    (array)           structs with following fields
%         .sEventName             (string)           name of the trigger event
%         .sColor                 (string)           color of the trigger signals in model
%         .nTriggerTick           (int)              ticks when to provide the trigger signal
%
%  OUTPUT            DESCRIPTION
%    stResult                   (struct)          Return values
%      .hSchedulerSub           (handle)            handle of created scheduler subsystem
%      .mEventSrcPort           (map)               Map from EventName of the calls to the src-ports from which the
%                                                   trigger signals will be provided
%


%%
stArgs = i_evalArgs(varargin{:});

hSchedulerSub = i_addEmptySubsystem(stArgs.Location, stArgs.SchedulerSubName, numel(stArgs.Calls));
stResult = struct( ...
    'hSchedulerSub', hSchedulerSub, ...
    'mEventSrcPort', i_addChartScheduler(hSchedulerSub, stArgs.SchedulerSfName, stArgs.Calls, stArgs.RescheduleFunc));
end


%%
function hSchedulerSub = i_addEmptySubsystem(sLocation, sSchedulerSubName, nCalls)
dOffset = 20;
dWidth  = 200;
adUpperLeft  = [20 100];
adLowerRight = [adUpperLeft(1) + dWidth, adUpperLeft(2) + max((nCalls + 1)*dOffset, 100)];

% Scheduler Subsystem
sSchedulerSubPath = i_fullPath(sLocation, sSchedulerSubName);
hSchedulerSub = add_block('built-in/Subsystem', sSchedulerSubPath, 'MakeNameUnique', 'on');
set_param(hSchedulerSub, 'Position', [adUpperLeft, adLowerRight]);
end


%%
function mEventSrcPort = i_addChartScheduler(hSchedulerSub, sSchedulerSfName, astCalls, hRescheduleFunc)
[hChart, oChartSF] = i_addEmptyChart(hSchedulerSub, sSchedulerSfName, numel(astCalls));

mEventSrcPort = i_createAndWireInterfaces(hSchedulerSub, hChart, oChartSF, astCalls);

i_addSchedulingLogic(oChartSF, i_rescheduleCalls(hRescheduleFunc, astCalls));
end


%%
function [hChart, oChart] = i_addEmptyChart(hTargetSubsystem, sSchedulerSfName, nCalls)
dOffset = 30;
dWidth  = 200;
adUpperLeft = [20, 100];
adPosition = [adUpperLeft, adUpperLeft(1) + dWidth, adUpperLeft(2) + (nCalls + 1)*dOffset];

hChart = add_block('sflib/Chart', i_fullPath(hTargetSubsystem, sSchedulerSfName), 'Position', adPosition);

oChart = i_getStateflowObject(hChart);
set(oChart, 'ActionLanguage', 'C');
end


%%
function mEventSrcPort = i_createAndWireInterfaces(hSchedulerSub, hChart, oChart, astCalls)
sSchedulerSubPath = getfullname(hSchedulerSub);

nCalls = numel(astCalls);
for i = 1:nCalls
    oEvent = Stateflow.Event(oChart);
    oEvent.Trigger = 'Function call';
    oEvent.Scope = 'Output';
    oEvent.Name = astCalls(i).sEventName;
end

% add Outports to subsystem and connect them to SF-Chart
dPortBlockWidth  = 30;
dPortBlockHeight = 20;

stChartPorts = get(hChart, 'PortHandles');
for i = 1:nCalls
    stCall = astCalls(i);
    hSrcPort = stChartPorts.Outport(i);
    
    adPos = i_getBlockPositionOppositePortPosition(get_param(hSrcPort, 'Position'), dPortBlockWidth, dPortBlockHeight);
    
    hOutportBlock = add_block('built-in/Outport', [sSchedulerSubPath '/' stCall.sEventName],...
        'MakeNameUnique', 'on',...
        'Position',       adPos,...
        'showname',       'on');
    stPortHandles = get_param(hOutportBlock, 'PortHandles');
    add_line(sSchedulerSubPath, hSrcPort, stPortHandles.Inport);
    
    set(hOutportBlock, 'ForegroundColor', stCall.sColor);
end

stSubPorts = get_param(hSchedulerSub, 'PortHandles');
mEventSrcPort = containers.Map();
for i = 1:nCalls
    mEventSrcPort(astCalls(i).sEventName) = stSubPorts.Outport(i);
end
end


%%
function astCalls = i_rescheduleCalls(hRescheduleFunc, astCalls)
if ~isempty(hRescheduleFunc)
    astCalls = feval(hRescheduleFunc, astCalls);
end
end


%%
function i_addSchedulingLogic(oChart, astCalls)
nCalls = numel(astCalls);
nMaxEventNameLength = max(cellfun(@length,{astCalls.sEventName}));
dOffset = 30;
dWidth  = 10;
adUpperLeft = [20, 100];
adPosition = [adUpperLeft, adUpperLeft(1) + dWidth*nMaxEventNameLength, adUpperLeft(2) + (nCalls + 1)*dOffset];

oState= i_createScheduleState(oChart);
oState.Position = adPosition;
i_updateStateWithSchedule(oState, astCalls);
end


%%
function oState = i_createScheduleState(oChart)
oState = Stateflow.State(oChart);
% Add a default transition to the state.
oT0 = Stateflow.Transition(oChart);
oT0.Destination = oState;
oT0.DestinationOClock = 0;
oT0.SourceEndpoint = oT0.DestinationEndpoint - [0 30];
oT0.Midpoint = oT0.DestinationEndpoint - [0 30];
oT0.LabelString = '/*Update the Order/Rate/Asynchronous calls of the runnables*/';
end


%%
function i_updateStateWithSchedule(hState, astCalls)
sContent = sprintf('Schedule\nen:\n');
nCalls = numel(astCalls);
for i = 1:nCalls
    stCall = astCalls(i);
    sEventName = stCall.sEventName;
    sContent = [sContent, sprintf('send(%s);\n', sEventName)]; %#ok<AGROW>
end

sContent = [sContent, sprintf('\ndu:\n')];
for i = 1:nCalls
    stCall = astCalls(i);
    
    sEventName = stCall.sEventName;
    nTriggerTick = stCall.nTriggerTick;
    sContent = [sContent, sprintf('on every(%d, tick):send(%s);\n', nTriggerTick, sEventName)]; %#ok<AGROW>
end
hState.LabelString = sContent;
end


%%
function adPos = i_getBlockPositionOppositePortPosition(adPortPos, dBlockWidth, dBlockHeight)
dBlockDistance = 90;
dVert = 0.5*dBlockHeight;

adPos = [adPortPos + [dBlockDistance, -dVert], adPortPos + [dBlockDistance + dBlockWidth, dVert]];
end


%%
function oChart = i_getStateflowObject(hChart)
oRoot = sfroot;
oModel = oRoot.find('-isa', 'Simulink.BlockDiagram', '-and', 'Name', get_param(bdroot(hChart), 'Name'));
oChart = oModel.find('-isa','Stateflow.Chart', '-and', 'Name', get_param(hChart, 'Name'));
end


%%
function stArgs = i_evalArgs(varargin)
% default values
stArgs = struct ( ...
    'Location',         bdroot, ...
    'SchedulerSubName', 'Scheduler', ...
    'SchedulerSfName',  'SF_Scheduler', ...
    'Calls',            [], ...
    'RescheduleFunc',   []);

stUserArgs = ep_core_transform_args(varargin, fieldnames(stArgs));
casUserArgs = fieldnames(stUserArgs);
for i = 1:numel(casUserArgs)
    sArgName = casUserArgs{i};
    stArgs.(sArgName) = stUserArgs.(sArgName);
end
end


%%
% xParent -- either handle or full model path
function sBlockPath = i_fullPath(xParent, sBlockName)
sBlockPath = [getfullname(xParent), '/', sBlockName];
end
