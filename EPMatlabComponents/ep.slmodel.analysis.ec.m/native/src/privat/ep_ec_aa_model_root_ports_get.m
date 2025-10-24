function stPorts = ep_ec_aa_model_root_ports_get(sModelName)
% Analyzes the AA model and returns all required methods.
%
%  function stPorts = ep_ec_aa_model_root_ports_get(sModelName)
%
%  INPUT              DESCRIPTION
%    sModelName             (string)    name of the AUTOSAR model (default = current model)
%
%  OUTPUT            DESCRIPTION
%    stPorts                (struct)    return struct with the following info:
%      .aoInports             (objects)   array of Eca.ec.wrapper.Port objects representing Inports
%      .aoOutports            (objects)   array of Eca.ec.wrapper.Port objects representing Outports
%
%
% ! Requirement: Provided model has to be loaded/open and in "compiled" mode.
%


%%
if (nargin < 1)
    sModelName = bdroot(gcs);
end

[ahInports, ahOutports] = i_getPorts(get_param(sModelName, 'handle'));
oFieldUpdateInfoMap = i_getFieldUpdateInfo(sModelName);

stPorts = struct( ...
    'aoInports',  arrayfun(@(o) i_evalPort(o, oFieldUpdateInfoMap), ahInports), ...
    'aoOutports', arrayfun(@(o) i_evalPort(o, oFieldUpdateInfoMap), ahOutports));
end



%%
function oMap = i_getFieldUpdateInfo(sModelName)
oMap = containers.Map;

ahMessageTriggerPorts = ep_find_system(get_param(sModelName, 'Handle'), ...
    'BlockType',   'TriggerPort', ...
    'TriggerType', 'message', ...
    'TriggerTime', 'on message available', ...
    'ScheduleAsAperiodic', 'on');

for i=1:numel(ahMessageTriggerPorts)
    hParentSub = get_param(get_param(ahMessageTriggerPorts(i), 'Parent'), 'Handle');
    astPortCon = get_param(hParentSub, 'PortConnectivity');
    abTrigger = arrayfun(@(x) strcmp(x.Type, 'trigger'), astPortCon);
    hFieldUpdateInport = astPortCon(abTrigger);

    oMap(get_param(hParentSub, 'Name'))= hFieldUpdateInport.SrcBlock;
end
end


%%
function [ahInports, ahOutports] = i_getPorts(hModelOrSub)
ahInports = ep_find_system(hModelOrSub, ...
    'SearchDepth',     1,...
    'LookUnderMasks',  'all',...
    'FollowLinks',     'on',...
    'BlockType',       'Inport');

ahOutports = ep_find_system(hModelOrSub, ...
    'SearchDepth',     1,...
    'LookUnderMasks',  'all',...
    'FollowLinks',     'on',...
    'BlockType',       'Outport');
end


%%
function oPort = i_evalPort(hPortBlock, oFieldUpdateInfoMap)
oPort = Eca.aa.wrapper.Port;

oPort.sPortName              = get_param(hPortBlock, 'PortName');
oPort.nPortNum               = sscanf(get_param(hPortBlock, 'Port'), '%d');
oPort.bIsFunctionCall        = i_isFunctionCall(hPortBlock);
oPort.bIsClientServer        = i_isClientServer(hPortBlock);
oPort.sElement               = get_param(hPortBlock, 'Element');
oPort.sOutDataTypeStr        = get_param(hPortBlock, 'OutDataTypeStr');
oPort.sOutputAsVirtualBus    = get_param(hPortBlock, 'BusOutputAsStruct');

if ~oPort.bIsClientServer
    stCompiledInfo = i_getCompiledInfo(hPortBlock);
else
    stCompiledInfo = i_getEmptyCompiledInfo();
end
oPort.sDataType   = stCompiledInfo.sDataType;
oPort.aiDim       = stCompiledInfo.aiDim;
oPort.dSampleTime = i_getSampleTime(hPortBlock);
abFound = cellfun(@(x)isequal(x,hPortBlock),values(oFieldUpdateInfoMap));
casKeys = keys(oFieldUpdateInfoMap);
if any(abFound)
    oPort.sMessageTriggeredSubName = casKeys{abFound};
end
end



%%
function stCompiled = i_getEmptyCompiledInfo()
stCompiled = struct( ...
    'sDataType', '', ...
    'aiDim',     [1 1]);
end


%%
function stCompiled = i_getCompiledInfo(hPortBlock)
stPortDims = get_param(hPortBlock, 'CompiledPortDimensions');
if isempty(stPortDims)
    warning('INTERNAL:ERROR', ...
        'Model is not in compiled mode. Cannot evaluate compiled properties of port block "%s".', ...
        getfullname(hPortBlock));
    stCompiled = i_getEmptyCompiledInfo();
    return;
end
stPortTypes = get_param(hPortBlock, 'CompiledPortDataTypes');

sBlockType = get_param(hPortBlock, 'BlockType');
if strcmp(sBlockType, 'Inport')
    stCompiled = struct( ...
        'sDataType', char(stPortTypes.Outport), ...
        'aiDim',     stPortDims.Outport);
else
    stCompiled = struct( ...
        'sDataType', char(stPortTypes.Inport), ...
        'aiDim',     stPortDims.Inport);
end
end


%%
function bIsFunctionCall = i_isFunctionCall(hPortBlock)
bIsFunctionCall = false;

sBlockType = get_param(hPortBlock, 'BlockType');
if strcmpi(sBlockType, 'Inport')
    bIsFunctionCall = strcmpi(get_param(hPortBlock, 'OutputFunctionCall'), 'on');
end
end


%%
function bIsClientServer = i_isClientServer(hPortBlock)
bIsClientServer = strcmp(get_param(hPortBlock, 'IsClientServer'), 'on');
end


%%
function dSampleTime = i_getSampleTime(xBlock)
dSampleTime = str2double(get_param(xBlock, 'SampleTime'));
if (isempty(dSampleTime)  || isequal(dSampleTime, -1) || ~isfinite(dSampleTime))
    adSampleTime = get_param(xBlock, 'CompiledSampleTime');
    dSampleTime = adSampleTime(1);
end
end
