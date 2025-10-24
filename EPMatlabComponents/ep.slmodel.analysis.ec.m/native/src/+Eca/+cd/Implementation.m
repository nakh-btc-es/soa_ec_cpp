classdef Implementation < Eca.cd.Element
    methods
        function oObj = Implementation(oImpl, oCD)
            oObj = oObj@Eca.cd.Element(oImpl, oCD);
        end
        
        function stInfo = getInfo(oObj)
            stInfo = i_getInfo(oObj);
        end
    end

    methods (Hidden = true)
        function oNewImpl = createImplementation(oObj, oNewImplCD)
            oNewImpl = Eca.cd.Element.constructFromOptional(@Eca.cd.Implementation, oNewImplCD, oObj.oCD_);
        end

        function oNewType = createType(oObj, oNewTypeCD)
            oNewType = Eca.cd.Element.constructFromOptional(@Eca.cd.Type, oNewTypeCD, oObj.oCD_);
        end
    end
end


%%
function stInfo = i_getInfo(oObj)
sClass = oObj.getClass();
switch sClass
    case 'Variable'
        stInfo = i_getVariable(oObj);

    case 'PointerVariable'
        stInfo = i_getPointerVariable(oObj);

    case 'StructAccessorVariable'
        stInfo = i_getStructAccessorVariable(oObj);

    case 'ArrayExpression'
        stInfo = i_getArrayExpression(oObj);

    case 'BasicAccessFunctionExpression'
        stInfo = i_getBasicAccessFunctionExpression(oObj);
        
    case 'StructExpression'
        stInfo = i_getStructExpression(oObj);
        
    case 'CustomExpression'
        stInfo = i_getCustomExpression(oObj);

    case 'TypedCollection'
        stInfo = i_getTypedCollection(oObj);

    case 'TypedRegion'
        stInfo = i_getTypedRegion(oObj);

    case 'DataImplementation'
        stInfo = i_getDataImplementation(oObj);

    case 'AutosarSenderReceiver'
        stInfo = i_getAutosarSenderReceiver(oObj);

    case 'AutosarCalibration'
        stInfo = i_getAutosarCalibration(oObj);

    case 'AutosarInterRunnable'
        stInfo = i_getAutosarInterRunnable(oObj);

    case 'AutosarMemoryExpression'
        stInfo = i_getAutosarMemoryExpression(oObj);

    case 'AutosarErrorStatus'
        stInfo = i_getAutosarErrorStatus(oObj);

    case 'ClassMemberExpression'
        stInfo = i_getClassMemberExpression(oObj);

    case 'ClassMethodExpression'
        stInfo = i_getClassMethodExpression(oObj);

    case 'Literal'
        stInfo = i_getLiteral(oObj);

    otherwise
        error('UNDER:CONSTRUCTION', 'Unknown implementation class "%s".', sClass);
end
casFields = fieldnames(stInfo);
stInfo.class = sClass;
stInfo = orderfields(stInfo, [{'class'}, reshape(casFields, 1, [])]);
end


%%
function stInfo = i_getVariable(oObj, oVar)
if (nargin < 2)
    oVar = oObj.oElem_;
end
stInfo = struct( ...
    'Type',             oObj.createType(oVar.Type), ...
    'CodeType',         oObj.createType(oVar.CodeType), ...
    'VarOwner',         oVar.VarOwner, ...
    'Identifier',       oVar.Identifier, ...
    'Variant',          oVar.Variant, ...
    'DeclarationFile',  oVar.DeclarationFile, ...
    'DefinitionFile',   oVar.DefinitionFile, ...
    'StorageSpecifier', oVar.StorageSpecifier);
end


%%
% subclass of coder.descriptor.Variable
function stInfo = i_getPointerVariable(oObj)
stInfo = i_getVariable(oObj);
stInfo.TargetVariable = i_getVariable(oObj, oObj.oElem_.TargetVariable);
end


%%
% subclass of coder.descriptor.Variable
function stInfo = i_getStructAccessorVariable(oObj)
oVar = oObj.oElem_;
stInfo = i_getVariable(oObj);
stInfo.Accessor = oObj.createImplementation(oVar.Accessor);
end


%%
function stInfo = i_getArrayExpression(oObj)
oExp = oObj.oElem_;
stInfo = struct( ...
    'Type',       i_getType(oExp.Type), ...
    'BaseRegion', oObj.createImplementation(oExp.BaseRegion), ...
    'Offset',     oExp.Offset);
end


%%
function stInfo = i_getBasicAccessFunctionExpression(oObj)
oExp = oObj.oElem_;
stInfo = struct( ...
    'Type',         oObj.createType(oExp.Type), ...
    'CodeType',     oObj.createType(oExp.CodeType), ...
    'IOAccessMode', oExp.IOAccessMode, ...
    'Prototype',    i_getPrototype(oObj, oExp.Prototype));
end


%%
function stInfo = i_getStructExpression(oObj)
oExp = oObj.oElem_;
stInfo = struct( ...
    'Type',               oObj.createType(oExp.Type), ...
    'CodeType',           oObj.createType(oExp.CodeType), ...
    'ElementIdentifier',  oExp.ElementIdentifier, ...
    'BaseRegion',         oObj.createImplementation(oExp.BaseRegion), ...
    'Variant',            oExp.Variant);
end


