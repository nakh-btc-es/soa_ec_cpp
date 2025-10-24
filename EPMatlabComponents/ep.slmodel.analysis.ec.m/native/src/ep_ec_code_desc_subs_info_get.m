function mSubToArgs = ep_ec_code_desc_subs_info_get(sModel)
% Creates a mapping from subsystem paths to supported step functions (with arguments)
%
%

if (nargin < 1)
    sModel = bdroot;
end

% Get Code Descriptor information for ML2021a and higher; for lower ML versions just return an empty map
if verLessThan('matlab', '9.10')
    mSubToArgs = containers.Map;
else
    castSubInfos = i_readSubsystemStepFunctionArgs(sModel);
    mSubToArgs = i_createSubsystemToArgsMap(castSubInfos);
end
end


%%
function mSubToArgs = i_createSubsystemToArgsMap(castSubInfos)
mSubToArgs = containers.Map;
for i = 1:numel(castSubInfos)
    castSubsystem = castSubInfos{i};
    for j = 1:numel(castSubsystem)
        stSubsystem = castSubsystem{j};

        sSubsysPath = stSubsystem.SubsystemBlockPath;
        if ~i_isGraphInterfaceFunc(sSubsysPath)
            continue;
        end

        castInArgs = {};
        castOutArgs = {};
        stFctArgs = struct(...
            'castInArgs',  {{}}, ...
            'castOutArgs', {{}});
        stPrototype = stSubsystem.OutputFunctions{1}.Prototype;
        casArguments = stPrototype.Arguments;
        if ~isempty(casArguments)
            for k = 1:numel(casArguments)
                if strcmp(char(stPrototype.Arguments{k}.IOType), 'INPUT')
                    castInArgs(end+1) = stPrototype.Arguments(k); %#ok
                elseif strcmp(char(stPrototype.Arguments{k}.IOType), 'INPUT_OUTPUT')
                    castOutArgs(end+1) = stPrototype.Arguments(k); %#ok
                end
            end
            stFctArgs.castInArgs = castInArgs;
            stFctArgs.castOutArgs = castOutArgs;
            mSubToArgs(sSubsysPath) = stFctArgs;
        end
    end
end
end


%%
function bIsGraphInterface = i_isGraphInterfaceFunc(sSubsysPath)
try
    sFuncSpec = get_param(sSubsysPath, 'FunctionInterfaceSpec');
    bIsGraphInterface = strcmp(sFuncSpec, 'Allow arguments (Match graphical interface)');
catch
    bIsGraphInterface = false;
end
end


%%
function castInfos = i_readSubsystemStepFunctionArgs(sModel)
oCD = coder.getCodeDescriptor(sModel);

castInfos = {i_getModelLevelInfo(oCD)};

oRefModelCDs = i_getRefModelCDs(oCD);
castSubInfos = cellfun(@i_getModelLevelInfo, oRefModelCDs.values, 'uni', false);
castInfos = [castInfos, reshape(castSubInfos, 1, [])];
end


%%
function oRefModelCDs = i_getRefModelCDs(oCD, oRefModelCDs)
if (nargin < 2)
    oRefModelCDs = containers.Map();
end

casRefModels = oCD.getReferencedModelNames();
for i = 1:numel(casRefModels)
    if ~oRefModelCDs.isKey(casRefModels{i})
        oRefCD = oCD.getReferencedModelCodeDescriptor(casRefModels{i});
        oRefModelCDs(casRefModels{i}) = oRefCD;
        
        oRefModelCDs = i_getRefModelCDs(oRefCD, oRefModelCDs);
    end
end
end


%%
function astInfo = i_getModelLevelInfo(oCD)
oCompIF = oCD.getFullComponentInterface;
astInfo = i_getArrayInfo(@i_getSubsystemInterface, oCompIF.Subsystems);
end


