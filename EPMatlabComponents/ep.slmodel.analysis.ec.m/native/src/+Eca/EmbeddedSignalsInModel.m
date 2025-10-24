classdef EmbeddedSignalsInModel
    
    properties (Access = private)
        sModelName
        mNameToSignalPort
        mRtwIdentifierToSignalPort
    end

    methods
        function oObj = EmbeddedSignalsInModel(xModelContext)
            hModel = i_getModelHandle(xModelContext);
            oObj.sModelName = getfullname(hModel);
            [oObj.mNameToSignalPort, oObj.mRtwIdentifierToSignalPort] = i_getSignalPortMaps(hModel);
        end

        function sModel = getModelName(oObj)
            sModel = oObj.sModelName;
        end

        function [oSignal, sSourceBlock] = getByName(oObj, sName)
            if oObj.mNameToSignalPort.isKey(sName)
                [oSignal, sSourceBlock] = i_getSignalAndSourceBlock(oObj.mNameToSignalPort(sName));
            else
                oSignal = [];
                sSourceBlock = '';
            end
        end

        function [oSignal, sSourceBlock] = getByRtwIdentifier(oObj, sIdentifier)
            if oObj.mRtwIdentifierToSignalPort.isKey(sIdentifier)
                [oSignal, sSourceBlock] = i_getSignalAndSourceBlock(oObj.mRtwIdentifierToSignalPort(sIdentifier));
            else
                oSignal = [];
                sSourceBlock = '';
            end
        end       
    end
end


%%
function [oSignal, sSourceBlock] = i_getSignalAndSourceBlock(hPort)
oSignal = get_param(hPort, 'SignalObject');
sSourceBlock = get_param(hPort, 'Parent');
end


%%
function hModel = i_getModelHandle(xModelContext)
hModel = get_param(bdroot(xModelContext), 'handle');
end


%%
function [mNameToSignalPort, mRtwIdentifierToSignalPort] = i_getSignalPortMaps(hModel)
mNameToSignalPort = containers.Map;
mRtwIdentifierToSignalPort = containers.Map;

ahAllPorts = ep_core_feval('ep_find_system', hModel, ...
    'FindAll',                     'on', ...
    'FollowLinks',                 'on', ...
    'LookUnderMasks',              'on', ...
    'type',                        'port');
ahPortsWithoutSignal = ep_core_feval('ep_find_system', hModel, ...
    'FindAll',                     'on', ...
    'FollowLinks',                 'on', ...
    'LookUnderMasks',              'on', ...
    'type',                        'port', ...
    'SignalObject',                '');

ahPortsWithSignal = setdiff(ahAllPorts, ahPortsWithoutSignal);
for i = 1:numel(ahPortsWithSignal)
    hPort = ahPortsWithSignal(i);

    sName = get_param(hPort, 'Name');
    if ~isempty(sName) && ~mNameToSignalPort.isKey(sName)
        mNameToSignalPort(sName) = hPort;
    end

    sIdentifier = get_param(hPort, 'CompiledRTWSignalIdentifier');
    if ~isempty(sIdentifier) && ~mRtwIdentifierToSignalPort.isKey(sIdentifier)
        mRtwIdentifierToSignalPort(sIdentifier) = hPort;
    end
end
end

