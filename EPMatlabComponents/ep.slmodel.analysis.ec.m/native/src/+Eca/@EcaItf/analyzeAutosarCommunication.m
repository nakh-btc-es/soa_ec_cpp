function oItf = analyzeAutosarCommunication(oEca, oItf, sMode, oDataObj)
%
stAutosarInfo.oAutosarProps = oEca.oAutosarProps;
stAutosarInfo.oAutosarSLMapping = oEca.oAutosarSLMapping;
stAutosarInfo.sArComponentPath = oEca.sArComponentPath;
stAutosarInfo.sAutosarVersion = oEca.sAutosarVersion;
stAutosarInfo.sArComponentName = oEca.sArComponentName;
stAutosarInfo.oAutosarMetaProps = oEca.oAutosarMetaProps;
stAutosarInfo.mApp2Imp = oEca.mApp2Imp;
stAutosarInfo.mParamReceiverPortsToInterface = oEca.mParamReceiverPortsToInterface;
if strcmp(sMode, 'PORT')
    oItf = i_analyzePortAutosarCom(oItf, stAutosarInfo);
    
elseif strcmp(sMode, 'DATAOBJECT')
    oItf = i_analyzeDataObjectAutosarCom(oItf, stAutosarInfo, oDataObj);
end
end


%%
function oItf = i_analyzePortAutosarCom(oItf, stAutosarInfo)
% IRV or O

bMatchAutosarCom = false;
stInfo.arProps = stAutosarInfo.oAutosarProps;
stInfo.sKind = oItf.kind;
stInfo.sSwcPath = stAutosarInfo.sArComponentPath;
stInfo.oArMetaProps = stAutosarInfo.oAutosarMetaProps;

%Find as AUTOSAR Port and Interface (RootIO connectedports)
bSLMappingExist = false;
if oItf.bIsRootIO
    sRootIOName = get(oItf.hRootIOSrcBlk, 'Name');
    try %#ok<TRYNC>
        switch oItf.kind
            case 'IN'
                [sPortName, sDataElementName, sDataAccessMode] = getInport(stAutosarInfo.oAutosarSLMapping, sRootIOName);
            case 'OUT'
                [sPortName, sDataElementName, sDataAccessMode] = getOutport(stAutosarInfo.oAutosarSLMapping, sRootIOName);
        end
        bSLMappingExist = true;
    end
    if bSLMappingExist
        stInfo.sPortName = sPortName;
        stInfo.sDataElementName = sDataElementName;
        stInfo.sDataAccessMode = sDataAccessMode;
        %Analyze as Autosar Ports Interfaces
        oItf.oAutosarComInfo = i_analyzeAsInterface(stInfo);
        oItf.name = [ ...
            '[', oItf.oAutosarComInfo.sInterfaceType, '] Port:', ...
            oItf.oAutosarComInfo.sPortName, ' DE:', oItf.oAutosarComInfo.sDataElementName];
        bMatchAutosarCom = true;
    end
end

%Find as AUTOSAR IRV
if ~bMatchAutosarCom
    if oItf.bParentScopeIsRunnableChild && ~isempty(oItf.hParentRunExtIOPort)
        %The interface belong to a scope inside a runnable scope
        sLineName = get(oItf.hParentRunExtIOPort, 'Name');
    else
        sLineName = oItf.sExternLineName;
        if (isempty(sLineName) && ~isempty(oItf.externalSourcePortHandle))
            hAlternativeHandle = ep_core_feval('ep_ec_port_src_dst_trace', oItf.externalSourcePortHandle, 1);
            if ~isempty(hAlternativeHandle)
                sLineName = get(hAlternativeHandle, 'Name');
            end
        end
    end
    if ~isempty(sLineName)
        try %#ok<TRYNC>
            [sIrvName, sDataAccessMode] = getDataTransfer(stAutosarInfo.oAutosarSLMapping, sLineName);
            bSLMappingExist = true;
        end
        if bSLMappingExist
            stInfo.sIrvName = sIrvName;
            stInfo.sDataAccessMode = sDataAccessMode;
            %Analyze as IRV intefaces
            oItf.oAutosarComInfo = i_analyzeAsIrv(stInfo);
            oItf.name = ['[', oItf.oAutosarComInfo.sComType,'] Data:', oItf.oAutosarComInfo.sDataName];
            bMatchAutosarCom = true;
        end
    end