%%
function stSub = i_getSubsystemInterface(oSubIF)
stSub = struct( ...
    'SubsystemBlockPath',   oSubIF.SubsystemBlockPath, ...
    'SubsystemType',        oSubIF.SubsystemType, ...
    'SID',                  oSubIF.SID, ...
    'Inports',              {i_getArrayInfo(@i_getDataInterface, oSubIF.Inports)}, ...
    'Outports',             {i_getArrayInfo(@i_getDataInterface, oSubIF.Outports)}, ...
    'Parameters',           {i_getArrayInfo(@i_getDataInterface, oSubIF.Parameters)}, ...
    'DataStores',           {i_getArrayInfo(@i_getDataInterface, oSubIF.DataStores)}, ...
    'InternalData',         {i_getArrayInfo(@i_getDataInterface, oSubIF.InternalData)}, ...
    'ExternalBlockOutputs', {i_getArrayInfo(@i_getDataInterface, oSubIF.ExternalBlockOutputs)}, ...
    'GlobalBlockOutputs',   {i_getArrayInfo(@i_getDataInterface, oSubIF.GlobalBlockOutputs)}, ...
    'ConstantBlockOutputs', {i_getArrayInfo(@i_getDataInterface, oSubIF.ConstantBlockOutputs)}, ...
    'DWorks',               {i_getArrayInfo(@i_getDataInterface, oSubIF.DWorks)}, ...
    'InitializeFunctions',  {i_getArrayInfo(@i_getFunctionInterface, oSubIF.InitializeFunctions)}, ...
    'OutputFunctions',      {i_getArrayInfo(@i_getFunctionInterface, oSubIF.OutputFunctions)}, ...
    'UpdateFunctions',      {i_getArrayInfo(@i_getFunctionInterface, oSubIF.UpdateFunctions)}, ...
    'TerminateFunctions',   {i_getArrayInfo(@i_getFunctionInterface, oSubIF.TerminateFunctions)}, ...
    'TimingProperties',     {i_getArrayInfo(@i_getTimingInterface, oSubIF.TimingProperties)});
end


%%
function stInfo = i_getFunctionInterface(oFuncInterface)
stInfo = struct( ...
    'Prototype',     i_getOptionalInfo(@i_getPrototype, oFuncInterface.Prototype), ...
    'ActualReturn',  i_getOptionalInfo(@i_getDataInterface, oFuncInterface.ActualReturn), ...
    'VariantInfo',   i_getOptionalInfo(@i_getVariantInfo, oFuncInterface.VariantInfo), ...
    'FunctionOwner', i_getOptionalInfo(@i_getTypedRegion, oFuncInterface.FunctionOwner), ...
    'ActualArgs',    {i_getArrayInfo(@i_getDataInterface, oFuncInterface.ActualArgs)}, ...
    'DirectReads',   {i_getArrayInfo(@i_getDataInterface, oFuncInterface.DirectReads)}, ...
    'DirectWrites',  {i_getArrayInfo(@i_getDataInterface, oFuncInterface.DirectWrites)}, ...
    'Timing',        i_getOptionalInfo(@i_getTimingInterface, oFuncInterface.Timing));
end


%%
function stInfo = i_getTimingInterface(oTimingIF)
stInfo = struct( ...
    'TimingMode',               oTimingIF.TimingMode, ...
    'NonFcnCallPartitionName',  oTimingIF.NonFcnCallPartitionName, ...
    'SamplePeriod',             oTimingIF.SamplePeriod, ...
    'SampleOffset',             oTimingIF.SampleOffset, ...
    'Priority',                 oTimingIF.Priority, ...
    'TaskingMode',              oTimingIF.TaskingMode, ...
    'UnionTimingInfo',          {i_getArrayInfo(@i_getTimingInterface, oTimingIF.UnionTimingInfo)});
end


%%
function stInfo = i_getPrototype(oProto)
stInfo = struct( ...
    'Name',       oProto.Name, ...
    'HeaderFile', oProto.HeaderFile, ...
    'SourceFile', oProto.SourceFile, ...
    'Return',     i_getOptionalInfo(@i_getArgument, oProto.Return), ...
    'Arguments',  {i_getArrayInfo(@i_getArgument, oProto.Arguments)});
