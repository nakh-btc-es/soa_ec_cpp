function [oItf, oEx] = getSignalProperties(oItf, oDataObject)
oEx = [];

try
    if ~isempty(oDataObject)
        oItf.dataClass = class(oDataObject);
        if strcmp(oDataObject.StorageClass, 'Custom')
            oItf.storageClass = [oDataObject.CustomStorageClass '(Custom)'];
        else
            oItf.storageClass = oDataObject.StorageClass;
        end
        
        oItf.alias = i_getAliasName(oDataObject);
    end   
    
    oItf = i_getSimulinkDataType(oItf, oDataObject);
    oItf = i_getCCodeDatatype(oItf);
    oItf = i_getScaling(oItf);
    oItf = i_getDimensions(oItf, oDataObject);
    oItf = i_getMinMax(oItf, oDataObject);
    
catch oEx
end
end


%%
function sAliasName = i_getAliasName(oDataObject)
sAliasName = '';
try %#ok<TRYNC>
    if (isa(oDataObject, 'Simulink.Signal') || isa(oDataObject, 'Simulink.Parameter'))
        sAliasName = oDataObject.CoderInfo.Alias;
    end
end
end


%%
function oItf = i_getCCodeDatatype(oItf)
sDataType = oItf.sldatatype;

%BaseType native names
baseTypes.int8    = 'int8_T';
baseTypes.int16   = 'int16_T';
baseTypes.int32   = 'int32_T';
baseTypes.uint8   = 'uint8_T';
baseTypes.uint16  = 'uint16_T';
baseTypes.uint32  = 'uint32_T';
baseTypes.boolean = 'boolean_T';
baseTypes.single  = 'real32_T';
baseTypes.double  = 'real_T';

cs = getActiveConfigSet(oItf.getBdroot());
%Data type replacement defined in Model configSettings

stCurrentWarnState = warning('off');
oOnCleanupRestoreWarnState = onCleanup(@() warning(stCurrentWarnState));

try %#ok<TRYNC>
    if strcmp(get_param(cs, 'EnableUserReplacementTypes'), 'on')
        stReplacement = get_param(cs, 'ReplacementTypes');
        casReplacedTypes = fieldnames(stReplacement);
        for k = 1:numel(casReplacedTypes)
            sReplacedType = casReplacedTypes{k};
            
            if isfield(baseTypes, sReplacedType)
                sNewValue = stReplacement.(sReplacedType);
                if ~isempty(sNewValue)
                    baseTypes.(sReplacedType) = sNewValue;
                end
            end
        end
    end
end
oItf.codedatatype = i_transferToCodeDataType(sDataType, oItf, baseTypes);
end


%%
function sCodeDataType = i_transferToCodeDataType(sDataType, oItf, baseTypes)
if ismember(sDataType, {'boolean', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'single', 'double'})
    sCodeDataType = baseTypes.(sDataType);
    return;
end

if strcmp(sDataType, 'auto')
    sCodeDataType = 'AUTO';
    return;
end

sDataType = regexprep(sDataType, '^Enum:\s*', '');
if ~isempty(enumeration(sDataType))
    sCodeDataType = sDataType;
    try %#ok<TRYNC>
        sStorageType = Simulink.data.getEnumTypeInfo(sCodeDataType, 'StorageType');
        if ~strcmp(sStorageType, 'int')
            sCodeDataType = i_transferToCodeDataType(sStorageType, oItf, baseTypes);
        end
    end
    return;
end

% Expect an AliasType or a NumericType
try
    oNumOrAliasType = oItf.evalinGlobal(sDataType);
catch
    oNumOrAliasType = [];
end

%Try to evaluation from compiled fixed-point string representation (eg. sfix16_En1_B1)
if isempty(oNumOrAliasType)
    try
        oNumOrAliasType = fixdt(sDataType);
    catch
        oNumOrAliasType = [];
    end
end

if isa(oNumOrAliasType, 'Simulink.AliasType')
    sCodeDataType = sDataType;
    return;
