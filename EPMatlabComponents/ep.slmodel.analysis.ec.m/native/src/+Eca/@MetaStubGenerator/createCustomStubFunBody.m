function sFunBody = createCustomStubFunBody(oStubGen, oStubInfo, sType)

sVarName = oStubInfo.sStubCustomVariableName;
bIsScalar = oStubInfo.bIsScalar;
bIsArray1D = oStubInfo.bIsArray1D;
nDimAsRowCol = oStubInfo.nDimAsRowCol;
b2DVarIs1DTable = oStubInfo.b2DMatlabIs1DCode;
s2DMatlabTo2DCodeConv = oStubInfo.s2DMatlabTo2DCodeConv;

if strcmp(sType, 'Get')
    aoFunArgs = oStubInfo.aoStubCustomGetFunArgs;
else
    aoFunArgs = oStubInfo.aoStubCustomSetFunArgs;
end

sFunBody = '';

idxArgMapToVar = [aoFunArgs(:).bMapToStubVar];
if (~any(idxArgMapToVar) || numel(find(idxArgMapToVar)) > 1)
    return;
end

sFunBody = [sFunBody, '{\n'];
oArgMapToVar = aoFunArgs(idxArgMapToVar);

%Process return
if strcmp(oArgMapToVar.sKind, 'return')
    sReturnExpr = i_createReturnExpression(sVarName, bIsScalar, oArgMapToVar.bIsPointer, bIsArray1D, b2DVarIs1DTable);
    sFunBody = [sFunBody, '  ', sReturnExpr, '\n'];
    
