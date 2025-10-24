function atgcv_m01_model_analysis_export(stEnv, stModel, sOutputFile)
% Export model analysis structure into an XML file.
%
% function atgcv_m01_model_analysis_export(stEnv, stModel, sOutputFile)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  environment structure
%     stModel             (struct)  Model analysis struct produced by
%                                   "atgcv_m01_model_analyse"
%     sOutputFile         (string)  full path to output file
%
%   OUTPUT              DESCRIPTION
%
%
%   <et_copyright>


%% prepare data
% reset persistent counters (used globally)
i_resetInternalCounters();
xOnCleanupClearCounters = onCleanup(@() i_clearInternalCounters());

i_typeInfo('init', i_createTypeInfoMap(stModel.astTypeInfos));

% set TL or SL context
i_isSL(strcmpi(stModel.sModelMode, 'SL'));

% write XML
sGlobalInitFunc = '';
if ~i_isSL()
    if stModel.bSetGlobalInitFuncForAutosar
        sGlobalInitFunc = 'Rte_Start';
    end
end

%% write XML
hRootNode = i_createHeader();
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hRootNode));
try
    casSubIDs = {stModel.astSubsystems(:).sId};

    nSub = length(stModel.astSubsystems);
    for i = 1:nSub
        stSub = stModel.astSubsystems(i);

        hSubNode = i_addSubsystemNode(stEnv, hRootNode, stSub, sGlobalInitFunc);

        i_addChildrenAndParentsNode(hSubNode, stSub, casSubIDs);
        i_addInterfaceNode(stEnv, hSubNode, stSub, stModel);
        i_addSignatureNode(stEnv, hSubNode, stSub.stFuncInterface);
        i_addFunctionNode(stEnv, hSubNode, 'proxyStep', stSub.stProxyFunc);

        if ~strcmp(stSub.sModelPath, stSub.sTlPath)
            i_addModelReferenceNode(stEnv, hSubNode, stSub.sModelPath, 'TL');
        end
        if isfield(stSub, 'sSlPath')
            if ~strcmp(stSub.sModelPathSl, stSub.sSlPath)
                i_addModelReferenceNode(stEnv, hSubNode, stSub.sModelPathSl, 'SL');
            end
        end
    end

    if (isfield(stModel, 'stSystemTimeVar') && ~isempty(stModel.stSystemTimeVar))
        i_addSystemTimeVar(stEnv, hRootNode, stModel.stSystemTimeVar);
    end

    astEnums = atgcv_m01_enum_type_store();
    if ~isempty(astEnums)
        hEnumTypes = mxx_xmltree('add_node', hRootNode, 'EnumTypes');
        for i = 1:length(astEnums)
            stEnum = astEnums(i);
            hEnumType = mxx_xmltree('add_node', hEnumTypes, 'EnumType');
            mxx_xmltree('set_attribute', hEnumType, 'id', stEnum.sName);
            mxx_xmltree('set_attribute', hEnumType, 'name', stEnum.sName);
            for j = 1:length(stEnum.astEnumElements)
                stEnumElement = stEnum.astEnumElements(j);
                hEnumElement = mxx_xmltree('add_node', hEnumType, 'EnumElement');
                mxx_xmltree('set_attribute', hEnumElement, 'name', stEnumElement.sName);
                mxx_xmltree('set_attribute', hEnumElement, 'value', stEnumElement.sValue);
            end
        end
    end

catch %#ok<CTCH>
    stErr = osc_lasterror();
    osc_throw(stErr);
end
mxx_xmltree('save', hRootNode, sOutputFile);
end


%%
function i_addChildrenAndParentsNode(hSubNode, stSub, casSubIDs)
hChildrenNode = [];

aiChildIdx = stSub.aiChildIdx;
if ~isempty(aiChildIdx)
    hChildrenNode = mxx_xmltree('add_node', hSubNode, 'Children');
    nChildren = length(aiChildIdx);
    for j = 1:nChildren
        hRefNode = mxx_xmltree('add_node', hChildrenNode, 'SubsystemRef');
        sChildId = casSubIDs{aiChildIdx(j)};
        mxx_xmltree('set_attribute', hRefNode, 'refID', sChildId);
    end
end

if (isfield(stSub, 'astBlocks') && ~isempty(stSub.astBlocks))
    if isempty(hChildrenNode)
        hChildrenNode = mxx_xmltree('add_node', hSubNode, 'Children');
    end
    for j = 1:length(stSub.astBlocks)
        stBlock = stSub.astBlocks(j);
        hBlockNode = mxx_xmltree('add_node', hChildrenNode, 'Block');

        mxx_xmltree('set_attribute', hBlockNode, 'name', stBlock.sName);
        mxx_xmltree('set_attribute', hBlockNode, 'path', stBlock.sPath);
        mxx_xmltree('set_attribute', hBlockNode, 'type', stBlock.sType);
    end
end

iParentIdx = stSub.iParentIdx;
if ~isempty(iParentIdx)
    hParentsNode = mxx_xmltree('add_node', hSubNode, 'Parents');
    hRefNode     = mxx_xmltree('add_node', hParentsNode, 'SubsystemRef');
    sParentId    = casSubIDs{iParentIdx};
    mxx_xmltree('set_attribute', hRefNode, 'refID', sParentId);
end
end


%%
% function respresenting a global state
function bIsSL = i_isSL(bIsSL)
persistent p_bIsSL;

if (nargin < 1)
    bIsSL = p_bIsSL;
else
    p_bIsSL = bIsSL;
end
end


%%
function i_resetInternalCounters()
i_clearInternalCounters();
atgcv_m01_counter('add', 'nInputCount');
atgcv_m01_counter('add', 'nOutputCount');
atgcv_m01_counter('add', 'nVarCount');
atgcv_m01_counter('add', 'nIfCount');
atgcv_m01_counter('add', 'nIvCount');
clear atgcv_m01_enum_type_store;
end


%%
function i_clearInternalCounters()
clear atgcv_m01_counter;
clear atgcv_m01_enum_type_store;
end


%%
function i_addSystemTimeVar(stEnv, hParentNode, stSystemTimeVar)
sVarName = stSystemTimeVar.sRootName;
if isempty(sVarName)
    return;
end

hVarNode = mxx_xmltree('add_node', hParentNode, 'SystemTimeVar');
mxx_xmltree('set_attribute', hVarNode, 'name', sVarName);

if ~isempty(stSystemTimeVar.sModuleName)
    mxx_xmltree('set_attribute', hVarNode, 'module', stSystemTimeVar.sModuleName);
end

i_addDataTypeScaleNode(stEnv, hVarNode, stSystemTimeVar.stRootType, stSystemTimeVar.astProp(1));
end


%%
function hFuncNode = i_addFunctionNode(~, hParentNode, sFuncKind, stFuncInfo)
if (isempty(stFuncInfo) || isempty(stFuncInfo.sName))
    return;
end
hFuncNode = mxx_xmltree('add_node', hParentNode, 'Function');
mxx_xmltree('set_attribute', hFuncNode, 'kind',    sFuncKind);
mxx_xmltree('set_attribute', hFuncNode, 'name',    stFuncInfo.sName);
mxx_xmltree('set_attribute', hFuncNode, 'module',  stFuncInfo.sModuleName);
mxx_xmltree('set_attribute', hFuncNode, 'storage', stFuncInfo.sStorage);
end


%%
function hSubNode = i_addSubsystemNode(~, hParentNode, stSub, sGlobalInitFunc)
hSubNode = mxx_xmltree('add_node', hParentNode, 'Subsystem');
mxx_xmltree('set_attribute', hSubNode, 'id',     stSub.sId);
mxx_xmltree('set_attribute', hSubNode, 'tlPath', stSub.sTlPath);

if (isfield(stSub, 'sSlPath') && ~isempty(stSub.sSlPath))
    mxx_xmltree('set_attribute', hSubNode, 'slPath', stSub.sSlPath);
end
mxx_xmltree('set_attribute', hSubNode, 'sampleTime', sprintf('%g', stSub.dSampleTime));

sStepFunc = stSub.sStepFunc;
mxx_xmltree('set_attribute', hSubNode, 'stepFct', sStepFunc);

if ~isempty(stSub.sModuleName)
    mxx_xmltree('set_attribute', hSubNode, 'module', stSub.sModuleName);
end

if stSub.bIsDummy
    mxx_xmltree('set_attribute', hSubNode, 'isDummy', 'yes');
end

if isfield(stSub, 'bHasMilSupport')
    bHasMilSupport = stSub.bHasMilSupport;
else
    bHasMilSupport = ~isempty(stSub.stInterface);
end
if bHasMilSupport
    mxx_xmltree('set_attribute', hSubNode, 'milSupport', 'yes');
else
    mxx_xmltree('set_attribute', hSubNode, 'milSupport', 'no');
end

if isempty(sGlobalInitFunc)
    if ~isempty(stSub.hInitFunc)
        sInitFunc = stSub.sInitFunc;
        mxx_xmltree('set_attribute', hSubNode, 'initFct', sInitFunc);
    end
    if ~isempty(stSub.hPostInitFunc)
        sPostInitFunc = stSub.sPostInitFunc;
        mxx_xmltree('set_attribute', hSubNode, 'postInitFct', sPostInitFunc);
    end
else
    % if we have a global InitFunction, -->
    %    1) use it as init function of the Subsystem
    %    2) use the original init functiono of the Subsystem as postInitFct
    mxx_xmltree('set_attribute', hSubNode, 'initFct', sGlobalInitFunc);
    if ~isempty(stSub.hInitFunc)
        sInitFunc = stSub.sInitFunc;
        mxx_xmltree('set_attribute', hSubNode, 'postInitFct', sInitFunc);
    end
    % just ignore the real postInitFunc for now; probably not relevant in
    % AUTOSAR UseCase
end

if ~isempty(stSub.sDescription)
    mxx_xmltree('set_attribute', hSubNode, 'description', stSub.sDescription);
end

mxx_xmltree('set_attribute', hSubNode, 'kind', upper(stSub.sKind));
end


