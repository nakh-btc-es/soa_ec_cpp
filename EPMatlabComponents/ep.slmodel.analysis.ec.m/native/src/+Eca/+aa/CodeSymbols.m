classdef CodeSymbols
    methods (Static)

        function sVariableName = getEventVariable(sInterfaceName, sPortName, sEventName) %#ok<INUSD>
            sVariableName = sprintf('%s_%s', sPortName, sEventName);
        end


        function sFuncName = getRequiredMethodFunc(sInterfaceName, sPortName, sMethodName)
            sFuncName = sprintf('%s_%s_%s', sInterfaceName, sPortName, sMethodName);
        end

        function sFuncName = getProvidedMethodFunc(sInterfaceName, sPortName, sMethodName) %#ok<INUSD>
            sFuncName = sprintf('sut_%s_%s', sPortName, sMethodName);
        end


        function sVariableName = getFieldVariable(sInterfaceName, sPortName, sFieldName) %#ok<INUSD>
            sVariableName = sprintf('%s_%s', sPortName, sFieldName);
        end

        function sFuncName = getRequiredFieldGetterFunc(sInterfaceName, sPortName, sFieldName)
            sFuncName = sprintf('%s_%s_%s_get', sInterfaceName, sPortName, sFieldName);
        end

        function sFuncName = getRequiredFieldSetterFunc(sInterfaceName, sPortName, sFieldName)
            sFuncName = sprintf('%s_%s_%s_set', sInterfaceName, sPortName, sFieldName);
        end

        function sFuncName = getProvidedFieldGetterFunc(sInterfaceName, sPortName, sFieldName) %#ok<INUSD>
            sFuncName = sprintf('sut_%s_%s_get', sPortName, sFieldName);
        end

        function sFuncName = getProvidedFieldSetterFunc(sInterfaceName, sPortName, sFieldName) %#ok<INUSD>
            sFuncName = sprintf('sut_%s_%s_set', sPortName, sFieldName);
        end
    end
end
