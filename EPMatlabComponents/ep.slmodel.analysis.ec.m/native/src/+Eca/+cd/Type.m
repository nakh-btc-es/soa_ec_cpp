classdef Type < Eca.cd.Element
    methods
        function oObj = Type(oType, oCD)
            oObj = oObj@Eca.cd.Element(oType, oCD);
        end

        function sName = getName(oObj)
            sName = oObj.oElem_.Name;
        end

        function stInfo = getInfo(oObj, bFullInfo)
            if (nargin < 2)
                bFullInfo = false;
            end
            stInfo = i_getInfo(oObj, bFullInfo);
        end
    end

    methods (Hidden = true)
        function oNewType = createType(oObj, oNewTypeCD)
            oNewType = Eca.cd.Element.constructFromOptional(@Eca.cd.Type, oNewTypeCD, oObj.oCD_);
        end
    end
end


%%
function stInfo = i_getInfo(oObj, bFullInfo)
sClass = oObj.getClass();
oType = oObj.oElem_;

% base info, which is common for all type objects
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
        stInfo.BaseType = oObj.createType(oType.BaseType);

    case 'Reference'
        stInfo.BaseType = oObj.createType(oType.BaseType);

    case 'Matrix'
        stInfo.Dimensions = num2str(i_getArray(oType.Dimensions));
        stInfo.BaseType   = oObj.createType(oType.BaseType);

    case 'Struct'
        if bFullInfo
            astElems = arrayfun( ...
                @(o) struct('Identifier', o.Identifier, 'Type', oObj.createType(o.Type)), ...
                i_getArray(oType.Elements));
            stInfo.Elements = astElems;
        end

    case 'Enum'
        stInfo.Strings = i_getArray(oType.Strings);
        stInfo.Values  = i_getArray(oType.Values);

    case 'Class'
        if bFullInfo
            astElems = arrayfun( ...
                @(o) struct('Identifier', o.Identifier, 'Type', oObj.createType(o.Type)), ...
                i_getArray(oType.Elements));
            astMethods = arrayfun(@(o) i_getClassMethod(oObj, o), i_getArray(oType.Methods));
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
function stInfo = i_getClassMethod(oObj, oClassMethod)
stInfo = struct( ...
    'class',      oObj.getClass(oClassMethod), ...
    'Type',       oObj.createType(oClassMethod.Type), ...
    'Name',       oClassMethod.Name, ...
    'ReadOnly',   oClassMethod.ReadOnly, ...
    'Volatile',   oClassMethod.Volatile, ...
    'Arguments',  Eca.cd.Element.constructFromSequence(@Eca.cd.Argument, oClassMethod.Arguments, oObj.oCD_));
end

