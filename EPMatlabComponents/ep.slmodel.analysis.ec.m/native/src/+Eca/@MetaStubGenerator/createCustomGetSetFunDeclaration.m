%createCustomGetSetFunDeclaration
function sFileContent = createCustomGetSetFunDeclaration(oStubGen, sFileContent, oStubInfo)

sStubCustomGetFunName  = oStubInfo.sStubCustomGetFunName;
sStubCustomSetFunName  = oStubInfo.sStubCustomSetFunName;
aoStubCustomGetFunArgs = oStubInfo.aoStubCustomGetFunArgs;
aoStubCustomSetFunArgs = oStubInfo.aoStubCustomSetFunArgs;

%Process variable declaration
if oStubInfo.bStubVariable
    sFileContent = oStubGen.createVariableDeclaration(sFileContent, oStubInfo);
end

%Process Get function
if (~isempty(sStubCustomGetFunName) && ~isempty(aoStubCustomGetFunArgs))
    sFunSignature = oStubGen.createCustomStubFunSignature(oStubInfo, 'Get');
    sFileContent  = [sFileContent, '\n', sFunSignature, ';\n'];
end

%Process Set function
if (~isempty(sStubCustomSetFunName) && ~isempty(aoStubCustomSetFunArgs))
    sFunSignature = oStubGen.createCustomStubFunSignature(oStubInfo, 'Set');
    sFileContent  = [sFileContent, '\n', sFunSignature, ';\n'];
end  
end