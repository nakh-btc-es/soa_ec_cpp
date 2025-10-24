classdef Model2CodeType < handle
    properties (SetAccess = private, Hidden = true)
        sModel
        bIsAutosar
        mApp2ImpModel
        jBuiltinTypeSet
        mCachedModel2CodeType
    end
    
    methods
        function oNewObj = Model2CodeType(xModelContext, bIsAutosar, mApp2ImpModel)
            try
                sModelContext = getfullname(xModelContext); % accept handle or block path and normalize to block path
            catch oEx
                error('EP:USAGE_ERROR', 'Model context is invalid.');
            end
            oNewObj.sModel = bdroot(sModelContext);
            
            if (nargin < 2)
                bIsAutosar = false;
            end
            oNewObj.bIsAutosar = bIsAutosar;            
            
            if (nargin < 3)
                if bIsAutosar
                    oUtils = autosar.api.Utils;
                    mApp2ImpModel = oUtils.app2ImpMap(oNewObj.sModel);
                else
                    mApp2ImpModel = containers.Map;                    
                end
            else
                if isempty(mApp2ImpModel)
                    mApp2ImpModel = containers.Map;
                end
            end
            oNewObj.mApp2ImpModel = mApp2ImpModel;
            
            [oNewObj.mCachedModel2CodeType, oNewObj.jBuiltinTypeSet] = i_getBuiltinTypes2Code(oNewObj.sModel);
        end
        
        function sCodeType = translateToBaseType(this, sModelType)
            sCodeType = i_cachedTranslateModel2CodeType(this, sModelType);
        end

        function [sImpType, bIsRteType] = translateToImplementationType(this, sModelType)
            sModelType = i_normalizeType(sModelType);
            if i_isModelBuiltinType(this, sModelType)
                % for buitin types the implementation type is essentially the code base type
                sImpType = this.translateToBaseType(sModelType);
                bIsRteType = false;
            else
                % note: for Customer types the implementation type is the model type except for AUTOSAR App types
                sImpType = sModelType;
                bIsAutosarAppType = this.mApp2ImpModel.isKey(sModelType);
                if bIsAutosarAppType
                    sImpType = this.mApp2ImpModel(sModelType);
                    bIsRteType = true; % note: type is automatically an RTE type if it is an Application type
                else
                    bIsRteType = strcmpi('Rte_Type.h', i_getHeaderFileName(this, sModelType));
                end
            end
        end

        
        function [sModel, bIsAutosar] = getModel(this)
            sModel = this.sModel;
            bIsAutosar = this.bIsAutosar;
        end
    end
    
    methods (Hidden = true)
        function oType = evalinGlobal(this, sModelType)
            oType = Simulink.data.evalinGlobal(this.sModel, sModelType);
        end
        
        function clearCache(this)
            this.mCachedModel2CodeType = i_getBuiltinTypes2Code(this.sModel);
        end
    end
end


%%
% remove prefixes like "Enum: ", "Bus: ", "Inherited: ", ...
function sModelType = i_normalizeType(sModelType)
sModelType = regexprep(sModelType, '^.+:\s*', '');
end


%%
function sHeaderFileName = i_getHeaderFileName(oObj, sModelType)
sHeaderFileName = '';
try
    sEvalIsObjWithHeader = sprintf( ...
        'isa(%s, ''Simulink.AliasType'') || isa(%s, ''Simulink.NumericType'') || isa(%s, ''Simulink.Bus'')', ...
        sModelType, sModelType, sModelType);
    bHasHeader = oObj.evalinGlobal(sEvalIsObjWithHeader);
    if bHasHeader
        sHeaderFileName = oObj.evalinGlobal(sprintf('%s.HeaderFile', sModelType));
    end

catch
    if i_isEnum(sModelType)
        try %#ok<TRYNC>
            sHeaderFileName = Simulink.data.getEnumTypeInfo(sModelType, 'HeaderFile');
        end
    end
end
end


%%
function bIsModelBuiltinType = i_isModelBuiltinType(oObj, sModelType)
bIsModelBuiltinType = oObj.jBuiltinTypeSet.contains(sModelType);
if ~bIsModelBuiltinType
    % if it's not an explicit builtin type, we try for an implicit builtin type: FXP type
    if (~isempty(regexp(sModelType, '^[s,u]fix\d', 'once')) || ~isempty(regexp(sModelType, '^flt[s,u]\d', 'once')))
        try %#ok<TRYNC>
            oNumType = fixdt(sModelType);
            bIsModelBuiltinType = ~isempty(oNumType);
        end
    end
end
end



%%
function bIsEnum = i_isEnum(sName)
try
    bIsEnum = ~isempty(enumeration(sName));
catch
    bIsEnum = false;
end
end




%%
function oType = i_getTypeObject(oObj, sModelType)
oType = [];
try %#ok<TRYNC>
    oType = oObj.evalinGlobal(sModelType);
end
if isempty(oType)
    try %#ok<TRYNC>
        oType = fixdt(sModelType);
    end
end
end


