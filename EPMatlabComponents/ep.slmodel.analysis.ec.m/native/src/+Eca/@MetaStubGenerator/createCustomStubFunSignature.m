%createCustomStubFunSignature()
function sFunSignature = createCustomStubFunSignature(oStubGen, oStubInfo, sType)
sDataType = oStubInfo.sVariableDatatype;
sStubVarName = oStubInfo.sStubCustomVariableName;
if strcmp(sType, 'Get')
    sFunName = oStubInfo.sStubCustomGetFunName;
    aoFunArgs = oStubInfo.aoStubCustomGetFunArgs;
else
    sFunName = oStubInfo.sStubCustomSetFunName;
    aoFunArgs = oStubInfo.aoStubCustomSetFunArgs;
end
bIsScalar = oStubInfo.bIsScalar;
bIsArray1D = oStubInfo.bIsArray1D;
nDimAsRowCol = oStubInfo.nDimAsRowCol;
b2DVarIs1DTable = oStubInfo.b2DMatlabIs1DCode;
s2DMatlabTo2DCodeConv = oStubInfo.s2DMatlabTo2DCodeConv;
idxRetArg = ismember({aoFunArgs(:).sKind}, 'return');
if (~any(idxRetArg) || numel(find(idxRetArg)) > 1)
    sReturnArgType = 'void';
else
    if aoFunArgs(idxRetArg).bMapToStubVar
        if bIsScalar
            sReturnArgType = [aoFunArgs(idxRetArg).sQualiferScalar, ' ', aoFunArgs(idxRetArg).sDataType];
            if aoFunArgs(idxRetArg).bIsPointer
                sReturnArgType = [sReturnArgType, '*'];
            end
            
        else
            sTypePrefix = [aoFunArgs(idxRetArg).sQualiferArray, ' '];
            if bIsArray1D %1D
                if aoFunArgs(idxRetArg).bArrayPointerNotation
                    sPostfix = ['[', num2str(nDimAsRowCol(2)), ']'];
                else
                    sPostfix = '*';
                end
                
            else %2D
                if aoFunArgs(idxRetArg).bArrayPointerNotation
                    if b2DVarIs1DTable
                        sPostfix = ['[', num2str(prod(nDimAsRowCol)), ']'];
                    else
                        if strcmp(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                            sPostfix = ['[', num2str(nDimAsRowCol(1)), '][', num2str(nDimAsRowCol(2)), ']'];
                        else
                            sPostfix = ['[', num2str(nDimAsRowCol(2)), '][', num2str(nDimAsRowCol(1)), ']'];
                        end
                    end
                else
                    sPostfix = '*';
                end
            end
            sReturnArgType = [sTypePrefix, aoFunArgs(idxRetArg).sDataType, sPostfix];
        end
    else
        if aoFunArgs(idxRetArg).bIsPointer
            sReturnArgType = [aoFunArgs(idxRetArg).sDataType '*'];
        else
            sReturnArgType = aoFunArgs(idxRetArg).sDataType;
        end
    end
end

sFunSignature = [sReturnArgType, ' ', sFunName, '('];

nArgsIndexes = setxor(find(idxRetArg), 1:numel(aoFunArgs));
if isempty(nArgsIndexes)
    sFunSignature = [sFunSignature, 'void'];
else
    for iArg = nArgsIndexes
        oFunArg = aoFunArgs(iArg);
        if oFunArg.bMapToStubVar
            if strcmp(oFunArg.sKind, 'input')
                if bIsScalar
                    sTypePrefix = [oFunArg.sQualiferScalar, ' ', oFunArg.sDataType, ' '];
                    if oFunArg.bIsPointer
                        sArgPrefix = '*';
                    else
                        sArgPrefix = '';
                    end                    
                    sArgNameExpr = [sTypePrefix, sArgPrefix, oFunArg.sArgName];
                    
                else
                    sTypePrefix = [oFunArg.sQualiferArray, ' ', oFunArg.sDataType, ' '];
                    if bIsArray1D %1D
                        if oFunArg.bArrayPointerNotation
                            sArgNameExpr = [sTypePrefix, oFunArg.sArgName, '[', num2str(nDimAsRowCol(2)), ']'];
                        else
                            sArgNameExpr = [sTypePrefix, '*', oFunArg.sArgName];
                        end
                        
                    else %2D
                        if oFunArg.bArrayPointerNotation
                            if b2DVarIs1DTable
                                sArgNameExpr = [sTypePrefix, oFunArg.sArgName, '[', num2str(prod(nDimAsRowCol)), ']'];
                            else
                                if strcmp(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                                    sArgNameExpr = [sTypePrefix, oFunArg.sArgName, ...
                                        '[', num2str(nDimAsRowCol(1)), '][', num2str(nDimAsRowCol(2)), ']'];
                                else
                                    sArgNameExpr = [sTypePrefix, oFunArg.sArgName, ...
                                        '[', num2str(nDimAsRowCol(2)), '][', num2str(nDimAsRowCol(1)), ']'];
                                end
                            end
                        else
                            sArgNameExpr = [sTypePrefix, '*', oFunArg.sArgName];
                        end
                    end
                end
            elseif strcmp(oFunArg.sKind, 'output')
                if bIsScalar
                    sTypePrefix = [oFunArg.sQualiferScalar, ' ', oFunArg.sDataType, ' '];
                    sArgNameExpr = [sTypePrefix, '*', oFunArg.sArgName];
                else
                    sTypePrefix = [oFunArg.sQualiferArray, ' ', oFunArg.sDataType, ' '];
                    if bIsArray1D %1D
                        if oFunArg.bArrayPointerNotation
                            sArgNameExpr = [sTypePrefix, oFunArg.sArgName, '[',num2str(nDimAsRowCol(2)),']'];
                        else
                            sArgNameExpr = [sTypePrefix, '*', oFunArg.sArgName];
                        end
                        
                    else %2D
                        if oFunArg.bArrayPointerNotation
                            if b2DVarIs1DTable
                                sArgNameExpr = [sTypePrefix, oFunArg.sArgName, '[', num2str(prod(nDimAsRowCol)), ']'];
                            else
                                if strcmp(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                                    sArgNameExpr = [sTypePrefix, oFunArg.sArgName, ...
                                        '[', num2str(nDimAsRowCol(1)), '][', num2str(nDimAsRowCol(2)), ']'];
                                else
                                    sArgNameExpr = [sTypePrefix, oFunArg.sArgName, ...
                                        '[', num2str(nDimAsRowCol(2)), '][', num2str(nDimAsRowCol(1)), ']'];
                                end
                            end
                        else
                            sArgNameExpr = [sTypePrefix, '*', oFunArg.sArgName];
                        end
                    end
                end
            end
        else
            if strcmp(oFunArg.sKind, 'input')
                if oFunArg.bIsPointer
                    sArgNameExpr = [oFunArg.sQualiferScalar, ' ', oFunArg.sDataType, ' *', oFunArg.sArgName];
                else
                    sArgNameExpr = [oFunArg.sQualiferScalar, ' ', oFunArg.sDataType, ' ', oFunArg.sArgName];
                end
            elseif strcmp(oFunArg.sKind, 'output') || strcmp(oFunArg.sKind, 'input/output')
                sArgNameExpr = [oFunArg.sQualiferScalar, ' ', oFunArg.sDataType, ' *', oFunArg.sArgName];
            end
        end
        sFunSignature = [sFunSignature, sArgNameExpr];
        if iArg ~= nArgsIndexes(end)
            sFunSignature = [sFunSignature, ', '];
        end
    end
end
sFunSignature = [sFunSignature, ')'];
end