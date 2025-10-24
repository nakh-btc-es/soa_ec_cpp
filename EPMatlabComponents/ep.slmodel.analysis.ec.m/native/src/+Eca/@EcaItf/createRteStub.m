function oEca = createRteStub(oEca, casIncludeFilesName)

if oEca.bDiagMode
    fprintf('\n## Generation of Rte Stub code ... \n');
end

oModel2CodeTranslator = Eca.Model2CodeType(oEca.sAutosarModelName, true, oEca.mApp2Imp);
casTypedefLines = {};

%Include files
casRteStubHeaderNames = i_getRteStubHeaderNames(oEca);
casIncludeFileNames = [casRteStubHeaderNames, casIncludeFilesName];
%Init runnable name
sInitRunnableName = oEca.aoRunnables([oEca.aoRunnables(:).bIsInitFunction]).sName;
%
if ~isempty(oEca.oRootScope)
    bCfgSwcStubAllRunItfs = oEca.stActiveConfig.General.bStubRteApiForNonTestedRunnables;
    aoArItfs = oEca.getAllAutosarComInterfaces(bCfgSwcStubAllRunItfs);
    stItfGroups = i_groupAutosarComInterfaces(aoArItfs);
    
    %Build stub generation objects for Rte Stubbable variables
    aoArItfStubInfoVariables = i_createRteGlobalVariablesStubGenerationInfo(aoArItfs, oModel2CodeTranslator);
    
    %Build stub generation objects for Rte Api
    aoArItfStubInfoFunctions = i_extractFromCodeFormatStubGenerationInfo(aoArItfs, stItfGroups, oModel2CodeTranslator);
    %Build stub generation objets from Initial Condition Rte Api (Related to Runnable Init)
    aoArItfStubInfoIntCondFunctions = ...
        i_createInitConditionStubGenerationInfo(aoArItfs, sInitRunnableName, oModel2CodeTranslator);

    % for AUTOSAR multi-instance extend signatures with additional first input argument of type RteIntstance
    if oEca.bIsAutosarMultiInstance
        aoArItfStubInfoFunctions = i_extendAllFuncsForMultiInstance(aoArItfStubInfoFunctions);
        aoArItfStubInfoIntCondFunctions = i_extendAllFuncsForMultiInstance(aoArItfStubInfoIntCondFunctions);
    end

    %Combine all stub info
    aoArItfStubInfo = [aoArItfStubInfoVariables, aoArItfStubInfoFunctions, aoArItfStubInfoIntCondFunctions];
    %Create stub generation folder
    oEca.createStubDir();
    %Stub generation
    sStubCFileName = oEca.getStubSourceFile('rte');
    sStubHFileName = oEca.getStubHeaderFile('rte');
    %Generate autosar stub files
    oStubGenerator = Eca.MetaStubGenerator;
    [casStubHFiles, casStubCFiles, sVarInitFunc] = oStubGenerator.createStub( ...
        aoArItfStubInfo, ...
        sStubCFileName, ...
        sStubHFileName, ...
        casIncludeFileNames, ...
        casTypedefLines);
    %Updatelist of source files list
    oEca = updateSourceFileList(oEca, casStubHFiles, casStubCFiles, sVarInitFunc);
    %Flag
    oEca.bArStubGenerated = true;
end
end


%%
function aoSubFuncs = i_extendAllFuncsForMultiInstance(aoSubFuncs)
aoSubFuncs = arrayfun(@i_extendFuncForMultiInstance, aoSubFuncs);
end


%%
function oFunc = i_extendFuncForMultiInstance(oFunc)
if ~isempty(oFunc.sStubCustomGetFunName)
    oFunc.aoStubCustomGetFunArgs = i_extendArgsForMultiInstance(oFunc.aoStubCustomGetFunArgs);
elseif ~isempty(oFunc.sStubCustomSetFunName)
    oFunc.aoStubCustomSetFunArgs = i_extendArgsForMultiInstance(oFunc.aoStubCustomSetFunArgs);
end
end


%%
function aoArgs = i_extendArgsForMultiInstance(aoArgs)
oInstArg = i_createDefaultInstanceArg();

if isempty(aoArgs)
    aoArgs = oInstArg;
else
    % skip the first 'return'arg
    if strcmp(aoArgs(1).sKind, 'return')
        aoArgs = [aoArgs(1), oInstArg, reshape(aoArgs(2:end), 1, [])];
    else
        aoArgs = [oInstArg, reshape(aoArgs, 1, [])];
    end