%%
function i_addInterfaceNode(stEnv, hParentNode, stSubsystem, stModel)
stInterface     = stSubsystem.stInterface;
stFuncInterface = stSubsystem.stFuncInterface;

astDummyArgs = [];

% report dummy variables only for non-dummy Subsystems and only for TL
bIsTL = strcmpi(stModel.sModelMode, 'TL');
bDoReportDummy = ~stSubsystem.bIsDummy && bIsTL;

% get all relevant DSM variables
astDsmVars = [];
if bIsTL
    if i_hasNonemptyField(stSubsystem, 'astDsmRefs')
        astDsmVars = stModel.astDsmVars([stSubsystem.astDsmRefs(:).iVarIdx]);
    end
else
    if (i_hasNonemptyField(stSubsystem, 'astDsmReaderRefs') || i_hasNonemptyField(stSubsystem, 'astDsmWriterRefs'))
        astDsmVars = stModel.astDsmVars;
    end
end

% add the root node for interfaces
hInterfaceNode = mxx_xmltree('add_node', hParentNode, 'Interface');
if isempty(stInterface)
    return;
end

bUseSlTypes = (stModel.bIsSimulinkOnly || (stSubsystem.bIsDummy && stSubsystem.bHasMilSupport));

% add Input Ports
astDummyArgs = ...
    [astDummyArgs, i_addInportNodes(stEnv, hInterfaceNode, stInterface.astInports, stModel, bUseSlTypes, bDoReportDummy)];

% add DSM Input ports
if bIsTL
    i_addDsmPorts(stEnv, hInterfaceNode, 'in', stModel.sTlRoot, stModel.sSlRoot, astDsmVars);
else
    astDummyArgs = [astDummyArgs, i_addModelDsmPorts(stEnv, ...
        hInterfaceNode, 'in', stModel.sTlRoot, stModel.sSlRoot, astDsmVars, stSubsystem.astDsmReaderRefs)];
end

% add cals and explicit params
astDummyArgs = ...
    [astDummyArgs, i_addCalibrationNodes(stEnv, hInterfaceNode, stSubsystem.astCalRefs, stModel, bUseSlTypes)];

% add Output Ports
astDummyArgs = ...
    [astDummyArgs, i_addOutportNodes(stEnv, hInterfaceNode, stInterface.astOutports, stModel, bUseSlTypes, bDoReportDummy)];

% add DSM Output ports
if bIsTL
    i_addDsmPorts(stEnv, hInterfaceNode, 'out', stModel.sTlRoot, stModel.sSlRoot, astDsmVars);
else
    astDummyArgs = [astDummyArgs, i_addModelDsmPorts(stEnv, ...
        hInterfaceNode, 'out', stModel.sTlRoot, stModel.sSlRoot, astDsmVars, stSubsystem.astDsmWriterRefs)];
end

% add Display outputs
astDummyArgs = ...
    [astDummyArgs, i_addDisplayNodes(stEnv, hInterfaceNode, stSubsystem.astDispRefs, stModel, bUseSlTypes)];

% add arguments (function parameters)
i_addFunctionInterface(stEnv, hInterfaceNode, stFuncInterface);

% add dummy vars
nDummyArgs = length(astDummyArgs);
for i = 1:nDummyArgs
    stArg = astDummyArgs(i);
    stArg.nLocation = 0;
    i_addArgumentNode(stEnv, hInterfaceNode, stArg);
end
end


%%
function bHasField = i_hasNonemptyField(stStruct, sField)
bHasField = isfield(stStruct, sField) && ~isempty(stStruct.(sField));
end


%%
function i_addFunctionInterface(stEnv, hInterfaceNode, stFuncInterface)
if ~isempty(stFuncInterface)
    nArgs = length(stFuncInterface.astArgs);
    if (nArgs > 0)
        % ReturnValue is (for now) not inserted into list of arguments
        if strcmpi(stFuncInterface.astFormalArgs(nArgs).sKind, 'RETURN_VALUE')
            nArgs = nArgs - 1;
        end
    end
    for i = 1:nArgs
        stArg = stFuncInterface.astArgs(i);
        stArg.nLocation = i;
        i_addArgumentNode(stEnv, hInterfaceNode, stArg);
    end
end
end


%%
function astDummyArgs = i_addCalibrationNodes(stEnv, hInterfaceNode, astCalRefs, stModel, bUseSlTypes)
astDummyArgs = [];

nCalVars = length(astCalRefs);
for i = 1:nCalVars
    iVarIdx = astCalRefs(i).iVarIdx;
    stVar   = stModel.astCalVars(iVarIdx);

    aiBlockIdx = astCalRefs(i).aiBlockIdx;
    nModelRefs = length(aiBlockIdx);

    % add input node
    hInputNode = i_addInOutNode(stEnv, hInterfaceNode, 'in');

    % use the first reference for general info
    stVar.stBlockInfo = stVar.astBlockInfo(aiBlockIdx(1));

    % per default: no restrictions on CALs
    if strcmpi(stVar.stCal.sKind, 'limited')
        hCalNode = i_addCalVarNode(stEnv, hInputNode, stVar, stModel.sTlRoot, stModel.sSlRoot);
        bIsExplicitUsage = false;

    else  % ASSUMPTION: sKind == 'explicit'
        hCalNode = i_addParamVarNode(hInputNode, stVar, stModel.sTlRoot, stModel.sSlRoot);
        bIsExplicitUsage = true;
    end

    xKnownLocations = containers.Map;
    iFirstIdx = 1;
    for j = 1:nModelRefs
        stBlockInfo = stVar.astBlockInfo(aiBlockIdx(j));
        if strcmpi(stBlockInfo.sBlockKind, 'Stateflow')
            if ~isempty(stBlockInfo.stSfInfo)
                iFirstIdx = stBlockInfo.stSfInfo.iSfFirstIndex;
            else
                iFirstIdx = 1;
            end
        end
        sLocationKey = [stBlockInfo.sTlPath, ':', stBlockInfo.sBlockUsage];
        if xKnownLocations.isKey(sLocationKey)
            continue;
        end
        xKnownLocations(sLocationKey) = true;

        i_addModelContextNode(stEnv, hCalNode, stBlockInfo, bIsExplicitUsage, ...
            stModel.sTlRoot, stModel.sSlRoot, stBlockInfo.sRestriction);
    end
    stVarInfo = stVar.stInfo;
    if ~isempty(stVarInfo)
        if (iFirstIdx ~= 1)
            mxx_xmltree('set_attribute', hCalNode, 'startIdx', num2str(iFirstIdx));
            stVarInfo.iFirstIdx = iFirstIdx;
        end
        hVarNode = i_addVariableNode(stEnv, hCalNode, stVarInfo);

        sType = stVar.stCal.sType;
        if strcmpi(sType, 'double')
            sType = '';
        end
        sMin = stVar.stCal.sMin;
        sMax = stVar.stCal.sMax;
        if any(~cellfun('isempty', {sType, sMin, sMax}))
            ahIfs = mxx_xmltree('get_nodes', hVarNode, './ma:ifName');
            for k = 1:length(ahIfs)
                hIf = ahIfs(k);
                if ~isempty(sType)
                    mxx_xmltree('set_attribute', hIf, 'signalType', sType);
                end
                if ~isempty(sMin)
                    mxx_xmltree('set_attribute', hIf, 'min', sMin);
                end
                if ~isempty(sMax)
                    mxx_xmltree('set_attribute', hIf, 'max', sMax);
                end
            end
        end
    else
        stDummyArg = i_addDummyVariableForParams(stEnv, hCalNode, stVar.stCal, bUseSlTypes);
        if isempty(astDummyArgs)
            astDummyArgs = stDummyArg;
        else
            astDummyArgs(end + 1) = stDummyArg; %#ok<AGROW>
        end
    end

    % Add model reference information
    if (i_hasNonemptyField(stVar.stBlockInfo, 'sModelPath') ...
            && ~strcmp(stVar.stBlockInfo.sTlPath, stVar.stBlockInfo.sModelPath))
        if stModel.bIsSimulinkOnly
            i_addModelReferenceNode(stEnv, hCalNode, stVar.stBlockInfo.sModelPath, 'SL');
        else
            i_addModelReferenceNode(stEnv, hCalNode, stVar.stBlockInfo.sModelPath, 'TL');
        end
    end
end
end


%%
% add different C-vars to same Display node if they have a common TL-block
function astDummyArgs = i_addDisplayNodes(stEnv, hInterfaceNode, astDispRefs, stModel, bUseSlTypes)
astDummyArgs = [];

