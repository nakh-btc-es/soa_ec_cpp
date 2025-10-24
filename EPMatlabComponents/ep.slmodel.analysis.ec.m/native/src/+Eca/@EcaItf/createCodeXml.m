function createCodeXml(oEca)

if oEca.bDiagMode
    fprintf('\n## Generation of Code Architecture xml description file ...\n')
end

oRootScope = oEca.oRootScope;

%Gathering files and include pathes
[stFiles, stIncludePaths, stDefines] = i_getCCodeFiles(oRootScope);

%Get functions, sub-functions and corresponding interfaces
sArchName  = [oEca.sModelName, ' [C-Code]'];

stFunctions = i_getSubFunctions(oEca, stFiles, sArchName, oRootScope.sStubVarInitFunc);


if ~isempty(stDefines)
    stDefines.Define = [reshape(stDefines.Define, 1, []), reshape(i_getCompilerDefineAttributes(oEca.oModelActiveCfg), 1, [])];
else
    stDefines.Define = i_getCompilerDefineAttributes(oEca.oModelActiveCfg);
end

% put all structures together
stCodeModel.Files        = stFiles;
stCodeModel.IncludePaths = stIncludePaths;
stCodeModel.Defines      = stDefines;
stCodeModel.Functions    = stFunctions;
stETXml.CodeModel        = stCodeModel;

ep_core_feval('epecastruct2xml', stETXml, oEca.sCodeXmlFile);
end


%%
function castInterfaceObj = i_getItfObj(castInterfaceObj, sPortKind, sPortClass, oItf)

% set kind (in, out, cal, disp)
Attributes.kind = sPortKind;

%Append interface attibutes : var, access
if strcmp(sPortKind, 'cal')
    %Append interface attibutes for "cal"
    if oItf.bIsScalar
        if strcmp(sPortClass, 'struct')
            Attributes.access = oItf.codeStructComponentAccess;
            Attributes.var = oItf.codeStructName;
        elseif strcmp(sPortClass, 'var')
            Attributes.var = oItf.codeVariableName;
        end
        castInterfaceObj{end+1}.Attributes = Attributes;
    else
        %Array/Matrix
        if oItf.bIsArray1D
            %1D
            for nCol = 1:oItf.nDimAsRowCol(2)
                if strcmp(sPortClass, 'struct')
                    Attributes.var = oItf.codeStructName;
                    Attributes.access = [oItf.codeStructComponentAccess '[',num2str(nCol-1),']'];
                else
                    Attributes.var = oItf.codeVariableName;
                    Attributes.access = ['[',num2str(nCol-1),']'];
                end
                castInterfaceObj{end+1}.Attributes = Attributes; %#ok<AGROW>
            end
        else
            %2D
            if oItf.bIsAutosarCom
                stCodeFormatCfg = oItf.stArComCfg;
            else
                stCodeFormatCfg = oItf.codeFormatCfg;
            end
            for nRow = 1:oItf.nDimAsRowCol(1)
                for nCol = 1:oItf.nDimAsRowCol(2)
                    %2D Matlab matrix generated as 1D variable
                    if stCodeFormatCfg.Format.b2DMatlabIs1DCode
                        if strcmpi(stCodeFormatCfg.Format.s2DMatlabTo1DCodeConv, 'ColumnMajor')
                            indexElmt = (nCol-1)*oItf.nDimAsRowCol(1)+(nRow-1);
                        else
                            indexElmt = (nRow-1)*oItf.nDimAsRowCol(2)+(nCol-1);
                        end
                        if strcmp(sPortClass, 'struct')
                            Attributes.var = oItf.codeStructName;
                            Attributes.access = [oItf.codeStructComponentAccess '[',num2str(indexElmt),']'];
                        else
                            Attributes.var = oItf.codeVariableName;
                            Attributes.access = ['[',num2str(indexElmt),']'];
                        end
                        castInterfaceObj{end+1}.Attributes = Attributes; %#ok<AGROW>
                    else
                        if strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_RowCol')
                            if strcmp(sPortClass, 'struct')
                                Attributes.var = oItf.codeStructName;
                                Attributes.access = [oItf.codeStructComponentAccess '[',num2str(nRow-1),'][',num2str(nCol-1),']'];
                            else
                                Attributes.var = oItf.codeVariableName;
                                Attributes.access = ['[',num2str(nRow-1),'][',num2str(nCol-1),']'];
                            end
                            castInterfaceObj{end+1}.Attributes = Attributes; %#ok<AGROW>
                        elseif strcmpi(stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv, 'M_RowCol_C_ColRow')
                            if strcmp(sPortClass, 'struct')
                                Attributes.var = oItf.codeStructName;
                                Attributes.access = [oItf.codeStructComponentAccess '[',num2str(nCol-1),'][',num2str(nRow-1),']'];
                            else
                                Attributes.var = oItf.codeVariableName;
                                Attributes.access = ['[',num2str(nCol-1),'][',num2str(nRow-1),']'];
                            end
                            castInterfaceObj{end+1}.Attributes = Attributes; %#ok<AGROW>
                        else
                            error('#EC Plugin# Non-supported %s for code format attribute ".code2DVarMatlabToCCon"',...
                                stCodeFormatCfg.Format.s2DMatlabTo2DCodeConv);
                        end
                    end
                end
            end
        end
    end
