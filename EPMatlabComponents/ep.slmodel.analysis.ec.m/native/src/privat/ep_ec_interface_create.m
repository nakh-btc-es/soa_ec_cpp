function aoItfs = ep_ec_interface_create(oItf, aoBusSigs, stCodeFormat)

bWithCodeMapping = ~isempty(stCodeFormat);

aoItfs = oItf;

%For Bus Interfaces, expand Intefarces objects to all Bus elements signals
iItf = 1;
if aoItfs(iItf).isBusElement
    iFirstBusElement = iItf;
    aoItfs(iItf).isBusFirstElement = true;
    for iBusElmt = 1:numel(aoBusSigs)
        if iBusElmt > 1
            iItf = iItf + 1;
            aoItfs(iItf) = aoItfs(iItf - 1);
            aoItfs(iItf).metaBus.bFirstElmtMappingValid = aoItfs(iFirstBusElement).bMappingValid;
            aoItfs(iItf).metaBus.stFirstElmtArComCfg = aoItfs(iFirstBusElement).stArComCfg;
        end
        if bWithCodeMapping
            aoItfs(iItf).metaBusSignal = [];
            aoItfs(iItf).oMetaBusSig_ = aoBusSigs(iBusElmt);
            if aoItfs(iItf).bIsAutosarCom
                aoItfs(iItf) = i_analyzePropsAndCodeRepAutosar(aoItfs(iItf), stCodeFormat);
            else
                aoItfs(iItf) = i_getBusSignalName(aoItfs(iItf), aoBusSigs(iBusElmt).signalName);
                aoItfs(iItf) = i_analyzePropsAndCodeRep(aoItfs(iItf), stCodeFormat);
            end
        end
    end
else
    if bWithCodeMapping
        if aoItfs(iItf).bIsAutosarCom
            aoItfs(iItf) = i_analyzePropsAndCodeRepAutosar(aoItfs(iItf), stCodeFormat);
        else
            if isempty(aoItfs(iItf).name)
                %% bIsModelInterface = oScope.bScopeIsModelBlock && (any(strcmp(sKind, {'IN', 'OUT'})));
                bIsModelInterface = false;
                aoItfs(iItf) = i_getSignalName(aoItfs(iItf), bIsModelInterface);
            end
            aoItfs(iItf) = i_analyzePropsAndCodeRep(aoItfs(iItf), stCodeFormat);
        end
    end
end
end


%%
% get code variable name for non-Bus interfaces
function oItf = i_getSignalName(oItf, bIsModelInterface)

%a. Get name from port name (if port resolves a Signal Object or a Signal Object is specified localy)
portProps = get(oItf.sourcePortHandle);
if strcmp(portProps.MustResolveToSignalObject, 'on') || ~isempty(portProps.SignalObject)
    oItf.name = portProps.Name;
else
    %b. Get name from CompiledRTWIdentifier
    hPort = i_getPortHandleForSignalIdentifier(oItf, bIsModelInterface);
    sSignalName = get(hPort, 'CompiledRTWSignalIdentifier');
    if isempty(sSignalName)
        oItf.name = 'UNKNOWN-SIGNAL-NAME';
        oItf.casAnalysisNotes{end + 1} = 'Signal name cannot be retrieved from compiled RTW Identifier because it is empty.';
    else
        oItf.name = sSignalName;
    end
end
end


%%
function hPort = i_getPortHandleForSignalIdentifier(oItf, bIsModelInterface)
if (strcmpi(oItf.kind, 'IN') && ~isempty(oItf.externalSourcePortHandle) && ~bIsModelInterface)
    hPort = oItf.externalSourcePortHandle;
else
    if ~isempty(oItf.internalSourcePortHandle)
        hPort = oItf.internalSourcePortHandle;
    else
        hPort = oItf.externalSourcePortHandle;
    end
end
end


%%
% get code variable for Bus element interface
function oItf = i_getBusSignalName(oItf, sSignalName)
if isempty(sSignalName)
    oItf.name = 'UNKNOWN-SIGNAL-NAME';
    oItf.casAnalysisNotes{end + 1} = 'Signal name cannot be retrieved from Bus hierarchy.';
else
    oItf.name = sSignalName;
end
end


%%
function oItf = i_analyzePropsAndCodeRepAutosar(oItf, stCodeFormatAutosar)
oItf = oItf.getSignalProperties([]);
oItf = oItf.getCodeVariableAutosar(stCodeFormatAutosar);
end


%%
function oItf = i_analyzePropsAndCodeRep(oItf, stCodeFormat)
if (isempty(oItf.name) || strcmp(oItf.name, 'UNKNOWN-SIGNAL-NAME'))
    oDataObject = [];
else
    oDataObject = oItf.findCorrespondingDataObject();
end
if ~isempty(oDataObject)
    oItf = oItf.getSignalProperties(oDataObject);
    oItf = oItf.getCodeVariable(stCodeFormat, oDataObject);
else
    oItf.casAnalysisNotes{end + 1} = ...
        'Code representation cannot be extracted because no corresponding signal object can be found.';
end
end

