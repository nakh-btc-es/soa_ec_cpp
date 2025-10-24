function sFileContent = createSLGetSetFunDeclaration(oStubGen, sFileContent, oStubInfo)
sDataType = oStubInfo.sVariableDatatype;
sStubSLGetFunName = oStubInfo.sStubSLGetFunName;
sStubSLSetFunName = oStubInfo.sStubSLSetFunName;
bIsScalar = oStubInfo.nDimAsRowCol;
bIsArray1D = oStubInfo.bIsArray1D;

%variable
if oStubInfo.bStubVariable
    sFileContent = oStubGen.createVariableDeclaration(sFileContent, oStubInfo);
end
sFileContent = [sFileContent, '\n'];

%functions (first getter, then setter)
if bIsScalar
    sFileContent =  [sFileContent, 'extern  ', sDataType, ' ', sStubSLGetFunName, '(void);\n'];
    sFileContent =  [sFileContent, 'extern  void ', sStubSLSetFunName, '(', sDataType, ' val);\n'];
    
else
    if ~bIsArray1D %Matrix
        sFileContent =  [sFileContent, 'extern ', sDataType, ' ', sStubSLGetFunName, '(int colIndex);\n'];
        sFileContent =  [sFileContent, 'extern void ', sStubSLSetFunName, '(int index, ', sDataType, ' val);\n'];
        
    else %Vector
        sFileContent =  [sFileContent, 'extern ', sDataType, ' ', sStubSLGetFunName, '(int index);\n'];
        sFileContent =  [sFileContent, 'extern void ', sStubSLSetFunName, '(int index, ', sDataType, ' val);\n'];
    end
end
end