else
    %Append interfaces attibutes for "in", "out" and "disp"
    if strcmp(sPortClass, 'struct')
        Attributes.access = oItf.codeStructComponentAccess;
        Attributes.var = oItf.codeStructName;
    elseif strcmp(sPortClass, 'var')
        Attributes.var = oItf.codeVariableName;
    end
    castInterfaceObj{end+1}.Attributes = Attributes;
end
end


%%
function [stFiles, stIncludePaths, stDefines] = i_getCCodeFiles(oRootScope)

stFiles = {};
stIncludePaths = {};
stDefines = {};

%Files dependencies

%Include Paths
nInclPath = 0;
for k = 1:numel(oRootScope.casCodegenIncludePaths)
    sFilePath = oRootScope.casCodegenIncludePaths{k};
    if k==1
        nInclPath = nInclPath+1;
        stIncludePaths.IncludePath{nInclPath}.Attributes.path = sFilePath;
    else
        bNewPath = true;
        for m=1:numel(stIncludePaths.IncludePath)
            if strcmp(stIncludePaths.IncludePath{m}.Attributes.path, sFilePath)
                bNewPath = false;
            end
        end
        if bNewPath
            nInclPath = nInclPath+1;
            stIncludePaths.IncludePath{nInclPath}.Attributes.path = sFilePath;
        end
    end
end

%Sources Files
nFile  = 0;
for k = 1:numel(oRootScope.astCodegenSourcesFiles)
    Attributes = [];
    [sFilePath, sFileName, sFileExt] = fileparts(oRootScope.astCodegenSourcesFiles(k).path);
    %Annotate or hide only source files
    if ~oRootScope.astCodegenSourcesFiles(k).hide
        Attributes.kind = 'source';
        if oRootScope.astCodegenSourcesFiles(k).codecov
            Attributes.annotate = 'yes';
        else
            Attributes.annotate = 'no';
        end
    else
        Attributes.kind = 'library';
        Attributes.annotate = 'no';
    end
    %Path and ID
    nFile = nFile+1;
    Attributes.path = sFilePath;
    Attributes.name = [sFileName sFileExt];
    Attributes.id = ['ID' num2str((70 + nFile))];
    stFiles.File{nFile}.Attributes = Attributes;
end

%astDefines
nDef = 0;
Attributes = [];
for k = 1:numel(oRootScope.astDefines)
    nDef = nDef+1;
    Attributes.name = oRootScope.astDefines(k).name;
    Attributes.value = oRootScope.astDefines(k).value;
    stDefines.Define{nDef}.Attributes = Attributes;
end
end


%%
function castDefines = i_getCompilerDefineAttributes(oModelCfg)
castDefines = {};
try
    bIsPortable = strcmp('on', oModelCfg.get_param('PortableWordSizes'));
catch oEx
    bIsPortable = false;
end

if bIsPortable
    stKeyValue = struct( ...
        'name',  'PORTABLE_WORDSIZES', ...
        'value', '1');
    castDefines{end + 1} = struct( ...
        'Attributes', stKeyValue);
end
end


%%
function stFunctions = i_getSubFunctions(oEca, stFiles, sArchName, sStubVarInitFunc)

stFunctions.Function = {};