end
end


%%
function oArg = i_createDefaultInstanceArg()
oArg = Eca.MetaFunArg();
oArg.sKind = 'input';
oArg.sArgName = 'self';
oArg.sDataType = 'Rte_Instance';
end


%%
function stItfGroups = i_groupAutosarComInterfaces(aoArItfs)
stItfGroups = struct( ...
    'mExplicitReceiverToErrorStatus', containers.Map);

aiErrorStatusIdx = [];
for i = 1:numel(aoArItfs)
    oComInfo = aoArItfs(i).oAutosarComInfo;
    
    if strcmp(oComInfo.sInterfaceType, 'SenderReceiver')
        switch oComInfo.sAccessMode
            case {'ExplicitReceive', 'QueuedExplicitReceive'}
                sKey = i_getComAccessKey(oComInfo);
                stItfGroups.mExplicitReceiverToErrorStatus(sKey) = -1; % first loop sets invalid index -1
                
            case 'ErrorStatus'
                aiErrorStatusIdx(end + 1) = i; %#ok<AGROW>
                
            otherwise
                % ignore
        end
    end
end

for i = 1:numel(aiErrorStatusIdx)
    iIdx = aiErrorStatusIdx(i);
    oComInfo = aoArItfs(iIdx).oAutosarComInfo;
    
    sKey = i_getComAccessKey(oComInfo);
    if stItfGroups.mExplicitReceiverToErrorStatus.isKey(sKey)
        stItfGroups.mExplicitReceiverToErrorStatus(sKey) = iIdx;
    end
end
end


%%
function sKey = i_getComAccessKey(oComInfo)
sKey = sprintf('%s:%s:%s', oComInfo.sItfName, oComInfo.sPortName, oComInfo.sDataElementName);
end


%%
function [casHeaderNames, casRteStubHeaders] = i_getRteStubHeaderNames(oEca)
casRteStubHeaders = oEca.getCodegenRteStubHeaderFiles();
casHeaderNames = cellfun(@i_getFileName, casRteStubHeaders, 'uni', false);
end


%%
function sFileName = i_getFileName(sFilePath)
[~, f, e] = fileparts(sFilePath);
sFileName = [f, e];
end


%%
function aoArItfStubInfo = i_createRteGlobalVariablesStubGenerationInfo(aoArItfs, oModel2CodeTranslator)
nInterfaces = numel(aoArItfs);
aoArItfStubInfo = repmat(Eca.MetaStubIntefaceInfo, 1, nInterfaces); % preallocate the space for the stubbing info
abSelect = false(size(aoArItfStubInfo));
jKnownStubVariables = java.util.HashSet();

