function [ahLocalItfBlks, anLocalItfBlksPortNums] = getLocalSignalBlocks(oEca, oScope, stDOCfg)
ahPorts = [];
ahPortsCurrentModel = [];
ahLocalItfBlks = [];
anLocalItfBlksPortNums = [];
if oEca.bMergedArch
    %Merged Architecture
    %1. Find all ports that match the data object name filter
    if ~isempty(stDOCfg.SearchGlobal.DataObjectName)
        casRegExpr = cellstr(stDOCfg.SearchGlobal.DataObjectName);
    else
        casRegExpr = {'.'}; %Any names but one name
    end
    for k = 1:numel(casRegExpr)
        ahPortsCurrentModel = [ahPortsCurrentModel; ep_core_feval('ep_find_system', ...
            oScope.sSubSystemAccess,...
            'FollowLinks',    'on', ...
            'LookUnderMasks', 'on', ...
            'regexp',         'on', ...
            'FindAll',        'on', ...
            'type',           'port', ...
            'Name',           casRegExpr{k})]; %#ok<AGROW>
    end
    
    sThisScopePath = oScope.sSubSystemAccess;
    
    % 2. Keep only the ports which fulfill the following conditions
    % 2.1 ports having an Embedded Signal Object or resolving a Data Obj
    % 2.2 ports with Optional TestPoint filter if option is activated
    % 2.3 exclude output ports of scope itself
    % 2.4 exclude Inport block of scope itself
    % 2.5 filter with DO Config Property filters
    for iPort = 1:numel(ahPortsCurrentModel)
        stPortProps = get(ahPortsCurrentModel(iPort));
        
        % (2.1) ports having an Embedded Signal Object or resolving a Data Obj
        bHasDefinedSignal = ~isempty(stPortProps.SignalObject) || strcmp(stPortProps.MustResolveToSignalObject, 'on');
        if ~bHasDefinedSignal
            continue;
        end
        
        % (2.3) exclude output ports of scope itself
        bIsOutportOfThisScope = strcmpi(stPortProps.Parent, sThisScopePath);
        if bIsOutportOfThisScope
            continue;
        end
        
        % (2.4) exclude Inport block ports of children scopes subsystems
        bIsInport = strcmp(get_param(stPortProps.Parent, 'BlockType'), 'Inport');
        if (bIsInport && strcmpi(get_param(stPortProps.Parent, 'Parent'), sThisScopePath))
            continue;
        end
        
        % (new) AoB check <-- currently AoB signals are not supported as locals
        bIsAoB = i_isArrayOfBusesSignal(stPortProps);
        if bIsAoB
            continue;
        end
        
        % (2.2) note: TestPoint check is passed, if the check is not active or if the TestPoint property is set
        if ~oEca.bIsAutosarArchitecture
            bPassesTestPointCheck = strcmp(stPortProps.TestPoint, 'on');
        else
            bPassesTestPointCheck = ~stDOCfg.SearchGlobal.TestPointActive || strcmp(stPortProps.TestPoint, 'on');
        end
        if ~bPassesTestPointCheck
            continue;
        end
        
        % (2.5) filter with Config Property filter
        if i_isSignalObjectCompliantInternal(oEca, stPortProps, stDOCfg)
            ahPorts = [ahPorts, ahPortsCurrentModel(iPort)]; %#ok<AGROW>
        end
    end