%Get sampling time
stFunctions.Attributes.archName = sArchName;

aoScopes = oEca.getAllValidScopes('Code');

%For all functions
nSkipped = 0;
for k = 1:numel(aoScopes)
    oScope = aoScopes(k);
    
    if isempty(oScope.sCFunctionName)
        % skip subsystems without C-function <-- dummy subsystem
        nSkipped = nSkipped + 1;
        continue;
    end
    kEffective = k - nSkipped;
    
    Attributes = '';
    
    %Fileref ID
    for nFile = 1:numel(stFiles.File)
        sFilePath = [stFiles.File{nFile}.Attributes.path '\' stFiles.File{nFile}.Attributes.name];
        if strcmp(strrep(sFilePath,'/', '\'), strrep(oScope.sCFunctionDefinitionFile, '/','\'))
            Attributes.fileref = stFiles.File{nFile}.Attributes.id;
        end
    end
    
    %Function name
    Attributes.name = oScope.sCFunctionName;
    %Inition Function
    if ~isempty(oScope.sInitCFunctionName)
        Attributes.initFunc = oScope.sInitCFunctionName;
    end
    if ~isempty(sStubVarInitFunc)
        Attributes.postInitFunc = sStubVarInitFunc;        
    end
    %preStepFunc name
    if ~isempty(oScope.sPreStepCFunctionName)
        Attributes.preStepFunc = oScope.sPreStepCFunctionName;
    end
    %postStepFunc name (aka UpdateFunction)
    if ~isempty(oScope.sCFunctionUpdateName)
        Attributes.postStepFunc = oScope.sCFunctionUpdateName;
    end
    %Set attribites
    stFunctions.Function{kEffective}.Attributes = Attributes;
    
    %Get the interfaces corresponding to the function
    %put inports and attributes into structure
    castInterfaceObj = i_getInterfaces(oEca, oScope);
    
    %put all interfaces into structure
    stFunctions.Function{end}.Interface.InterfaceObj = castInterfaceObj;
end
end


%%
function castInterfaceObj = i_getInterfaces(oEca, oScope)

castInterfaceObj = {};

%Inputs
aoInputItfs = oScope.oaInputs;
for k = 1:numel(aoInputItfs)
    if i_isDataValid(oEca, aoInputItfs(k))
        if aoInputItfs(k).isCodeStructComponent
            sPortClass = 'struct';
        else
            sPortClass = 'var';
        end
        castInterfaceObj = i_getItfObj(castInterfaceObj, 'in', sPortClass, aoInputItfs(k));
    end
end

%Outputs
aoOutputItfs = oScope.oaOutputs;
for k = 1:numel(aoOutputItfs)
    if i_isDataValid(oEca, aoOutputItfs(k))
        if aoOutputItfs(k).isCodeStructComponent
            sPortClass = 'struct';
        else
            sPortClass = 'var';
        end
        castInterfaceObj = i_getItfObj(castInterfaceObj, 'out', sPortClass, aoOutputItfs(k));
    end
end

%Params
aoParams = oScope.oaParameters;
for k = 1:numel(aoParams)
    if i_isDataValid(oEca, aoParams(k))
        if aoParams(k).isCodeStructComponent
            sPortClass = 'struct';
        else
            sPortClass = 'var';
        end
        castInterfaceObj = i_getItfObj(castInterfaceObj, 'cal', sPortClass, aoParams(k));
    end
end

%Displays
if oEca.bMergedArch
    aoDisps = oScope.getAllValidUniqLocalsInclChdrScopes();
else
    aoDisps = oScope.oaLocals;
end
for k = 1:numel(aoDisps)
    if i_isDataValid(oEca, aoDisps(k))
        if aoDisps(k).isCodeStructComponent
            sPortClass = 'struct';
        else
            sPortClass = 'var';
        end
        castInterfaceObj = i_getItfObj(castInterfaceObj, 'disp', sPortClass, aoDisps(k));
    end
end
end


%%
function bValid = i_isDataValid(oEca, oItf)

bValid = oItf.bMappingValid && oItf.bIsActive;
if ~bValid && oEca.bDiagMode
    fprintf('# Interface [%s] %s (%s) has been ignored in c-code architecture \n', ...
        oItf.kind, oItf.sourceBlockFullName, oItf.name);
end
end