end

%Others ar info
if bMatchAutosarCom
    oItf.oAutosarComInfo.sComponentName = stAutosarInfo.sArComponentName;
    oItf.oAutosarComInfo.sRunnableName = oItf.sParentRunnableName;
    oItf.oAutosarComInfo.sAutosarVersion = stAutosarInfo.sAutosarVersion;
    oItf.bIsAutosarCom = true;
else
    oItf.casAnalysisNotes{end+1} = sprintf( ...
        '% port %s is not configured with an Autosar communication and therefore cannot be analyzed.', ...
        oItf.kind, ...
        oItf.sourceBlockName);
    oItf.bIsAutosarCom = false;
end
end


%%
function oArComInfo = i_analyzeAsInterface(stInfo)
switch stInfo.sKind
    case 'IN'
        %Sender/Receiver interface -> Receiver Port
        oArComInfo = i_findAs('SenderReceiver', stInfo, stInfo.oArMetaProps.astReceiverPorts, 'Receiver');
        if ~isempty(oArComInfo)
            return;
        end
        
        %NvData interface -> NvReceiver Port
        oArComInfo = i_findAs('NvData', stInfo, stInfo.oArMetaProps.astNvReceiverPorts, 'Receiver');
        if ~isempty(oArComInfo)
            return;
        end
        
        % ModeSwitch interface -> Receiver port
        oArComInfo = i_findAsModeSwitch('ModeSwitch', stInfo, stInfo.oArMetaProps.astModeReceiverPorts, 'Receiver');
        if ~isempty(oArComInfo)
            return;
        end
        
        %SenderReceiverPort
        oArComInfo = i_findAs('SenderReceiver', stInfo, stInfo.oArMetaProps.astSenderReceiverPorts, 'SenderReceiverPortIN');
        if ~isempty(oArComInfo)
            return;
        end
        
        %NvSenderReceiverPort
        oArComInfo = i_findAs('NvData', stInfo, stInfo.oArMetaProps.astNvSenderReceiverPorts, 'SenderReceiverPortIN');
        if ~isempty(oArComInfo)
            return;
        end
        
    case 'OUT'
        %Sender/Receiver interface -> Sender Port
        oArComInfo = i_findAs('SenderReceiver', stInfo, stInfo.oArMetaProps.astSenderPorts, 'Sender');
        if ~isempty(oArComInfo)
            return;
        end
        
        %NvData interface -> NvSender Port
        oArComInfo = i_findAs('NvData', stInfo, stInfo.oArMetaProps.astNvSenderPorts, 'Sender');
        if ~isempty(oArComInfo)
            return;
        end
        
        %ModeSwitch interface -> ModeSwitch Port
        oArComInfo = i_findAsModeSwitch('ModeSwitch', stInfo, stInfo.oArMetaProps.astModeSenderPorts, 'Sender');
        if ~isempty(oArComInfo)
            return;
        end
        
        %SenderReceiverPort
        oArComInfo = i_findAs('SenderReceiver', stInfo, stInfo.oArMetaProps.astSenderReceiverPorts, 'SenderReceiverPortOUT');
        if ~isempty(oArComInfo)
            return;
        end
        
        %NvSenderReceiverPort
        oArComInfo = i_findAs('NvData', stInfo, stInfo.oArMetaProps.astNvSenderReceiverPorts, 'SenderReceiverPortOUT');
        if ~isempty(oArComInfo)
            return;
        end
end

% if not found, return a default but non-valid object
oArComInfo = Eca.MetaAutosarCom;
oArComInfo.bValidCom = false;
end