for iItf = 1:nInterfaces
    oItf = aoArItfs(iItf);

    oArComInfo = oItf.oAutosarComInfo;
    if ismember(oArComInfo.sComType, {'Interface', 'InterRunnableVariable', 'CalprmInterface', 'InternalCalibration'})
        oStubInfo = Eca.MetaStubIntefaceInfo;
        
        bIsCal = ismember(oArComInfo.sComType, {'CalprmInterface', 'InternalCalibration'});
        if bIsCal
            oStubInfo.sStubType = 'varinit';
        else
            oStubInfo.sStubType = 'variable';
        end
        oStubInfo.b2DMatlabIs1DCode = oItf.stArComCfg.Format.b2DMatlabIs1DCode;
        oStubInfo.s2DMatlabTo2DCodeConv = oItf.stArComCfg.Format.s2DMatlabTo2DCodeConv;
        oStubInfo.bIsScalar = oItf.bIsScalar;
        oStubInfo.bIsArray1D = oItf.bIsArray1D;
        oStubInfo.nDimAsRowCol = oItf.nDimAsRowCol;
        if oItf.isBusElement && ~oItf.metaBus.isVirtual
            oStubInfo.sVariableDatatype = oModel2CodeTranslator.translateToImplementationType(oItf.metaBus.busObjectName);
        else
            oStubInfo.sVariableDatatype = oModel2CodeTranslator.translateToImplementationType(oItf.sldatatype);
        end
        oStubInfo = i_replaceAutosarMacrosRecursive(oStubInfo, oItf);
        %Interfaces data elements
        if strcmp(oArComInfo.sComType, 'Interface')
            if strcmp(oArComInfo.sAccessMode, 'ErrorStatus')
                oStubInfo.sVariableName = ...
                    ['RteStub_', oArComInfo.sItfName, '_', oArComInfo.sPortName, '_', oArComInfo.sDataElementName, '_err'];

            elseif strcmp(oArComInfo.sAccessMode, 'EndToEndRead')
                oStubInfo.sVariableName = ...
                    ['RteStub_', oArComInfo.sItfName, '_', oArComInfo.sDataElementName, '_e2ein'];

            elseif strcmp(oArComInfo.sAccessMode, 'EndToEndWrite')
                oStubInfo.sVariableName = ...
                    ['RteStub_', oArComInfo.sItfName, '_', oArComInfo.sDataElementName, '_e2eout'];

            elseif strcmp(oArComInfo.sAccessMode, 'ModeSend') || strcmp(oArComInfo.sAccessMode, 'ModeReceive')                
                oStubInfo.sVariableName = ...
                        ['RteStub_',  oArComInfo.sPortName, '_', oArComInfo.sModeGroup, '_ModeSwitch'];

            else % for ImplicitSend, ExplicitSend, ImplicitSendByRef, ImplicitReceive, ExplicitReceive, SenderReceiver...
                oStubInfo.sVariableName = ...
                        ['RteStub_',  oArComInfo.sItfName, '_', oArComInfo.sPortName, '_', oArComInfo.sDataElementName];
            end
            
        elseif strcmp(oArComInfo.sComType, 'InterRunnableVariable')
            oStubInfo.sVariableName = ['RteStub_', oArComInfo.sDataName];
            
        elseif bIsCal
            oStubInfo.sVariableName = oItf.getCodeRootVarName();
            oStubInfo.stInitInfo = i_getInitInfo(oItf);
        end
        
        % Append new stub info if not already known
        if ~jKnownStubVariables.contains(oStubInfo.sVariableName)
            aoArItfStubInfo(iItf) = oStubInfo;
            abSelect(iItf) = true;
            jKnownStubVariables.add(oStubInfo.sVariableName);
        end
    end
end
aoArItfStubInfo = aoArItfStubInfo(abSelect);
end


%%
function stInitInfo = i_getInitInfo(oItf)
stInitInfo = struct( ...
    'sClass',          '', ...
    'casSuperclasses', {{}}, ...
    'mValues',         containers.Map());

try
    if strcmp(oItf.stParam_.sSourceType, 'model workspace')
        oObj = oItf.evalinLocal(oItf.name);
    else
        oObj = oItf.evalinGlobal(oItf.name);
    end
    if ~isobject(oObj)
        return;
    end
    
catch
    return;
end

stInitInfo.sClass = class(oObj);
stInitInfo.casSuperclasses = superclasses(oObj);

if (isa(oObj, 'Simulink.LookupTable') && ~strcmp(oObj.BreakpointsSpecification, 'Reference'))
    oTable = oObj.Table;
    sAccess = oTable.FieldName;
    xValues = oTable.Value;
    stTypeInfo = i_getTypeInfo(oTable.DataType, xValues, oItf);
    stInitInfo.mValues('Table') = i_initValInfo(sAccess, xValues, stTypeInfo);
    
    aoBps = oObj.Breakpoints;
    for i = 1:numel(aoBps)
        oBp = aoBps(i);
        
        sAccess = oBp.FieldName;
        xValues = oBp.Value;
        stTypeInfo = i_getTypeInfo(oBp.DataType, xValues, oItf);
        
        sField = sprintf('Breakpoints_%d', i);
        stInitInfo.mValues(sField) = i_initValInfo(sAccess, xValues, stTypeInfo);
    end
else
    if isa(oObj, 'Simulink.LookupTable')
        oObj = oObj.Table;
        
    elseif isa(oObj, 'Simulink.Breakpoint')
        oObj = oObj.Breakpoints;
    end
    
    sAccess = '';
    try
        xValues = oObj.Value;
    catch
        xValues = [];
    end
    stTypeInfo = i_getTypeInfo(oObj.DataType, xValues, oItf);
    stInitInfo.mValues('Value') = i_initValInfo(sAccess, xValues, stTypeInfo);
end
end


%%
function sDataType = i_evalDataType(sDataType, xValue)
if strcmp(sDataType, 'auto')
    try %#ok<TRYNC>
        sDataType = class(xValue);
    end
end
end