nDispVars = length(astDispRefs);
casDispPaths = cell(1, nDispVars);
casDispNodes = cell(1, nDispVars);
for i = 1:nDispVars
    iVarIdx = astDispRefs(i).iVarIdx;
    stVar   = stModel.astDispVars(iVarIdx);

    % for now use the first reference! assuming _no_ multiple refs in model
    stVar.stBlockInfo = stVar.astBlockInfo(1);
    bIsStateflowVar = strcmpi(stVar.stBlockInfo.sBlockKind, 'Stateflow');
    iFirstIdx = 1;
    if bIsStateflowVar
        iFirstIdx = stVar.stBlockInfo.stSfInfo.iSfFirstIndex;
        sPortNumb = i_getDispPortNumber(stEnv, stVar);
        sDispPath = [stVar.stBlockInfo.stSfInfo.sSfName, ':SF:', stVar.stBlockInfo.sTlPath];
    else
        sPortNumb  = i_getDispPortNumber(stEnv, stVar);
        sDispPath  = [sPortNumb, stVar.stBlockInfo.sTlPath];
    end

    iFoundDisp = find(strcmp(sDispPath, casDispPaths));
    bAddModelRef = false;
    if (isempty(iFoundDisp) || (iFoundDisp < 0))
        hOutputNode = i_addInOutNode(stEnv, hInterfaceNode, 'out');
        hDispNode   = i_addDispVarNode(stEnv, hOutputNode, stVar, stModel.sTlRoot, stModel.sSlRoot, sPortNumb);
        i_addCompositeSigAttribute(hDispNode, stVar.sSigKind);
        i_addExtraBusInfo(hDispNode, stVar.sBusType, stVar.sBusObj);
        bAddModelRef = true;

        if isempty(iFoundDisp)
            casDispPaths{i} = sDispPath;
            casDispNodes{i} = hDispNode;
        end
    else
        hDispNode = casDispNodes{iFoundDisp};
    end

    stVarInfo = stVar.stInfo;
    if ~isempty(stVarInfo)
        if (iFirstIdx ~= 1)
            mxx_xmltree('set_attribute', hDispNode, 'startIdx', num2str(iFirstIdx));
            stVarInfo.iFirstIdx = iFirstIdx;
        end
        i_addVariableNode(stEnv, hDispNode, stVarInfo, stVar.astSomeSubSigs);
    else
        if (iFirstIdx ~= 1)
            mxx_xmltree('set_attribute', hDispNode, 'startIdx', num2str(iFirstIdx));
            stVarInfo.iFirstIdx = iFirstIdx;
        end
        for j = 1:length(stVar.astSignals)
            stSignal = stVar.astSignals(j);
            stDummyArg = i_addDummyVariableNode(stEnv, ...
                hDispNode, stSignal, stSignal.astSubSigs, bUseSlTypes, iFirstIdx);
            if isempty(astDummyArgs)
                astDummyArgs = stDummyArg;
            else
                astDummyArgs(end + 1) = stDummyArg; %#ok<AGROW>
            end
        end
    end

    % Add model reference information
    if (isfield(stVar.stBlockInfo, 'sModelPath') ...
            && ~isempty(stVar.stBlockInfo.sModelPath) ...
            && ~strcmp(stVar.stBlockInfo.sTlPath, stVar.stBlockInfo.sModelPath) ...
            && bAddModelRef)
        if stModel.bIsSimulinkOnly
            i_addModelReferenceNode(stEnv, hDispNode, stVar.stBlockInfo.sModelPath, 'SL');
        else
            i_addModelReferenceNode(stEnv, hDispNode, stVar.stBlockInfo.sModelPath, 'TL');
        end
    end
end
end


%%
function astDummyArgs = i_addInportNodes(stEnv, hInterfaceNode, astInports, stModel, bUseSlTypes, bDoReportDummy)
astDummyArgs = [];

sReportDummyID = '';
if bDoReportDummy
    sReportDummyID = 'ATGCV:MOD_ANA:DUMMY_INPORT_VAR';
end
for i = 1:length(astInports)
    stInport = astInports(i);

    hInputNode = i_addInOutNode(stEnv, hInterfaceNode, 'in');
    astDummyArgs = [astDummyArgs, ...
        i_addGenericPortNode(stEnv, hInputNode, stInport, stModel, bUseSlTypes, sReportDummyID)]; %#ok<AGROW>
end
end


%%
function astDummyArgs = i_addOutportNodes(stEnv, hInterfaceNode, astOutports, stModel, bUseSlTypes, bDoReportDummy)
astDummyArgs = [];

sReportDummyID = '';
if bDoReportDummy
    sReportDummyID = 'ATGCV:MOD_ANA:DUMMY_OUTPORT_VAR';
end
for i = 1:length(astOutports)
    stOutport = astOutports(i);

    hOutputNode = i_addInOutNode(stEnv, hInterfaceNode, 'out');
    astDummyArgs = [astDummyArgs, ...
        i_addGenericPortNode(stEnv, hOutputNode, stOutport, stModel, bUseSlTypes, sReportDummyID)]; %#ok<AGROW>
end
end


%%
function astDummyArgs = i_addGenericPortNode(stEnv, hInterfaceKindNode, stPort, stModel, bUseSlTypes, sReportDummyID)
astDummyArgs = [];

hPortNode = i_addPortNode(stEnv, hInterfaceKindNode, stPort, stModel.sTlRoot, stModel.sSlRoot);

nVars = length(stPort.astSignals);
for j = 1:nVars
    stSignal = stPort.astSignals(j);

    if isempty(stSignal.stVarInfo)
        stDummyArg = i_addDummyVariableNode(stEnv, hPortNode, stSignal, stSignal.astSubSigs, bUseSlTypes, 1);
        if isempty(astDummyArgs)
            astDummyArgs = stDummyArg;
        else
            astDummyArgs(end + 1) = stDummyArg; %#ok<AGROW>
        end
        if ~isempty(sReportDummyID)
            i_reportPortDummyVar(stEnv, stPort, stSignal, sReportDummyID);
        end
    else
        i_addVariableNode(stEnv, hPortNode, stSignal.stVarInfo, ...
            stSignal.astSubSigs, stSignal.aiElements, stSignal.aiElements2);
    end
end
i_modifyMuxPort(stEnv, hPortNode, stPort);


% Add model reference information
if stModel.bIsSimulinkOnly
    if (i_hasNonemptyField(stPort, 'sModelPortPath') && ~strcmp(stPort.sModelPortPath, stPort.sSlPortPath))
        i_addModelReferenceNode(stEnv, hPortNode, stPort.sModelPortPath, 'SL');
    elseif (i_hasNonemptyField(stPort, 'sPath') && ~strcmp(stPort.sPath, stPort.sSlPortPath))
        i_addModelReferenceNode(stEnv, hPortNode, stPort.sPath, 'SL');
    end
else
    if (i_hasNonemptyField(stPort, 'sModelPortPath') && ~strcmp(stPort.sModelPortPath, stPort.sSlPortPath))
        i_addModelReferenceNode(stEnv, hPortNode, stPort.sModelPortPath, 'TL');
    end
end
end


%%
function i_reportPortDummyVar(stEnv, stPort, stSignal, sErrorID)
try
    sName = get_param(stPort.sSlPortPath, 'name');
catch %#ok<CTCH>
    [~, sName] = fileparts(stPort.sSlPortPath);
end
sObjectPart = sprintf('#%i', stPort.iPortNumber);

if strcmpi(stPort.stCompInfo.sSigKind, 'bus')
    bIsBus = true;
else
    bIsBus = false;
end

astSubSigs = stSignal.astSubSigs;
nSub = numel(astSubSigs);
for i = 1:nSub
    if (~bIsBus || isempty(astSubSigs(i).sName))
        sSigPart = '';
    else
        sSigName = astSubSigs(i).sName;
        if (sSigName(1) == '.')
            sSigName = ['signal1', sSigName]; %#ok<AGROW>
        end
        sSigPart = ['{', sSigName, '}'];
    end
    if bIsBus
        if isempty(astSubSigs(i).iSubSigIdx)
            sIndexPart = '';
        else
            sIndexPart = sprintf('(%i)', astSubSigs(i).iSubSigIdx);
        end
    else
        if isempty(astSubSigs(i).iIdx)
            sIndexPart = '';
        else
            sIndexPart = sprintf('(%i)', astSubSigs(i).iIdx);
        end
    end

    sSigId = [sName, '[', sObjectPart, sSigPart, sIndexPart, ']'];
    osc_messenger_add(stEnv, sErrorID, 'port', stPort.sSlPortPath, 'signal_id',  sSigId);
end
end


%%
function i_addDsmPorts(stEnv, hInterfaceNode, sInOutMode, sTlRoot, sSlRoot, astDsmVars)
if isempty(astDsmVars)
    return;
end

casDsmKeys = {};
casDsmPortNodes = {};
bIsInput = strcmpi(sInOutMode, 'in');
for i = 1:length(astDsmVars)
    stVar = astDsmVars(i);

    % for inputs accept only "read" DSMs, for outputs only "write"
    sKind = stVar.stDsm.sKind;
    if bIsInput
        if ~strcmpi(sKind, 'read')
            continue;
        end
    else
        if ~strcmpi(sKind, 'write')
            continue;
        end
    end


    % !ASSUMPTION: for DSM assume that only the first block is relevant
    sBlockPath = stVar.astBlockInfo(1).sTlPath;
    sSignal    = stVar.stDsm.sWorkspaceVar;
    
    % for TL AUTOSAR we have blocks with access to different DS signals --> use block path && signal name as key
    sDsmKey = sprintf('%s - %s', sBlockPath, sSignal);
    iFoundDsm = find(strcmp(sDsmKey, casDsmKeys));
    if (isempty(iFoundDsm) || (iFoundDsm < 0))
        % add input or output node depending on sInOutMode
        hInOutNode = i_addInOutNode(stEnv, hInterfaceNode, sInOutMode);
        hPortNode  = i_addDsmPortNode(stEnv, hInOutNode, sSignal, sBlockPath, sTlRoot, sSlRoot);
        i_addCompositeSigAttribute(hPortNode, stVar.sSigKind);
        i_addExtraBusInfo(hPortNode, stVar.sBusType, stVar.sBusObj);

        if isempty(iFoundDsm)
            casDsmKeys{i} = sDsmKey; %#ok<AGROW>
            casDsmPortNodes{i} = hPortNode; %#ok<AGROW>
        end
    else
        hPortNode = casDsmPortNodes{iFoundDsm};
    end
    
    i_addVariableNode(stEnv, hPortNode, stVar.stInfo, stVar.astSomeSubSigs);
    
    if (i_hasNonemptyField(stVar.astBlockInfo(1), 'sModelPath') && ...
            ~strcmp(stVar.astBlockInfo(1).sModelPath, stVar.astBlockInfo(1).sTlPath))
        i_addModelReferenceNode(stEnv, hPortNode, stVar.astBlockInfo(1).sModelPath, 'TL');
    end
end
end


%%
function astDummyArgs = i_addModelDsmPorts(stEnv, hInterfaceNode, sInOutMode, sTlRoot, sSlRoot, astDsmVars, astVarRefs)
astDummyArgs = [];
if isempty(astDsmVars)
    return;
end