end

    
if isa(oNumOrAliasType, 'Simulink.NumericType')
    if oNumOrAliasType.IsAlias
        sCodeDataType = sDataType;
        
    elseif oNumOrAliasType.isboolean
        sCodeDataType = baseTypes.boolean;
        
    elseif oNumOrAliasType.issingle
        sCodeDataType = baseTypes.single;
        
    elseif oNumOrAliasType.isdouble
        sCodeDataType = baseTypes.double;
        
    else
        if oNumOrAliasType.getSpecifiedSign %signed
            if oNumOrAliasType.WordLength() <= 8
                sCodeDataType = baseTypes.int8;
            elseif oNumOrAliasType.WordLength() <= 16
                sCodeDataType = baseTypes.int16;
            elseif oNumOrAliasType.WordLength() <= 32
                sCodeDataType = baseTypes.int32;
            else
                sCodeDataType = 'NOT-SUPPORTED';
            end
            
        else %unsigned
            if oNumOrAliasType.WordLength() <= 8
                sCodeDataType = baseTypes.uint8;
            elseif oNumOrAliasType.WordLength() <= 16
                sCodeDataType = baseTypes.uint16;
            elseif oNumOrAliasType.WordLength() <= 32
                sCodeDataType = baseTypes.uint32;
            else
                sCodeDataType = 'NOT-SUPPORTED';
            end
        end
    end
    return;
end
    
sCodeDataType = 'UNKNOWN';
end


%%
function oItf = i_getMinMax(oItf, oDataObject)
dataObjectMin = '';
dataObjectMax = '';

if oItf.isBusElement && oItf.getMetaBus().iBusObjElement
    [dataObjectMin, dataObjectMax] = oItf.getMetaBusMinMax();
else
    if ~isempty(oDataObject)
        dataObjectMin = i_getObjectProperty(oDataObject, 'Min');
        dataObjectMax = i_getObjectProperty(oDataObject, 'Max');
    end
end

%Min
if ~isempty(dataObjectMin) %find from data object
    oItf.min = dataObjectMin;
    
else
    if ~oItf.isDsm
        %Ports
        compiledDesignMin = get(oItf.sourcePortHandle, 'CompiledPortDesignMin'); %find from compiled range
        if isempty(compiledDesignMin)
            oItf.min = [];
        else
            if ~isstruct(compiledDesignMin)
                if ischar(compiledDesignMin)
                    oItf.min = str2num(compiledDesignMin);
                elseif isnumeric(compiledDesignMin)
                    oItf.min = compiledDesignMin;
                else
                    oItf.min = [];
                end
            else
                if oItf.isBusElement
                    nCompiledMin = i_getMinMaxFromCompiledStructInfo(...
                        compiledDesignMin, ...
                        oItf.getMetaBus().modelSignalPath,...
                        oItf.name);
                else
                    nCompiledMin = [];
                end
                if isempty(nCompiledMin) || ~isfinite(nCompiledMin)
                    oItf.min = [];
                else
                    oItf.min = nCompiledMin;
                end
            end
        end
    else
        %Data Store
        if ~isempty(oItf.stDsmInfo.sPath)
            dBlkMin = str2num(get_param(oItf.stDsmInfo.sPath, 'OutMin'));
            if ~isempty(dBlkMin)
                oItf.min = dBlkMin;
            else
                oItf.min = [];
            end
        end
    end
end

%Max
if ~isempty(dataObjectMax) %find from data object
    oItf.max = dataObjectMax;
else
    if ~oItf.isDsm
        %Ports
        compiledDesignMax = get(oItf.sourcePortHandle, 'CompiledPortDesignMax'); %find from compiled range
        if isempty(compiledDesignMax)
            oItf.max = [];
        else
            if ~isstruct(compiledDesignMax)
                if ischar(compiledDesignMax)
                    oItf.max = str2num(compiledDesignMax);
                elseif isnumeric(compiledDesignMax)
                    oItf.max = compiledDesignMax;
                else
                    oItf.max = [];
                end
            else
                if oItf.isBusElement
                    dCompiledMax = i_getMinMaxFromCompiledStructInfo(...
                        compiledDesignMax, ...
                        oItf.getMetaBus().modelSignalPath, ...
                        oItf.name);
                else
                    dCompiledMax = [];
                end
                if isempty(dCompiledMax) || ~isfinite(dCompiledMax)
                    oItf.max = [];
                else
                    oItf.max = dCompiledMax;
                end
            end
        end
    else
        %Data Store
        if ~isempty(oItf.stDsmInfo.sPath)
            dBlkMax = str2num(get_param(oItf.stDsmInfo.sPath, 'OutMax'));
            if ~isempty(dBlkMax)
                oItf.max = dBlkMax;
            else
                oItf.max = [];
            end
        end
    end
end
end