%%
function sCodeType = i_cachedTranslateModel2CodeType(oObj, sModelType)
if (oObj.mCachedModel2CodeType.isKey(sModelType))
    sCodeType = oObj.mCachedModel2CodeType(sModelType);
else
    sCodeType = i_translateModel2CodeType(oObj, sModelType);
    oObj.mCachedModel2CodeType(sModelType) = sCodeType;
end
end


%%
function sCodeType = i_translateModel2CodeType(oObj, sModelType)
sModelType = i_normalizeType(sModelType);
sCodeType  = sModelType; % default: model-type == code-type

if strcmp(sModelType, 'auto')
    sCodeType = 'AUTO';
    
elseif ~isempty(enumeration(sModelType))
    try %#ok<TRYNC>
        sStorageType = Simulink.data.getEnumTypeInfo(sCodeType, 'StorageType');
        if strcmp(sStorageType, 'int')
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'int32');
        else
            sCodeType = i_cachedTranslateModel2CodeType(oObj, sStorageType);
        end
    end
    
else
    oType = i_getTypeObject(oObj, sModelType);
    if isa(oType, 'Simulink.AliasType')
        sCodeType = i_cachedTranslateModel2CodeType(oObj, oType.BaseType);
        
    elseif isa(oType, 'Simulink.NumericType')
        sCodeType = i_getCodeTypeFromNumericType(oObj, oType);
        
    elseif isa(oType, 'Simulink.Bus')
        error('MODEL2CODE:ERROR:BUS_TRANSLATE_TO_BASE', 'Bus types cannot be tranlated to a simple base type.');
    end
end
end


%%
function sCodeType = i_getCodeTypeFromNumericType(oObj, oType)
sCodeType = 'NOT-SUPPORTED';
if oType.isboolean
    sCodeType = i_cachedTranslateModel2CodeType(oObj, 'boolean');
    
elseif oType.issingle
    sCodeType = i_cachedTranslateModel2CodeType(oObj, 'single');
    
elseif oType.isdouble
    sCodeType = i_cachedTranslateModel2CodeType(oObj, 'double');
    
else
    if oType.getSpecifiedSign % signed
        if oType.WordLength() <= 8
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'int8');
            
        elseif oType.WordLength() <= 16
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'int16');
            
        elseif oType.WordLength() <= 32
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'int32');
        end
        
    else % unsigned
        if oType.WordLength() <= 8
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'uint8');
            
        elseif oType.WordLength() <= 16
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'uint16');
            
        elseif oType.WordLength() <= 32
            sCodeType = i_cachedTranslateModel2CodeType(oObj, 'uint32');
        end
    end
end
end


%%
function mBuiltin2CodeType = i_getDefaultMappingBuiltinToCodeTypes()
mBuiltin2CodeType = containers.Map;
mBuiltin2CodeType('int8')    = 'int8_T';
mBuiltin2CodeType('int16')   = 'int16_T';
mBuiltin2CodeType('int32')   = 'int32_T';
mBuiltin2CodeType('int64')   = 'int64_T';
mBuiltin2CodeType('uint8')   = 'uint8_T';
mBuiltin2CodeType('uint16')  = 'uint16_T';
mBuiltin2CodeType('uint32')  = 'uint32_T';
mBuiltin2CodeType('uint64')  = 'uint64_T';
mBuiltin2CodeType('boolean') = 'boolean_T';
mBuiltin2CodeType('single')  = 'real32_T';
mBuiltin2CodeType('double')  = 'real_T';
end


%%
function [mBuiltin2CodeType, jBuiltinTypeSet] = i_getBuiltinTypes2Code(sModelName)
mBuiltin2CodeType = i_getDefaultMappingBuiltinToCodeTypes();

% store the names of the builtin types in a set for later use
jBuiltinTypeSet = java.util.HashSet();
casBuiltinTypeNames = mBuiltin2CodeType.keys;
for i = 1:numel(casBuiltinTypeNames)
    jBuiltinTypeSet.add(casBuiltinTypeNames{i});
end

% replace the default names with the user-defined replacements if available
oConfig = getActiveConfigSet(sModelName);

stWarningStateNow = warning('off');
oOnCleanupRestore = onCleanup(@() warning(stWarningStateNow));
try %#ok<TRYNC>
    if strcmp(get_param(oConfig, 'EnableUserReplacementTypes'), 'on')
        stReplacement = get_param(oConfig, 'ReplacementTypes');
        casBuiltinTypes = fieldnames(stReplacement);
        for i = 1:numel(casBuiltinTypes)
            sBuiltinType = casBuiltinTypes{i};
            sReplacingCodeType = stReplacement.(sBuiltinType);
            if ~isempty(sReplacingCodeType)
                mBuiltin2CodeType(sBuiltinType) = sReplacingCodeType;
            end
        end
    end
end

% Note: Fake extension --> code base type maps always to code base type (this is used later for other workflows)
casCodeBaseTypes = mBuiltin2CodeType.values();
for i = 1:numel(casCodeBaseTypes)
    sCodeBaseType = casCodeBaseTypes{i};
    
    mBuiltin2CodeType(sCodeBaseType) = sCodeBaseType;
end
end
