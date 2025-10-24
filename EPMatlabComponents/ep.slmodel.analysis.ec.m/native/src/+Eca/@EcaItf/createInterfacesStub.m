function oEca = createInterfacesStub(oEca, casIncludeExternalFileNames)
% Generate stub file to declare and/or define imported variables or
% Simulink Get/Set functions

[sMainHeaderFile, casDefaultTypesHeaderFiles] = oEca.getDefaultTypesHeaderFile;
if isempty(oEca.oRootScope)
    return;
end

if oEca.bDiagMode
    fprintf('\n## Generation of Stub code ... \n');
end

%List all relevant header file to be included in the _STUB.H
casIncludeFileNames = casIncludeExternalFileNames;
if oEca.bIsAutosarArchitecture
    casIncludeFileNames{end+1} = [oEca.sAutosarModelName, '.h'];
else
    casIncludeFileNames = [casIncludeFileNames, casDefaultTypesHeaderFiles];
end
aoStubItfs = [];
casMissingHFiles = {};
casMissingCFiles = {};
bGenerateStub = false;

oaItfs = getAllValidUniqVarItfInclChdrScopes(oEca.oRootScope);
for iItf = 1:numel(oaItfs)
    %Check if stub variable is required
    if oaItfs(iItf).bStubNeeded && ~oaItfs(iItf).bIsAutosarCom
        if oaItfs(iItf).bHFileMissing && ~isempty(oaItfs(iItf).codeHeaderFile)
            casMissingHFiles = unique([casMissingHFiles, Eca.EcaItf.FileName(oaItfs(iItf).codeHeaderFile)]);
        end
        if oaItfs(iItf).bCFileMissing && ~isempty(oaItfs(iItf).codeHeaderFile)
            sMissingCFile = replace(Eca.EcaItf.FileName(oaItfs(iItf).codeHeaderFile),'.h','.c');
            casMissingCFiles = unique([casMissingCFiles, sMissingCFile]);
            oaItfs(iItf).codeDefinitionFile = sMissingCFile{1};
        end
        aoStubItfs = [aoStubItfs oaItfs(iItf)]; %#ok<AGROW>
        bGenerateStub = true;
    end
end

%"Define" interfaces to be stubbed
aoStubDefineItfs = [];
oaDefineItfs = getAllValidUniqDefinesItfInclChdrScopes(oEca.oRootScope);
for iItf = 1:numel(oaDefineItfs)
    if oaDefineItfs(iItf).bStubNeeded && ~oaDefineItfs(iItf).bIsAutosarCom
        aoStubDefineItfs = [aoStubDefineItfs oaDefineItfs(iItf)]; %#ok<AGROW>
        if oaDefineItfs(iItf).bHFileMissing && ~isempty(oaDefineItfs(iItf).codeHeaderFile)
            casMissingHFiles = unique([casMissingHFiles Eca.EcaItf.FileName(oaDefineItfs(iItf).codeHeaderFile)]);
        end
        bGenerateStub = true;
    end
end

%Get used type info
if isempty(casDefaultTypesHeaderFiles)
    sDefaultTypesHeader = sMainHeaderFile;
else
    sDefaultTypesHeader = casDefaultTypesHeaderFiles{1};
end
astTypeInfo = i_createTypeInfo(oEca, [aoStubItfs, aoStubDefineItfs], sDefaultTypesHeader, casIncludeExternalFileNames);

