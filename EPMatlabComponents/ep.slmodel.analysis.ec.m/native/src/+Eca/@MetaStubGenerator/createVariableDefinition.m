function sFileContent = createVariableDefinition(oStubGen, sFileContent, oStubInfo)

% note: a variable definition is the same as a declaration but without the keyword "extern" at the beginning
sFileContent = oStubGen.createVariableDeclaration(sFileContent, oStubInfo, false);
end