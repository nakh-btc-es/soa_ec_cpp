classdef FunctionArg
% Argument of a SL function.

    properties
        sName char

        sOutDataTypeStr char
        sDataType char
        sCodeDataType char

        aiDim % CompiledPortDimension
        stTypeInfo
    end

    methods
        function sDim = getDimForPortAttributeSetting(oObj)
            sDim = i_getDimForPortAttributeSetting(oObj.aiDim);
        end

        function aiDim = getVariableStyleDim(oObj)
            aiDim = i_transformPortStyleToVariableStyleDim(oObj.aiDim);
        end

        function sDataTypeDS = getDataTypeForDataStoreSignals(oObj)
            sDataTypeDS = i_getDataTypeForDS(oObj.sOutDataTypeStr, oObj.stTypeInfo);
        end
    end
end


%%
function sDimToSet = i_getDimForPortAttributeSetting(aiPortDim)
if isempty(aiPortDim)
    sDimToSet = '';
else
    switch aiPortDim(1)
        case 1
            sDimToSet = sprintf('%d', aiPortDim(2));

        case 2
            sDimToSet = sprintf('[%d %d]', aiPortDim(2), aiPortDim(3));

        otherwise
            error('EP:ERROR:DIMENSIONS_NOT_SUPPORTED', ...
                'Given Matrix dimension = %d! Matrix dimensions above 2 are not supported.', aiPortDim(1));
    end
end
end


%%
function aiVarDim = i_transformPortStyleToVariableStyleDim(aiPortDim)
if isempty(aiPortDim)
    aiVarDim = [];
else
    if (aiPortDim(1) == 1)
        % always transform dimensions of scalar/array-signals to dimensions of column-vector variables (better compatibility)
        aiVarDim = [aiPortDim(2), 1];

    else
        aiVarDim = reshape(aiPortDim(2:end), 1, []);
    end
end
end


%%
% Note: In ML20222a a DS Signals may not reference an AliasType if that one is referencing an EnumType. --> Use the
%       original Enum Type directly for the DS Signal.
function sDataTypeDS = i_getDataTypeForDS(sOutDataTypeStr, stTypeInfo)
sDataTypeDS = sOutDataTypeStr;
if (stTypeInfo.bIsValidType && stTypeInfo.bIsEnum)
    bIsAlias = numel(stTypeInfo.casAliasChain) > 1;
    if bIsAlias
        sDataTypeDS = sprintf('Enum: %s', stTypeInfo.casAliasChain{end});
    end
end
end