%%
function oItf = i_getDimensions(oItf, oDataObject)

dataObjectDimensions = [];
if ~isempty(oDataObject)
    if strcmpi(oItf.kind, 'PARAM')
        dataObjectDimensions = size(i_getObjectProperty(oDataObject, 'Value'));
    else
        if oItf.isBusElement && oItf.getMetaBus().iBusObjElement
            % If signal is element of a bus object, get dimension from the element object
            dataObjectDimensions = oItf.getMetaBusDimensions();
        else
            dataObjectDimensions = oDataObject.Dimensions;
        end
    end
end

if strcmpi(oItf.kind, 'PARAM')
    oItf.dimension = dataObjectDimensions;
    
else
    if ~isempty(dataObjectDimensions) && ~isequal(dataObjectDimensions, -1) %find from data object
        oItf.dimension = dataObjectDimensions;
    else
        %Ports
        nDim = get(oItf.sourcePortHandle, 'CompiledPortDimensions');
        %If dimension is expressed as matrix (e.g. [X Y]), the compiled port dim has one
        %additional element N that specifies the N-Dimension (eg. [2 3 5],
        %N = 2 for a 2D matrix
        if isempty(nDim)
            oItf.dimension = [];
            oItf.casAnalysisNotes{end+1} = ...
                sprintf('Signal dimension is not available. This can lead to wrong model & code mapping of the interface.');
        elseif numel(nDim) > 3
            oItf.dimension = 1;
            oItf.casAnalysisNotes{end+1} = ...
                sprintf('Signal dimension cannot be extracted, it has been set to 1 by default. This can lead to wrong model & code mapping of the interface.');
        elseif numel(nDim) == 3 && nDim(1) == 2
            oItf.dimension = [nDim(2), nDim(3)];
        else
            oItf.dimension =  nDim(2);% [1 3] -> 3
        end
    end
end

% bIsScalar
% bIsArray1D
% bIsArray2D
% nDimAsRowCol
% bMLArrayUseRowIndexOnly
if not(isempty(oItf.dimension)) && not(isequal(oItf.dimension, [1 1])) && not(isequal(oItf.dimension, 1))
    oItf.bIsScalar = false;
    oItf.bIsArray1D = (min(oItf.dimension(1)) == 1) || (numel(oItf.dimension)==1 && min(oItf.dimension) > 1); % [1 3] or [3 1] or 3
    oItf.bIsArray2D = ~oItf.bIsArray1D;
    if numel(oItf.dimension) == 1
        oItf.nDimAsRowCol = [1 oItf.dimension];
    else
        oItf.nDimAsRowCol = oItf.dimension;
    end
    oItf.bMLArrayUseRowIndexOnly =...
        (~strcmp(oItf.kind, 'PARAM') && numel(oItf.dimension) == 1) || (strcmp(oItf.kind, 'PARAM') && oItf.bIsArray1D);
else
    oItf.bIsScalar = true;
    oItf.bIsArray1D = false;
    oItf.bIsArray2D = false;
    oItf.nDimAsRowCol = [1 1];
    oItf.bMLArrayUseRowIndexOnly = true;
end
end


%%
function oItf = i_getSimulinkDataType(oItf, oDataObject)
if (oItf.isBusElement && oItf.getMetaBus().iBusObjElement)
    % If signal is element of a bus object, get datatype from the element object
    oItf.sldatatype = oItf.getMetaBusDataType();
    oItf.sldatatypesource = 'DataObjectOrBusElementObject';
    
else
    % If signal is not a bus, get datatype from the data object
    if ~isempty(oDataObject)
        sDataType = i_getObjectProperty(oDataObject, 'DataType');
    else
        sDataType = '';
    end
    
    % Replace Empty or Auto datatype with compiled datatype
    if ~isempty(sDataType) && ~strcmp(sDataType, 'auto')
        oItf.sldatatype = sDataType;
        oItf.sldatatypesource = 'DataObjectOrBusElementObject';
        
    else
        if ismember(oItf.kind, {'IN', 'OUT', 'LOCAL'})
            if oItf.isDsm
                % Data Stores
                oItf.sldatatype = oItf.stDsmInfo.stSignalInfo.stTypeInfo.sBaseType;
                oItf.sldatatypesource = 'DsmStructureInfo';
                
            else
                % Ports
                oItf.sldatatype = get(oItf.sourcePortHandle, 'CompiledPortDataType');
                oItf.sldatatypesource = 'CompiledPortDataType';
            end
            
        else %'PARAM' & 'DEFINE'
            % note: basically dead code here! if we have a PARAM/DEFINE, we also have a DataObject
            oItf.sldatatype       = 'double';
            oItf.sldatatypesource = 'DefaultAsDouble';
        end
    end
end
end


%%
function xPropValue = i_getObjectProperty(oObj, sProp)
if isa(oObj, 'Simulink.LookupTable')
    oObj = oObj.Table;
elseif isa(oObj, 'Simulink.Breakpoint')
    oObj = oObj.Breakpoints;
end
try
    xPropValue = eval(['oObj.', sProp]);
catch
    xPropValue = [];
end
end


%%
function oItf = i_getScaling(oItf)
[ ...
    oItf.resolution, ...
    oItf.offset, ...
    oItf.isFloatPoint, ...
    oItf.isBoolean, ...
    oItf.isEnumeration] = i_getScalingRecursive(oItf.sldatatype);
end


%%
function  [dResolution, dOffset, bIsFloatPoint, bIsBoolean, bIsEnumeration] = i_getScalingRecursive(sDataType)
dResolution     = 1;
dOffset         = 0;
bIsFloatPoint   = false;
bIsBoolean      = false;
bIsEnumeration  = false;
if ismember(sDataType, {'single', 'double'})
    bIsFloatPoint   = true;
    dResolution     = NaN;
    dOffset         = NaN;
elseif ismember(sDataType, {'boolean', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32'})
    bIsBoolean      = strcmp(sDataType, 'boolean');
    dResolution     = 1;
    dOffset         = 0;
elseif strcmp(sDataType, 'auto')
    dResolution     = NaN;
    dOffset         = NaN;
    bIsFloatPoint   = NaN;
    bIsBoolean      = NaN;
    bIsEnumeration  = NaN;
elseif  strncmp(sDataType, 'Enum:', 5) || not(isempty(enumeration(sDataType)))
    dResolution     = 1;
    dOffset         = 0;
    bIsEnumeration  = true;
else
    %Expect for an AliasType or a NumericType
    %Try to evaluate from the Workspase
    try
        oNumType = oItf.evalinGlobal(sDataType);
    catch
        oNumType = [];
    end
    %Try to evaluation from compiled fixed-point string representation (eg. sfix16_En1_B1)
    if isempty(oNumType)
        try
            oNumType = fixdt(sDataType);
        catch
            oNumType = [];
        end
    end
    if ~isempty(oNumType)
        if isa(oNumType, 'Simulink.AliasType')
            [dResolution, dOffset, bIsFloatPoint, bIsBoolean, bIsEnumeration] = i_getScalingRecursive(oNumType.BaseType);
        elseif isa(oNumType, 'Simulink.NumericType')
            if oNumType.isdouble() || oNumType.isfloat() %(isfloat <=> issingle ?)
                bIsFloatPoint   = true;
                dResolution     = NaN;
                dOffset         = NaN;
            else
                bIsBoolean      = oNumType.isboolean();
                dResolution     = oNumType.Slope;
                dOffset         = oNumType.Bias;
            end
        end
        
    end
end
end


%%
function dCompiledMinOrMax = i_getMinMaxFromCompiledStructInfo(compiledDesignMinorMaxStructInfo, sBusSignalPath, sSignalName)

dCompiledMinOrMax = [];
if not(isempty(compiledDesignMinorMaxStructInfo))
    if isstruct(compiledDesignMinorMaxStructInfo)
        fldNames = fieldnames(compiledDesignMinorMaxStructInfo);
        
        if ismember(sSignalName, fldNames)
            dCompiledMinOrMax = compiledDesignMinorMaxStructInfo.(sSignalName);
        else
            for n=1:numel(fldNames)
                fldname = fldNames{n};
                if ~isempty(strfind(sBusSignalPath, fldname)) %Example : Found 'BusSig1' in '.InBusOfBuses.BusSig1.FlptSig2'
                    dCompiledMinOrMax = i_getMinMaxFromCompiledStructInfo(compiledDesignMinorMaxStructInfo.(fldname), sBusSignalPath, sSignalName);
                    break;
                end
            end
        end
    elseif isnumeric(compiledDesignMinorMaxStructInfo)
        dCompiledMinOrMax = compiledDesignMinorMaxStructInfo;
    else
        dCompiledMinOrMax = [];
    end
end
end