%%
function oArComInfo = i_findAs(sInterfaceType, stInfo, astPortsInfo, sPortType)
oArComInfo = [];
for iPort = 1:numel(astPortsInfo)
    if strcmp(astPortsInfo(iPort).sPortName, stInfo.sPortName)
        nIdxFound = ismember({astPortsInfo(iPort).astDataElement(:).sName}, stInfo.sDataElementName);
        if any(nIdxFound)
            oArComInfo = Eca.MetaAutosarCom;
            oArComInfo.sDataElementName = astPortsInfo(iPort).astDataElement(nIdxFound).sName;
            oArComInfo.sItfName = astPortsInfo(iPort).sItfName;
            oArComInfo.sPortName = stInfo.sPortName;
            oArComInfo.sAccessMode = stInfo.sDataAccessMode;
            oArComInfo.sPortType = sPortType;
            oArComInfo.sInterfaceType = sInterfaceType;
            oArComInfo.bIsInterfaceCom = true;
            oArComInfo.sComType = 'Interface';
            oArComInfo.bValidCom = true;
            oArComInfo.sImplDatatype = astPortsInfo(iPort).astDataElement(nIdxFound).sImplDatatype;
            break;
        end
    end
end
end


%%
function oArComInfo = i_findAsModeSwitch(sInterfaceType, stInfo, astPortsInfo, sPortType)
oArComInfo = [];
for iPort = 1:numel(astPortsInfo)
    if strcmp(astPortsInfo(iPort).sPortName, stInfo.sPortName)
        oArComInfo = Eca.MetaAutosarCom;
        oArComInfo.sItfName = astPortsInfo(iPort).sItfName;
        oArComInfo.sPortName = stInfo.sPortName;
        oArComInfo.sAccessMode = stInfo.sDataAccessMode;
        oArComInfo.sPortType = sPortType;
        oArComInfo.sInterfaceType = sInterfaceType;
        oArComInfo.bIsInterfaceCom = true;
        oArComInfo.sComType = 'Interface';
        oArComInfo.bValidCom = true;
        oArComInfo.sModeGroup = astPortsInfo(iPort).sModeGroup;
        break;
    end
end
end


%%
function oArComInfo = i_analyzeAsIrv(stInfo)
%astIRVs(iIrv).sName
%astIRVs(iIrv).sPath
%astIRVs(iIrv).sImplDatatype
oArComInfo = Eca.MetaAutosarCom;
oArComInfo.sDataName = stInfo.sIrvName;
oArComInfo.sAccessMode = stInfo.sDataAccessMode;
oArComInfo.sComType = 'InterRunnableVariable';
for iIrv = 1:numel(stInfo.oArMetaProps.astIRVs)
    if strcmp(stInfo.oArMetaProps.astIRVs(iIrv).sName, stInfo.sIrvName)
        oArComInfo.sImplDatatype = stInfo.oArMetaProps.astIRVs(iIrv).sImplDatatype;
        oArComInfo.bIsIRVCom = true;
        oArComInfo.bValidCom = true;
        break;
    end
end
end


%%
function oItf = i_analyzeDataObjectAutosarCom(oItf, stAutosarInfo, oDataObj)
%Search as CalPrm Interface, Internal Calibration  or PerInstanceMemory

oItf.bIsAutosarCom = false;

%Parameters
if strcmp(oItf.kind, 'PARAM')
    if isa(oDataObj, 'AUTOSAR.Parameter') && strcmp(oDataObj.CoderInfo.CustomStorageClass, 'CalPrm')
        stInfo.arProps = stAutosarInfo.oAutosarProps;
        stInfo.sPortName = oDataObj.CoderInfo.CustomAttributes.PortName;
        stInfo.sCalPrmElementName = oDataObj.CoderInfo.CustomAttributes.ElementName;
        stInfo.sCalibrationComponent = oDataObj.CoderInfo.CustomAttributes.CalibrationComponent;
        stInfo.sProviderPortName = oDataObj.CoderInfo.CustomAttributes.ProviderPortName;
        stInfo.sInterfacePath = oDataObj.CoderInfo.CustomAttributes.InterfacePath;
        stInfo.sSwcPath = stAutosarInfo.sArComponentPath;
        stInfo.mParamReceiverPortsToInterface = stAutosarInfo.mParamReceiverPortsToInterface;
        oItf.oAutosarComInfo = i_analyzeAsCalPrmInterface(stInfo);
        oItf.bIsAutosarCom = true;
    end
    
    %Find as Internal Calibration
    if isa(oDataObj, 'AUTOSAR.Parameter') && strcmp(oDataObj.CoderInfo.CustomStorageClass, 'InternalCalPrm')
        bIsPerInstance = i_isPerInstance(oDataObj.CoderInfo.CustomAttributes.PerInstanceBehavior);
        oItf.oAutosarComInfo = i_analyzeAsInternalCalibration(oItf.name, bIsPerInstance);
        oItf.bIsAutosarCom = true;
    end
    
    oAutosarComInfo = i_findAutosarMapping(stAutosarInfo, oItf.name, oDataObj);
    if ~isempty(oAutosarComInfo)
        oItf.oAutosarComInfo = oAutosarComInfo;
        oItf.bIsAutosarCom = true;
    end

    