for i = 1:length(astVarRefs)
    stVarRef = astVarRefs(i);

    stVar = astDsmVars(stVarRef.iVarIdx);

    % add input or output node depending on sInOutMode
    hInOutNode = i_addInOutNode(stEnv, hInterfaceNode, sInOutMode);

    % !ASSUMPTION: for DSM we currently assume that only the first block is relevant
    stBlock = stVar.astBlockInfo(stVarRef.aiBlockIdx(1));

    sBlockPath  = stBlock.sTlPath;
    sSignalName = stVar.stModelDsm.sName;
    sMemBlock   = stVar.stModelDsm.sPath;
    hPortNode   = i_addModelDsmPortNode(stEnv, hInOutNode, sSignalName, sMemBlock, sBlockPath, sTlRoot, sSlRoot);

    stSignal = stVar.stModelDsm.astSignals;
    stDummyArg = i_addDummyVariableNode(stEnv, hPortNode, stSignal, stSignal.astSubSigs, true, 1);
    if isempty(astDummyArgs)
        astDummyArgs = stDummyArg;
    else
        astDummyArgs(end + 1) = stDummyArg; %#ok<AGROW>
    end

    if (i_hasNonemptyField(stBlock, 'sModelPath') && ~strcmp(stBlock.sModelPath, stBlock.sTlPath))
        i_addModelReferenceNode(stEnv, hPortNode, stBlock.sModelPath, 'SL');
    end
end
end


%%
function i_addSignatureNode(stEnv, hParentNode, stFuncInterface)
hSignatureNode = mxx_xmltree('add_node', hParentNode, 'Signature');

% add arguments (function parameters)
hArgs = mxx_xmltree('add_node', hSignatureNode, 'Args');
if ~isempty(stFuncInterface)
    nArgs = length(stFuncInterface.astFormalArgs);
    for i = 1:nArgs
        stFormalArg = stFuncInterface.astFormalArgs(i);
        stActualArg = stFuncInterface.astArgs(i);
        i_addSignatureArgNode(stEnv, hArgs, stFormalArg, stActualArg);
    end
end

% add interface vars (currently not used)
mxx_xmltree('add_node', hSignatureNode, 'InterfaceVars');
end


%%
function i_addModelReferenceNode(~, hParentNode, sModelPath, sKind)

% find separator / but ignore multiple separators //
iFind = regexp(sModelPath, '[^/]/[^/]', 'once');
if isempty(iFind)
    sModelName = sModelPath;
else
    sModelName = sModelPath(1:iFind);
end
[~, ~, sExt] = fileparts(get_param(sModelName, 'FileName'));
sModelFile = [sModelName, sExt];
hModelRefNode = mxx_xmltree('add_node', hParentNode, 'ModelReference');
mxx_xmltree('set_attribute', hModelRefNode, 'path',  sModelPath);
mxx_xmltree('set_attribute', hModelRefNode, 'model', sModelFile);
mxx_xmltree('set_attribute', hModelRefNode, 'kind',  sKind);
end



%%
function hVarNode = i_addVariableNode(stEnv, hParentNode, stVarInfo, astSubSigs, aiElements, aiElements2)
if (nargin < 4)
    astSubSigs = [];
end
if (nargin < 5)
    aiElements = [];
end
if (nargin < 6)
    aiElements2 = [];
end

sModuleName = '';
if isfield(stVarInfo, 'stInterface')
    if strcmpi(stVarInfo.stInterface.sKind, 'RETURN_VALUE')
        sScopeFlag  = '-1';
        sGlobalName = '';
    else
        sScopeFlag = '0';
        sGlobalName = stVarInfo.stInterface.sName;
    end
else
    sScopeFlag = '0';
    sGlobalName = stVarInfo.sRootName;

    % set module name only for CAL and DISP variables
    if isfield(stVarInfo, 'sModuleName')
        sModuleName = stVarInfo.sModuleName;
    end
end
aiWidth = stVarInfo.aiWidth;
if ~isempty(stVarInfo.stRootType.sStructTag)
    sTypeName = stVarInfo.stRootType.sStructTag;
elseif ~isempty(stVarInfo.stRootType.sUserDest)
    sTypeName = stVarInfo.stRootType.sUserDest;
else
    if stVarInfo.stRootType.bHasTypedef
        sTypeName = stVarInfo.stRootType.sUser;
    else
        sTypeName = stVarInfo.stRootType.sBase;
    end
end

bIsMacro = false;
if (~isempty(stVarInfo.stRootClass) && stVarInfo.stRootClass.bIsMacro)
    bIsMacro = true;
end

% make copy of variable for every different signal_name
if (~isempty(astSubSigs) && (length(astSubSigs) > 1))
    caaiIdx = {1};
    sSigName = astSubSigs(1).sName;
    for i = 2:length(astSubSigs)
        if strcmp(astSubSigs(i).sName, sSigName)
            caaiIdx{end} = [caaiIdx{end}, i];
        else
            caaiIdx{end + 1} = i; %#ok<AGROW>
        end
    end
    nCopies = length(caaiIdx);
    if (nCopies > 1)
        if isempty(aiElements)
            aiElements = 0:(length(astSubSigs) - 1);
        end
    else
        caaiIdx = {};
        nCopies = 1;
    end
else
    caaiIdx = {};
    nCopies = 1;
end

for i = 1:nCopies
    hVarNode = mxx_xmltree('add_node', hParentNode, 'Variable');

    sId = sprintf('var%i', atgcv_m01_counter('get', 'nVarCount'));
    mxx_xmltree('set_attribute', hVarNode, 'varid', sId);
    mxx_xmltree('set_attribute', hVarNode, 'paramNr', sScopeFlag);
    mxx_xmltree('set_attribute', hVarNode, 'usage', 'VAL');
    if ~isempty(sGlobalName)
        mxx_xmltree('set_attribute', hVarNode, 'globalName', sGlobalName);
    end
    if ~isempty(sModuleName)
        mxx_xmltree('set_attribute', hVarNode, 'module', sModuleName);
    end
    if bIsMacro
        mxx_xmltree('set_attribute', hVarNode, 'isMacro', 'yes');
    end
    mxx_xmltree('set_attribute', hVarNode, 'typeName', sTypeName);

    if ~isempty(aiWidth)
        mxx_xmltree('set_attribute', hVarNode, 'width1', sprintf('%i', aiWidth(1)));
        if (length(aiWidth) > 1)
            mxx_xmltree('set_attribute', hVarNode, 'width2', sprintf('%i', aiWidth(2)));
        end
    end

    if ~isempty(caaiIdx)
        astSubSigsCopy  = astSubSigs(caaiIdx{i});
        aiElementsCopy  = aiElements(caaiIdx{i});
        aiElementsCopy2 = aiElements2; % Note: this is _wrong_ but no better alternative!!!
    else
        astSubSigsCopy  = astSubSigs;
        aiElementsCopy  = aiElements;
        aiElementsCopy2 = aiElements2;
    end
    i_addIfNodes(stEnv, hVarNode, stVarInfo, astSubSigsCopy, aiElementsCopy, aiElementsCopy2);
end
end


%%
function stArg = i_addDummyVariableNode(stEnv, hParentNode, stSignal, astSubSigs, bUseSlTypes, iFirstIdx)
if (nargin < 6)
    iFirstIdx = 1;
end
sId        = sprintf('var%i', atgcv_m01_counter('get', 'nVarCount'));
sName      = sprintf('__osc_dummy_%s', sId);
sScopeFlag = '0';

if bUseSlTypes
    sFoundType = 'double';
    if isfield(stSignal, 'sType')
        sFoundType = stSignal.sType;
    else
        if (~isempty(astSubSigs) && isfield(astSubSigs(1), 'sType'))
            sFoundType = astSubSigs(1).sType;
        end
    end
    stDummy = i_getDummyInfo(sFoundType);
else
    stDummy = i_getDummyInfo();
end

iWidth = [];
if (length(astSubSigs) > 1)
    iWidth = length(astSubSigs);
end

%sDummyType = 'int';
sDummyType = stDummy.sTypeName;
if ~isempty(iWidth)
    sDeclaration = sprintf('%s %s[%i];', sDummyType, sName, iWidth);
else
    sDeclaration = sprintf('%s %s;', sDummyType, sName);
end
stArg = struct( ...
    'sExpression', '', ...
    'sDeclaration', sDeclaration);


% make copy of variable for every different signal_name
caaiIdx = {1};
casId   = {sId};
if isempty(iWidth)
    casAccess = {''};
else
    casAccess = {'[0]'};
end
sSigName = astSubSigs(1).sName;
for i = 2:length(astSubSigs)
    if strcmp(astSubSigs(i).sName, sSigName)
        caaiIdx{end} = [caaiIdx{end}, i];
    else
        caaiIdx{end + 1} = i; %#ok<AGROW>
        casId{end + 1}   = sprintf('var%i', atgcv_m01_counter('get', 'nVarCount')); %#ok<AGROW>
    end
    if isempty(iWidth)
        casAccess{end + 1} = ''; %#ok<AGROW>
    else
        casAccess{end + 1} = sprintf('[%i]', i-1); %#ok<AGROW>
    end
end
nCopies = length(caaiIdx);

for i = 1:nCopies
    hVarNode = mxx_xmltree('add_node', hParentNode, 'Variable');
    mxx_xmltree('set_attribute', hVarNode, 'varid',      casId{i});
    mxx_xmltree('set_attribute', hVarNode, 'paramNr',    sScopeFlag);
    mxx_xmltree('set_attribute', hVarNode, 'usage',      'VAL');
    mxx_xmltree('set_attribute', hVarNode, 'globalName', sName);
    mxx_xmltree('set_attribute', hVarNode, 'typeName',   stDummy.sTypeName);
    if ~isempty(iWidth)
        mxx_xmltree('set_attribute', hVarNode, 'width1', sprintf('%i', iWidth));
    end
    mxx_xmltree('set_attribute', hVarNode, 'isDummy', 'yes');

    i_addDummyIfNodes(stEnv, hVarNode, stDummy, astSubSigs(caaiIdx{i}), casAccess(caaiIdx{i}), iFirstIdx);
end
end


%%
function stArg = i_addDummyVariableForParams(stEnv, hParentNode, stCal, bUseSlTypes)
sId   = sprintf('var%i', atgcv_m01_counter('get', 'nVarCount'));
sName = sprintf('__osc_dummy_%s', sId);