else
    % Simulink SIL use case
    % 1. Find all ports that have Test Point Active
    % 1.a In the current model
    ahPortsCurrentModel = [ahPortsCurrentModel; ep_core_feval('ep_find_system', oScope.sSubSystemAccess,...
        'FollowLinks', 'on', ...
        'RegExp',      'on', ...
        'FindAll',     'on', ...
        'type',        'port', ...
        'TestPoint',   'on')];
    %1.b In the referenced models
    if (stDOCfg.SearchGlobal.SearchInRefModel)
        casMdlBlk = ep_core_feval('ep_find_system', oScope.sSubSystemAccess, ...
            'FollowLinks',      'on', ...
            'LookUnderMasks',   'all', ...
            'IncludeCommented', 'off',...
            'BlockType',        'ModelReference');
        if ~isempty(casMdlBlk)
            sRefMdlNames = get_param(casMdlBlk, 'ModelName');
            hPortsRefModel = [];
            for iMod = 1:numel(sRefMdlNames)
                ahPortsCurrentModel = [hPortsRefModel; ep_core_feval('ep_find_system', sRefMdlNames{iMod},...
                    'FollowLinks', 'on', ...
                    'RegExp',      'on', ...
                    'FindAll',     'on', ...
                    'type',        'port', ...
                    'TestPoint',   'on')];
            end
            ahPortsCurrentModel = [ahPortsCurrentModel, hPortsRefModel];
        end
    end
    
    %2 Filter with DO Config Property filters if a Signal Object is used (Signal Object is optional for Simulink SIL)
    for iPort = 1:numel(ahPortsCurrentModel)
        stPortProps = get(ahPortsCurrentModel(iPort));
        %If Signal object linked to the port, check its compliance with config analysis
        if (not(isempty(stPortProps.SignalObject)) || strcmp(stPortProps.MustResolveToSignalObject, 'on'))
            if i_isSignalObjectCompliantInternal(oEca, stPortProps, stDOCfg)
                ahPorts = [ahPorts, ahPortsCurrentModel(iPort)]; %#ok<AGROW>
            end
        else
            ahPorts = [ahPorts, ahPortsCurrentModel(iPort)]; %#ok<AGROW>
        end
    end
end

% filter out in-active ports (possible for variant sources/sinks introduced with R2016a)
if (~isempty(ahPorts) && ~verLessThan('matlab', '9.0'))
    ahPorts = ahPorts(i_isActivePort(ahPorts));
end

if ~isempty(ahPorts)
    ahLocalItfBlks = i_getSimulinkBlockHandle(get(ahPorts, 'Parent'));
    anLocalItfBlksPortNums = get(ahPorts, 'PortNumber');
    if iscell(anLocalItfBlksPortNums)
        anLocalItfBlksPortNums = cell2mat(anLocalItfBlksPortNums);
    end
end
end


%%
function bIsAoB = i_isArrayOfBusesSignal(stPortProps)
bIsAoB = false;

bIsNonVirtualBus = strcmp(stPortProps.CompiledBusType, 'NON_VIRTUAL_BUS');
if ~bIsNonVirtualBus
    return;
end

nMainSigWidth = prod(stPortProps.CompiledPortDimensions(2:end));
if (nMainSigWidth > 1)
    bIsAoB = true;
    return;
end

bIsAoB = i_isArrayOfBusesSignalFullCheck(stPortProps);
end


%%
function bIsAob = i_isArrayOfBusesSignalFullCheck(stPortProps)
bIsAob = false;

% full analysis is very costly; do it only if we have a signal hierarchy with a toplevel bus object available
stSignalHierarchy = stPortProps.SignalHierarchy;
if ~isempty(stSignalHierarchy)
    sBusObj = stSignalHierarchy.BusObject;
    if ~isempty(sBusObj)
        try
            oSig = ep_core_feval('ep_sl_signal_from_port_get', stPortProps.Handle);
            bIsAob = oSig.isValid && oSig.containsArrayOfBuses;
        end
    end
end
end


%%
function abIsActive = i_isActivePort(ahPorts)
abIsActive = arrayfun(@(h) ~isempty(get_param(h, 'CompiledPortDimensions')), ahPorts);
end


%%
function bMatch = i_isSignalObjectCompliantInternal(oEca, stPortProps, stDOCfg)
sName = stPortProps.Name;
if ~isempty(stPortProps.SignalObject)
    oObj = stPortProps.SignalObject;
else
    try
        oObj = Simulink.data.evalinGlobal(bdroot(stPortProps.Parent), sName);
    catch oEx
        % TODO signal could come from the model workspace; to not handle it for now, but simply return false
        oObj = [];
    end
end
bMatch = ~isempty(oObj) && oEca.isConfigAnalysisCompliant(oObj, stDOCfg);
end


%%
function ah = i_getSimulinkBlockHandle(paths)
ah = cell2mat(get_param(cellstr(paths), 'handle'));
end