else
    %Process interface argument
    if strcmp(oArgMapToVar.sKind, 'input')
        if oArgMapToVar.bIsPointer
            if bIsScalar
                sFunBody = [sFunBody, '  ', sVarName,' = *', oArgMapToVar.sArgName, ';\n'];
            else
                if bIsArray1D
                    %1D
                    sFunBody =  [sFunBody,'  int i;\n'];
                    sFunBody =  [sFunBody,'  for(i=0; i<',num2str(nDimAsRowCol(2)),'; i++) {\n'];
                    sFunBody =  [sFunBody,'    ', sVarName, '[i] = ',oArgMapToVar.sArgName,'[i];\n'];
                    sFunBody =  [sFunBody,'  }\n'];
                else
                    %2D
                    if b2DVarIs1DTable
                        sFunBody =  [sFunBody,'  int i;\n'];
                        sFunBody =  [sFunBody,'  for(i=0; i<', num2str(prod(nDimAsRowCol)), '; i++) {\n'];
                        sFunBody =  [sFunBody,'    ', sVarName, '[i] = ',oArgMapToVar.sArgName,'[i];\n'];
                        sFunBody =  [sFunBody,'  }\n'];
                    else
                        sFunBody =  [sFunBody,'  int i, j;\n'];
                        if strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                            sFunBody =  [sFunBody,'  for(i=0; i<',num2str(nDimAsRowCol(1)), '; i++) {\n'];
                            sFunBody =  [sFunBody,'    for(j=0; i<',num2str(nDimAsRowCol(2)), '; j++) {\n'];
                        else
                            sFunBody =  [sFunBody,'  for(i=0; i<',num2str(nDimAsRowCol(2)), '; i++) {\n'];
                            sFunBody =  [sFunBody,'    for(j=0; i<',num2str(nDimAsRowCol(1)), '; j++) {\n'];
                        end
                        sFunBody =      [sFunBody,'      ', sVarName,'[i][j] = ', oArgMapToVar.sArgName, '[i][j];\n'];
                        sFunBody =      [sFunBody,'    }\n'];
                        sFunBody =      [sFunBody,'  }\n'];
                    end
                end
                
            end
        else
            if bIsScalar
                sFunBody = [sFunBody,' ', sVarName, ' = ', oArgMapToVar.sArgName, ';\n'];
            else
                if bIsArray1D
                    %1D
                    sFunBody =  [sFunBody, '  int i;\n'];
                    sFunBody =  [sFunBody, '  for(i=0; i<', num2str(nDimAsRowCol(2)),'; i++) {\n'];
                    sFunBody =  [sFunBody, '    ', sVarName, '[i] = ', oArgMapToVar.sArgName, '[i];\n'];
                    sFunBody =  [sFunBody, '  }\n'];
                else
                    %2D
                    if b2DVarIs1DTable
                        sFunBody =  [sFunBody, '  int i;\n'];
                        sFunBody =  [sFunBody, '  for(i=0; i<', num2str(prod(nDimAsRowCol)), '; i++) {\n'];
                        sFunBody =  [sFunBody, '    ', sVarName, '[i] = ', oArgMapToVar.sArgName, '[i];\n'];
                        sFunBody =  [sFunBody, '  }\n'];
                    else
                        sFunBody =  [sFunBody, '  int i, j;\n'];
                        if strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                            sFunBody =  [sFunBody, '  for(i=0; i<', num2str(nDimAsRowCol(1)), '; i++) {\n'];
                            sFunBody =  [sFunBody, '    for(j=0; i<', num2str(nDimAsRowCol(2)), '; j++) {\n'];
                        else
                            sFunBody =  [sFunBody, '  for(i=0; i<',num2str(nDimAsRowCol(2)),'; i++) {\n'];
                            sFunBody =  [sFunBody, '    for(j=0; i<',num2str(nDimAsRowCol(1)),'; j++) {\n'];
                        end
                        sFunBody =      [sFunBody, '      ', sVarName, '[i][j] = ', oArgMapToVar.sArgName, '[i][j];\n'];
                        sFunBody =      [sFunBody, '    }\n'];
                        sFunBody =      [sFunBody, '  }\n'];
                    end
                end
            end
        end
    elseif strcmp(oArgMapToVar.sKind, 'output')
        if bIsScalar
            sFunBody = [sFunBody, '  *', oArgMapToVar.sArgName, ' = ', sVarName, ';\n'];
        else
            if bIsArray1D %1D
                sFunBody =  [sFunBody, '  int i;\n'];
                sFunBody =  [sFunBody, '  for(i=0; i<',num2str(nDimAsRowCol(2)), '; i++) {\n'];
                sFunBody =  [sFunBody, '    ', oArgMapToVar.sArgName, '[i] = ', sVarName,'[i];\n'];
                sFunBody =  [sFunBody, '  }\n'];
                
            else %2D
                if b2DVarIs1DTable
                    sFunBody =  [sFunBody, '  int i;\n'];
                    sFunBody =  [sFunBody, '  for(i=0; i<',num2str(prod(nDimAsRowCol)),'; i++) {\n'];
                    sFunBody =  [sFunBody, '    ', oArgMapToVar.sArgName, '[i] = ', sVarName, '[i];\n'];
                    sFunBody =  [sFunBody, '  }\n'];
                else
                    sFunBody =  [sFunBody, '  int i, j;\n'];
                    if strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                        sFunBody =  [sFunBody, '  for(i=0; i<',num2str(nDimAsRowCol(1)),'; i++) {\n'];
                        sFunBody =  [sFunBody, '    for(j=0; i<',num2str(nDimAsRowCol(2)),'; j++) {\n'];
                    else
                        sFunBody =  [sFunBody, '  for(i=0; i<',num2str(nDimAsRowCol(2)),'; i++) {\n'];
                        sFunBody =  [sFunBody, '    for(j=0; i<',num2str(nDimAsRowCol(1)),'; j++) {\n'];
                    end
                    sFunBody =      [sFunBody, '      ', oArgMapToVar.sArgName,'[i][j] = ', sVarName,'[i][j];\n'];
                    sFunBody =      [sFunBody, '    }\n'];
                    sFunBody =      [sFunBody, '  }\n'];
                end
            end
        end
    end
    
    %Process return anyway
    idxRetArg = ismember({aoFunArgs(:).sKind}, 'return');
    if (~any(idxRetArg) || numel(find(idxRetArg)) > 1)
        
    else
        sFunBody = [sFunBody, '  ', i_transformToReturnExpression(aoFunArgs(idxRetArg)), '\n'];
    end
    
end

sFunBody = [sFunBody, '}\n'];
end


%%
function sReturnExpr = i_transformToReturnExpression(oReturnFuncArg)
sName = oReturnFuncArg.sArgName;
if isempty(sName)
    if oReturnFuncArg.bIsPointer
        sReturnExpr = sprintf('return (%s*)void;', oReturnFuncArg.sDataType);
    else
        sReturnExpr = sprintf('return (%s)0;', oReturnFuncArg.sDataType);
    end
else
    if oReturnFuncArg.bIsPointer
        sReturnExpr = sprintf('return (%s*)%s;', oReturnFuncArg.sDataType, sName);
    else
        sReturnExpr = sprintf('return (%s)%s;', oReturnFuncArg.sDataType, sName);
    end
end
end


%%
function sReturnExpr = i_createReturnExpression(sVarName, bIsScalar, bIsPointer, bIsArray1D, b2DVarIs1DTable)
if bIsScalar
    if bIsPointer
        sVarAccess = ['&', sVarName];
    else
        sVarAccess = sVarName;
    end
else
    if bIsArray1D
        sVarAccess = ['&', sVarName, '[0]'];
    else
        if b2DVarIs1DTable
            sVarAccess = ['&', sVarName, '[0]'];
        else
            sVarAccess = ['&', sVarName, '[0][0]'];
        end
    end
end
sReturnExpr = sprintf('return %s;', sVarAccess);
end
