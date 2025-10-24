classdef Port
% Ports inside EC AA models.

    properties
        sPortName = '';
        nPortNum = [];
        bIsFunctionCall = false;
        bIsClientServer = false;
        sElement = '';
        sOutputAsVirtualBus = 'off';
        sOutDataTypeStr = '';
        sDataType = '';
        aiDim = [1 1];
        dSampleTime = -1;
        sMessageTriggeredSubName = '';
        stSLFunction = '';
    end

    methods
        function sDim = getDimForPortAttributeSetting(oObj)
            sDim = i_getDimForPortAttributeSetting(oObj.aiDim);
        end

        function aiDim = getVariableStyleDim(oObj)
            aiDim = i_transformPortStyleToVariableStyleDim(oObj.aiDim);
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
