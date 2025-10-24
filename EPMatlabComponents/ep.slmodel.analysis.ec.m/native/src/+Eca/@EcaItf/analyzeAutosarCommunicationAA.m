function oItf = analyzeAutosarCommunicationAA(oEca, oItf)
%
stAutosarInfo.oAutosarProps = oEca.oAutosarProps;
stAutosarInfo.oAutosarSLMapping = oEca.oAutosarSLMapping;
stAutosarInfo.sArComponentPath = oEca.sArComponentPath;
stAutosarInfo.sAutosarVersion = oEca.sAutosarVersion;
stAutosarInfo.sArComponentName = oEca.sArComponentName;
stAutosarInfo.oAutosarMetaProps = oEca.oAutosarMetaProps;
stAutosarInfo.mApp2Imp = oEca.mApp2Imp;

oItf = i_analyzePortAutosarCom(oItf, stAutosarInfo);
end


%%
function oItf = i_analyzePortAutosarCom(oItf, stAutosarInfo)

bIsValidAutosarCom = false;
if oItf.bIsRootIO
    sRootIOName = get(oItf.hRootIOSrcBlk, 'Name');
    try
        switch oItf.kind
            case 'IN'
                [sMappedPortName, sMappedEventName] = getInport(stAutosarInfo.oAutosarSLMapping, sRootIOName);
                bAllocMem = false;

                stPortMetaInfo = i_findPortMetaInfo( ...
                    stAutosarInfo.oAutosarMetaProps.astRequiredPorts, ...
                    sMappedPortName, ...
                    sMappedEventName);

            case 'OUT'
                [sMappedPortName, sMappedEventName, bAllocMem] = getOutport(stAutosarInfo.oAutosarSLMapping, sRootIOName);

                stPortMetaInfo = i_findPortMetaInfo( ...
                    stAutosarInfo.oAutosarMetaProps.astProvidedPorts, ...
                    sMappedPortName, ...
                    sMappedEventName);
        end
        bIsValidAutosarCom = ~isempty(stPortMetaInfo);

    catch
        bIsValidAutosarCom = false;
    end
end

if bIsValidAutosarCom
    stAddInfo = struct( ...
        'sMappedEventName',         sMappedEventName, ...
        'bAllocateMemory',          bAllocMem, ...
        'sArComponentName',         stAutosarInfo.sArComponentName, ...
        'sAutosarVersion',          stAutosarInfo.sAutosarVersion, ...
        'sIdentifyServiceInstance', stAutosarInfo.oAutosarProps.get('XmlOptions', 'IdentifyServiceInstance'));
    oItf.oAutosarComInfo = i_createComObject(stPortMetaInfo, stAddInfo);

    oItf.name = sprintf('[%s] Port:%s Event:%s', ...
        oItf.oAutosarComInfo.sPortType, ...
        oItf.oAutosarComInfo.sPortName, ...
        oItf.oAutosarComInfo.sMappedEventName);
    
    oItf.oAutosarComInfo.sComponentName  = stAutosarInfo.sArComponentName;
    oItf.oAutosarComInfo.sAutosarVersion = stAutosarInfo.sAutosarVersion;
    oItf.bIsAutosarCom = true;
    oItf.bIsAdaptiveAutosar = true;

else
    oItf.oAutosarComInfo = Eca.aa.Com; % create empty default Com object (which is a placeholder for invalid-info)
    oItf.casAnalysisNotes{end + 1} = sprintf( ...
        '% port %s is not configured for AUTOSAR communication and therefore cannot be analyzed.', ...
        oItf.kind, ...
        oItf.sourceBlockName);
    oItf.bIsAutosarCom = false;

end
end


%%
function stPortMetaInfo = i_findPortMetaInfo(astPortMetaInfos, sPortName, sEventOrFieldName)
stPortMetaInfo = [];

for iPort = 1:numel(astPortMetaInfos)
    if strcmp(astPortMetaInfos(iPort).sPortName, sPortName)
        if(isempty(astPortMetaInfos(iPort).stInterface.astEvents(:)))
            bEventFound = false;
        else
            bEventFound = ismember({astPortMetaInfos(iPort).stInterface.astEvents(:).sName}, sEventOrFieldName);
        end
        if(isempty(astPortMetaInfos(iPort).stInterface.astFields(:)))
            bFieldFound = false;
        else
            bFieldFound = ismember({astPortMetaInfos(iPort).stInterface.astFields(:).sName}, sEventOrFieldName);
        end
        if any(bEventFound) || any(bFieldFound)
            stPortMetaInfo = astPortMetaInfos(iPort);
            break;
        end
    end
end
end


%%
function oCom = i_createComObject(stPortMetaInfo, stAddInfo)
oCom = Eca.aa.Com;

oCom.sComponentName  = stAddInfo.sArComponentName;
oCom.sAutosarVersion = stAddInfo.sAutosarVersion;

oCom.sInterfaceName = stPortMetaInfo.stInterface.sName;
oCom.astEvents      = stPortMetaInfo.stInterface.astEvents;
oCom.casNamespaces  = stPortMetaInfo.stInterface.casNamespaces;

oCom.sPortType             = stPortMetaInfo.sPortType;
oCom.sPortName             = stPortMetaInfo.sPortName;
oCom.sInstanceSpecifier    = stPortMetaInfo.sInstanceSpecifier;
oCom.sInstanceIdentifier   = stPortMetaInfo.sInstanceIdentifier;
oCom.sServiceDiscoveryMode = stPortMetaInfo.sServiceDiscoveryMode;

oCom.sMappedEventName = stAddInfo.sMappedEventName;
oCom.bAllocateMemory  = stAddInfo.bAllocateMemory;

if strcmp(stAddInfo.sIdentifyServiceInstance, 'InstanceSpecifier')
    oCom.sInstanceKey = oCom.sInstanceSpecifier;
else
    oCom.sInstanceKey = oCom.sInstanceIdentifier;
end
end



