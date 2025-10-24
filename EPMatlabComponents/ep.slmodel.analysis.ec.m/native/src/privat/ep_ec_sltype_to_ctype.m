function sCodeDataType = ep_ec_sltype_to_ctype(sModelName, sDataType)

bUseBaseTypeName = true;

%BaseType native names
stBaseTypes.int8    = 'int8_T';
stBaseTypes.int16   = 'int16_T';
stBaseTypes.int32   = 'int32_T';
stBaseTypes.uint8   = 'uint8_T';
stBaseTypes.uint16  = 'uint16_T';
stBaseTypes.uint32  = 'uint32_T';
stBaseTypes.boolean = 'boolean_T';
stBaseTypes.single  = 'real32_T';
stBaseTypes.double  = 'real_T';

cs = getActiveConfigSet(sModelName);
%Data type replacement defined in Model configSettings

warning('off');
try
    if strcmp(get_param(cs,'EnableUserReplacementTypes'), 'on')
        sT = get_param(cs,'ReplacementTypes');
        if ~isempty(sT.int8)
            stBaseTypes.int8    = sT.int8;
        end
        if ~isempty(sT.int16)
            stBaseTypes.int16   = sT.int16;
        end
        if ~isempty(sT.int32)
            stBaseTypes.int32   = sT.int32;
        end
        if ~isempty(sT.uint8)
            stBaseTypes.uint8   = sT.uint8;
        end
        if ~isempty(sT.uint16)
            stBaseTypes.uint16  = sT.uint16;
        end
        if ~isempty(sT.uint32)
            stBaseTypes.uint32  = sT.uint32;
        end
        if ~isempty(sT.boolean)
            stBaseTypes.boolean = sT.boolean;
        end
        if ~isempty(sT.single)
            stBaseTypes.single  = sT.single;
        end
        if ~isempty(sT.double)
            stBaseTypes.double  = sT.double;
        end
    end
end

if ismember(sDataType, {'boolean', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'single', 'double'})
    sCodeDataType = stBaseTypes.(sDataType);
    
elseif strcmp(sDataType, 'auto')
    sCodeDataType = 'AUTO';
    
elseif strncmp(sDataType, 'Enum:', 5)%Enumeration type
    sCodeDataType = strtrim(sDataType(6:end));
    try
        sStorageType = Simulink.data.getEnumTypeInfo(sCodeDataType, 'StorageType');
        if ~strcmp(sStorageType, 'int')
            if bUseBaseTypeName
                sCodeDataType = stBaseTypes.(sStorageType);
            else
                sCodeDataType = sStorageType;
            end
        end
    end
    
elseif ~isempty(enumeration(sDataType))
    sCodeDataType = sDataType;
    try
        sStorageType = Simulink.data.getEnumTypeInfo(sCodeDataType, 'StorageType');
        if ~strcmp(sStorageType, 'int')
            if bUseBaseTypeName
                sCodeDataType = stBaseTypes.(sStorageType);
            else
                sCodeDataType = sStorageType;
            end
        end
    end
    
else
    %Expect an AliasType or a NumericType
    try
        oType = Simulink.data.evalinGlobal(sModelName, sDataType);
    catch
        oType = [];
    end
    %Try to evaluation from compiled fixed-point string representation (eg. sfix16_En1_B1)
    if isempty(oType)
        try
            oType = fixdt(sDataType);
        catch
            oType = [];
        end
    end
    if isa(oType, 'Simulink.AliasType')        
        if bUseBaseTypeName
            sBaseType = oType.BaseType;
            if ~strcmp(sBaseType, sDataType)
                sCodeDataType = ep_ec_sltype_to_ctype(sModelName, sBaseType);
            else
                sCodeDataType = stBaseTypes.(sBaseType);
            end
        else
            sCodeDataType = sDataType; %Use name of the AliasType
        end
    elseif isa(oType, 'Simulink.NumericType')
        if (~bUseBaseTypeName && oType.IsAlias)
            sCodeDataType = sDataType;
        elseif oType.isboolean
            sCodeDataType = stBaseTypes.boolean;
        elseif oType.issingle
            sCodeDataType = stBaseTypes.single;
        elseif oType.isdouble
            sCodeDataType = stBaseTypes.double;
        else
            if oType.getSpecifiedSign %signed
                if oType.WordLength() <= 8
                    sCodeDataType = stBaseTypes.int8;
                elseif oType.WordLength() <= 16
                    sCodeDataType = stBaseTypes.int16;
                elseif oType.WordLength() <= 32
                    sCodeDataType = stBaseTypes.int32;
                else
                    sCodeDataType = 'NOT-SUPPORTED';
                end
            else %unsigned
                if oType.WordLength() <= 8
                    sCodeDataType = stBaseTypes.uint8;
                elseif oType.WordLength() <= 16
                    sCodeDataType = stBaseTypes.uint16;
                elseif oType.WordLength() <= 32
                    sCodeDataType = stBaseTypes.uint32;
                else
                    sCodeDataType = 'NOT-SUPPORTED';
                end
            end
        end
        
    elseif isa(oType, 'Simulink.Bus')
        sCodeDataType = sDataType;
    else
        sCodeDataType = 'UNKNWON';
    end
end
warning('on'); %#ok<WNON>
end
