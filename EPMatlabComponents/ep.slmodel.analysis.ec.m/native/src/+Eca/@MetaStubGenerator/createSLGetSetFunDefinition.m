%createSLGetSetFunDefinition
function sFileContent = createSLGetSetFunDefinition(oStubGen, sFileContent, oStubInfo)

sDataType = oStubInfo.sVariableDatatype;
sStubSLGetSetVariableName = oStubInfo.sStubSLGetSetVariableName;
sStubSLGetFunName = oStubInfo.sStubSLGetFunName;
sStubSLSetFunName = oStubInfo.sStubSLSetFunName;
bIsScalar = oStubInfo.nDimAsRowCol;
bIsArray1D = oStubInfo.bIsArray1D;
nDimAsRowCol = oStubInfo.nDimAsRowCol;

%Variable
if isfield(oStubInfo, 'bStubVariable')
    if oStubInfo.bStubVariable
        sFileContent = oStubGen.createVariableDefinition(sFileContent, oStubInfo);
    end
end
%Functions
if bIsScalar
%     %getset global variab
%     sFileContent = [sFileContent, sDataType,' ',sStubSLGetSetVariableName,';\n\n'];
    %get access function
    sFileContent =  [sFileContent, sDataType,' ',sStubSLGetFunName,'(void) {\n'];
    sFileContent =  [sFileContent,' return ', sStubSLGetSetVariableName, ';\n'];
    sFileContent =  [sFileContent,'}\n\n'];
    %set access function
    sFileContent =  [sFileContent,'void',' ',sStubSLSetFunName, '(',sDataType,' val) {\n'];
    sFileContent =  [sFileContent,'  ', sStubSLGetSetVariableName,' =  val;\n'];
    sFileContent =  [sFileContent,'}\n\n'];
else
%     %getset global variable
%     sFileContent = [sFileContent, sDataType,' ', sStubSLGetSetVariableName, '[',num2str(prod(nDimAsRowCol)),']', ';\n\n'];
    %get/set functions
    if ~bIsArray1D %Matrix
        sNROWs = [upper(sStubSLGetSetVariableName),'_NROWS'];
        sNCOLs =  [upper(sStubSLGetSetVariableName),'_NCOLS'] ;
        sFileContent = [sFileContent, '#define  ', sNROWs ,' ',num2str(nDimAsRowCol(1)),'\n'];
        sFileContent = [sFileContent, '#define  ', sNCOLs,'  ',num2str(nRowCol(2)),'\n\n'];
        %get access function
        sFileContent =  [sFileContent, sDataType, ' ',sStubSLGetFunName,'(int colIndex) {\n'];
        sFileContent =  [sFileContent,' int rowIndex = ', sNCOLs,' * (colIndex % ',sNROWs,') + colIndex / ',sNROWs,'; \n'];
        sFileContent =  [sFileContent,' return ', sStubSLGetSetVariableName, '[rowIndex];\n'];
        sFileContent =  [sFileContent,'}\n\n'];
        %set access function
        sFileContent =  [sFileContent,'void ',sStubSLSetFunName,'(int colIndex, ',sDataType,' val) {\n'];
        sFileContent =  [sFileContent,' int rowIndex = ', sNCOLs,' * (colIndex % ',sNROWs,') + colIndex / ',sNROWs,'; \n'];
        sFileContent =  [sFileContent,' ', sStubSLGetSetVariableName,'[rowIndex] = val;\n'];
        sFileContent =  [sFileContent,'}\n\n'];
    else %Vector
        %get access function
        sFileContent =  [sFileContent, sDataType,' ',sStubSLGetFunName,'(int index) {\n'];
        sFileContent =  [sFileContent,' return ', sStubSLGetSetVariableName, '[index];\n'];
        sFileContent =  [sFileContent,'}\n\n'];
        %set access function
        sFileContent =  [sFileContent,'void ',sStubSLSetFunName,'(int index, ',sDataType,' val) {\n'];
        sFileContent =  [sFileContent,'  ', sStubSLGetSetVariableName,'[index] = val;\n'];
        sFileContent =  [sFileContent,'}\n\n'];
    end
end
end