end


%%
function stInfo = i_getArgument(oArg)
stInfo = struct( ...
    'Name',   oArg.Name, ...
    'IOType', oArg.IOType, ...
    'Type',   i_getType(oArg.Type, true));
end


%%
function stInfo = i_getTypedRegion(oTypedRegion)
sClass = i_getShortClass(oTypedRegion);
switch sClass
    case 'Variable'
        stInfo = i_getVariable(oTypedRegion);
        
    otherwise
        error('UNDER:CONSTRUCTION', 'Found unknown TypedRegion subtype "%s".', sClass);
end
casFields = fieldnames(stInfo);
stInfo.class = sClass;
stInfo = orderfields(stInfo, [{'class'}, reshape(casFields, 1, [])]);
end


%%
function stInfo = i_getDataImplementation(oData)
if ~isempty(oData)
    error('UNDER:CONSTRUCTION', 'Non-empty DataImplementation found. Analysis must be extended.')
end

% nothing yet since the object is always empty (maybe an extension-point by MathWorks for later releases)
stInfo = struct();
end


%%
function stInfo = i_getDataInterface(oIO)
sClass = i_getShortClass(oIO);
stInfo = struct( ...
    'class',          sClass, ...
    'Name',           oIO.GraphicalName, ...
    'SID',            oIO.SID, ...
    'Type',           i_getOptionalInfo(@i_getType, oIO.Type, true), ...
    'Implementation', i_getImplementation(oIO.Implementation), ...
    'VariantInfo',    i_getOptionalInfo(@i_getVariantInfo, oIO.VariantInfo), ...
    'Timing',         i_getOptionalInfo(@i_getTimingInterface, oIO.Timing), ...
    'Range',          i_getOptionalInfo(@i_getRange, oIO.Range));
switch sClass
    case 'LookupTableDataInterface'
        stInfo.SupportTunableSize      = oIO.SupportTunableSize;
        stInfo.BreakpointSpecification = oIO.BreakpointSpecification;
        stInfo.Output                  = i_getOptionalInfo(@i_getDataInterface, oIO.Output);
        stInfo.Breakpoints             = i_getArrayInfo(@i_getDataInterface, oIO.Breakpoints);
        
    case 'ReadWriteDataInterface'
        stInfo.DataReads  = i_getArrayInfo(@i_getTimingInterface, oIO.DataReads);
        stInfo.DataWrites = i_getArrayInfo(@i_getTimingInterface, oIO.DataWrites);
        
    case 'BreakpointDataInterface'
        stInfo.OperatingPoint     = i_getOptionalInfo(@i_getDataInterface, oIO.OperatingPoint);
        stInfo.SupportTunableSize = oIO.SupportTunableSize;
        if ~isempty(oIO.FixAxisMetadata)
            error('UNDER:CONSTRUCTION', 'Non-empty FixAxisMetadata found.')
        end
        
    case {'DataInterface', 'MessageDataInterface'}
        % nothing more to add (just the basic stuff)
        
    otherwise
        error('UNDER:CONSTRUCTION', 'Found unknown DataInterface subtype "%s".', sClass);
end
end


%%
function stInfo = i_getRange(oRange)
stInfo = struct( ...
    'Min', oRange.Min, ...
    'Max', oRange.Max);
end


%%
function stInfo = i_getType(oType, bFullInfo)
if (nargin < 2)
    bFullInfo = false;
end
stInfo = [];

