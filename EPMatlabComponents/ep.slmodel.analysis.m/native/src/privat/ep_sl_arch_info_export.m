function ep_sl_arch_info_export(xEnv, stArchInfo, sFile)
% TODO docu
%


%%
if (nargin < 3)
    sFile = fullfile(pwd, 'slArch.xml');
end

%%
[hRootDoc, oOnCleanupClose] = i_createRootNode(stArchInfo.sAddModelInfoFile, stArchInfo.sInitScriptFile); %#ok<ASGLU>
i_addMainToolInfos(hRootDoc);
[hRootModel, mRefModelIDs] = i_addModels(hRootDoc, stArchInfo.astModules, stArchInfo.sInitScriptFile);
i_addSubsystems(xEnv, hRootModel, stArchInfo.stModel, mRefModelIDs);

mxx_xmltree('save', hRootDoc, sFile);
end


%%
function i_addSubsystems(xEnv, hParent, stModel, mRefModelIDs)
mTypeInfoMap = i_createTypeInfoMap(stModel.astTypeInfos);

nSubs = numel(stModel.astSubsystems);
if (nSubs < 1)
    return;
end

casSubIDs = cell(1, nSubs);
for i = 1:nSubs
    casSubIDs{i} = i_translateSubsysID(stModel.astSubsystems(i).iID);
end

hRootSub = [];
for i = 1:nSubs
    stSubsystem = stModel.astSubsystems(i);
    stGlobalSubElements = i_getGlobalSubsysElements(stModel, i);
    sSubID = casSubIDs{i};
    
    hSub = i_addSubsystem(hParent, stSubsystem, sSubID, mRefModelIDs);
    
    i_addInports(xEnv, hSub, stSubsystem, mTypeInfoMap, mRefModelIDs);
    i_addDsmInports(xEnv, hSub, stGlobalSubElements.astDsmReaders, mRefModelIDs);
    
    i_addParameters(xEnv, hSub, stGlobalSubElements.astParams, mTypeInfoMap, mRefModelIDs);
    
    i_addOutports(xEnv, hSub, stSubsystem, mTypeInfoMap, mRefModelIDs);
    i_addDsmOutports(xEnv, hSub, stGlobalSubElements.astDsmWriters, mRefModelIDs);
    
    i_addLocals(xEnv, hSub, stGlobalSubElements.astLocals, mTypeInfoMap, mRefModelIDs);
    
    i_addExternalDependencySlFunctions(hSub, stGlobalSubElements.astSlFunctions);
    
    i_addChildSubsystems(hSub, casSubIDs(stSubsystem.aiChildIdx));
    
    if i_isRootSubsystem(stSubsystem)
        hRootSub = hSub;
    end
end
hRootSubsysRef = mxx_xmltree('add_node', hParent, 'rootSystem');
mxx_xmltree('set_attribute', hRootSubsysRef, 'refSubsysID', mxx_xmltree('get_attribute', hRootSub, 'subsysID'));
end


%%
function i_addInports(xEnv, hParent, stSubsystem, mTypeInfoMap, mRefModelIDs)
% note: all inports share model reference with parent subsystem
sRefModelID = i_getRefModelID(stSubsystem.sPath, mRefModelIDs);
sArchPathSub = i_removeModelPrefix(stSubsystem.sVirtualPath);
i_addPorts(xEnv, hParent, stSubsystem.stCompInfo.astInports, 'inport', sArchPathSub, sRefModelID, mTypeInfoMap);
end


%%
function i_addDsmInports(xEnv, hParent, astDsmReaders, mRefModelIDs)
i_addDsmPorts(xEnv, hParent, astDsmReaders, 'inport', mRefModelIDs);
end