elseif strcmp(oItf.kind, 'IN') || strcmp(oItf.kind, 'OUT') %PIM accesses (Using DataStore)
    
    %Find as PIM
    if isa(oDataObj, 'AUTOSAR.Signal') && strcmp(oDataObj.CoderInfo.CustomStorageClass, 'PerInstanceMemory')
        stInfo.sPIMName = oItf.name;
        stInfo.sPimIsComplexType = ~oDataObj.CoderInfo.CustomAttributes.IsArTypedPerInstanceMemory;
        stInfo.bPimAccessNVRam = oDataObj.CoderInfo.CustomAttributes.needsNVRAMAccess;
        oItf.oAutosarComInfo = i_analyzeAsPIM(stInfo);
        oItf.bIsAutosarCom = true;
    end
end

if  oItf.bIsAutosarCom
    oItf.oAutosarComInfo.sComponentName = stAutosarInfo.sArComponentName;
    oItf.oAutosarComInfo.sRunnableName = oItf.sParentRunnableName;
    oItf.oAutosarComInfo.sAutosarVersion = stAutosarInfo.sAutosarVersion;
    oItf.oAutosarComInfo.sImplDatatype = oItf.codedatatype;
else
    if strcmp(oItf.kind, 'IN') || strcmp(oItf.kind, 'OUT')
        oItf.casAnalysisNotes{end+1} = sprintf( ...
            '[%s] Inteface on block %s cannot be analyzed as Autosar Communication.', oItf.kind, oItf.sourceBlockName);
    end
end
end


%%
function oAutosarComInfo = i_findAutosarMapping(stAutosarInfo, sDataObjName, oDataObj)
oAutosarComInfo = [];

stMappingInfo = i_getAutosarMappingInfo(stAutosarInfo.oAutosarSLMapping, sDataObjName, oDataObj);
if ~isempty(stMappingInfo.sAccessMode)
    switch stMappingInfo.sAccessMode
        case 'PortParameter'
            stInfo.arProps               = stAutosarInfo.oAutosarProps;
            stInfo.sPortName             = stMappingInfo.sPortName;
            stInfo.sCalPrmElementName    = stMappingInfo.sParamData;
            stInfo.sSwcPath              = stAutosarInfo.sArComponentPath;
            stInfo.sCalibrationComponent = stAutosarInfo.sArComponentName;
            stInfo.sProviderPortName     = '';
            stInfo.mParamReceiverPortsToInterface = stAutosarInfo.mParamReceiverPortsToInterface;
            stInfo.sInterfacePath        = i_getParamInterfacePath(stInfo);

            oAutosarComInfo = i_analyzeAsCalPrmInterface(stInfo);

        case {'PerInstance', 'PerInstanceParameter'}
            oAutosarComInfo = i_analyzeAsInternalCalibration(stMappingInfo.sParamData, true);

        case {'Shared', 'SharedParameter'}
            oAutosarComInfo = i_analyzeAsInternalCalibration(stMappingInfo.sParamData, false);

        case 'ConstantMemory'
            oAutosarComInfo = i_analyzeAsConstantMemory(stMappingInfo.sParamData);

        otherwise
            % just ignore for now
    end
end
end


%%
function stInfo = i_getAutosarMappingInfo(oMappingAR, sObjName, oObj)
stInfo = struct( ...
    'bIsValid',    false, ...
    'sAccessMode', '', ...
    'sPortName',   '', ...
    'sParamData',  '');

