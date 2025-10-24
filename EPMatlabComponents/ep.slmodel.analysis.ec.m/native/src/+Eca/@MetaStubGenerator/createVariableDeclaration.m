function sContent = createVariableDeclaration(oStubGen, sContent, oStubInfo, bUseExtern)
if (nargin < 4)
    bUseExtern = true;
end

sDataType = oStubInfo.sVariableDatatype;
if strcmp(oStubInfo.sStubType, 'variable')
    sVariableName = oStubInfo.sVariableName;
else
    if strcmp(oStubInfo.sStubFuncType, 'SimulinkGetSet')
         sVariableName = oStubInfo.sStubSLGetSetVariableName;
    else
         sVariableName = oStubInfo.sStubCustomVariableName;
    end
end
bIsScalar = oStubInfo.bIsScalar;
bIsArray1D = oStubInfo.bIsArray1D;
nDimAsRowCol = oStubInfo.nDimAsRowCol;
b2DVarIs1DTable = oStubInfo.b2DMatlabIs1DCode;
s2DMatlabTo2DCodeConv = oStubInfo.s2DMatlabTo2DCodeConv;


sPrefix = '';
if bUseExtern
    sPrefix = 'extern ';
end
if ~oStubInfo.bIsStructComponent
    if ~isempty(sVariableName)
        if bIsScalar
            sPostfix = '';
        else
            if bIsArray1D
                sPostfix = ['[', num2str(nDimAsRowCol(2)), ']'];
            else
                if b2DVarIs1DTable
                    sPostfix = ['[', num2str(prod(nDimAsRowCol)), ']'];
                else
                    if strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                        sPostfix =  ['[', num2str(nDimAsRowCol(1)), '][', num2str(nDimAsRowCol(2)), ']'];
                    elseif strcmpi(s2DMatlabTo2DCodeConv, 'M_RowCol_C_ColRow')
                        sPostfix =  ['[', num2str(nDimAsRowCol(2)), '][', num2str(nDimAsRowCol(1)), ']'];
                    else
                        sPostfix = ['[', num2str(prod(nDimAsRowCol)), ']'];
                    end
                end
            end
        end
        sContent = [sContent, sPrefix, sDataType, ' ', sVariableName, sPostfix, ';\n'];
    end
else
    sVariableStructComponentName = oStubInfo.sVariableStructComponentName;
    sVariableStructName = oStubInfo.sVariableStructName;
    sContent = [sContent, '//Stub of structure variables is not supported yet: ',...
        sVariableStructName, '.', sVariableStructComponentName, ';\n\n'];
end
end