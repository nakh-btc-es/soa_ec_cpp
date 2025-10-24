function [oItf, astBusSignals, sErrMsg] = analyzeBus(oItf, stEnvLegacy)

oBusObject = [];
astBusSignals = [];
sCompiledBusType = get(oItf.sourcePortHandle, 'CompiledBusType');
bIsBus = ~isempty(sCompiledBusType) && ~strcmp(sCompiledBusType, 'NOT_BUS');
oMetaBus = Eca.MetaBus;
sErrMsg = '';

if bIsBus
    oItf.isBusElement = true;
    oMetaBus.busType    = sCompiledBusType;
    oMetaBus.isVirtual  = strcmp(sCompiledBusType, 'VIRTUAL_BUS');
    busSignalHierarchy  = get(oItf.sourcePortHandle, 'SignalHierarchy');
    %Bus object
    oMetaBus.busObjectName = busSignalHierarchy.BusObject;
    if not(isempty(oMetaBus.busObjectName))
        oBusObject = oItf.evalinGlobal(oMetaBus.busObjectName);
    end
    %Bus signal name
    sPropagatedSignalName = get(oItf.sourcePortHandle, 'PropagatedSignals');
    if strcmp(oItf.kind, 'IN')
        rtwBusSignalName = get(oItf.externalSourcePortHandle, 'CompiledRTWSignalIdentifier');
    else
        rtwBusSignalName = get(oItf.internalSourcePortHandle, 'CompiledRTWSignalIdentifier');
    end
    if not(oMetaBus.isVirtual)
        %Ccode identifier for non-virtual buses -> BusSignalName
        if isempty(rtwBusSignalName) %ML 2017b: "rtwBusSignalName" returned as empty in some cases
            oMetaBus.busSignalName = busSignalHierarchy.SignalName;
        else
            oMetaBus.busSignalName = rtwBusSignalName;
        end
    else
        %if Virtual, get signal name from bus hierarchy or from propagated signal
        oMetaBus.busSignalName = busSignalHierarchy.SignalName;
        if isempty( oMetaBus.busSignalName)
            oMetaBus.busSignalName = sPropagatedSignalName;
        end
    end
    if isempty(oMetaBus.busSignalName)
        oMetaBus.busSignalName = 'EMPTY';
    end
    
    %Bus signal path (model) for EP mapping xml
    if strcmp(oItf.kind, 'LOCAL') % bus signal name is originating from port so always specified
        sMapppingModelSignalPath = oMetaBus.busSignalName;
    else
        sSignalName = get(oItf.internalSourcePortHandle, 'Name');
        if ~isempty(sSignalName)
            sMapppingModelSignalPath = sSignalName;
        else
            if ~isempty(sPropagatedSignalName)
                sMapppingModelSignalPath = sPropagatedSignalName;
            else
                sMapppingModelSignalPath = '<signal1>';
            end
        end
    end
    
    bBackupBusSignalNameExists = false;
    if strcmp(oMetaBus.busSignalName, 'EMPTY')
        [sBusSignalName, sErrMsg] = i_getBusName(oItf);
        bBackupBusSignalNameExists = true;
        if ~isempty(sBusSignalName)
            oMetaBus.busSignalName = sBusSignalName;
        end
    end
    if strcmp(sMapppingModelSignalPath, '<signal1>')
        if ~bBackupBusSignalNameExists
            [sBusSignalName, sErrMsg] = i_getBusName(oItf);
        end
        if ~isempty(sBusSignalName)
            sMapppingModelSignalPath = sBusSignalName;
        end
    end
    
    % TODO: somewhen the following command shall replace everything that is done in this function!
    [oSig, oAlternativeMetaBus, aoBusSigs] = ...
        ep_core_feval('ep_ec_port_bus_signals_get', stEnvLegacy, oItf.sourcePortHandle, sMapppingModelSignalPath);
    oItf.oSigSL_ = oSig;
    
    %Extract Bus elements
    stHierarchyInfo.sModelSignalPath        = ['.', sMapppingModelSignalPath];
    stHierarchyInfo.sCodeVariableAccessPath = '';
    stHierarchyInfo.sTopBusSignalName       = oMetaBus.busSignalName;
    stHierarchyInfo.busObjectName           = oMetaBus.busObjectName;
    stHierarchyInfo.isVirtual               = oMetaBus.isVirtual && isempty(oBusObject); %Virtual means no BusObject available
    stHierarchyInfo.elementObject           = [];
    stHierarchyInfo.signalName              = '';
    
    astBusSignals = i_getBusSignals(oItf, busSignalHierarchy, stHierarchyInfo);
    
    if (numel(astBusSignals) == numel(aoBusSigs))
        for i = 1:numel(astBusSignals)
            astBusSignals(i).oMetaBusSig = aoBusSigs(i);
        end
    end
