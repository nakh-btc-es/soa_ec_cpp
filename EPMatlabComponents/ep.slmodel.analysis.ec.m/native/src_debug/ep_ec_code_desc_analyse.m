function [castInfos, sInfoAsString] = ep_ec_code_desc_analyse(sModel)
if (nargin < 1)
    sModel = bdroot;
end

fprintf('Analysing model: %s\n', sModel);
oCD = coder.getCodeDescriptor(sModel);

castInfos = {i_getModelLevelInfo(oCD)};

oRefModelCDs = i_getRefModelCDs(oCD);
castSubInfos = cellfun(@i_getModelLevelInfo, oRefModelCDs.values, 'uni', false);
castInfos = [castInfos, reshape(castSubInfos, 1, [])];

sInfoAsString = jsonencode(castInfos, 'PrettyPrint', true);
if (nargout < 2)
    sFile = fullfile(pwd, 'ana.json');
    i_toFile(sInfoAsString, sFile);
end
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
function stInfo = i_getModelLevelInfo(oCD)
oCompIF = oCD.getFullComponentInterface;

stInfo = struct( ...
    'Name',                 oCompIF.Name, ...
    'GraphicalPath',        oCompIF.GraphicalPath, ...
    'ModelData',            {i_getArrayInfo(@i_getDataInterface, oCompIF.ModelData)}, ...
    'AllocationFunction',   {i_getArrayInfo(@i_getFunctionInterface, oCompIF.AllocationFunction)}, ...
    'ConstructorFunction',  {i_getArrayInfo(@i_getFunctionInterface, oCompIF.ConstructorFunction)}, ...
    'SetupRuntimeResFct',   {i_getArrayInfo(@i_getFunctionInterface, oCompIF.SetupRuntimeResourcesFunction)}, ...
    'CleanupRuntimeResFct', {i_getArrayInfo(@i_getFunctionInterface, oCompIF.CleanupRuntimeResourcesFunction)}, ...
    'EventsFunction',       {i_getArrayInfo(@i_getFunctionInterface, oCompIF.EventsFunction)}, ...
    'DerivativeFunction',   {i_getArrayInfo(@i_getFunctionInterface, oCompIF.DerivativeFunction)}, ...
    'InitConditionsFct',    {i_getArrayInfo(@i_getFunctionInterface, oCompIF.InitConditionsFunction)}, ...
    'SystemInitializeFct',  {i_getArrayInfo(@i_getFunctionInterface, oCompIF.SystemInitializeFunction)}, ...
    'SystemResetFunction',  {i_getArrayInfo(@i_getFunctionInterface, oCompIF.SystemResetFunction)}, ...
    'HeaderFile',           oCompIF.HeaderFile, ...
    'SourceFile',           oCompIF.SourceFile, ...
    'ModelRefUtilFctDef',   oCompIF.ModelRefUtilityFunctionDefinitions, ...
    'ArrayLayout',          oCD.getArrayLayout, ...
    'Inports',              {i_getArrayInfo(@i_getDataInterface, oCompIF.Inports)}, ...
    'Outports',             {i_getArrayInfo(@i_getDataInterface, oCompIF.Outports)}, ...
    'Parameters',           {i_getArrayInfo(@i_getDataInterface, oCompIF.Parameters)}, ...
    'DataStores',           {i_getArrayInfo(@i_getDataInterface, oCompIF.DataStores)}, ...
    'InternalData',         {i_getArrayInfo(@i_getDataInterface, oCompIF.InternalData)}, ...
    'ExternalBlockOutputs', {i_getArrayInfo(@i_getDataInterface, oCompIF.ExternalBlockOutputs)}, ...     
    'GlobalBlockOutputs',   {i_getArrayInfo(@i_getDataInterface, oCompIF.GlobalBlockOutputs)}, ...
    'ConstantBlockOutputs', {i_getArrayInfo(@i_getDataInterface, oCompIF.ConstantBlockOutputs)}, ...
    'DWorks',               {i_getArrayInfo(@i_getDataInterface, oCompIF.DWorks)}, ...
    'ContinuousStates',     {i_getArrayInfo(@i_getDataInterface, oCompIF.ContinuousStates)}, ...
    'NonSampledZeroCross',  {i_getArrayInfo(@i_getDataInterface, oCompIF.NonSampledZeroCrossings)}, ...
    'ZeroCrossingEvents',   {i_getArrayInfo(@i_getDataInterface, oCompIF.ZeroCrossingEvents)}, ...
    'InitializeFunctions',  {i_getArrayInfo(@i_getFunctionInterface, oCompIF.InitializeFunctions)}, ...
    'OutputFunctions',      {i_getArrayInfo(@i_getFunctionInterface, oCompIF.OutputFunctions)}, ...
    'UpdateFunctions',      {i_getArrayInfo(@i_getFunctionInterface, oCompIF.UpdateFunctions)}, ...
    'TerminateFunctions',   {i_getArrayInfo(@i_getFunctionInterface, oCompIF.TerminateFunctions)}, ...
    'ServerCallPoints',     {i_getArrayInfo(@i_getServerCallPoint, oCompIF.ServerCallPoints)}, ...
    'Subsystems',           {i_getArrayInfo(@i_getSubsystemInterface, oCompIF.Subsystems)}, ...
    'TimingProperties',     {i_getArrayInfo(@i_getTimingInterface, oCompIF.TimingProperties)}, ...
    'Types',                {i_getArrayInfo(@i_getType, oCompIF.Types)}, ...
    'EnableFunction',       {i_getArrayInfo(@i_getFunctionInterface, oCompIF.EnableFunction)}, ...
    'DisableFunction',      {i_getArrayInfo(@i_getFunctionInterface, oCompIF.DisableFunction)}, ...
    'SkippedSubInterfInfo', i_getSkippedSubsystemInterfaceInfo(oCompIF.SkippedSubsystemInterfaceInfo), ...
    'PlatformDataTypes',    {i_getArrayInfo(@i_getPlatformType, oCompIF.PlatformDataTypes)}, ...
    'Code',                 i_getCodeInfo(oCompIF.Code), ... %    'GlobalSymbolNodes',    {i_getArrayInfo(@i_getGlobalSymbolNode, oCompIF.GlobalSymbolNodes)}, ...
    'refModelNames',        {oCD.getReferencedModelNames});