if ~isempty(oType)
    sClass = i_getShortClass(oType);
    stInfo = struct( ...
        'class',      sClass, ...
        'Identifier', oType.Identifier, ...
        'Name',       oType.Name, ...
        'ReadOnly',   oType.ReadOnly, ...
        'Volatile',   oType.Volatile);
    switch sClass
        case {'Bool', 'Integer', 'Double', 'Single', 'Half'}
            stInfo.Signedness = i_isSignedType(oType);
            
        case 'Fixed'
            stInfo.Signedness = i_isSignedType(oType);
            stInfo.Bias       = oType.Bias;
            stInfo.Slope      = oType.Slope;
            
        case 'Pointer'
            stInfo.BaseType = i_getType(oType.BaseType, true);
            
        case 'Matrix'
            if verLessThan('matlab', '9.14')
                stInfo.Dimensions = num2str(oType.Dimensions.toArray);
            else
                stInfo.Dimensions = num2str(oType.Dimensions);
            end
            stInfo.BaseType   = i_getType(oType.BaseType, true);
            
        case 'Struct'
            if bFullInfo
                if verLessThan('matlab', '9.13')
                    astElems = arrayfun( ...
                        @(o) struct('Identifier', o.Identifier, 'Type', i_getType(o.Type)), ...
                        oType.Elements.toArray);
                else
                    astElems = arrayfun( ...
                        @(o) struct('Identifier', o.Identifier, 'Type', i_getType(o.Type)), oType.Elements);
                end
                stInfo.Elements = astElems;
            end
            
        case 'Enum'
            stInfo.Strings = oType.Strings.toArray;
            stInfo.Values  = oType.Values.toArray;
            
        case 'Class'
            if bFullInfo
                astElems = arrayfun( ...
                    @(o) struct('Identifier', o.Identifier, 'Type', i_getType(o.Type)), ...
                    oType.Elements.toArray);
                astMethods = arrayfun(@i_getClassMethod, oType.Methods.toArray);
                stInfo.Elements = astElems;
                stInfo.Methods = astMethods;
            end
            
        case 'Opaque'
            % nothing special to add
            
        otherwise
            error('UNDER:CONSTRUCTION', 'Found unknown Type subtype "%s".', sClass);
    end
end
end


%%
function bIsSigned = i_isSignedType(oType)
persistent p_bIsLowML;
if isempty(p_bIsLowML)
    p_bIsLowML = verLessThan('matlab', '23.2'); %#ok<VERLESSMATLAB> -- everything below ML2023b is considered low ML
end

if p_bIsLowML
    bIsSigned = oType.Signedness;
else
    bIsSigned = oType.Signed;
end
end


%%
function stInfo = i_getClassMethod(oClassMethod)
stInfo = struct( ...
    'class',      i_getShortClass(oClassMethod), ...
    'Type',       i_getOptionalInfo(@i_getType, oClassMethod.Type), ...
    'Name',       oClassMethod.Name, ...
    'ReadOnly',   oClassMethod.ReadOnly, ...
    'Volatile',   oClassMethod.Volatile, ...
    'Arguments',  {i_getArrayInfo(@i_getArgument, oClassMethod.Arguments)});
end


%%
function stInfo = i_getVariantInfo(oVariantInfo)
stInfo = struct( ...
    'MATLABVariantCondition',   oVariantInfo.MATLABVariantCondition, ...
    'CodeVariantCondition',     oVariantInfo.CodeVariantCondition, ...
    'StartupVariantCCondition', oVariantInfo.StartupVariantCCondition, ...
    'VariantActive',            oVariantInfo.VariantActive);
end


%%
function stInfo = i_getImplementation(oImpl)
sClass = i_getShortClass(oImpl);