%Process stub generation
if bGenerateStub
    
    if not(isempty(aoStubItfs))
        abIsBusNotFirstElement = arrayfun(@(oItf) oItf.isBusElement && ~oItf.isBusFirstElement, aoStubItfs);
        aoStubItfs = aoStubItfs(~abIsBusNotFirstElement);
        %Append stubbed interface header files
        casIncludeFileNames = unique([casIncludeFileNames {aoStubItfs(:).codeHeaderFile}], 'stable');
    end
    if not(isempty(aoStubDefineItfs))
        abIsBusNotFirstElement = arrayfun(@(oItf) oItf.isBusElement && ~oItf.isBusFirstElement, aoStubDefineItfs);
        aoStubDefineItfs = aoStubDefineItfs(~abIsBusNotFirstElement);
        casIncludeFileNames = unique([casIncludeFileNames {aoStubDefineItfs(:).codeHeaderFile}], 'stable');
    end

    %Create stub_eca folder
    sStubDir = oEca.createStubDir();

    %Main stub file names
    sMainStubDefFile = oEca.getStubSourceFile('main');
    sMainStubDeclFile = oEca.getStubHeaderFile('main');

    %Create missing header files (Not for Defines)
    casStubHFiles = {};
    casStubCFiles = {};

    %Create content of each header file (Combine stub of Variable declaration and #Defines)
    for k = 1:numel(casMissingHFiles)

        sContent = '';
        casIncludeHeadersForTypes = {};
        hfilename = casMissingHFiles{k};

        %Interfaces which Headerfile equal the current looped missing file
        if ~isempty(aoStubItfs)
            tmpItfs = aoStubItfs(ismember({aoStubItfs(:).codeHeaderFile}, hfilename));
            if ~isempty(tmpItfs)
                [sContent, casIncludeHeadersForTypes] = i_createDeclarations(tmpItfs, astTypeInfo);
            end
        end

        %"Defines" Interfaces which Headerfile equals the current looped missing file
        if ~isempty(aoStubDefineItfs)
            tmpItfs = aoStubDefineItfs(ismember({aoStubDefineItfs(:).codeHeaderFile}, hfilename));
            if ~isempty(tmpItfs)
                sContent = sprintf('%s\n%s', sContent, i_createDefines(tmpItfs));
            end
        end

        %Create H file
        if ~isempty(char(sContent))
            casIncludeFileNamesForHeader = setdiff([casIncludeExternalFileNames, casIncludeHeadersForTypes], ...
                ['', hfilename], 'stable');
            
            astTypeDefStubs = astTypeInfo(strcmp(hfilename, {astTypeInfo.header}));
            sTypeDefContent = '';
            for i = 1:numel(astTypeDefStubs)
                stTypeInfo = astTypeDefStubs(i);
                if ~ismember(stTypeInfo.requiredHeaders , hfilename)
                    casIncludeFileNamesForHeader = unique([casIncludeFileNamesForHeader, stTypeInfo.requiredHeaders], 'stable');
                    sTypeDefContent = [stTypeInfo.typedefContent, sTypeDefContent];
                else
                    % the type def depends on other types defined in the same header file
                    sTypeDefContent = [sTypeDefContent, stTypeInfo.typedefContent];
                end
                astTypeInfo(strcmp(stTypeInfo.sldatatype, {astTypeInfo.sldatatype})).stubneeded = false;
            end
            sContent = [sTypeDefContent, sContent];
            casStubHFiles{end+1} = i_createHeaderfile(fullfile(sStubDir, hfilename), sContent, casIncludeFileNamesForHeader);
            
            %Append file to all include files required in _SUB.H
            sFileName = char(Eca.EcaItf.FileName(casStubHFiles{end}));
            if ~ismember(sFileName, casIncludeFileNames)
                casIncludeFileNames{end+1} = sFileName; %#ok<AGROW>
            end
        end
    end
    % stub missing types
    i_stubMissingTypes(oEca, astTypeInfo);
    
    bSeparateStubFiles = oEca.stConfig.General.GenerateSeparateStubFiles;
    %Create the source file for Interface variable definition
    %Creates multiple .c-stub-files for every stub-header when bSeparateStubFiles == 1
    if bSeparateStubFiles && ~isempty(aoStubItfs) && ~isempty(casMissingCFiles)
        aoStubbedItfs = [];
        for i = 1:numel(casMissingCFiles)
            sMissingCFile = casMissingCFiles{i};
            aoTmpItfs = aoStubItfs(ismember({aoStubItfs(:).codeDefinitionFile}, sMissingCFile));
            sContent = i_createDefinitions(aoTmpItfs, astTypeInfo);
            casStubCFiles{end+1} = i_createSourcefile(fullfile(sStubDir , sMissingCFile), sContent, sMainHeaderFile); %#ok<AGROW>

            aoStubbedItfs = [aoStubbedItfs aoTmpItfs]; %#ok<AGROW>
        end

        %get all Interfaces that are not yet stubbed and write them to into main stub
        aoMissingStubItfs = aoStubItfs(~ismember({aoStubItfs(:).sUniqID}, {aoStubbedItfs(:).sUniqID}));
        if ~isempty(aoMissingStubItfs)
            %create main stub .c and .h file           
            casStubHFiles{end+1} = i_createHeaderfile(sMainStubDeclFile, {}, casIncludeFileNames);
            sContent = i_createDefinitions(aoMissingStubItfs, astTypeInfo);
            casStubCFiles{end+1} = i_createSourcefile(sMainStubDefFile, sContent, Eca.EcaItf.FileName(sMainStubDeclFile));
        end
    else
        %create main stub .c and .h file   
        casStubHFiles{end+1} = i_createHeaderfile(sMainStubDeclFile, {}, casIncludeFileNames);
        sContent = i_createDefinitions(aoStubItfs, astTypeInfo);
        casStubCFiles{end+1} = i_createSourcefile(sMainStubDefFile, sContent, Eca.EcaItf.FileName(sMainStubDeclFile));
    end

    %Show generate file in the workspace
    casFiles = [casStubHFiles casStubCFiles];
    if oEca.bDiagMode
        for k=1:numel(casFiles)
            fprintf('<a href="matlab:winopen(''%s'')">%s</a>\n', casFiles{k}, casFiles{k});
        end
    end

    %Updatelist of source files list
    oEca = updateSourceFileList(oEca, casStubHFiles, casStubCFiles);

    oEca.bStubGenerated = true;
    oEca.oRootScope.casStubFiles = casFiles;
    %Stubbed interfaces
    oEca.oRootScope.oaStubbedIfs  = aoStubItfs;
    oEca.oRootScope.oaStubbedDefs = aoStubDefineItfs;
end
end


%%
function [sContent, casIncludeHeaders] = i_createDeclarations(aoItfs, astTypeInfo)
sContent = '';
casIncludeHeaders = {};
if ~isempty(aoItfs)
    for iItf = 1:numel(aoItfs)
        
        oItf = aoItfs(iItf);
        stCodeFormatCfg = oItf.codeFormatCfg;
        oDataObj = oItf.findCorrespondingDataObject();
        
        [sDataType, sHeaderFile] = i_getDataType(oItf, astTypeInfo);
        sVariableName = i_getVarName(oItf);
        aiRowCol = i_getRowColDim(oItf);
        
        %isAccessedByVariable
        if oItf.isAccessedByVariable

            sDeclaration = i_getVariableDeclaration(sDataType, sVariableName, aiRowCol, stCodeFormatCfg);

        %isAccessedByFunction
        elseif oItf.isAccessedByFunction
            
            if strcmpi(stCodeFormatCfg.Stub.accessFuncType, 'Simplified')

                
                [sGlobalVar, sGetFunc, sSetFunc] = i_getFunctionNaming(oItf, stCodeFormatCfg, oDataObj, sVariableName);
                                
                sDeclaration = i_getFunctionDeclaration(sDataType, sGlobalVar, aiRowCol, sGetFunc, sSetFunc);

            else
                sDeclaration = ['//Only the "Simplified" accessFuncType is supported at the moment : ', oItf.name, ';\n\n'];
            end
            %isCodeStructComponent
        else
            sDeclaration = ['//Structure Variable Stub is not yet supported: ', oItf.name, ';\n\n'];
        end
        sContent = [sContent, sDeclaration, '\n\n'];
        if ~isempty(sHeaderFile) && ~ismember(sHeaderFile, casIncludeHeaders)
            casIncludeHeaders = [casIncludeHeaders, sHeaderFile];
        end
    end
    sContent = [sContent, '\n\n'];
    sContent = sprintf(sContent);
end
end


%%
function sDeclaration = i_getVariableDeclaration(sDataType, sVariableName, aiRowCol, stCodeFormatCfg)
if aiRowCol(1) == 1 && aiRowCol(2) == 1
    sDeclaration = ['extern ', sDataType, ' ', sVariableName, ';'];
else
    if aiRowCol(1) == 1
        sDeclaration =  ['extern ', sDataType, ' ', sVariableName, '[',num2str(aiRowCol(2)),']', ';'];
    else
        if stCodeFormatCfg.Format.b2DMatlabIs1DCode
            sDeclaration =  ['extern ', sDataType, ' ', sVariableName, '[',num2str(prod(aiRowCol)),']', ';'];
        else
            if strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                sDeclaration =  ['extern ', sDataType, ' ', sVariableName, ...
                    '[',num2str(aiRowCol(1)),'][',num2str(aiRowCol(2)),']', ';'];
            elseif strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_ColRow')
                sDeclaration =  ['extern ', sDataType, ' ', sVariableName, ...
                    '[',num2str(aiRowCol(2)),'][',num2str(aiRowCol(1)),']', ';'];
            else
                sDeclaration =  ['extern ', sDataType, ' ', sVariableName, ...
                    '[',num2str(prod(aiRowCol)),']', ';'];
            end
        end
    end
end
end


%%
function sDeclaration = i_getFunctionDeclaration(sDataType, sGlobalVar, aiRowCol, sGetFunc, sSetFunc)
if aiRowCol(1) == 1 && aiRowCol(2) == 1
    sDeclaration = ['extern ', sDataType, ' ', sGlobalVar, ';\n'];
    if ~isempty(sGetFunc)
        sDeclaration =  [sDeclaration, 'extern ', sDataType, ' ', sGetFunc, '(void);\n'];
    end                    
    if ~isempty(sSetFunc)
        sDeclaration =  [sDeclaration,'extern void ', sSetFunc, '(', sDataType, ' val);\n'];
    end
else
    sDeclaration = ['extern ', sDataType, ' ', sGlobalVar, '[',num2str(prod(aiRowCol)), '];\n'];
    if aiRowCol(1) == 1 
        if ~isempty(sGetFunc)
            sDeclaration =  [sDeclaration, 'extern ', sDataType, ' ', sGetFunc, '(int colIndex);\n'];
        end
        if ~isempty(sSetFunc)
            sDeclaration =  [sDeclaration, 'extern void ', sSetFunc, '(int index, ', sDataType, ' val);\n'];
        end
    else 
        if ~isempty(sGetFunc)
            sDeclaration =  [sDeclaration, 'extern ', sDataType, ' ', sGetFunc, '(int index);\n'];
        end
        if ~isempty(sSetFunc)
            sDeclaration =  [sDeclaration, 'extern void ', sSetFunc, '(int index, ' ,sDataType, ' val);\n'];
        end
    end
end
end


%%
function sContent = i_createDefinitions(aoItfs, astTypeInfo)
sContent = '';
if ~isempty(aoItfs)
    for iItf = 1:numel(aoItfs)
        if aoItfs(iItf).bCFileMissing

            oItf = aoItfs(iItf);
            stCodeFormatCfg = oItf.codeFormatCfg;
            oDataObj = oItf.findCorrespondingDataObject();

            [sDataType, ~] = i_getDataType(oItf, astTypeInfo);
            sVariableName = i_getVarName(oItf);
            aiRowCol = i_getRowColDim(oItf);
            
            %isAccessedByVariable
            if oItf.isAccessedByVariable

                sDefinition = i_getVariableDefinition(sDataType, sVariableName, aiRowCol, stCodeFormatCfg);
                
                %isAccessedByFunction
            elseif oItf.isAccessedByFunction
                if strcmpi(stCodeFormatCfg.Stub.accessFuncType, 'Simplified')
                    
                    [sGlobalVar, sGetFunc, sSetFunc] = i_getFunctionNaming(oItf, stCodeFormatCfg, oDataObj, sVariableName);

                    sDefinition = i_getFunctionDefinition(sDataType, sGlobalVar, aiRowCol, sGetFunc, sSetFunc);
                    
                else
                    sDefinition = ['//Only the "Simplified" accessFuncType is currently supported : ', aoItfs(iItf).name, ';\n\n'];
                end

                %isCodeStructComponent
            else
                sDefinition = ['//Structure Variable Stub is not yet supported: ', aoItfs(iItf).name, ';\n\n'];
            end
        end
        
        sContent = [sContent, sDefinition, '\n\n'];
        sContent = strrep(sContent, '%', '%%');
        sContent = sprintf(sContent);
    end
end
end


%%
function sDefinition = i_getVariableDefinition(sDataType, sVariableName, aiRowCol, stCodeFormatCfg)
%Scalar
if aiRowCol(1) == 1 && aiRowCol(2) == 1
    sDefinition =  [sDataType, ' ', sVariableName, ';'];
else
    if aiRowCol(1) == 1
        sDefinition =  [sDataType, ' ', sVariableName, '[',num2str(aiRowCol(2)),']', ';'];
    else % Matrix
        if stCodeFormatCfg.Format.b2DMatlabIs1DCode
            sDefinition =  [sDataType, ' ', sVariableName, '[',num2str(prod(aiRowCol)),']', ';'];
        else
            if strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                sDefinition =  [sDataType, ' ', sVariableName, ...
                    '[',num2str(aiRowCol(1)),'][',num2str(aiRowCol(2)),']', ';'];
            elseif strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_ColRow')
                sDefinition =  [sDataType, ' ', sVariableName, ...
                    '[',num2str(aiRowCol(2)),'][',num2str(aiRowCol(1)),']', ';'];
            else
                sDefinition =  [sDataType, ' ', sVariableName, '[',num2str(prod(aiRowCol)),']', ';'];
            end
        end
    end
end
end


%%
function sDefinition = i_getFunctionDefinition(sDataType, sGlobalVar, aiRowCol, sGetFunc, sSetFunc)
if aiRowCol(1) == 1 && aiRowCol(2) == 1
    sDefinition = [sDataType, ' ', sGlobalVar, ';\n'];
    if ~isempty(sGetFunc)
        sDefinition =  [sDefinition, sDataType, ' ', sGetFunc, '(void) {\n'];
        sDefinition =  [sDefinition, ' return ', sGlobalVar, ';\n'];
        sDefinition =  [sDefinition, '}\n'];
    end
    if ~isempty(sSetFunc)
        sDefinition =  [sDefinition, 'void ', sSetFunc, '(', sDataType, ' val) {\n'];
        sDefinition =  [sDefinition, '  ', sGlobalVar, ' = val;\n'];
        sDefinition =  [sDefinition, '}\n'];
    end
else
    sDefinition = [sDataType, ' ', sGlobalVar, '[', num2str(prod(aiRowCol)), '];\n'];
    if ~isempty(sGetFunc)
        sDefinition =  [sDefinition, sDataType, ' ', sGetFunc, '(int index) {\n'];
        sDefinition =  [sDefinition, ' return ', sGlobalVar, '[index];\n'];
        sDefinition =  [sDefinition, '}\n'];
    end
    if ~isempty(sSetFunc)
        sDefinition =  [sDefinition, 'void ', sSetFunc, '(int index, ', sDataType, ' val) {\n'];
        sDefinition =  [sDefinition, '  ', sGlobalVar, '[index] = val;\n'];
        sDefinition =  [sDefinition,'}\n'];
    end
end
end

%%
function [sGlobalVar, sGetFunc, sSetFunc] = i_getFunctionNaming(oItf, stCodeFormatCfg, oDataObj, sVariableName)
if ~oItf.isBusElement
    sGlobalVar = oItf.replaceAndEvaluateMacros(stCodeFormatCfg.Stub.StubVariableName, oDataObj);

    sGetFunc = oItf.replaceAndEvaluateMacros(stCodeFormatCfg.Stub.getFunc.Name, oDataObj);
    sGetFunc = strrep(sGetFunc, '$N', oItf.getAliasRootName());

    sSetFunc = oItf.replaceAndEvaluateMacros(stCodeFormatCfg.Stub.setFunc.Name, oDataObj);
    sSetFunc = strrep(sSetFunc, '$N', oItf.getAliasRootName());
else
    sGlobalVar = sVariableName;
    
    sGetFunc = oItf.replaceAndEvaluateMacros(stCodeFormatCfg.Stub.getFunc.Name, oDataObj);
    sGetFunc = strrep(sGetFunc, '$N', sVariableName);
    
    sSetFunc = oItf.replaceAndEvaluateMacros(stCodeFormatCfg.Stub.setFunc.Name, oDataObj);
    sSetFunc = strrep(sSetFunc, '$N', sVariableName);
end
end


%%
function sContent = i_createDefines(oDefineItf)
sContent = '';
if ~isempty(oDefineItf)
    for k = 1:numel(oDefineItf)
        dataObject = oDefineItf(k).evalinGlobal(oDefineItf(k).name);
        %define
        sContent =  [sContent, '#define ', oDefineItf(k).codeVariableName, ' ', num2str(dataObject.Value), ' \n'];
    end
    sContent  = sprintf(sContent);
end
end


%%
function [sDataType, sHeaderFile] = i_getDataType(oItf, astTypeInfo)
sHeaderFile = [];
sDataType = oItf.codedatatype;
if oItf.isBusElement
    stTypeInfo = astTypeInfo(strcmp(oItf.metaBus.busObjectName, {astTypeInfo.sldatatype}));
    sDataType = stTypeInfo.codedatatype;
    sHeaderFile = stTypeInfo.header;
end
end


%%
function sVarName = i_getVarName(oItf)
sVarName = oItf.codeVariableName;
if oItf.isBusElement
    sVarName = oItf.codeStructName;
end
end


%%
function aiRowCol = i_getRowColDim(oItf)
aiRowCol = oItf.nDimAsRowCol;
if oItf.isBusElement
    aiDim = oItf.oSigSL_.aiDim_;
    if aiDim(1) ==1
        aiRowCol = aiDim;
    elseif aiDim(1) == 2
        aiRowCol = aiDim(2:3);
    else
        % more than two dimionions are not suported
    end
end
end


%%
function sFile = i_createHeaderfile(sFile, sContent, includeFileNames)
includeFileNames = setdiff(includeFileNames, '', 'stable'); %remove empty name
includeFileNames = cellstr(includeFileNames);
sContent = cellstr(sContent);

[~, fileName] = fileparts(sFile);

%Create H file
fid = fopen(sFile,'w');
fprintf(fid, '#ifndef _%s_ET_H_\n',upper(fileName));
fprintf(fid, '#define _%s_ET_H_\n',upper(fileName));
fprintf(fid, '\n');
if ~isempty(char(includeFileNames))
    fprintf(fid, '#include "%s"\n',  includeFileNames{:});
end
fprintf(fid, '\n');
if ~isempty(char(sContent))
    fprintf(fid, '%s\n', sContent{:});
end
fprintf(fid, '\n');
fprintf(fid, '#endif //_%s_ET_H_\n',upper(fileName));
fclose(fid);
end


%%
function sFile = i_createSourcefile(sFile, sContent, includeFileNames)
[~, fileName] = fileparts(sFile);
includeFileNames = cellstr(includeFileNames);
sContent = cellstr(sContent);

%Create C file
fid = fopen(sFile,'w');
fprintf(fid, '#ifndef _%s_ET_C_\n',upper(fileName));
fprintf(fid, '#define _%s_ET_C_\n',upper(fileName));
fprintf(fid, '\n');
if ~isempty(char(includeFileNames))
    fprintf(fid, '#include "%s"\n',  includeFileNames{:});
end
fprintf(fid, '\n');
fprintf(fid, '%s\n', sContent{:});
fprintf(fid, '\n');
fprintf(fid, '#endif //_%s_ET_C_\n',upper(fileName));
fclose(fid);
end


%%
function stType = i_createDataTypeInfo(sldatatype, codedatatype)
stType =struct('sldatatype', sldatatype, ...
                'codedatatype', codedatatype, ...
                'kind', 'basetype', ...
                'header', '', ...
                'stubneeded', false, ...
                'requiredHeaders', [], ...
                'typedefContent', '');
end


%%
function astTypeInfo = i_createTypeInfo(oEca, allItfs, sDefaultTypesHeader, casIncludeExternalFileNames)
astTypeInfo = [];
for i = 1:numel(allItfs)
    oTmp = allItfs(i);
    if (i == 1 || ~ismember(oTmp.sldatatype, {astTypeInfo.sldatatype}))
        stTypeInfo = i_createDataTypeInfo(oTmp.sldatatype, oTmp.codedatatype);
        if (~isempty(casIncludeExternalFileNames))
            stTypeInfo.header = casIncludeExternalFileNames{1};
        end
        astTypeInfo = [astTypeInfo , stTypeInfo];
    end
end

astTypeInfo = i_processBusTypes(astTypeInfo, oEca, allItfs, sDefaultTypesHeader);
end


%%
function i_stubMissingTypes(oEca, astTypeInfo)
astMissingTypes = astTypeInfo([astTypeInfo(:).stubneeded]);
for i = 1:numel(astMissingTypes)
    stTypeInfo = astMissingTypes(i);
    i_createHeaderfile(fullfile(oEca.getStubCodeDir, stTypeInfo.header), stTypeInfo.typedefContent, stTypeInfo.requiredHeaders);
end
end


%%
function astTypeInfo = i_processBusTypes(astTypeInfo, oEca, allItfs, sDefaultTypesHeader)
aoBusses = allItfs(arrayfun(@(oTmp) oTmp.isBusElement && oTmp.isBusFirstElement, allItfs));
if(isempty(aoBusses))
    return;
end
casAllHeaders = Eca.EcaItf.FileName(oEca.casCodegenHeaderFiles);
for i = 1:numel(aoBusses)
    oTmp = aoBusses(i);
    sDataType = oTmp.metaBus.busObjectName;
    oBusObject = oTmp.evalinGlobal(oTmp.metaBus.busObjectName);

    if (i==1)
        adFilter = ones(1, numel(aoBusses));
    elseif(ismember(sDataType, {astTypeInfo.sldatatype}))
        adFilter(i) = 0;
        continue;
    end
    
    astTypeInfo = i_addBusTypeInfo(astTypeInfo, sDataType, oBusObject, sDefaultTypesHeader, casAllHeaders);
end

aoBusTypeDefStubs = aoBusses(logical(adFilter));
for i = 1:numel(aoBusTypeDefStubs)
    oTmp = aoBusTypeDefStubs(i);
    sDataType = oTmp.metaBus.busObjectName;
    oBusObject = oTmp.evalinGlobal(oTmp.metaBus.busObjectName);
    
    casIncludes = [];
    sContent = 'typedef struct {\n';
    aoBusElements = oBusObject.Elements;
    for k = 1:numel(aoBusElements)
        oElement = aoBusElements(k);
        sType = oElement.DataType;
        if (startsWith(sType, 'Bus: '))
            sType = strrep(sType, 'Bus: ', '');
            if ~ismember(sType, {astTypeInfo.sldatatype})
                oBusObject = oTmp.evalinGlobal(sType);
                astTypeInfo = i_addBusTypeInfo(astTypeInfo, sType, oBusObject, sDefaultTypesHeader, casAllHeaders);
            end
        end
        sName = oElement.Name;
        stElementTypeInfo = astTypeInfo(strcmp(sType, {astTypeInfo.sldatatype}));
        sContent = [sContent, '    ', stElementTypeInfo.codedatatype, ' ', sName];
        aiDim = oElement.Dimensions;
        if prod(aiDim) > 1
            if isprop(oBusObject, 'PreserveElementDimensions') && oBusObject.PreserveElementDimensions
                if numel(aiDim) == 1 || aiDim(1) == 1 || aiDim(2) == 1
                    sContent = [sContent, '[', num2str(prod(aiDim)), ']'];
                else
                    sContent = [sContent, '[', num2str(aiDim(1)), ']', '[', num2str(aiDim(2)), ']'];
                end
            else
                sContent = [sContent, '[', num2str(prod(aiDim)), ']'];
            end
        end
        sContent = [sContent, ';\n'];
        
        if(~isempty(stElementTypeInfo.header))
            casIncludes = unique([casIncludes {stElementTypeInfo.header}]);
        end
    end
    sContent = [sContent, '} ', sDataType, ';\n\n'];
    sContent = sprintf(sContent);
    
    astTypeInfo(strcmp(sDataType, {astTypeInfo.sldatatype})).typedefContent = sContent;
    astTypeInfo(strcmp(sDataType, {astTypeInfo.sldatatype})).requiredHeaders = casIncludes;
end
end


%%
function astTypeInfo = i_addBusTypeInfo(astTypeInfo, sDataType, oBusObject, sDefaultTypesHeader, casAllHeaders)
stTypeInfo = i_createDataTypeInfo(sDataType, sDataType);
stTypeInfo.kind = 'bus';
sHeaderFile = oBusObject.HeaderFile;
if isempty(sHeaderFile)
    if strcmp(oBusObject.DataScope, 'Auto')
        sHeaderFile = sDefaultTypesHeader;
    end
    if strcmp(oBusObject.DataScope, 'Exported')
        sHeaderFile = [sDataType, '.h'];
    end
end
stTypeInfo.header = sHeaderFile;
if (~ismember(sHeaderFile, casAllHeaders))
    stTypeInfo.stubneeded = true;
end
astTypeInfo = [astTypeInfo, stTypeInfo];
end