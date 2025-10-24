%createCustomGetSetFunDefinition
function sFileContent = createCustomGetSetFunDefinition(oStubGen, sFileContent, oStubInfo)

sStubCustomGetFunName = oStubInfo.sStubCustomGetFunName;
sStubCustomSetFunName = oStubInfo.sStubCustomSetFunName;
aoStubCustomGetFunArgs = oStubInfo.aoStubCustomGetFunArgs;
aoStubCustomSetFunArgs = oStubInfo.aoStubCustomSetFunArgs;

%Process variable definition
if oStubInfo.bStubVariable
    sFileContent = oStubGen.createVariableDefinition(sFileContent, oStubInfo);
end

%Process Get Function
if (~isempty(sStubCustomGetFunName) && ~isempty(aoStubCustomGetFunArgs))
    sFunSignature = oStubGen.createCustomStubFunSignature(oStubInfo, 'Get');
    sFunBody = oStubGen.createCustomStubFunBody(oStubInfo, 'Get');
    sFileContent = [sFileContent, sFunSignature, sFunBody];
end

%Process Set Function
if (~isempty(sStubCustomSetFunName) && ~isempty(aoStubCustomSetFunArgs))
    sFunSignature = oStubGen.createCustomStubFunSignature(oStubInfo, 'Set');
    sFunBody = oStubGen.createCustomStubFunBody(oStubInfo, 'Set');
    sFileContent = [sFileContent, sFunSignature, sFunBody];    
end
end