%%
function stInfo = i_getCustomExpression(oObj)
oExp = oObj.oElem_;
stInfo = struct( ...
    'Type',                  oObj.createType(oExp.Type), ...
    'CodeType',              oObj.createType(oExp.CodeType), ...
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
function stInfo = i_getTypedCollection(oObj)
oCollection = oObj.oElem_;
stInfo = struct( ...
    'CollectionType',  char(oCollection.CollectionType), ... % MUX, VIRTUAL_BUS, UNKNOWN
    'Elements',        {i_getArrayInfo(@(e) oObj.createImplementation(e), oCollection.Elements)}, ...
    'RegionOffset',    num2str(i_getArray(oCollection.RegionOffset)), ...
    'RegionLength',    num2str(i_getArray(oCollection.RegionLength)));
end


%%
function stInfo = i_getTypedRegion(oObj)
oTypedRegion = oObj.oElem_;
if isempty(oTypedRegion)
    stInfo = struct();
    return;
end

sClass = oObj.getClass(oTypedRegion);
switch sClass
    case 'Variable'
        stInfo = i_getVariable(oObj, oTypedRegion);

    otherwise
        error('UNDER:CONSTRUCTION', 'Found unknown TypedRegion subtype "%s".', sClass);
end
casFields = fieldnames(stInfo);
stInfo.class = sClass;
stInfo = orderfields(stInfo, [{'class'}, reshape(casFields, 1, [])]);
end


%%
function stInfo = i_getDataImplementation(oObj)
oData = oObj.oElem_;
if ~isempty(oData)
    error('UNDER:CONSTRUCTION', 'Non-empty DataImplementation found. Analysis must be extended.')
end

% nothing yet since the object is always empty (maybe an extension-point by MathWorks for later releases)
stInfo = struct();
end


%%
function stInfo = i_getAutosarSenderReceiver(oObj)
oSendRec = oObj.oElem_;
stInfo = struct( ...
    'Type',            oObj.createType(oSendRec.Type), ...
    'DataAccessMode',  oSendRec.DataAccessMode, ...
    'Port',            oSendRec.Port, ...
    'Interface',       oSendRec.Interface, ...
    'DataElement',     oSendRec.DataElement);
end


%%
function stInfo = i_getAutosarCalibration(oObj)
oCal = oObj.oElem_;
stInfo = struct( ...
    'Type',                 oObj.createType(oCal.Type), ...
    'DataAccessMode',       oCal.DataAccessMode, ...
    'Port',                 oCal.Port, ...
    'InterfacePath',        oCal.InterfacePath, ...
    'ElementName',          oCal.ElementName, ...
    'Shared',               oCal.Shared, ...
    'CalibrationComponent', oCal.CalibrationComponent, ...
    'ProviderPortName',     oCal.ProviderPortName, ...
    'CoderDataGroupName',   oCal.CoderDataGroupName, ...
    'AccessMode',           oCal.AccessMode, ...
    'BaseRegion',           oObj.createImplementation(oCal.BaseRegion));
end


%%
function stInfo = i_getAutosarInterRunnable(oObj)
oInterRun = oObj.oElem_;
stInfo = struct( ...
    'Type',                 oObj.createType(oInterRun.Type), ...
    'DataAccessMode',       oInterRun.DataAccessMode, ...
    'VariableName',         oInterRun.VariableName, ...
    'InitialValue',         oInterRun.InitialValue);
end


%%
function stInfo = i_getAutosarMemoryExpression(oObj)
oExpr = oObj.oElem_;
stInfo = struct( ...
    'Type',               oObj.createType(oExpr.Type), ...
    'DataAccessMode',     oExpr.DataAccessMode, ...
    'VariableName',       oExpr.VariableName, ...
    'CoderDataGroupName', oExpr.CoderDataGroupName, ...
    'BaseRegion',         oObj.createImplementation(oExpr.BaseRegion));
end


%%
function stInfo = i_getAutosarErrorStatus(oObj)
oErrStatus = oObj.oElem_;
stInfo = struct( ...
    'Type',               oObj.createType(oErrStatus.Type), ...
    'DataAccessMode',     oErrStatus.DataAccessMode, ...
    'ReceiverPortNumber', oErrStatus.ReceiverPortNumber);
end


%%
function stInfo = i_getClassMemberExpression(oObj)
oExpr = oObj.oElem_;
stInfo = struct( ...
    'Type',               oObj.createType(oExpr.Type), ...
    'CodeType',           oObj.createType(oExpr.CodeType), ...
    'Visibility',         oExpr.Visibility, ...
    'ElementIdentifier',  oExpr.ElementIdentifier, ...
    'Variant',            oExpr.Variant, ...
    'BaseRegion',         oObj.createImplementation(oExpr.BaseRegion));
end


%%
function stInfo = i_getClassMethodExpression(oObj)
oExpr = oObj.oElem_;
stInfo = struct( ...
    'Type',        oObj.createType(oExpr.Type), ...
    'CodeType',    oObj.createType(oExpr.CodeType), ...
    'Getter',      oExpr.Getter, ...
    'Setter',      oExpr.Setter, ...
    'BaseRegion',  oObj.createImplementation(oExpr.BaseRegion));
end


%%
function stInfo = i_getLiteral(oObj)
oLit = oObj.oElem_;
stInfo = struct( ...
    'Type',      oObj.createType(oLit.Type), ...
    'CodeType',  oObj.createType(oLit.CodeType), ...
    'Value',     oLit.Value);
end


%%
function stInfo = i_getPrototype(oObj, oProto)
stInfo = struct( ...
    'Name',       oProto.Name, ...
    'HeaderFile', oProto.HeaderFile, ...
    'SourceFile', oProto.SourceFile, ...
    'Return',     Eca.cd.Element.constructFromOptional(@Eca.cd.Argument, oProto.Return, oObj.oCD_), ...
    'Arguments',  {Eca.cd.Element.constructFromSequence(@Eca.cd.Argument, oProto.Arguments, oObj.oCD_)});
end


%%
function xArray = i_getArray(xAggregateObj)
persistent p_bIsLowML;
if isempty(p_bIsLowML)
    p_bIsLowML = verLessThan('matlab', '23.2');
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