if (isa(oObj, 'Simulink.Parameter') || isa(oObj, 'Simulink.Breakpoint') || isa(oObj, 'Simulink.LookupTable'))
    try %#ok<TRYNC>
        stInfo.sAccessMode = oMappingAR.getParameter(sObjName);
    end    
    switch stInfo.sAccessMode
        case 'PortParameter'
            stInfo.sPortName = oMappingAR.getParameter(sObjName, 'Port');
            stInfo.sParamData = oMappingAR.getParameter(sObjName, 'DataElement');
            stInfo.bIsValid = true;

        case {'PerInstanceParameter', 'SharedParameter'}
            stInfo.sParamData = sObjName;
            stInfo.bIsValid = true;
    end
end

% for older ML versions, Breakpoints and Tables can also be accessed differently; check this if needed
if (~stInfo.bIsValid && (isa(oObj, 'Simulink.Breakpoint') || isa(oObj, 'Simulink.LookupTable')))
    try %#ok<TRYNC> 
        [stInfo.sAccessMode, stInfo.sPortName, stInfo.sParamData] = oMappingAR.getLookupTable(sObjName);
        stInfo.bIsValid = true;
    end
end
end


%%
function sItfPath = i_getParamInterfacePath(stInfo)
sItfPath = '';
if stInfo.mParamReceiverPortsToInterface.isKey(stInfo.sPortName)
    sItfPath = stInfo.mParamReceiverPortsToInterface(stInfo.sPortName);
end
end


%%
function oArComInfo = i_analyzeAsCalPrmInterface(stInfo)
oArComInfo = Eca.MetaAutosarCom;
if stInfo.mParamReceiverPortsToInterface.isKey(stInfo.sPortName)    
    sItfPath = stInfo.sInterfacePath;
    casDEs = stInfo.arProps.get(sItfPath, 'DataElements', 'PathType', 'FullyQualified');
    for iDE = 1:numel(casDEs)
        [~, sDEName] = fileparts(casDEs{iDE});
        if strcmp(sDEName, stInfo.sCalPrmElementName)
            oArComInfo.sDataElementName = sDEName;
            oArComInfo.sItfName = i_getName(stInfo.arProps, sItfPath);
            oArComInfo.sPortName = stInfo.sPortName;
            oArComInfo.sPortType = 'ReceiverCalPrm';
            oArComInfo.sInterfaceType = 'Calibration';
            oArComInfo.bIsInterfaceCom = true;
            oArComInfo.sComType = 'CalprmInterface';
            oArComInfo.bValidCom = true;
            break;
        end
    end
end
oArComInfo.bIsCalPrmInterfaceCom = true;
end


%%
function oArComInfo = i_analyzeAsInternalCalibration(sParamName, bIsPerInstance)
oArComInfo = Eca.MetaAutosarCom;
oArComInfo.sDataName                 = sParamName;
oArComInfo.sPerInstanceParam         = bIsPerInstance;
oArComInfo.sComType                  = 'InternalCalibration';
oArComInfo.bIsInternalCalibrationCom = true;
oArComInfo.bValidCom                 = true;
end


%%
function oArComInfo = i_analyzeAsConstantMemory(sParamName)
oArComInfo = Eca.MetaAutosarCom;
oArComInfo.sDataName                 = sParamName;
oArComInfo.sComType                  = 'ConstantMemory';
oArComInfo.bIsInternalCalibrationCom = true;
oArComInfo.bValidCom                 = true;
end


%%
function bIsPerInstance = i_isPerInstance(sPerInstanceBhv)
bIsPerInstance = strcmp(sPerInstanceBhv, 'Each instance of the Software Component has its own copy of the parameter');
end


%%
function oArComInfo = i_analyzeAsPIM(stInfo)
oArComInfo = Eca.MetaAutosarCom;
oArComInfo.sDataName = stInfo.sPIMName;
oArComInfo.bPimAccessNVRam = stInfo.bPimAccessNVRam;
oArComInfo.sPimIsComplexType = stInfo.sPimIsComplexType;
oArComInfo.sComType = 'PerInstanceMemory';
oArComInfo.bIsPIMCom = true;
oArComInfo.bValidCom = true;
end


%%
function sName = i_getName(oAutosarProps, sPath) %#ok<INUSL>
bDoItClean = false;

if bDoItClean
    % this is the *clean* way but much too slow
    sName = oAutosarProps.get(sPath, 'Name'); %#ok<UNRCH> OK TODO: dead code can used for later re-factoring!
else
    sName = regexprep(sPath, '.*/', '');
end
end