if bUseSlTypes
    stDummy = i_getDummyInfo(stCal.sType);
else
    stDummy = i_getDummyInfo();
end
aiWidth = stCal.aiWidth(stCal.aiWidth > 1);
if (length(aiWidth) < 1)
    iWidth  = [];
    iWidth1 = [];
    iWidth2 = [];
else
    iWidth = prod(aiWidth);
    if (length(aiWidth) < 2)
        iWidth1 = aiWidth(1);
        iWidth2 = [];
    else
        iWidth1 = aiWidth(1);
        iWidth2 =  aiWidth(2);
    end
end

sDummyType = stDummy.sTypeName;
if isempty(iWidth)
    sDeclaration = sprintf('%s %s;', sDummyType, sName);
else
    if ~isempty(iWidth2)
        sDeclaration = sprintf('%s %s[%i][%i];', sDummyType, sName, iWidth1, iWidth2);
    else
        sDeclaration = sprintf('%s %s[%i];', sDummyType, sName, iWidth);
    end
end
stArg = struct( ...
    'sExpression', '', ...
    'sDeclaration', sDeclaration);

hVarNode = mxx_xmltree('add_node', hParentNode, 'Variable');
mxx_xmltree('set_attribute', hVarNode, 'varid',      sId);
mxx_xmltree('set_attribute', hVarNode, 'paramNr',    '0');
mxx_xmltree('set_attribute', hVarNode, 'usage',      'VAL');
mxx_xmltree('set_attribute', hVarNode, 'globalName', sName);
mxx_xmltree('set_attribute', hVarNode, 'typeName',   stDummy.sTypeName);
if ~isempty(iWidth1)
    mxx_xmltree('set_attribute', hVarNode, 'width1', sprintf('%i', iWidth1));
    if ~isempty(iWidth2)
        mxx_xmltree('set_attribute', hVarNode, 'width2', sprintf('%i', iWidth2));
    end
end
mxx_xmltree('set_attribute', hVarNode, 'isDummy', 'yes');

i_addDummyIfNodesForParams(stEnv, hVarNode, stDummy, stCal);
end


%%
function sArray = i_getIntArrayAsString(aiArray)
if isempty(aiArray)
    sArray = '[]';
else
    % Note: "strjoin" for lower ML-versions, e.g. ML2010b
    % print all integers with a following space and then remove the last space
    sInnerString = sprintf('%d ', aiArray(:));
    sArray = ['[', sInnerString(1:end-1), ']'];
end
end


%%
function i_addDummyIfNodes(~, hParentNode, stDummy, astSubSigs, casAccess, iFirstIdx)
nSigs = length(astSubSigs);
for i = 1:nSigs
    stSig = astSubSigs(i);

    % ifName node
    nCount  = atgcv_m01_counter('get', 'nIfCount');
    sId     = sprintf('if%i', nCount);
    hIfNode = mxx_xmltree('add_node', hParentNode, 'ifName');
    mxx_xmltree('set_attribute', hIfNode, 'ifid', sId);

    if ~isempty(stSig.sName)
        if (stSig.sName(1) == '.')
            stSig.sName = ['<signal1>', stSig.sName];
        end
        mxx_xmltree('set_attribute', hIfNode, 'signalName', stSig.sName);
    end
    if ~isempty(stSig.aiDim)
        sSignalDim = i_getIntArrayAsString(stSig.aiDim);
        mxx_xmltree('set_attribute', hIfNode, 'signalDim', sSignalDim);
    end
    if ~isempty(stSig.sType)
        % Note: not clear if "signalType" should only be set for TL-ModelMode
        % TODO: check side-effects for setting only "slSignalType" for SL-ModelMode
        mxx_xmltree('set_attribute', hIfNode, 'signalType', stSig.sType);
        if i_isSL()
            mxx_xmltree('set_attribute', hIfNode, 'slSignalType', stSig.sType);
        end
    end

    [sMin, sMax] = i_getSignalMinMax(stSig);
    if ~isempty(sMin)
        if i_isSL()
            mxx_xmltree('set_attribute', hIfNode, 'slMin', sMin);
        else
            mxx_xmltree('set_attribute', hIfNode, 'min', sMin);
        end
        dLower = str2double(sMin);
    else
        dLower = stDummy.dLower;
    end
    if ~isempty(sMax)
        if i_isSL()
            mxx_xmltree('set_attribute', hIfNode, 'slMax', sMax);
        else
            mxx_xmltree('set_attribute', hIfNode, 'max', sMax);
        end
        dUpper = str2double(sMax);
    else
        dUpper = stDummy.dUpper;
    end

    if ~isempty(stSig.iSubSigIdx)
        aiIdx = i_linToMatrixSignalIdx(stSig.aiDim, stSig.iSubSigIdx);
        if (iFirstIdx ~= 1)
            aiIdx = aiIdx + iFirstIdx - 1;
        end
        for k = 1:length(aiIdx)
            mxx_xmltree('set_attribute', hIfNode, sprintf('index%d', k), sprintf('%d', aiIdx(k)));
        end
    end

    if ~isempty(casAccess{i})
        mxx_xmltree('set_attribute', hIfNode, 'accessPath', casAccess{i});
    end

    % DataType node
    hTypeNode = mxx_xmltree('add_node', hIfNode, 'DataType');
    mxx_xmltree('set_attribute', hTypeNode, 'tlTypeName', stDummy.sTypeName);
    i_setAttribDouble(hTypeNode, 'tlTypeMin', stDummy.dMin);
    i_setAttribDouble(hTypeNode, 'tlTypeMax', stDummy.dMax);
    if stDummy.bIsFloat
        mxx_xmltree('set_attribute', hTypeNode, 'isFloat', 'yes');
    end

    % Scaling node
    hScaleNode = mxx_xmltree('add_node', hTypeNode, 'Scaling');
    i_setAttribDouble(hScaleNode, 'lsb',    stDummy.dLsb);
    i_setAttribDouble(hScaleNode, 'offset', stDummy.dOffset);
    i_setAttribDouble(hScaleNode, 'lower',  dLower);
    i_setAttribDouble(hScaleNode, 'upper',  dUpper);
end
end


%%
function [sMin, sMax] = i_getSignalMinMax(stSignal)
% use the highest possible min
sMin = i_getDesignMin(stSignal);
if (isfield(stSignal, 'sMin') && ~isempty(stSignal.sMin))
    if (isempty(sMin) || (str2double(stSignal.sMin) > str2double(sMin)))
        sMin = stSignal.sMin;
    end
end

% use the lowest possible max
sMax = i_getDesignMax(stSignal);
if (isfield(stSignal, 'sMax') && ~isempty(stSignal.sMax))
    if (isempty(sMax) || (str2double(stSignal.sMax) < str2double(sMax)))
        sMax = stSignal.sMax;
    end
end
end


%%
function sMin = i_getDesignMin(stSignal)
sMin = i_getDesignData(stSignal, 'xDesignMin');
end


%%
function sMax = i_getDesignMax(stSignal)
sMax = i_getDesignData(stSignal, 'xDesignMax');
end


%%
function sValue = i_getDesignData(stSignal, sDesignDataField)
sValue = '';
if ~isfield(stSignal, sDesignDataField)
    return;
end
try
    xDesignData = stSignal.(sDesignDataField);
    if iscell(xDesignData)
        iIdx = stSignal.iSubSigIdx;
        if ~isempty(iIdx) && (iIdx <= length(xDesignData))
            xDesignData = xDesignData{iIdx};
        end
    end
    if isnumeric(xDesignData)
        sValue = sprintf('%.16e', xDesignData);
    else
        warning('EP:MODEL_ANALYSIS:INTERNAL', 'Unexpected kind of Design Data found.');
    end
catch oEx
    warning('EP:MODEL_ANALYSIS:INTERNAL', 'Retrieving Design Data failed.\n%s', oEx.message);
end
end


%%
% aiDim is analog to the block Property "CompiledPortDimensions":
%    first element provides number of dimensions, the rest provides the widths
%
function aiMatIdx = i_linToMatrixSignalIdx(aiDim, iIdx)
if (isempty(aiDim) || (length(aiDim) < 3))
    % not a multi-dim signal
    aiMatIdx = iIdx;
    return;
end

nDim = aiDim(1);

% special case: check for row-vector or col-vector --> not counted as Matrix
if (nDim == 2)
    if any(aiDim(2:end) == 1)
        aiMatIdx = iIdx;
        return;
    end
end

% general case
caiMatIdx = cell(nDim, 1);
[caiMatIdx{:}] = ind2sub(aiDim(2:end), iIdx);
aiMatIdx = cell2mat(caiMatIdx);
end


%%
function i_setAttribDouble(hNode, sAttName, dValue)
mxx_xmltree('set_attribute', hNode, sAttName, sprintf('%.16e', dValue));
end


%%
function i_setAttribNonempty(hNode, sAttName, sValue)
if ~isempty(sValue)
    mxx_xmltree('set_attribute', hNode, sAttName, sValue);
end
end


%%
function stDummy = i_getDummyInfo(sFoundType)
if (nargin < 1)
    dMax = 3.402823466E+38;
    dMin = -dMax;
    stDummy = struct( ...
        'sTypeName', 'float', ...
        'dMin',      dMin, ...
        'dMax',      dMax, ...
        'dLower',    dMin, ...
        'dUpper',    dMax, ...
        'dLsb',      1.0, ...
        'dOffset',   0.0, ...
        'bIsFloat',  true);
else
    stTypeInfo = i_typeInfo('get', sFoundType);
    if stTypeInfo.bIsValidType
        stDummy = struct( ...
            'sTypeName', stTypeInfo.sBaseType, ...
            'dMin',      stTypeInfo.oBaseTypeMin.doubleValue(), ...
            'dMax',      stTypeInfo.oBaseTypeMax.doubleValue(), ...
            'dLower',    stTypeInfo.oRepresentMin.doubleValue(), ...
            'dUpper',    stTypeInfo.oRepresentMax.doubleValue(), ...
            'dLsb',      stTypeInfo.dLsb, ...
            'dOffset',   stTypeInfo.dOffset, ...
            'bIsFloat',  stTypeInfo.bIsFloat);
    else
        stDummy = i_getDummyInfo();
    end