%%
function i_addParameters(xEnv, hParent, astParams, mTypeInfoMap, mRefModelIDs)
for i = 1:numel(astParams)
    stParam = astParams(i);
    stParamBlock = stParam.astBlockInfo(1);
    
    sRefModelID = i_getRefModelID(stParamBlock.sPath, mRefModelIDs);
    sArchPath   = i_removeModelPrefix(stParamBlock.sVirtualPath);
    
    hParam = mxx_xmltree('add_node', hParent, 'parameter');
    mxx_xmltree('set_attribute', hParam, 'name', stParam.sName);
    mxx_xmltree('set_attribute', hParam, 'path', sArchPath);
    mxx_xmltree('set_attribute', hParam, 'physicalPath', stParamBlock.sPath);
    i_setNonEmptyAttribute(hParam, 'modelRef', sRefModelID)
    mxx_xmltree('set_attribute', hParam, 'origin', 'explicit_param');
    
    % add workspace variable; however, not for TL-DD sources since there is none
    if ~strcmp(stParam.sSourceType, 'TL data dictionary')
        mxx_xmltree('set_attribute', hParam, 'workspace', stParam.sName);
    end
    
    oSig = ep_sl_param_signal_adapt(stParam, mTypeInfoMap);
    if ~oSig.isValid()
        ep_env_message_add(xEnv, 'EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sArchPath);
        mxx_xmltree('add_node', hParam, 'unsupportedTypeInformation');
    else
        oSig = i_setSignalNameAndClearIt(hParam, oSig);
        i_extendWithSignalInfo(xEnv, hParam, oSig);
    end
    i_addParamUsages(hParam, stParam.astBlockInfo, mRefModelIDs);
    i_addParamSource(hParam, stParam);
end
end


%%
function i_addParamUsages(hParent, astBlockInfos, mRefModelIDs)
for i = 1:numel(astBlockInfos)
    stParamBlock = astBlockInfos(i);
    
    sRefModelID = i_getRefModelID(stParamBlock.sPath, mRefModelIDs);
    sArchPath   = i_removeModelPrefix(stParamBlock.sVirtualPath);
    
    hParamUsage = mxx_xmltree('add_node', hParent, 'usageContext');
    mxx_xmltree('set_attribute', hParamUsage, 'path', sArchPath);
    mxx_xmltree('set_attribute', hParamUsage, 'physicalPath', stParamBlock.sPath);
    mxx_xmltree('set_attribute', hParamUsage, 'simulinkBlockType', stParamBlock.sBlockType);
    i_setNonEmptyAttribute(hParamUsage, 'blockAttribute', i_getBlockAttribute(stParamBlock.stUsage))
    i_setNonEmptyAttribute(hParamUsage, 'modelRef', sRefModelID)
end
end


%%
function i_addParamSource(hParent, stParam)
hParamSource = mxx_xmltree('add_node', hParent, 'source');
switch stParam.sSourceType
    case 'TL data dictionary'
        mxx_xmltree('set_attribute', hParamSource, 'kind', 'TL-DataDictionary');
        i_setNonEmptyAttribute(hParamSource, 'file',   stParam.sSource)
        i_setNonEmptyAttribute(hParamSource, 'access', stParam.sSourceAccess)

    case 'data dictionary'
        mxx_xmltree('delete_node', hParamSource);
%         mxx_xmltree('set_attribute', hParamSource, 'kind', 'SL-DataDictionary');
%         i_setNonEmptyAttribute(hParamSource, 'file', stParam.sSource);

    case 'base workspace'
        mxx_xmltree('delete_node', hParamSource);
%         mxx_xmltree('set_attribute', hParamSource, 'kind', 'BaseWorkspace');
%         mxx_xmltree('set_attribute', hParamSource, 'file', '');

    case 'model workspace'
        mxx_xmltree('set_attribute', hParamSource, 'kind', 'ModelWorkspace');
        i_setNonEmptyAttribute(hParamSource, 'file', stParam.sSource);

    otherwise %default behaviour
        mxx_xmltree('delete_node', hParamSource);
        warning('EP:INERNAL:ERROR', 'Unexpected parameter source type "%s" found.', stParam.sSourceType);
        return;
end
end


%%
function i_addExternalDependencySlFunctions(hParent, astSlFunctions)
for k = 1:numel(astSlFunctions)
    stSlFunc = astSlFunctions(k);
    
    for i = 1:numel(stSlFunc.astCallers)
        sArchPath = i_removeModelPrefix(stSlFunc.astCallers(i).sVirtualPath);
        sModelPath = stSlFunc.astCallers(i).sPath;

        hSlCallerUsage = mxx_xmltree('add_node', hParent, 'slfunc_caller');
        mxx_xmltree('set_attribute', hSlCallerUsage, 'path', sArchPath);
        mxx_xmltree('set_attribute', hSlCallerUsage, 'pathCaller', sModelPath);
        mxx_xmltree('set_attribute', hSlCallerUsage, 'pathFunction', stSlFunc.sPath);
    end
end
end


%%
function sBlockAttrib = i_getBlockAttribute(stUsage)
casBlockAttribs = fieldnames(stUsage);
if ~isempty(casBlockAttribs)
    sBlockAttrib = casBlockAttribs{1};
else
    sBlockAttrib = '';
end
end


%%
function i_addOutports(xEnv, hParent, stSubsystem, mTypeInfoMap, mRefModelIDs)
% note: all inports share model reference with parent subsystem
sRefModelID = i_getRefModelID(stSubsystem.sPath, mRefModelIDs);
sArchPathSub = i_removeModelPrefix(stSubsystem.sVirtualPath);
i_addPorts(xEnv, hParent, stSubsystem.stCompInfo.astOutports, 'outport', sArchPathSub, sRefModelID, mTypeInfoMap);
end


%%
function i_addDsmOutports(xEnv, hParent, astDsmWriters, mRefModelIDs)
i_addDsmPorts(xEnv, hParent, astDsmWriters, 'outport', mRefModelIDs);
end


%%
function i_addLocals(xEnv, hParent, astLocals, mTypeInfoMap, mRefModelIDs)
i_addLocalPorts(xEnv, hParent, astLocals, mRefModelIDs, mTypeInfoMap);
end


%%
% common function for inports and outports
function i_addPorts(xEnv, hParent, astPorts, sKind, sArchPathSub, sRefModelID, mTypeInfoMap)
for i = 1:numel(astPorts)
    stPort = astPorts(i);
    
    sPortName = i_getBlockNameFromPath(stPort.sPath);
    if isempty(sArchPathSub)
        sArchPathPort = regexprep(sPortName, '/', '//');
    else
        sArchPathPort = [sArchPathSub, '/', regexprep(sPortName, '/', '//')];
    end
    
    hPort = mxx_xmltree('add_node', hParent, sKind);
    mxx_xmltree('set_attribute', hPort, 'portNumber', sprintf('%d', stPort.iNumber));
    mxx_xmltree('set_attribute', hPort, 'name', sPortName);
    mxx_xmltree('set_attribute', hPort, 'physicalPath', stPort.sPath);
    mxx_xmltree('set_attribute', hPort, 'path', sArchPathPort);
    if stPort.oSig.isMessage()
        mxx_xmltree('set_attribute', hPort, 'isMessage', 'true'); 
    end
    i_setNonEmptyAttribute(hPort, 'modelRef', sRefModelID)
    
    oSig = ep_sl_port_signal_adapt(stPort, mTypeInfoMap);
    if ~i_isSignalTypeSupported(oSig)
        ep_env_message_add(xEnv, 'EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', stPort.sPath);
        mxx_xmltree('add_node', hPort, 'unsupportedTypeInformation');
    else
        oSig = i_setSignalNameAndClearIt(hPort, oSig);
        i_extendWithSignalInfo(xEnv, hPort, oSig);
    end
end
end


%%
function bIsSupported = i_isSignalTypeSupported(oSig)
bIsSupported = oSig.isValid();
if bIsSupported
    if oSig.isBus()
        for i = 1:numel(oSig.aoSubSignals_)
            bIsSupported = bIsSupported && i_isSignalTypeSupported(oSig.aoSubSignals_(i));
        end
        
    else
        oTypes = ep_sl.Types.getInstance();
        stTypeInfo = oSig.stTypeInfo_;
        bIsSupported = stTypeInfo.bIsValidType && oTypes.isSupported(stTypeInfo.sEvalType);
    end
end
end


%%
% Note: after the signal name is applied, the signal name is remove from the object to facilitate further processing
function oSig = i_setSignalNameAndClearIt(hSignal, oSig)
sSigName = i_adaptEmptyNameForBus(oSig);
i_setNonEmptyAttribute(hSignal, 'signalName', sSigName);
oSig.sName_ = '';
end


%%
function i_extendWithSignalInfo(xEnv, hSignal, oSig, bForceArray)
if (nargin < 4)
    bForceArray = false;
end

bIsScalar = ~bForceArray && isequal(oSig.getDim(), [1 1]);
if bIsScalar
    if oSig.isBus()
        i_addBusSignal(xEnv, hSignal, oSig);
    else
        i_addScalarSignal(xEnv, hSignal, oSig);
    end
else
    if oSig.isUniform()
        i_addArray(xEnv, hSignal, oSig);
    else
        i_addNonUniformArray(xEnv, hSignal, oSig);
    end
end
end


%%
function sSigName = i_adaptEmptyNameForBus(oSig)
sSigName = oSig.sName_;
if (oSig.isBus() && isempty(sSigName))
    sSigName = '<signal1>';
end
end


%%
function i_addScalarSignal(~, hSignal, oSig)
[bIsEnum, bIsFxpPoint] = i_checkScalarTypeCategory(oSig.stTypeInfo_);

sExportType = i_getExportType(oSig.stTypeInfo_);
if bIsEnum
    i_addEnumType(hSignal, sExportType, oSig.stTypeInfo_.astEnum);
else
    if bIsFxpPoint
        [sWordLength, sSigned, sSlope, sBias] = i_getFxpAttibs(oSig.stTypeInfo_);
        hSigType = mxx_xmltree('add_node', hSignal, 'fixedPoint');
        mxx_xmltree('set_attribute', hSigType, 'simulinkTypeName', sExportType);
        mxx_xmltree('set_attribute', hSigType, 'wordLength', sWordLength);
        mxx_xmltree('set_attribute', hSigType, 'isSigned',   sSigned);
        mxx_xmltree('set_attribute', hSigType, 'slope',      sSlope);
        mxx_xmltree('set_attribute', hSigType, 'bias',       sBias);
    else
        hSigType = mxx_xmltree('add_node', hSignal, sExportType);
    end
    [sMin, sMax] = oSig.getEffectiveMinMax();
    i_setNonEmptyAttribute(hSigType, 'min', sMin);
    i_setNonEmptyAttribute(hSigType, 'max', sMax);
end
if ~isempty(oSig.xInitValue_)
    sInitValue = i_getScalarInitValueAsString(oSig.xInitValue_);
    mxx_xmltree('set_attribute', hSignal, 'initValue', sInitValue);
end
end


%%
function sType = i_getExportType(stTypeInfo)
if stTypeInfo.bIsEnum
    sType = stTypeInfo.sEvalType;
    return;
end

bIsFxpType = ~isempty(regexp(stTypeInfo.sEvalType, '^fixdt\(', 'once'));
if bIsFxpType
    sType = stTypeInfo.sEvalType;
    return;
end

sType = stTypeInfo.sBaseType;
if strcmp(sType, 'logical')
    sType = 'boolean'; % always translate logical type from ML into boolean type from SL
end
end


%%
function i_addEnumType(hSignal, sEnumTypeName, astEnumElems)
hEnumType = mxx_xmltree('add_node', hSignal, 'enumType');
mxx_xmltree('set_attribute', hEnumType, 'name', sEnumTypeName);

for i = 1:numel(astEnumElems)
    stEnumElem = astEnumElems(i);
    
    hEnumElem = mxx_xmltree('add_node', hEnumType, 'enumElement');
    mxx_xmltree('set_attribute', hEnumElem, 'name',  stEnumElem.Key);
    mxx_xmltree('set_attribute', hEnumElem, 'value', sprintf('%d', stEnumElem.Value));
end
end


%%
function [bIsEnum, bIsFxpPoint] = i_checkScalarTypeCategory(stTypeInfo)
bIsFxpPoint = false;
bIsEnum = stTypeInfo.bIsEnum;
if bIsEnum
    return;
end

bIsFxpPoint = i_isFxpType(stTypeInfo);
end


%%
% TODO: on some branch isFxpType is already part of the stTypeInfo struct! --> replace after merge!
function bIsFxpPoint = i_isFxpType(stTypeInfo)
bIsFxpPoint = ~isempty(regexp(stTypeInfo.sEvalType, '^fixdt\(', 'once'));
end


%%
function i_addBusSignal(xEnv, hSignal, oSig)
hBusType = mxx_xmltree('add_node', hSignal, 'bus');
i_setNonEmptyAttribute(hBusType, 'busType', i_translateBusType(oSig.sBusType_));
i_setNonEmptyAttribute(hBusType, 'busObjectName', oSig.sBusObj_);

for i = 1:numel(oSig.aoSubSignals_)
    oSubSignal = oSig.aoSubSignals_(i);
    
    hBusSubSignal = mxx_xmltree('add_node', hBusType, 'signal');
    oSubSignal = i_setSignalNameAndClearIt(hBusSubSignal, oSubSignal);
    i_extendWithSignalInfo(xEnv, hBusSubSignal, oSubSignal);
end
end


%%
function sBusType = i_translateBusType(sBusType)
if strcmp(sBusType, 'NON_VIRTUAL_BUS')
    sBusType = 'non_virtual';
else
    sBusType = ''; % note: virtual is default --> so leave it unset
end
end


%%
function i_addNonUniformArray(xEnv, hSignal, oSig)
aiDim = oSig.getDim();
nDim  = aiDim(1);
iSize = aiDim(2);
if (nDim == 1)
    % array case: after getting the width
    % and set new dimension for following function indicating a scalar signal
    oSig.aiDim_ = [1 1];
    bForceArray = false;
else
    % matrix case: after getting the width
    % and set new dimension for following function indicating an array signal
    oSig.aiDim_ = [1 aiDim(3)];
    
    % note: special case aiDim might be [1 1]; however, still the following functions need to treat the signal as array!
    bForceArray = true;
end

hNonUniArray = mxx_xmltree('add_node', hSignal, 'nonUniformArray');
mxx_xmltree('set_attribute', hNonUniArray, 'size', sprintf('%d', iSize));

iIndexOffset = oSig.iIndexOffset_;
if (iIndexOffset ~= 0)
    mxx_xmltree('set_attribute', hNonUniArray, 'startIndex', sprintf('%d', 1 + iIndexOffset));
end

xOrigInitValue = oSig.xInitValue_;
for i = 1:iSize
    if ~isempty(xOrigInitValue)
        if (nDim == 1)
            xSliceInitValue = xOrigInitValue(i);    % 1-dim orig --> scalar slice
        else
            xSliceInitValue = xOrigInitValue(i, :); % 2-dim orig --> 1-dim slice
        end
        oSig.xInitValue_ = xSliceInitValue;
    end
        
    hSubSig = mxx_xmltree('add_node', hNonUniArray, 'signal');
    mxx_xmltree('set_attribute', hSubSig, 'index', sprintf('%d', i + iIndexOffset));
    i_extendWithSignalInfo(xEnv, hSubSig, oSig, bForceArray);
end
end


%%
function i_addArray(xEnv, hSignal, oSig)
aiDim = oSig.getDim();
nDim  = aiDim(1);
iSize = aiDim(2);
if (nDim == 1)
    % array case: get width
    % and set new dimension for following function indicating a scalar signal
    oSig.aiDim_ = [1 1];
    
    bForceArray = false;
else
    % matrix case: get width of second dimension
    % and set new dimension for following function indicating an array signal
    oSig.aiDim_ = [1 aiDim(3)];
    
    % note: special case aiDim might be [1 1]; however, still the following functions need to treat the signal as array!
    bForceArray = true;
end

iIndexOffset = oSig.iIndexOffset_;

hArray = mxx_xmltree('add_node', hSignal, 'array');
mxx_xmltree('set_attribute', hArray, 'size', sprintf('%d', iSize));
mxx_xmltree('set_attribute', hArray, 'startIndex', sprintf('%d', 1 + iIndexOffset));
i_extendWithSignalInfo(xEnv, hArray, oSig, bForceArray);
end


%%
% common function for inports and outports
function i_addLocalPorts(xEnv, hParent, astLocals, mRefModelIDs, mTypeInfoMap)
for i = 1:numel(astLocals)
    stLocal = astLocals(i);
    
    stSfInfo = i_getStateflowLocalAddInfo(stLocal);
    if isempty(stSfInfo)
        sLocalName = i_getBlockNameFromPath(stLocal.sPath);
        sSfVar = '';
        iIdxOffset = 0;
    else
        sLocalName = stSfInfo.sName;
        sSfVar     = stSfInfo.sName;
        iIdxOffset = stSfInfo.iIndexOffset;
    end
    if ~isempty(stLocal.aiPorts)
        sPortNum = sprintf('%d', stLocal.aiPorts(1));
    else
        sPortNum = '';
    end
    sRefModelID = i_getRefModelID(stLocal.sPath, mRefModelIDs);
    sArchPath   = i_removeModelPrefix(stLocal.sVirtualPath);
    
    hLocal = mxx_xmltree('add_node', hParent, 'display');
    mxx_xmltree('set_attribute', hLocal, 'physicalPath', stLocal.sPath);
    mxx_xmltree('set_attribute', hLocal, 'path', sArchPath);
    mxx_xmltree('set_attribute', hLocal, 'name', sLocalName);
    i_setNonEmptyAttribute(hLocal, 'stateflowVariable', sSfVar)
    i_setNonEmptyAttribute(hLocal, 'portNumber', sPortNum)
    i_setNonEmptyAttribute(hLocal, 'modelRef', sRefModelID)
    
    if ~isempty(stLocal.aiPorts)
        stPort = i_getLocalPort(stLocal.stCompInfo, stLocal.aiPorts(1));
    else
        stPort = i_getCorrespondingInternalLocalPort(stLocal);
        if isempty(stPort)
            ep_env_message_add(xEnv, 'EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sArchPath);
            mxx_xmltree('add_node', hLocal, 'unsupportedTypeInformation');
            return;
        end
    end
    oSig = ep_sl_port_signal_adapt(stPort, mTypeInfoMap);
    if oSig.isMessage()
    	mxx_xmltree('set_attribute', hLocal, 'isMessage', 'true'); 
    end
    if (iIdxOffset ~= 0)
        oSig = oSig.setLeafIndexOffset(iIdxOffset);
    end
    if ~i_isSignalTypeSupported(oSig)
        ep_env_message_add(xEnv, 'EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', stLocal.sPath);
        mxx_xmltree('add_node', hLocal, 'unsupportedTypeInformation');        
    else
        oSig = i_setSignalNameAndClearIt(hLocal, oSig);
        i_extendWithSignalInfo(xEnv, hLocal, oSig);
    end
end
end


%%
function stPort = i_getLocalPort(stBlock, iPortIdx)
if isempty(stBlock.astOutports)
    % this is the OutPort block --> this block has only one input port
    stPort = stBlock.astInports(iPortIdx);
else
    stPort = stBlock.astOutports(iPortIdx);
end
end


%%
function stPort = i_getCorrespondingInternalLocalPort(stLocal)
nInnerLocals = numel(stLocal.stCompInfo.astLocals);
if (nInnerLocals == 1)
    stPort = stLocal.stCompInfo.astLocals(1);
else
    sSfName = stLocal.sName;
    sSfRelPath = stLocal.sSfRelPath;
    for i = 1:nInnerLocals
        stInnerLocal = stLocal.stCompInfo.astLocals(i);
        if strcmp(stInnerLocal.sSfName, sSfName) && strcmp(stInnerLocal.sSfRelPath, sSfRelPath)
            stPort = stInnerLocal;
            return;
        end
    end
    stPort = [];
end
end


%%
function stSfInfo = i_getStateflowLocalAddInfo(stLocal)
stSfInfo = [];
if (isfield(stLocal, 'stSfInfo') && ~isempty(stLocal.stSfInfo))
    stSfInfo = struct( ...
        'sName',        stLocal.stSfInfo.sSfName, ...
        'iIndexOffset', stLocal.stSfInfo.iSfFirstIndex - 1);
end
end


%%
% common function for DSM readers and writers
function i_addDsmPorts(xEnv, hParent, astDsms, sKind, mRefModelIDs)
for i = 1:numel(astDsms)
    stDsm = astDsms(i);
    iIdxBlock = i_findBestSuitedBlock(astDsms(i).astUsingBlocks, sKind);
    stDsmIO = astDsms(i).astUsingBlocks(iIdxBlock);
    
    sDsmIOName  = i_getBlockNameFromPath(stDsmIO.sPath);
    sRefModelID = i_getRefModelID(stDsmIO.sPath, mRefModelIDs);
    sArchPath   = i_removeModelPrefix(stDsmIO.sVirtualPath);
    
    bIsSF = strcmpi(stDsmIO.sBlockType, 'SubSystem');
    if bIsSF
        % note: for SF-Charts the path might get ambiguous if multiple DSs are accessed
        %       --> to resolve ambiguity, introduce a fake extension here with the DS name
        sArchPath = [sArchPath, '/', stDsm.sName]; %#ok<AGROW>
    end
    
    hPort = mxx_xmltree('add_node', hParent, sKind);
    mxx_xmltree('set_attribute', hPort, 'portNumber', '0');
    mxx_xmltree('set_attribute', hPort, 'name', sDsmIOName);
    mxx_xmltree('set_attribute', hPort, 'physicalPath', stDsmIO.sPath);
    mxx_xmltree('set_attribute', hPort, 'path', sArchPath);
    i_setNonEmptyAttribute(hPort, 'modelRef', sRefModelID);
    
    oSig = stDsm.oSig;
    if ~i_isSignalTypeSupported(oSig)
        ep_env_message_add(xEnv, 'EP:EPSLIMP:SIGNAL_WITH_UNSUPPORTED_TYPE_DEFINITION', 'path', sArchPath);
        mxx_xmltree('add_node', hPort, 'unsupportedTypeInformation');
    else
        oSig = i_setSignalNameAndClearIt(hPort, oSig);
        i_extendWithSignalInfo(xEnv, hPort, oSig);
    end
    
    hDsm = mxx_xmltree('add_node', hPort, 'dataStoreMemory');
    mxx_xmltree('set_attribute', hDsm, 'signalName', stDsm.sName);
    i_setNonEmptyAttribute(hDsm, 'physicalPath', stDsm.sPath)
end
end


%%
% note1: Reader/Writers are potentially accepted as OUTPORTs 
%        --> for the OUTPORTs, prefer to report the Writer location instead of the Reader
% note2: also in context of OUTPORTs we can have SF-Chart access
%        --> prefer to use blocks that are not SF-Charts because they can cause ambiguity on higher levels
%        example: DSWriter X and SF-Chart Y are accessing datastore A --> return preferrably X instead of Y
%
function iIdx = i_findBestSuitedBlock(astUsingBlocks, sKind)
 % as a fallback use always 1
iIdx = 1;
if strcmp(sKind, 'inport')
    return;
end

for i = 1:numel(astUsingBlocks)
    if astUsingBlocks(i).bIsWriter
        iIdx = i;
        
        % note: if we have a SubSystem (== SF-Chart) access, memorize the index but keep on looking
        %       if we have a non-SubSystem access, return immediately
        if ~strcmpi(astUsingBlocks(i).sBlockType, 'SubSystem')
            return;
        end
    end
end
end


%%
function stGlobalSubElements = i_getGlobalSubsysElements(stModel, iSubsysIdx)
stSubsys = stModel.astSubsystems(iSubsysIdx);

stGlobalSubElements = struct( ...
    'astParams',      i_filterRelevantParams(stModel.astParams, stSubsys.astParamRefs), ...
    'astLocals',      i_filterRelevantLocals(stModel.astLocals, stSubsys.astLocalRefs), ...
    'astDsmReaders',  i_filterRelevantDatastores(stModel.astDsms, stSubsys.astDsmReaderRefs), ...
    'astDsmWriters',  i_filterRelevantDatastores(stModel.astDsms, stSubsys.astDsmWriterRefs), ...
    'astSlFunctions', i_filterRelevantSlFunctions(stModel.astSlFunctions, stSubsys.astSlFuncRefs));
end


%%
function astRelevantParams = i_filterRelevantParams(astParams, astParamRefs)
if isempty(astParamRefs)
    astRelevantParams = [];
else
    aiRelevantParamIndexes = [astParamRefs(:).iVarIdx];
    astRelevantParams = astParams(aiRelevantParamIndexes);
    
    % now we need to filter the relevant usage blocks of the parameters
    for i = 1:numel(astParamRefs)
        astRelevantParams(i).astBlockInfo = astRelevantParams(i).astBlockInfo(astParamRefs(i).aiBlockIdx);
    end
end
end


%%
function astRelevantLocals = i_filterRelevantLocals(astLocals, astLocalRefs)
if isempty(astLocalRefs)
    astRelevantLocals = [];
else
    % note1: currently locals can have only *one* corresponding block
    % --> this means that the reference always entails this block
    % ==> we do not need to filter out block information here
    % note2: this is different from params where we need to filter out the relevant blocks also
    aiRelevantLocalIndexes = [astLocalRefs(:).iVarIdx];
    astRelevantLocals = astLocals(aiRelevantLocalIndexes);
end
end


%%
function astRelevantDsms = i_filterRelevantDatastores(astDsms, astDsmRefs)
if isempty(astDsmRefs)
    astRelevantDsms = [];
else
    aiRelevantParamIndexes = [astDsmRefs(:).iVarIdx];
    astRelevantDsms = astDsms(aiRelevantParamIndexes);
    
    % now we need to filter the relevant reader/writer blocks of the datastores
    for i = 1:numel(astDsmRefs)
        astRelevantDsms(i).astUsingBlocks = astRelevantDsms(i).astUsingBlocks(astDsmRefs(i).aiBlockIdx);
    end
end
end


%%
function astRelevantSlFunctions = i_filterRelevantSlFunctions(astSlFunctions, astSlFuncRefs)
if isempty(astSlFuncRefs)
    astRelevantSlFunctions = [];
else
    aiRelevantParamIndexes = [astSlFuncRefs(:).iVarIdx];
    astRelevantSlFunctions = astSlFunctions(aiRelevantParamIndexes);
    
    % now we need to filter the relevant reader/writer blocks of the datastores
    for i = 1:numel(astSlFuncRefs)
        astRelevantSlFunctions(i).astCallers = astRelevantSlFunctions(i).astCallers(astSlFuncRefs(i).aiBlockIdx);
    end
end
end


%%
function mTypeInfoMap = i_createTypeInfoMap(astTypeInfos)
mTypeInfoMap = containers.Map;
for i = 1:length(astTypeInfos)
    mTypeInfoMap(astTypeInfos(i).sType) = astTypeInfos(i);
end
end


%%
function i_addChildSubsystems(hParent, casChildSubIDs)
for i = 1:numel(casChildSubIDs)
    hChildRef = mxx_xmltree('add_node', hParent, 'subsystem');
    mxx_xmltree('set_attribute', hChildRef, 'refSubsysID', casChildSubIDs{i});
end
end


%%
function bIsRoot = i_isRootSubsystem(stSubsystem)
bIsRoot = isempty(stSubsystem.iParentIdx);
end


%%
function sModelRefID = i_getRefModelID(sPath, mRefModelIDs)
sModelRefID = '';

sContainingModel = i_normalizeForModelRef(i_getModelNameFromPath(sPath));
if mRefModelIDs.isKey(sContainingModel)
    sModelRefID = mRefModelIDs(sContainingModel);
end
end


%%
function hSub = i_addSubsystem(hParent, stSubsystem, sSubID, mRefModelIDs)
sArchSubPath = i_removeModelPrefix(stSubsystem.sVirtualPath);

% note: for refence models use the name of the reference block instead of the ref model name
bIsMainModel = isempty(sArchSubPath);
bIsRefModel = ~bIsMainModel && strcmp(stSubsystem.sName, stSubsystem.sPath);
if bIsRefModel
    sSubName = i_getBlockNameFromPath(stSubsystem.sVirtualPath);
else
    sSubName = stSubsystem.sName;
end

hSub = mxx_xmltree('add_node', hParent, 'subsystem');
mxx_xmltree('set_attribute', hSub, 'subsysID',     sSubID);
mxx_xmltree('set_attribute', hSub, 'physicalPath', stSubsystem.sPath);
mxx_xmltree('set_attribute', hSub, 'path',         sArchSubPath);
mxx_xmltree('set_attribute', hSub, 'sampleTime',   sprintf('%g', stSubsystem.dSampleTime));
mxx_xmltree('set_attribute', hSub, 'name',         sSubName);
mxx_xmltree('set_attribute', hSub, 'scopeKind',    i_getScopeKind(stSubsystem));
mxx_xmltree('set_attribute', hSub, 'kind',         i_getSubsystemKind(stSubsystem));

sModelRefID = i_getRefModelID(stSubsystem.sPath, mRefModelIDs);
if ~isempty(sModelRefID)
    mxx_xmltree('set_attribute', hSub, 'modelRef', sModelRefID);
end
end


%%
function sKind = i_getScopeKind(stSubsystem)
if stSubsystem.bIsDummy
    sKind = 'DUMMY';
else
    sKind = 'SUT';
end
end


%%
function sKind = i_getSubsystemKind(stSubsystem)
if isempty(stSubsystem.sSFClass)
    sKind = 'subsystem';
else
    sKind = 'stateflow';
end
end


%%
function sSubsysID = i_translateSubsysID(iID)
sSubsysID = sprintf('ss%d', iID);
end


%%
function sPathWithoutModelPrefix = i_removeModelPrefix(sPath)
if any(sPath == '/')
    sPathWithoutModelPrefix = regexprep(sPath, '^([^/]|(//))*/', '');
else
    sPathWithoutModelPrefix = '';
end
end


%%
function [hRoot, oOnCleanupClose] = i_createRootNode(sAddModelInfoFile, sInitScriptFile)
hRoot = mxx_xmltree('create', 'sl:SimulinkArchitecture');
oOnCleanupClose = onCleanup(@() mxx_xmltree('clear', hRoot));

mxx_xmltree('set_attribute', hRoot, 'xmlns:sl', 'http://btc-es.de/ep/simulink/2014/12/09');

if ~isempty(sAddModelInfoFile)
    mxx_xmltree('set_attribute', hRoot, 'infoXML', sAddModelInfoFile);
end
if ~isempty(sInitScriptFile)
    mxx_xmltree('set_attribute', hRoot, 'initScript', sInitScriptFile);
end
end


%%
function [hRootModel, mRefModelIDs] = i_addModels(hParent, astModules, sInitScriptFile)
mRefModelIDs = containers.Map();
if isempty(astModules)
    % only for debug/UT workflows: empty model node is generated, if no meta data is available
    hRootModel = mxx_xmltree('add_node', hParent, 'model');
    mxx_xmltree('set_attribute', hRootModel, 'modelID', 'model001');
    
else
    hRootModel = [];
    
    nModels = length(astModules);
    ahModels = repmat(hParent, 1, nModels);
    for i = 1:nModels
        stModule = astModules(i);
        
        sCreated = i_convertDate(stModule.sCreated);
        sModified = i_convertDate(stModule.sModified);
        sModelID = sprintf('model00%d', i);
        ahModels(i) = i_addModel(hParent, stModule, sCreated, sModified, sInitScriptFile, sModelID);
        
        % assumption: kind = "model" occurs only once for the root model
        if strcmp(stModule.sKind, 'model')
            hRootModel = ahModels(i);
            mxx_xmltree('set_attribute', hParent, 'modelVersion', stModule.sVersion);
            mxx_xmltree('set_attribute', hParent, 'modelPath', stModule.sFile);
            mxx_xmltree('set_attribute', hParent, 'modelCreationDate', sCreated);
            mxx_xmltree('set_attribute', hParent, 'creator', stModule.sCreator);
            
        elseif strcmp(stModule.sKind, 'model_ref')
            sModelName = i_normalizeForModelRef(i_getModelNameFromFile(stModule.sFile));
            mRefModelIDs(sModelName) = sModelID;
        end
    end
    
    if isempty(hRootModel)
        error('EP:SL_ARCH:NO_ROOT_MODEL', 'Failed finding a root model.');
    end
end

hRootModelRef = mxx_xmltree('add_node', hParent, 'root');
mxx_xmltree('set_attribute', hRootModelRef, 'refModelID', mxx_xmltree('get_attribute', hRootModel, 'modelID'));
end


%%
function hModelNode = i_addModel(hParent, stModule, sCreated, sModified, sInitScriptFile, sID)
hModelNode = mxx_xmltree('add_node', hParent, 'model');

mxx_xmltree('set_attribute', hModelNode, 'modelID', sID);
mxx_xmltree('set_attribute', hModelNode, 'modelKind', stModule.sKind);
mxx_xmltree('set_attribute', hModelNode, 'modelVersion', stModule.sVersion);
mxx_xmltree('set_attribute', hModelNode, 'modelPath', stModule.sFile);
mxx_xmltree('set_attribute', hModelNode, 'creationDate', sCreated);
mxx_xmltree('set_attribute', hModelNode, 'modificationDate', sModified);
if ~isempty(sInitScriptFile)
    mxx_xmltree('set_attribute', hModelNode, 'initScript', sInitScriptFile);
end
end


%%
function i_addMainToolInfos(hParent)
stVersion = ver('Matlab');
sRelease = stVersion.Release;
[sVersion, sPatch] = ep_core_version_get('ML');
i_addToolInfo(hParent, 'Matlab', sRelease, sVersion, sPatch);

stVersion = ver('Simulink');
sRelease = stVersion.Release;
[sVersion, sPatch] = ep_core_version_get('SL');
i_addToolInfo(hParent, 'Simulink', sRelease, sVersion, sPatch);
end


%%
function i_addToolInfo(hParent, sToolName, sRelease, sVersion, sPatch)
hToolInfo = mxx_xmltree('add_node', hParent, 'toolInfo');
mxx_xmltree('set_attribute', hToolInfo, 'name',       sToolName);
mxx_xmltree('set_attribute', hToolInfo, 'release',    sRelease);
mxx_xmltree('set_attribute', hToolInfo, 'version',    sVersion);
mxx_xmltree('set_attribute', hToolInfo, 'patchLevel', sPatch);
end


%%
function sNormalizedDate = i_convertDate(sDate)
sTargetFormat = 'yyyy-mm-ddTHH:MM:SS'; % normalize all incoming dates into this format

try % try the MATLAB format
    sNormalizedDate = datestr(datenum(sDate, 'ddd mmm dd HH:MM:SS yyyy'), sTargetFormat);
    return;
catch
end

try % try the ISO format
    sNormalizedDate = datestr(datenum(sDate, 'yyyy-mm-ddTHH:MM:SS'), sTargetFormat);
    return;
catch
end

try % try MATLAB heuristic to determine the correct format
    sNormalizedDate = datestr(datenum(sDate), sTargetFormat);
    return;
catch
end

% use the 1st Jan 1970 as fall back if nothing else worked out
sNormalizedDate = '1970-01-01T00:00:00';
warning('EP:SL_ARCH:FAILED_DATE_CONVERSION', ...
    'Failed to convert date "%s" to format "%s". Date is set to "%s".', sDate, sTargetFormat, sNormalizedDate);
end


%%
function sName = i_normalizeForModelRef(sName)
sName = lower(sName);
end


%%
function sModelName = i_getModelNameFromFile(sFile)
[~, sModelName] = fileparts(sFile);
end


%%
function sModelName = i_getModelNameFromPath(sPath)
if any(sPath == '/')
    sModelName = regexprep(sPath, '/.*$', '');
else
    sModelName = sPath;
end
end


%%
function sName = i_getBlockNameFromPath(sPath)
% remove prefix path from block name; take care: in paths slashes in block names are escaped by "//"
sName = regexprep(sPath, '(.)*[^/]/([^/])', '$2');
% now replace escaped slashes in block name to get the valid block name
sName = regexprep(sName, '//', '/');
end


%%
function i_setNonEmptyAttribute(hNode, sAttrib, sAttribValue)
if ~isempty(sAttribValue)
    mxx_xmltree('set_attribute', hNode, sAttrib, sAttribValue);
end
end


%%
function sValue = i_getScalarInitValueAsString(xInitValue)
oVal = ep_sl.Value(xInitValue);
sValue = oVal.toString();
end


%%
function [sWordLength, sSigned, sSlope, sBias] = i_getFxpAttibs(stTypeInfo)
[bIsSigned, iWordLength] = i_getSignednessAndWordlength(stTypeInfo.sBaseType);

sWordLength = sprintf('%d', iWordLength);
sSigned     = sprintf('%d', bIsSigned);
sSlope      = i_getScalarInitValueAsString(stTypeInfo.dLsb);
sBias       = i_getScalarInitValueAsString(stTypeInfo.dOffset);
end


%%
function [bIsSigned, iWordLength] = i_getSignednessAndWordlength(sBaseType)
bIsSigned = ~isempty(sBaseType) && (sBaseType(1) ~= 'u');
iWordLength = str2double(regexprep(sBaseType, '^[^\d]+', ''));
end