switch sClass
    case 'Variable'
        stInfo = i_getVariable(oImpl);
        
    case 'PointerVariable'
        stInfo = i_getVarPointer(oImpl);
        
    case 'ArrayExpression'
        stInfo = i_getArrayExpression(oImpl);
        
    case 'BasicAccessFunctionExpression'
        stInfo = i_getBasicAccessFunctionExpression(oImpl);
        
    case 'StructExpression'
        stInfo = i_getStructExpression(oImpl);
        
    case 'CustomExpression'
        stInfo = i_getCustomExpression(oImpl);
        
    case 'TypedCollection'
        stInfo = i_getTypedCollection(oImpl);
        
    case 'TypedRegion'
        stInfo = i_getTypedRegion(oImpl);
        
    case 'DataImplementation'
        stInfo = i_getDataImplementation(oImpl);
        
    case 'AutosarSenderReceiver'
        stInfo = i_getAutosarSenderReceiver(oImpl);
        
    case 'AutosarCalibration'
        stInfo = i_getAutosarCalibration(oImpl);
        
    case 'AutosarInterRunnable'
        stInfo = i_getAutosarInterRunnable(oImpl);
        
    case 'AutosarMemoryExpression'
        stInfo = i_getAutosarMemoryExpression(oImpl);
        
    case 'AutosarErrorStatus'
        stInfo = i_getAutosarErrorStatus(oImpl);
        
    case 'ClassMemberExpression'
        stInfo = i_getClassMemberExpression(oImpl);
        
    otherwise
        error('UNDER:CONSTRUCTION', 'Unknown implementation class "%s".', sClass);
end
casFields = fieldnames(stInfo);
stInfo.class = sClass;
stInfo = orderfields(stInfo, [{'class'}, reshape(casFields, 1, [])]);
end


%%
function sClass = i_getShortClass(oObj)
sFullClass = class(oObj);
sClass = regexprep(sFullClass, '.+[.]', ''); % remove the namespace from the class name
end


%%
function stInfo = i_getVariable(oVar)
stInfo = struct( ...
    'Type',             i_getType(oVar.Type), ...
    'CodeType',         i_getType(oVar.CodeType), ...
    'VarOwner',         oVar.VarOwner, ...
    'Identifier',       oVar.Identifier, ...
    'Variant',          oVar.Variant, ...
    'DeclarationFile',  oVar.DeclarationFile, ...
    'DefinitionFile',   oVar.DefinitionFile, ...
    'StorageSpecifier', oVar.StorageSpecifier);
end


%%
% subclass of coder.descriptor.Variable
function stInfo = i_getVarPointer(oVarPointer)
stInfo = i_getVariable(oVarPointer);
stInfo.TargetVariable = i_getVariable(oVarPointer.TargetVariable);
end


%%
function stInfo = i_getBasicAccessFunctionExpression(oExp)
stInfo = struct( ...
    'Type',         i_getType(oExp.Type), ...
    'CodeType',     i_getType(oExp.CodeType), ...
    'IOAccessMode', oExp.IOAccessMode, ...
    'Prototype',    i_getPrototype(oExp.Prototype));
end


%%
function stInfo = i_getStructExpression(oExp)
stInfo = struct( ...
    'Type',               i_getType(oExp.Type), ...
    'CodeType',           i_getType(oExp.CodeType), ...
    'ElementIdentifier',  oExp.ElementIdentifier, ...
    'BaseRegion',         i_getImplementation(oExp.BaseRegion), ...
    'Variant',            oExp.Variant);
end


%%
function stInfo = i_getArrayExpression(oExp)
stInfo = struct( ...
    'Type',       i_getType(oExp.Type), ...
    'BaseRegion', i_getImplementation(oExp.BaseRegion), ...
    'Offset',     oExp.Offset);
end


%%
function stInfo = i_getCustomExpression(oExp)
stInfo = struct( ...
    'Type',                  i_getType(oExp.Type), ...
    'CodeType',              i_getOptionalInfo(@i_getType, oExp.CodeType), ...
    'ExprOwner',             oExp.ExprOwner, ...
    'HeaderFile',            oExp.HeaderFile, ...
    'ReadExpression',        oExp.ReadExpression, ...
    'WriteExpression',       oExp.WriteExpression, ...
    'InitializeExpression',  oExp.InitializeExpression, ...
    'AddressExpression',     oExp.AddressExpression, ...
    'DataElementIdentifier', oExp.DataElementIdentifier, ...
    'IsGetSet',              oExp.IsGetSet, ...
    'AccessViaMacro',        oExp.AccessViaMacro);
