classdef RequiredMethod
% A function call corresponding to a *required* AA method.

    properties
        sCallerBlock
        casAllCallerBlocks

        sFunctionPrototype
        sFunctionName
        aoFunctionInArgs
        aoFunctionOutArgs
        
        sArComponentName
        sArInterfaceName
        sArPortName
        sArMethodName
        sArFieldName
        aoArMethodArgs

        sFieldAccessKind
    end

    methods
        function [sFunctionName, sScope] = getFunctionParts(oObj)
            casParts = strsplit(oObj.sFunctionName, '.');
            if (numel(casParts) == 2)
                sScope = casParts{1};
                sFunctionName = casParts{2};
            else
                sScope = '';
                sFunctionName = oObj.sFunctionName;
            end
        end

        function sName = getDisplayFunctionName(oObj)
            sName = strrep(oObj.sFunctionName, '.', '_');
        end
        
        function sName = getCodeGlobalFunction(oObj)
            if isempty(oObj.sFieldAccessKind)
                sName = Eca.aa.CodeSymbols.getRequiredMethodFunc( ...
                    oObj.sArInterfaceName, oObj.sArPortName, oObj.sArMethodName);
            else
                switch oObj.sFieldAccessKind
                    case 'get'
                        sName = Eca.aa.CodeSymbols.getRequiredFieldGetterFunc( ...
                            oObj.sArInterfaceName, oObj.sArPortName, oObj.sArFieldName);
                    case 'set'
                        sName = Eca.aa.CodeSymbols.getRequiredFieldSetterFunc( ...
                            oObj.sArInterfaceName, oObj.sArPortName, oObj.sArFieldName);
                    otherwise
                        error('EP:ECAA:INTERNAL_ERROR', 'Unknown field access kind "%s".', oObj.sFieldAccessKind);
                end
            end
        end

        function sMethodName = getMethodName(oObj)
            if ~isempty(oObj.sArMethodName)
                sMethodName = oObj.sArMethodName;
            else
                sMethodName = sprintf('%s_%s', oObj.sArFieldName, oObj.sFieldAccessKind);
            end
        end
    end
end