%%
function stTypeInfo = i_getTypeInfo(sDataType, xValues, oItf)
sDataType = i_evalDataType(sDataType, xValues);
try
    stTypeInfo = ep_core_feval('ep_sl_type_info_get', sDataType, @(s) oItf.evalinGlobal(s));
    if ~stTypeInfo.bIsValidType
        stTypeInfo = [];
    end
catch
    stTypeInfo = [];
end
end


%%
function stInitValInfo = i_initValInfo(sAccess, xValues, stTypeInfo)
stInitValInfo = struct( ...
    'sAccess',    sAccess, ...
    'xValues',    xValues, ...
    'stTypeInfo', stTypeInfo);
end


%%
function aoArItfStubInfo = i_extractFromCodeFormatStubGenerationInfo(aoArItfs, stItfGroups, oModel2CodeTranslator)
aiExplReceiverErrStatusIdx = i_filterPosNumber(cell2mat(stItfGroups.mExplicitReceiverToErrorStatus.values));

mDefinedFuncs = containers.Map;
aoArItfStubInfo = [];
for iItf = 1:numel(aoArItfs)
    % note: skip creation of RTE function access for ErrorStatus that is belonging to an ExplicitReceiver
    if any(iItf == aiExplReceiverErrStatusIdx)
        continue;
    end
    
    oItf = aoArItfs(iItf);
    if oItf.stArComCfg.Format.bToBeStubbed
        oStubInfo = oItf.stArComCfg.Format.oStubInfo;
        oComInfo = oItf.oAutosarComInfo;
        if i_isExplicitReceiver(oComInfo)
            sKey = i_getComAccessKey(oComInfo);
            bIsErrorStatusUsedByModel = ...
                stItfGroups.mExplicitReceiverToErrorStatus.isKey(sKey) && ...
                stItfGroups.mExplicitReceiverToErrorStatus(sKey) > 0;
            if ~bIsErrorStatusUsedByModel
                % error status is not used ... 
                % --> this means that there is no definition for the status variable
                % --> this means that the stubbing shall return a literal value 0 instead of the variable value
                % ==> set the return name to empty to provoke this
                iRetArgIdx = 1; % NOTE: assuming here that the first arg is "return"
                oStubInfo.aoStubCustomGetFunArgs(iRetArgIdx).sArgName = '';
            end 
        end
        
        oStubInfo.bIsScalar = oItf.bIsScalar;
        oStubInfo.bIsArray1D = oItf.bIsArray1D;
        oStubInfo.nDimAsRowCol = oItf.nDimAsRowCol;
        oStubInfo.b2DMatlabIs1DCode = oItf.stArComCfg.Format.b2DMatlabIs1DCode;
        oStubInfo.s2DMatlabTo2DCodeConv = oItf.stArComCfg.Format.s2DMatlabTo2DCodeConv;
        %Bus interface:
        %- Datatype is the BusType
        %- Autosar Functions access the variable with Pointer argument
        if oItf.isBusFirstElement && ~oItf.metaBus.isVirtual
            oStubInfo.sVariableDatatype = oModel2CodeTranslator.translateToImplementationType(oItf.metaBus.busObjectName);
            oStubInfo.bForceScalarVarAccessAsPointer = true;
        else
            oStubInfo.sVariableDatatype = oModel2CodeTranslator.translateToImplementationType(oItf.sldatatype);
        end
        % Note: replacing ImpType here is a workaround and should be done earlier somewhere else
        oItf.oAutosarComInfo.sImplDatatype = oStubInfo.sVariableDatatype;
        oStubInfo = i_replaceAutosarMacrosRecursive(oStubInfo, oItf);
        
        % avoid stubbing the same functions multiple times by registering the functions and check for multi occurrence
        bIsAlreadyRegistered = i_registerGetSetFunctions(mDefinedFuncs, oStubInfo);
        if ~bIsAlreadyRegistered
            aoArItfStubInfo = [aoArItfStubInfo, oStubInfo]; %#ok<AGROW>
        end
    end
end
end


%%
function bIsReceiver = i_isExplicitReceiver(oComInfo)
bIsReceiver = ...
    strcmp(oComInfo.sInterfaceType, 'SenderReceiver')  ...
    && any(strcmp(oComInfo.sAccessMode, {'ExplicitReceive', 'QueuedExplicitReceive'}));
end


%%
function aiNums = i_filterPosNumber(aiNums)
aiNums = aiNums(arrayfun(@(x) x > 0, aiNums));
end


%%
function aoArItfStubInfo = i_createInitConditionStubGenerationInfo(aoArItfs, sInitRunnableName, oModel2CodeTranslator)
%Create stub info for Autosar output interfaces with Init Condition