end


%%
function stCode = i_getCodeInfo(oCode)
stCode = struct( ...
    'Types',                       {i_getArrayInfo(@i_getType, oCode.Types)}, ...
    'GlobalVariables',             {i_getArrayInfo(@i_getVariable, oCode.GlobalVariables)}, ...
    'MutuallyExclusiveVariables',  {i_getArray(oCode.MutuallyExclusiveVariables)});
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
function stInfo = i_getServerCallPoint(oSCP)
sClass = i_getShortClass(oSCP);
switch sClass
    case 'AutosarClientCall'
        stInfo = struct( ...
            'class',                sClass, ...
            'PortName',             oSCP.PortName, ...
            'SID',                  oSCP.SID, ...
            'Prototype',            i_getOptionalInfo(@i_getPrototype, oSCP.Prototype), ...
            'Timing',               i_getOptionalInfo(@i_getTimingInterface, oSCP.Timing), ...
            'SimulinkFunctionName', oSCP.SimulinkFunctionName);

    otherwise
        error('UNDER:CONSTRUCTION', 'Unknown ServerCallPoint found: "%s".', sClass);
end
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
if isempty(oTypedRegion)
    stInfo = struct();
    return;
end

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
    'Unit',           oIO.Unit, ...
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
function stInfo = i_getGlobalSymbolNode(oSymbol)
stInfo = struct( ...
    'Name',        oSymbol.Name, ...
    'HeaderFiles', {i_getArray(oSymbol.HeaderFiles)});
end


%%
function stInfo = i_getPlatformType(oPlatformType)

sClass = i_getShortClass(oPlatformType);
stInfo = struct( ...
    'class',                     sClass, ...
    'Name',                      oPlatformType.Name, ...
    'Symbol',                    oPlatformType.Symbol, ...
    'SymbolMin',                 oPlatformType.SymbolMin, ...
    'SymbolMax',                 oPlatformType.SymbolMax, ...
    'FixedWidthIntegerWordLen',  oPlatformType.FixedWidthIntegerWordLen, ...
    'Signed',                    oPlatformType.Signed, ...
    'ReplacementHeader',         oPlatformType.ReplacementHeader, ...
    'ReplacementBaseType',       oPlatformType.ReplacementBaseType);

if verLessThan('matlab', '24.2') %#ok
    stInfo.sReplacementSymbol = oPlatformType.ReplacementSymbol;
else
    stInfo.sReplacementSymbol = oPlatformType.CoderTypedefReplacementSymbol;
end
end


%%
function stInfo = i_getType(oType, bFullInfo)
if (nargin < 2)
    bFullInfo = false;
end

if isempty(oType)
    stInfo = [];
    return;
end