else
    oItf.metaBus.busType = 'NOT_BUS';
    oItf.isBusElement    = false;
end

oItf.metaBus = oMetaBus;
end


%%
function astBusSignals = i_getBusSignals(oItf, busSignalHierarchy, stHierarchyInfo)

astBusSignals = [];

if isempty(busSignalHierarchy.Children) %Bounded Signal is found when there is no more Chidlren
    
    astBusSignals.topBusSignalName    = stHierarchyInfo.sTopBusSignalName;
    astBusSignals.signalName          = busSignalHierarchy.SignalName;
    astBusSignals.modelSignalPath     = stHierarchyInfo.sModelSignalPath;
    astBusSignals.codeVariableAccess  = stHierarchyInfo.sCodeVariableAccessPath;
    astBusSignals.elementObject       = stHierarchyInfo.elementObject;
    astBusSignals.busObjectName       = stHierarchyInfo.busObjectName;
    astBusSignals.iBusObjElement      = not(isempty(stHierarchyInfo.elementObject));
    astBusSignals.oMetaBusSig         = [];
    
else
    %get  bus object
    if ~isempty(stHierarchyInfo.busObjectName)
        try
            tmpBusObject = oItf.evalinGlobal(stHierarchyInfo.busObjectName);
        catch
            tmpBusObject = [];
        end
    else
        tmpBusObject = [];
    end
    
    %get elements of child bus object and store them into BusSignal structures
    for iElmt = 1:numel(busSignalHierarchy.Children)
        
        busSignalHierarchyChild = busSignalHierarchy.Children(iElmt);
        stHierarchyInfoChild = [];
        stHierarchyInfoChild.isVirtual = isempty(tmpBusObject);
        
        if not(stHierarchyInfo.isVirtual)
            stHierarchyInfoChild.sTopBusSignalName = stHierarchyInfo.sTopBusSignalName;
        else
            if stHierarchyInfo.isVirtual && not(isempty(busSignalHierarchyChild.Children))
                stHierarchyInfoChild.sTopBusSignalName = busSignalHierarchyChild.SignalName;
            else
                stHierarchyInfoChild.sTopBusSignalName = stHierarchyInfo.sTopBusSignalName;
            end
        end
        stHierarchyInfoChild.busObjectName = busSignalHierarchyChild.BusObject;
        
        if not(isempty(tmpBusObject))
            stHierarchyInfoChild.elementObject = tmpBusObject.Elements(iElmt);
            stHierarchyInfoChild.sCodeVariableAccessPath = [stHierarchyInfo.sCodeVariableAccessPath '.' stHierarchyInfoChild.elementObject.Name];
            stHierarchyInfoChild.sModelSignalPath = [stHierarchyInfo.sModelSignalPath '.' stHierarchyInfoChild.elementObject.Name];
        else
            stHierarchyInfoChild.elementObject = [];
            stHierarchyInfoChild.sCodeVariableAccessPath = '';
            stHierarchyInfoChild.sModelSignalPath = [stHierarchyInfo.sModelSignalPath '.' busSignalHierarchyChild.SignalName];
        end
        astBusSignals = [astBusSignals, i_getBusSignals(oItf, busSignalHierarchyChild, stHierarchyInfoChild)];
    end
end
end


%%
function [sBusSignalName, sErrMsg] = i_getBusName(oItf)
sBusSignalName = '';

[oSig, sErrMsg] = i_getBusSig(oItf.internalSourcePortHandle);
if isempty(sErrMsg)
    sBusSignalName = oSig.getName();
end
end


%%
function [oSig, sErrMsg] = i_getBusSig(hPort)
oSig    = [];
sErrMsg = '';
try
    oSig = ep_core_feval('ep_sl_signal_from_port_get', hPort);
    if ~oSig.isValid
        sErrMsg = sprintf('Bus signal name for port "%s" could not be evaluated.', getfullname(hPort));
    end
catch oEx
    sErrMsg = oEx.message;
end
end