%Concerned AccessModes
casAccessModeFitler = {'ErrorStatus', 'ImplicitSend', 'Implicit', 'Explicit'};

mDefinedFuncs = containers.Map;
aoArItfStubInfo = [];
for iItf = 1:numel(aoArItfs)
    oItf = aoArItfs(iItf);
    if strcmp(oItf.kind, 'OUT') && oItf.stArComCfg.Format.bToBeStubbed && ...
            ismember(oItf.oAutosarComInfo.sAccessMode, casAccessModeFitler)
        
        %Overwrite the runnable name with the init
        oItf.oAutosarComInfo.sRunnableName = sInitRunnableName;
        
        %
        oStubInfo = oItf.stArComCfg.Format.oStubInfo;
        oStubInfo.bIsScalar = oItf.bIsScalar;
        oStubInfo.bIsArray1D = oItf.bIsArray1D;
        oStubInfo.nDimAsRowCol = oItf.nDimAsRowCol;
        oStubInfo.b2DMatlabIs1DCode = oItf.stArComCfg.Format.b2DMatlabIs1DCode;
        oStubInfo.s2DMatlabTo2DCodeConv = oItf.stArComCfg.Format.s2DMatlabTo2DCodeConv;
        %Bus interface:
        %- Datatype is the BusType
        %- Autosar Functions access the variable with Pointer argument
        if oItf.isBusFirstElement && ~oItf.metaBus.isVirtual
            oStubInfo.sVariableDatatype = oModel2CodeTranslator.translateToImplementationType(oItf.metaBus.busObjectName);
            oStubInfo.bForceScalarVarAccessAsPointer = true;
        else
            oStubInfo.sVariableDatatype = oModel2CodeTranslator.translateToImplementationType(oItf.sldatatype);
        end
        % Note: replacing ImpType here is a workaround and should be done earlier somewhere else
        oItf.oAutosarComInfo.sImplDatatype = oStubInfo.sVariableDatatype;
        oStubInfo = i_replaceAutosarMacrosRecursive(oStubInfo, oItf);
        
        % avoid stubbing the same functions multiple times by registering the functions and check for multi occurrence
        bIsAlreadyRegistered = i_registerGetSetFunctions(mDefinedFuncs, oStubInfo);
        if ~bIsAlreadyRegistered
            aoArItfStubInfo = [aoArItfStubInfo, oStubInfo]; %#ok<AGROW>
        end
    end
end
end


%%
function dataInOut = i_replaceAutosarMacrosRecursive(dataInOut, oItf)
if isobject(dataInOut)
    for ii = 1:numel(dataInOut)
        casProps = properties(dataInOut(ii));
        for iProp = 1:numel(casProps)
            dataInOut(ii).(casProps{iProp}) = i_replaceAutosarMacrosRecursive(dataInOut(ii).(casProps{iProp}), oItf);
        end
    end
elseif isstruct(dataInOut)
    for ii = 1:numel(dataInOut)
        casFields = fieldnames(dataInOut(ii));
        for iFld = 1:numel(casFields)
            dataInOut(ii).(casFields{iFld}) = i_replaceAutosarMacrosRecursive(dataInOut(ii).(casFields{iFld}), oItf);
        end
    end
elseif ischar(dataInOut) && ~isempty(dataInOut)
    dataInOut = oItf.replaceMacrosAutosar(dataInOut);
end
end


%%
function bIsAlreadyRegistered = i_registerGetSetFunctions(mDefinedFuncs, oStubInfo)
bIsAlreadyRegistered = false;

sGetFunc = oStubInfo.sStubCustomGetFunName;
if ~isempty(sGetFunc)
    bIsKnown = mDefinedFuncs.isKey(sGetFunc);
    if ~bIsKnown
        mDefinedFuncs(sGetFunc) = true;
    end
    bIsAlreadyRegistered = bIsAlreadyRegistered || bIsKnown;
end
sSetFunc = oStubInfo.sStubCustomSetFunName;
if ~isempty(sSetFunc)
    bIsKnown = mDefinedFuncs.isKey(sSetFunc);
    if ~bIsKnown
        mDefinedFuncs(sSetFunc) = true; %#ok<NASGU> mDefinedFuncs is a handle --> call-by-reference
    end
    bIsAlreadyRegistered = bIsAlreadyRegistered || bIsKnown;
end
end