end
end


%%
function aiLinElements = i_getLinearElementsIdx(aiWidth, aiElements, aiElements2)
if isempty(aiElements)
    aiLinElements = [];
    return;
end

if any(aiElements < 0)
    aiElements = 0:(aiWidth(1) - 1);
end

if isempty(aiElements2)
    aiLinElements = aiElements;
    return;
end

if any(aiElements2 < 0)
    aiElements2 = 0:(aiWidth(2) - 1);
end

iLen1 = length(aiElements);
iLen2 = length(aiElements2);

% create subindex of matrix (account for offset 1 by adding one)
aiSubIdx  = reshape(repmat(aiElements + 1, 1, iLen2), 1, []);
aiSubIdx2 = reshape(repmat(aiElements2 + 1, iLen1, 1), 1, []);

% create linear index (accound for offset 0 by subtracting one)
aiLinElements = sub2ind(aiWidth, aiSubIdx, aiSubIdx2) - 1;
end


%%
function i_addIfNodes(stEnv, hParentNode, stVarInfo, astSubSigs, aiElements, aiElements2)
if (isfield(stVarInfo, 'iFirstIdx') && ~isempty(stVarInfo.iFirstIdx) && (stVarInfo.iFirstIdx ~= 1))
    iFirstIdx = stVarInfo.iFirstIdx;
else
    iFirstIdx = [];
end

if ~isempty(stVarInfo.sAccessPath)
    sVarAccessPath = stVarInfo.sAccessPath;
else
    sVarAccessPath = '';
end

aiLinElements = i_getLinearElementsIdx(stVarInfo.aiWidth, aiElements, aiElements2);
astIf = stVarInfo.astProp;
if ~isempty(aiLinElements)
    astIf = astIf(aiLinElements + 1);
end

nIf = length(astIf);
nSubSigs = length(astSubSigs);
for i = 1:nIf
    stIf = astIf(i);
    nCount = atgcv_m01_counter('get', 'nIfCount');
    sId = sprintf('if%i', nCount);

    hIfNode = mxx_xmltree('add_node', hParentNode, 'ifName');
    mxx_xmltree('set_attribute', hIfNode, 'ifid', sId);

    if (nSubSigs > 0)
        if (i > nSubSigs)
            error('INTERNAL:ERROR', 'Index overflow for interface signals during export of the model analysis XML.');
        end
        stSig = astSubSigs(i);

        if ~isempty(stSig.sName)
            if (stSig.sName(1) == '.')
                stSig.sName = ['<signal1>', stSig.sName];
            end
            mxx_xmltree('set_attribute', hIfNode, 'signalName', stSig.sName);
        end
        if ~isempty(stSig.aiDim)
            sSignalDim = i_getIntArrayAsString(stSig.aiDim);
            mxx_xmltree('set_attribute', hIfNode, 'signalDim', sSignalDim);
        end
        if ~isempty(stSig.sType)
            mxx_xmltree('set_attribute', hIfNode, 'signalType', stSig.sType);
        end
        if ~isempty(stSig.iSubSigIdx)
            if ~isempty(stSig.aiDim)
                aiIdx = i_linToMatrixSignalIdx(stSig.aiDim, stSig.iSubSigIdx);
            else
                aiIdx = stSig.iSubSigIdx;
            end
            if ~isempty(iFirstIdx)
                aiIdx = aiIdx + iFirstIdx - 1;
            end
            for k = 1:length(aiIdx)
                mxx_xmltree('set_attribute', hIfNode, sprintf('index%d', k), sprintf('%d', aiIdx(k)));
            end
        end
        if ~isempty(stSig.sType)
            mxx_xmltree('set_attribute', hIfNode, 'signalType', stSig.sType);
        end

        [sMin, sMax] = i_getSignalMinMax(stSig);
        if ~isempty(sMin)
            mxx_xmltree('set_attribute', hIfNode, 'min', sMin);
        end
        if ~isempty(sMax)
            mxx_xmltree('set_attribute', hIfNode, 'max', sMax);
        end
    else
        if ~isempty(stIf.nIndex1)
            iIdx = stIf.nIndex1;
            if ~isempty(iFirstIdx)
                iIdx = iIdx + iFirstIdx - 1;
            end
            mxx_xmltree('set_attribute', hIfNode, 'index1', sprintf('%i', iIdx));
        end
        if ~isempty(stIf.nIndex2)
            iIdx = stIf.nIndex2;
            if ~isempty(iFirstIdx)
                iIdx = iIdx + iFirstIdx - 1;
            end
            mxx_xmltree('set_attribute', hIfNode, 'index2', sprintf('%i', iIdx));
        end
    end

    if ~isempty(sVarAccessPath) || ~isempty(stIf.sAccessPath)
        mxx_xmltree('set_attribute', hIfNode, 'accessPath', sprintf('%s%s', sVarAccessPath, stIf.sAccessPath));
    end
    if ~isempty(stIf.dInitValue)
        i_setAttribDouble(hIfNode, 'initValue', stIf.dInitValue);
    end

    stSubType = stVarInfo.oTypeMap(stIf.hVar);
    i_addDataTypeScaleNode(stEnv, hIfNode, stSubType, stIf);
end
end


%%
function i_addDataTypeScaleNode(~, hParentNode, stType, stScale)
hTypeNode = mxx_xmltree('add_node', hParentNode, 'DataType');

stEvalType = i_evalType(stType);

mxx_xmltree('set_attribute', hTypeNode, 'tlTypeName', stEvalType.sName);
i_setAttribDouble(hTypeNode, 'tlTypeMin', stEvalType.dMin);
i_setAttribDouble(hTypeNode, 'tlTypeMax', stEvalType.dMax);
if stEvalType.bIsFloat
    mxx_xmltree('set_attribute', hTypeNode, 'isFloat', 'yes');
end

if ~isempty(stEvalType.sEnumName)
    atgcv_m01_enum_type_store(stEvalType.sEnumName, stEvalType.astEnumElements);
    mxx_xmltree('set_attribute', hTypeNode, 'enumTypeRef', stEvalType.sEnumName);
end

hScaleNode = mxx_xmltree('add_node', hTypeNode, 'Scaling');
i_setAttribDouble(hScaleNode, 'lsb',    stScale.dLsb);
i_setAttribDouble(hScaleNode, 'offset', stScale.dOffset);
i_setAttribDouble(hScaleNode, 'lower',  stScale.dMin);
i_setAttribDouble(hScaleNode, 'upper',  stScale.dMax);
if ~isempty(stScale.sUnit)
    mxx_xmltree('set_attribute', hScaleNode, 'physUnit', stScale.sUnit);
end
end


%%
function stEvalType = i_evalType(stType)
if ~isempty(stType.sBaseDest)
    sBaseName = stType.sBaseDest;
    sUserName = stType.sUserDest;
else
    sBaseName = stType.sBase;
    sUserName = stType.sUser;
end

% handle enums and scaling enums
sEnumName = '';
astEnumElements = [];
if strcmpi(sBaseName, 'Enum')
    sEnumName = sUserName;
    astEnumElements = stType.astEnumElements;
else
    [bIsScalingEnum, astTabValues] = i_evalScalingEnum(stType);
    if bIsScalingEnum
        sBaseName = 'Enum';
        sEnumName = sUserName;
        astEnumElements = i_transferTableValuesToEnumValues(astTabValues);
    end
end

stEvalType = struct( ...
    'sName',           sBaseName, ...
    'dMin',            stType.dMin, ...
    'dMax',            stType.dMax, ...
    'bIsFloat',        stType.bIsFloat, ...
    'sEnumName',       sEnumName, ...
    'astEnumElements', astEnumElements);
end


%%
function [bIsScalingEnum, astTabValues] = i_evalScalingEnum(stType)
stScaling = i_getScaling(stType);
bIsScalingEnum = ~isempty(stScaling) && strcmp(stScaling.sConversionType, 'TAB_VERB');
if bIsScalingEnum
    astTabValues = stScaling.astTabValues;
else
    astTabValues = [];
end
end


%%
function stScaling = i_getScaling(stType)
if isempty(stType.stConstraints)
    stScaling = [];
else
    stScaling = stType.stConstraints.stScaling;
end
end


%%
function astEnumElements = i_transferTableValuesToEnumValues(astTabValues)
nEnumElements = numel(astTabValues);

astEnumElements = repmat(struct(...
    'sName',  '', ...
    'sValue', []), nEnumElements, 1);
for i = 1:nEnumElements
    stTabValue = astTabValues(i);
    astEnumElements(i).sName = stTabValue.sName;
    astEnumElements(i).sValue = sprintf('%d', stTabValue.xValue);
end
end


%%
function hCalNode = i_addCalVarNode(stEnv, hParentNode, stCal, sTlRoot, sSlRoot)
hCalNode = mxx_xmltree('add_node', hParentNode, 'Calibration');

sTlPath = stCal.stBlockInfo.sTlPath;
mxx_xmltree('set_attribute', hCalNode, 'tlBlockPath', sTlPath);
if ~isempty(sSlRoot)
    sSlPath = strrep(sTlPath, sTlRoot, sSlRoot);
    mxx_xmltree('set_attribute', hCalNode, 'slBlockPath', sSlPath);
end

sUsage = i_getLimitedCalUsage(stEnv, stCal.stBlockInfo);
mxx_xmltree('set_attribute', hCalNode, 'usage', sUsage);

if ~isempty(stCal.stBlockInfo.stSfInfo)
    mxx_xmltree('set_attribute', hCalNode, 'sfVariable', stCal.stBlockInfo.stSfInfo.sSfName);
end
end


%%
function hParamNode = i_addParamVarNode(hParentNode, stParam, sTlRoot, sSlRoot)
hParamNode = mxx_xmltree('add_node', hParentNode, 'Calibration');