end


%%
function stInfo = i_getTypedCollection(oCollection)
stInfo = struct( ...
    'CollectionType',  char(oCollection.CollectionType), ... % MUX, VIRTUAL_BUS, UNKNOWN
    'Elements',        {i_getArrayInfo(@i_getElement, oCollection.Elements)}, ...
    'RegionOffset',    num2str(oCollection.RegionOffset.toArray), ...
    'RegionLength',    num2str(oCollection.RegionLength.toArray));
end


%%
function stInfo = i_getAutosarSenderReceiver(oSendRec)
stInfo = struct( ...
    'Type',            i_getType(oSendRec.Type), ...
    'DataAccessMode',  oSendRec.DataAccessMode, ...
    'Port',            oSendRec.Port, ...
    'Interface',       oSendRec.Interface, ...
    'DataElement',     oSendRec.DataElement);
end


%%
function stInfo = i_getAutosarCalibration(oCal)
stInfo = struct( ...
    'Type',                 i_getType(oCal.Type), ...
    'DataAccessMode',       oCal.DataAccessMode, ...
    'Port',                 oCal.Port, ...
    'InterfacePath',        oCal.InterfacePath, ...
    'ElementName',          oCal.ElementName, ...
    'Shared',               oCal.Shared, ...
    'CalibrationComponent', oCal.CalibrationComponent, ...
    'ProviderPortName',     oCal.ProviderPortName, ...
    'CoderDataGroupName',   oCal.CoderDataGroupName, ...
    'AccessMode',           oCal.AccessMode, ...
    'BaseRegion',           i_getImplementation(oCal.BaseRegion));
end


%%
function stInfo = i_getAutosarInterRunnable(oInterRun)
stInfo = struct( ...
    'Type',                 i_getType(oInterRun.Type), ...
    'DataAccessMode',       oInterRun.DataAccessMode, ...
    'VariableName',         oInterRun.VariableName, ...
    'InitialValue',         oInterRun.InitialValue);
end


%%
function stInfo = i_getAutosarMemoryExpression(oExpr)
stInfo = struct( ...
    'Type',               i_getType(oExpr.Type), ...
    'DataAccessMode',     oExpr.DataAccessMode, ...
    'VariableName',       oExpr.VariableName, ...
    'CoderDataGroupName', oExpr.CoderDataGroupName, ...
    'BaseRegion',         i_getImplementation(oExpr.BaseRegion));
end


%%
function stInfo = i_getClassMemberExpression(oExpr)
stInfo = struct( ...
    'Type',               i_getType(oExpr.Type), ...
    'CodeType',           i_getType(oExpr.CodeType), ...
    'Visibility',         oExpr.Visibility, ...
    'ElementIdentifier',  oExpr.ElementIdentifier, ...
    'Variant',            oExpr.Variant, ...
    'BaseRegion',         i_getImplementation(oExpr.BaseRegion));
end


%%
function stInfo = i_getAutosarErrorStatus(oErrStatus)
stInfo = struct( ...
    'Type',               i_getType(oErrStatus.Type), ...
    'DataAccessMode',     oErrStatus.DataAccessMode, ...
    'ReceiverPortNumber', oErrStatus.ReceiverPortNumber);
end


%%
function stInfo = i_getElement(oElem)
stInfo = i_getImplementation(oElem);
end


%%
function caoInfo = i_getArrayInfo(hEvalFunc, oSequence, varargin)
caoInfo = arrayfun(@(oObj) i_getOptionalInfo(hEvalFunc, oObj, varargin{:}), oSequence.toArray, 'uni', false);
end


%%
% robust handling when the optional oObj is empty
function stInfo = i_getOptionalInfo(hGetInfo, oObj, varargin)
stInfo = [];
if isempty(oObj)
    return;
end

try
    stInfo = feval(hGetInfo, oObj, varargin{:});
catch oEx
    stInfo.Error = oEx.getReport('basic', 'hyperlinks', 'off');
end
end