sClass = i_getShortClass(oType);
stInfo = struct( ...
    'class',      sClass, ...
    'Identifier', oType.Identifier, ...
    'Name',       oType.Name, ...
    'ReadOnly',   oType.ReadOnly, ...
    'Volatile',   oType.Volatile);

switch sClass
    case {'Bool', 'Integer', 'Double', 'Single', 'Half', 'Char'}
        stInfo.Signedness = i_isSignedType(oType);

    case 'Fixed'
        stInfo.Signedness = i_isSignedType(oType);
        stInfo.Bias       = oType.Bias;
        stInfo.Slope      = oType.Slope;

    case 'Pointer'
        stInfo.BaseType = i_getType(oType.BaseType, true);

    case 'Reference'
        stInfo.BaseType = i_getType(oType.BaseType, true);

    case 'Matrix'
        stInfo.Dimensions = num2str(i_getArray(oType.Dimensions));
        stInfo.BaseType   = i_getType(oType.BaseType, true);

    case 'Struct'
        if bFullInfo
            astElems = arrayfun( ...
                @(o) struct('Identifier', o.Identifier, 'Type', i_getType(o.Type)), ...
                i_getArray(oType.Elements));
            stInfo.Elements = astElems;
        end

    case 'Enum'
        stInfo.Strings = i_getArray(oType.Strings);
        stInfo.Values  = i_getArray(oType.Values);

    case 'Class'
        if bFullInfo
            astElems = arrayfun( ...
                @(o) struct('Identifier', o.Identifier, 'Type', i_getType(o.Type)), ...
                i_getArray(oType.Elements));
            astMethods = arrayfun(@i_getClassMethod, i_getArray(oType.Methods));
            stInfo.Elements = astElems;
            stInfo.Methods = astMethods;
        end

    case 'Opaque'
        % nothing special to add

    otherwise
        error('UNDER:CONSTRUCTION', 'Found unknown Type subtype "%s".', sClass);
end
end


%%
function xArray = i_getArray(xAggregateObj)
persistent p_bIsLowML;
if isempty(p_bIsLowML)
    p_bIsLowML = verLessThan('matlab', '23.2'); %#ok<VERLESSMATLAB> -- everything below ML2023b is considered low ML
end

if p_bIsLowML
    xArray = xAggregateObj.toArray;
else
    try
        xArray = xAggregateObj.toArray();

    catch oEx %#ok<NASGU>
        xArray = xAggregateObj;
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
        stInfo = i_getPointerVariable(oImpl);

    case 'StructAccessorVariable'
        stInfo = i_getStructAccessorVariable(oImpl);

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

    case 'ClassMethodExpression'
        stInfo = i_getClassMethodExpression(oImpl);

    case 'Literal'
        stInfo = i_getLiteral(oImpl);

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
function stInfo = i_getPointerVariable(oVarPointer)
stInfo = i_getVariable(oVarPointer);
stInfo.TargetVariable = i_getVariable(oVarPointer.TargetVariable);
end


%%
% subclass of coder.descriptor.Variable
function stInfo = i_getStructAccessorVariable(oVar)
stInfo = i_getVariable(oVar);
stInfo.Accessor = i_getImplementation(oVar.Accessor);
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
    'RegionOffset',    num2str(i_getArray(oCollection.RegionOffset)), ...
    'RegionLength',    num2str(i_getArray(oCollection.RegionLength)));
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
function stInfo = i_getClassMethodExpression(oExpr)
stInfo = struct( ...
    'Type',        i_getType(oExpr.Type), ...
    'CodeType',    i_getType(oExpr.CodeType), ...
    'Getter',      oExpr.Getter, ...
    'Setter',      oExpr.Setter, ...
    'BaseRegion',  i_getImplementation(oExpr.BaseRegion));
end


%%
function stInfo = i_getLiteral(oLit)
stInfo = struct( ...
    'Type',      i_getType(oLit.Type), ...
    'CodeType',  i_getType(oLit.CodeType), ...
    'Value',     oLit.Value);
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
function i_toFile(sString, sFile)
hFid = fopen(sFile, 'wt');
fprintf(hFid, '%s\n', sString);
fclose(hFid);
end


%%
function caoInfo = i_getArrayInfo(hEvalFunc, oSequence, varargin)
caoInfo = arrayfun(@(oObj) i_getOptionalInfo(hEvalFunc, oObj, varargin{:}), i_getArray(oSequence), 'uni', false);
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


%%
function stInfo = i_getSkippedSubsystemInterfaceInfo(oSkippedSubsystemInterfaceInfo)
stInfo = struct( ...
    'SubsystemPath',     keys(oSkippedSubsystemInterfaceInfo));
end