sTlPath = stParam.stBlockInfo.sTlPath;
mxx_xmltree('set_attribute', hParamNode, 'tlBlockPath', sTlPath);

if ~isempty(sSlRoot)
    sSlPath = strrep(sTlPath, sTlRoot, sSlRoot);
    mxx_xmltree('set_attribute', hParamNode, 'slBlockPath', sSlPath);
end

mxx_xmltree('set_attribute', hParamNode, 'name', stParam.stCal.sUniqueName);

sDdPath = stParam.stCal.sPoolVarPath;
if ~isempty(sDdPath)
    mxx_xmltree('set_attribute', hParamNode, 'ddPath', sDdPath);
end

sWorkspaceVar = stParam.stCal.sWorkspaceVar;
if ~isempty(sWorkspaceVar)
    mxx_xmltree('set_attribute', hParamNode, 'workspace', sWorkspaceVar);
end

mxx_xmltree('set_attribute', hParamNode, 'usage', 'explicit_param');

if ~isempty(stParam.stBlockInfo.stSfInfo)
    mxx_xmltree('set_attribute', hParamNode, 'sfVariable', stParam.stBlockInfo.stSfInfo.sSfName);
end
end


%%
function hContextNode = ...
    i_addModelContextNode(stEnv, hParentNode, stBlockInfo, bIsExplicitUsage, sTlRoot, sSlRoot, sRestriction)
hContextNode = mxx_xmltree('add_node', hParentNode, 'ModelContext');

sTlPath = stBlockInfo.sTlPath;
mxx_xmltree('set_attribute', hContextNode, 'tlPath', sTlPath);

if ~isempty(sSlRoot)
    sSlPath = strrep(sTlPath, sTlRoot, sSlRoot);
    mxx_xmltree('set_attribute', hContextNode, 'slPath', sSlPath);
end

if ~isempty(stBlockInfo.sBlockKind)
    mxx_xmltree('set_attribute', hContextNode, 'blockKind', stBlockInfo.sBlockKind);
end
if ~isempty(stBlockInfo.sBlockType)
    mxx_xmltree('set_attribute', hContextNode, 'blockType', stBlockInfo.sBlockType);
end
if ~isempty(stBlockInfo.sBlockUsage)
    mxx_xmltree('set_attribute', hContextNode, 'blockUsage', stBlockInfo.sBlockUsage);
end

if bIsExplicitUsage
    sUsage = 'explicit_param';
else
    sUsage = i_getLimitedCalUsage(stEnv, stBlockInfo);
end
mxx_xmltree('set_attribute', hContextNode, 'usage', sUsage);

if ~isempty(stBlockInfo.stSfInfo)
    mxx_xmltree('set_attribute', hContextNode, 'sfVariable', stBlockInfo.stSfInfo.sSfName);
end

if ~isempty(sRestriction)
    mxx_xmltree('set_attribute', hContextNode, 'restriction', sRestriction);
end

% Add model reference information
if (i_hasNonemptyField(stBlockInfo, 'sModelPath') && ~strcmp(stBlockInfo.sModelPath, stBlockInfo.sTlPath))
    if isempty(sTlRoot)
        i_addModelReferenceNode(stEnv, hContextNode, stBlockInfo.sModelPath, 'SL');
    else
        i_addModelReferenceNode(stEnv, hContextNode, stBlockInfo.sModelPath, 'TL');
    end
end

end


%%
function sPortNumb = i_getDispPortNumber(~, stDisp)
% no port number for local SF variables
if ~isempty(stDisp.iPortNumber)
    sPortNumb = sprintf('%i', stDisp.iPortNumber);
else
    sPortNumb = '';
end
end


%%
function hDispNode = i_addDispVarNode(~, hParentNode, stDisp, sTlRoot, sSlRoot, sPortNumb)
hDispNode = mxx_xmltree('add_node', hParentNode, 'Display');

sTlPath = stDisp.stBlockInfo.sTlPath;
mxx_xmltree('set_attribute', hDispNode, 'tlBlockPath', sTlPath);

if ~isempty(sSlRoot)
    sSlPath = strrep(sTlPath, sTlRoot, sSlRoot);
    mxx_xmltree('set_attribute', hDispNode, 'slBlockPath', sSlPath);
end

if ~isempty(stDisp.stBlockInfo.stSfInfo)
    mxx_xmltree('set_attribute', hDispNode, 'sfVariable', stDisp.stBlockInfo.stSfInfo.sSfName);
    if strcmpi(stDisp.stBlockInfo.stSfInfo.sSfContext, 'var')
        return;
    end
end

mxx_xmltree('set_attribute', hDispNode, 'portNumber', sPortNumb);
end


%%
function i_addArgumentNode(~, hParentNode, stArg)
hArgNode = mxx_xmltree('add_node', hParentNode, 'Parameter');
mxx_xmltree('set_attribute', hArgNode, 'paramNr', sprintf('%i', stArg.nLocation));
if ~isempty(stArg.sExpression)
    mxx_xmltree('set_attribute', hArgNode, 'expression', stArg.sExpression);
end
if ~isempty(stArg.sDeclaration)
    mxx_xmltree('set_attribute', hArgNode, 'declaration', stArg.sDeclaration);
elseif ~isempty(stArg.sModule)
    mxx_xmltree('set_attribute', hArgNode, 'module',  stArg.sModule);
    mxx_xmltree('set_attribute', hArgNode, 'argName', stArg.sVarName);
    mxx_xmltree('set_attribute', hArgNode, 'argType', stArg.sTypeName);
end
end


%%
function i_addSignatureArgNode(~, hParentNode, stFormalArg, stActualArg)
hArgNode = mxx_xmltree('add_node', hParentNode, 'Arg');
mxx_xmltree('set_attribute', hArgNode, 'pos', sprintf('%i', stFormalArg.nPos));
if (stFormalArg.nPos < 0)
    % special case ReturnValue
    mxx_xmltree('set_attribute', hArgNode, 'name', 'ReturnValue');
    mxx_xmltree('set_attribute', hArgNode, 'ext_name', '');
else
    mxx_xmltree('set_attribute', hArgNode, 'name', stFormalArg.sArgName);
    mxx_xmltree('set_attribute', hArgNode, 'ext_name', stActualArg.sVarName);
end
mxx_xmltree('set_attribute', hArgNode, 'type', stFormalArg.sTypeName);

if stFormalArg.bIsPointer
    if stFormalArg.bIsConst
        sUsage = 'ptrCval';
    else
        sUsage = 'ptr';
    end
else
    if stFormalArg.bIsConst
        sUsage = 'cval';
    else
        sUsage = 'val';
    end
end
mxx_xmltree('set_attribute', hArgNode, 'usage', sUsage);
if ~isempty(stFormalArg.aiWidth)
    mxx_xmltree('set_attribute', hArgNode, 'width1', sprintf('%d', stFormalArg.aiWidth(1)));
    if (length(stFormalArg.aiWidth) > 1)
        mxx_xmltree('set_attribute', hArgNode, 'width2', sprintf('%d', stFormalArg.aiWidth(2)));
    end
end
end


%%
function hPortNode = i_addPortNode(~, hParentNode, stPort, sTlRoot, sSlRoot)
hPortNode = mxx_xmltree('add_node', hParentNode, 'Port');
mxx_xmltree('set_attribute', hPortNode, 'tlPath', stPort.sSlPortPath);
if ~isempty(sSlRoot)
    sSlPath = strrep(stPort.sSlPortPath, sTlRoot, sSlRoot);
    mxx_xmltree('set_attribute', hPortNode, 'slPath', sSlPath);
end
mxx_xmltree('set_attribute', hPortNode, 'portNumber', sprintf('%i', stPort.iPortNumber));

i_addCompositeSigAttribute(hPortNode, stPort.stCompInfo.sSigKind);
i_addExtraBusInfo(hPortNode, stPort.stCompInfo.sBusType, stPort.stCompInfo.sBusObj);
end


%%
function i_addCompositeSigAttribute(hNode, sSigKind)
if isempty(sSigKind)
    sCompSig = 'none';
else
    switch lower(sSigKind)
        case 'bus'
            sCompSig = 'bus';
        case 'pseudo_bus'
            sCompSig = 'pseudo_bus';
        case 'composite'
            sCompSig = 'mux';
        otherwise
            sCompSig = 'none';
    end
end
if ~strcmpi(sCompSig, 'none')
    mxx_xmltree('set_attribute', hNode, 'compositeSig', sCompSig);
end
end


%%
function i_addExtraBusInfo(hNode, sBusType, sBusObj)
if (isempty(sBusType) || strcmpi(sBusType, 'NOT_BUS'))
    return;
end
mxx_xmltree('set_attribute', hNode, 'busType', sBusType);
if ~isempty(sBusObj)
    mxx_xmltree('set_attribute', hNode, 'busObj',  sBusObj);
end
end


%%
function hPortNode = i_addDsmPortNode(~, hParentNode, sSignal, sBlockPath, sTlRoot, sSlRoot)
hPortNode = mxx_xmltree('add_node', hParentNode, 'Port');
mxx_xmltree('set_attribute', hPortNode, 'tlPath', sBlockPath);
if ~isempty(sSlRoot)
    sSlPath = strrep(sBlockPath, sTlRoot, sSlRoot);
    mxx_xmltree('set_attribute', hPortNode, 'slPath', sSlPath);
end
% note: special treatment for DSM ports --> portNumber is always 0
mxx_xmltree('set_attribute', hPortNode, 'portNumber', '0');
mxx_xmltree('set_attribute', hPortNode, 'signal', sSignal);
end


%%
function hPortNode = i_addModelDsmPortNode(~, hParentNode, sSignal, sMemBlockPath, sBlockPath, sTlRoot, sSlRoot)
hPortNode = i_addDsmPortNode([], hParentNode, sSignal, sBlockPath, sTlRoot, sSlRoot);
if ~isempty(sMemBlockPath)
    mxx_xmltree('set_attribute', hPortNode, 'memoryBlock', sMemBlockPath);
end
end


%%
% use a continuous (1,2,...) index for ifNames in ports with muxed signals
function hPortNode = i_modifyMuxPort(~, hPortNode, stPort)
if strcmpi(stPort.stCompInfo.sSigKind, 'composite')
    ahIf = mxx_xmltree('get_nodes', hPortNode, './/ma:ifName');
    nIf = length(ahIf);
    if (nIf > 1)
        for i = 1:nIf
            mxx_xmltree('set_attribute', ahIf(i), 'index1', int2str(i));
        end
    end
end
end


%%
function hInOutNode = i_addInOutNode(~, hParentNode, sMode)
if strcmpi(sMode, 'out')
    sNodeName = 'Output';
    sId = sprintf('op%i', atgcv_m01_counter('get', 'nOutputCount'));
else
    sNodeName = 'Input';
    sId = sprintf('ip%i', atgcv_m01_counter('get', 'nInputCount'));
end
hInOutNode = mxx_xmltree('add_node', hParentNode, sNodeName);
mxx_xmltree('set_attribute', hInOutNode, 'id', sId);
end


%%
function hRootNode = i_createHeader()
hRootNode = mxx_xmltree('create', 'ModelAnalysis', 'ma', 'http://www.osc-es.de/ModelAnalysis');
sToday = datestr(now, 'yyyy-mm-dd HH:MM');
sComment  = sprintf('Generated by %s: %s.', atgcv_version_get(), sToday);
mxx_xmltree('add_comment', hRootNode, sComment);
end


%%
function sUsage = i_getLimitedCalUsage(stEnv, stBlockInfo)
sMaskType  = stBlockInfo.sBlockKind;
if isempty(sMaskType)
    if atgcv_sl_block_isa(sBlockPath, 'Stateflow')
        sMaskType = 'stateflow';
    else
        sMaskType = '<empty>';
    end
end
switch lower(sMaskType)
    case 'tl_gain'
        sUsage = 'gain';

    case 'tl_constant'
        sUsage = 'const';

    case 'tl_saturate'
        switch lower(stBlockInfo.sBlockUsage)
            case 'upperlimit'
                sUsage = 'sat_upper';

            case 'lowerlimit'
                sUsage = 'sat_lower';

            otherwise
                i_throwWrongParamVal(stEnv, stBlockInfo.sTlPath, stBlockInfo.sBlockUsage);
        end

    case 'tl_switch'
        sUsage = 'switch_threshold';

    case 'tl_relay'
        switch lower(stBlockInfo.sBlockUsage)
            case 'offoutput'
                sUsage = 'relay_out_off';

            case 'onoutput'
                sUsage = 'relay_out_on';

            case 'offswitch'
                sUsage = 'relay_switch_off';

            case 'onswitch'
                sUsage = 'relay_switch_on';

            otherwise
                i_throwWrongParamVal(stEnv, stBlockInfo.sTlPath, stBlockInfo.sBlockUsage);
        end
    case 'stateflow'
        sUsage = 'sf_const';

    otherwise
        i_throwWrongParamVal(stEnv, stBlockInfo.sTlPath, sMaskType);
end
end


%%
function i_throwWrongParamVal(stEnv, sBlockPath, sBlockUsage)
stErr = osc_messenger_add(stEnv, 'ATGCV:STD:WRONG_PARAM_VAL', 'param_name', sBlockPath, 'wrong_value', sBlockUsage);
osc_throw(stErr);
end


%%
function i_addDummyIfNodesForParams(~, hParentNode, stDummy, stCal)
sSignalType = stCal.sType;

iWidth = prod(stCal.aiWidth);
if (iWidth < 2)
    iWidth  = [];
    iWidth1 = [];
    iWidth2 = [];
else
    aiWidth = stCal.aiWidth(stCal.aiWidth > 1);
    if (length(aiWidth) > 1)
        iWidth1 = aiWidth(1);
        iWidth2 = aiWidth(2);
    else
        iWidth1 = aiWidth(1);
        iWidth2 = [];
    end
end

xInitValue = stCal.xValue;
if isa(xInitValue, 'embedded.fi')
    xInitValue = double(xInitValue);
end

if isempty(iWidth)
    nCount  = atgcv_m01_counter('get', 'nIfCount');
    sId     = sprintf('if%i', nCount);

    astIfs = struct( ...
        'sId',        sId, ...
        'sIndex1',    '', ...
        'sIndex2',    '', ...
        'sAccess',    '', ...
        'sMin',       stCal.sMin, ...
        'sMax',       stCal.sMax, ...
        'sInitValue', i_convertInitValue(xInitValue));
else
    astIfs = [];
    if ~isempty(iWidth2)
        for k = 1:iWidth2
            for i = 1:iWidth1
                nCount  = atgcv_m01_counter('get', 'nIfCount');
                sId     = sprintf('if%i', nCount);
                if ~isempty(astIfs)
                    astIfs(end + 1) = struct( ...
                        'sId',        sId, ...
                        'sIndex1',    sprintf('%d', i), ...
                        'sIndex2',    sprintf('%d', k), ...
                        'sAccess',    sprintf('[%d][%d]', i-1, k-1), ...
                        'sMin',       stCal.sMin, ...
                        'sMax',       stCal.sMax, ...
                        'sInitValue', i_convertInitValue(xInitValue(i, k))); %#ok<AGROW>
                else
                    astIfs = struct( ...
                        'sId',        sId, ...
                        'sIndex1',    sprintf('%d', i), ...
                        'sIndex2',    sprintf('%d', k), ...
                        'sAccess',    sprintf('[%d][%d]', i-1, k-1), ...
                        'sMin',       stCal.sMin, ...
                        'sMax',       stCal.sMax, ...
                        'sInitValue', i_convertInitValue(xInitValue(i, k)));
                end
            end
        end
    else
        for i = 1:iWidth1
            nCount  = atgcv_m01_counter('get', 'nIfCount');
            sId     = sprintf('if%i', nCount);
            if ~isempty(astIfs)
                astIfs(end + 1) = struct( ...
                    'sId',        sId, ...
                    'sIndex1',    sprintf('%d', i), ...
                    'sIndex2',    '', ...
                    'sAccess',    sprintf('[%d]', i-1), ...
                    'sMin',       stCal.sMin, ...
                    'sMax',       stCal.sMax, ...
                    'sInitValue', i_convertInitValue(xInitValue(i))); %#ok<AGROW>
            else
                astIfs = struct( ...
                    'sId',        sId, ...
                    'sIndex1',    sprintf('%d', i), ...
                    'sIndex2',    '', ...
                    'sAccess',    sprintf('[%d]', i-1), ...
                    'sMin',       stCal.sMin, ...
                    'sMax',       stCal.sMax, ...
                    'sInitValue', i_convertInitValue(xInitValue(i)));
            end
        end
    end
end

nElems = length(astIfs);
for i = 1:nElems
    stIf = astIfs(i);

    hIfNode = mxx_xmltree('add_node', hParentNode, 'ifName');
    mxx_xmltree('set_attribute', hIfNode, 'ifid', stIf.sId);
    mxx_xmltree('set_attribute', hIfNode, 'signalType', sSignalType);
    if i_isSL()
        mxx_xmltree('set_attribute', hIfNode, 'slSignalType', sSignalType);
    end
    i_setAttribNonempty(hIfNode, 'index1',     stIf.sIndex1);
    i_setAttribNonempty(hIfNode, 'index2',     stIf.sIndex2);
    i_setAttribNonempty(hIfNode, 'initValue',  stIf.sInitValue);
    i_setAttribNonempty(hIfNode, 'accessPath', stIf.sAccess);


    [sMin, sMax] = i_getSignalMinMax(stIf);
    if ~isempty(sMin)
        mxx_xmltree('set_attribute', hIfNode, 'slMin', sMin);
        dLower = str2double(sMin);
    else
        dLower = stDummy.dLower;
    end
    if ~isempty(sMax)
        mxx_xmltree('set_attribute', hIfNode, 'slMax', sMax);
        dUpper = str2double(sMax);
    else
        dUpper = stDummy.dUpper;
    end

    % DataType node
    hTypeNode = mxx_xmltree('add_node', hIfNode, 'DataType');
    mxx_xmltree('set_attribute', hTypeNode, 'tlTypeName', stDummy.sTypeName);
    i_setAttribDouble(hTypeNode, 'tlTypeMin', stDummy.dMin);
    i_setAttribDouble(hTypeNode, 'tlTypeMax', stDummy.dMax);
    if stDummy.bIsFloat
        mxx_xmltree('set_attribute', hTypeNode, 'isFloat', 'yes');
    end

    % Scaling node
    hScaleNode = mxx_xmltree('add_node', hTypeNode, 'Scaling');
    i_setAttribDouble(hScaleNode, 'lsb',    stDummy.dLsb);
    i_setAttribDouble(hScaleNode, 'offset', stDummy.dOffset);
    i_setAttribDouble(hScaleNode, 'upper',  dUpper);
    i_setAttribDouble(hScaleNode, 'lower',  dLower);
end
end


%%
function oTypeInfoMap = i_createTypeInfoMap(astTypeInfos)
oTypeInfoMap = containers.Map;
for i = 1:length(astTypeInfos)
    oTypeInfoMap(astTypeInfos(i).sType) = astTypeInfos(i);
end
end


%%
function varargout = i_typeInfo(sCmd, varargin)
persistent p_oTypeInfoMap;

switch sCmd
    case 'init'
        p_oTypeInfoMap = varargin{1};

    case 'get'
        sType = varargin{1};
        if p_oTypeInfoMap.isKey(sType)
            varargout{1} = p_oTypeInfoMap(sType);
        else
            varargout{1} = ep_sl_type_info_get(sType);
        end

    otherwise
        error('EP:INTERNAL:ERROR', 'Unknown command %s.', sCmd);
end
end

%%
function sValue = i_convertInitValue(xInitValue)
try %#ok<TRYNC>
    if isenum(xInitValue)
        sValue = num2str(xInitValue);
        return;
    end
end
try
    sValue = sprintf('%.16e', xInitValue);
catch
    sValue = num2str(xInitValue);
end
end