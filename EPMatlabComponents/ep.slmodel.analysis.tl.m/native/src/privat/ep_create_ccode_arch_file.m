function ep_create_ccode_arch_file(stArgs, stModel)
% Exports the model analysis structure to the C-Code model XML file (see CodeModel.dtd).
%
% function ep_create_ccode_arch_file(stArgs, stModel)
%
%   INPUT               DESCRIPTION
%     stArgs                (struct)  argument staructure with the following data
%       .sCResultFile       (string)  path to the C-Code output file
%       .sFileList          (string)  path to the CodeGeneration XML
%
%     stModel               (struct)  Model analysis struct produced by ep_model_info_get
%
%   OUTPUT              DESCRIPTION
%      -                      -
%


%% main
hCodeModel = mxx_xmltree('create', 'CodeModel');
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hCodeModel));

sOutputPath = fileparts(stArgs.sCResultFile);

oFileIdMap = i_insertAllFilesInfo(hCodeModel, stArgs);
ahFuncNodes = i_insertAllFunctionsInfo(hCodeModel, stModel, oFileIdMap, sOutputPath);
if isfield(stModel, 'stSystemTimeVar')
    i_extendWithSystemTime(hCodeModel, stModel.stSystemTimeVar, ahFuncNodes, sOutputPath);
end
mxx_xmltree('save', hCodeModel, stArgs.sCResultFile);
end


%%
% Adds system time information to all functions if needed
% For each time value increment a certain function is called. So if the
% value shall be increased by '20', a method 'system_time_20' is generated.
%
% If any prestep functions are added the following two steps are also done:
% - the c-file 'btc_system_time.c' is generated to contain all those methods.
% - the c-file is added to the file list of the CodeModel.xml
%
function i_extendWithSystemTime(hRootDoc, stSystemTimeVar, ahFuncNodes, sOutputPath)
if (isempty(stSystemTimeVar) || isempty(ahFuncNodes))
    return;
end
sVarName = stSystemTimeVar.sRootName;
sVarModule = stSystemTimeVar.sModuleName;
if (isempty(sVarName) || isempty(sVarModule))
    return;
end
[~, sModuleName] = fileparts(sVarModule);
sVarHeader = [sModuleName, '.h'];

dSystemTimeLSB = [];
if ~stSystemTimeVar.stRootType.bIsFloat
    dSystemTimeLSB = stSystemTimeVar.astProp(1).dLsb;
end

[hPrestepFile, sPrestepFile] = i_createPrestepFile(sOutputPath, sVarHeader);
xOnCleanupCloseFile = onCleanup(@() i_closeFileRobustly(hPrestepFile));

xCreatedPrestepFuncs = containers.Map();
for i = 1:length(ahFuncNodes)
    hFuncNode = ahFuncNodes(i);

    xIncr = i_getTimeIncreasePerStep(hFuncNode, dSystemTimeLSB);
    if isempty(xIncr)
        continue;
    end

    if isfloat(xIncr)
        sPrestepFunc = sprintf('system_time_%.16g', xIncr);
        sPrestepFunc = regexprep(sPrestepFunc, '[.+-]', '_');
    else
        sPrestepFunc = sprintf('system_time_%i', xIncr);
    end
    mxx_xmltree('set_attribute', hFuncNode, 'preStepFunc', sPrestepFunc);

    % if prestep function is not created yet, do it now
    if xCreatedPrestepFuncs.isKey(sPrestepFunc)
        continue;
    end
    xCreatedPrestepFuncs(sPrestepFunc) = true;
    i_appendPrestepBody(hPrestepFile, sPrestepFunc, sVarName, xIncr);
end

if isempty(xCreatedPrestepFuncs)
    clear xOnCleanupCloseFile; % close hFile implicitly
    try
        delete(sPrestepFile);
    catch
    end
else
    [~, f, e] = fileparts(sPrestepFile);
    i_addFile(hRootDoc, [f, e], 'sysID1');
end
end


%%
function xIncr = i_getTimeIncreasePerStep(hFuncNode, dSystemTimeLSB)
xIncr = [];

sFuncSampleTime = mxx_xmltree('get_attribute', hFuncNode, 'sampleTime');
if ~isempty(sFuncSampleTime)
    xIncr = str2double(sFuncSampleTime);
    if ~isempty(dSystemTimeLSB)
        xIncr = uint64(round(xIncr/dSystemTimeLSB));
    end
end
end


%%
function [hFile, sFile] = i_createPrestepFile(sFilePath, sHeader)
sFile = fullfile(sFilePath, 'btc_system_time.c');
if exist(sFile, 'file')
    delete(sFile);
end

hFile = fopen(sFile, 'a');
fprintf(hFile, '#include "%s"\n\n', sHeader);
end


%%
function i_appendPrestepBody(hFile, sPrestepFunc, sVarName, xIncr)
fprintf(hFile, 'void %s(void) {\n', sPrestepFunc);
if isfloat(xIncr)
    sInc = sprintf('%.16e', xIncr);
else
    sInc = sprintf('%i', xIncr);
end
fprintf(hFile, '  %s += %s;\n', sVarName, sInc);
fprintf(hFile, '}\n\n');
end


%%
function i_addFile(hDoc, sFile, sID)
[sPath, f, e] = fileparts(sFile);
sFileName = [f, e];

hFilesNode = mxx_xmltree('get_nodes', hDoc, '/CodeModel/Files');
hFileNode = mxx_xmltree('add_node', hFilesNode, 'File');
if ~isempty(sPath)
    mxx_xmltree('set_attribute', hFileNode, 'path', sPath);
end
mxx_xmltree('set_attribute', hFileNode, 'name', sFileName);
mxx_xmltree('set_attribute', hFileNode, 'annotate', 'no');
mxx_xmltree('set_attribute', hFileNode, 'id', sID);
end


%%
function i_closeFileRobustly(hFile)
try
    fclose(hFile);
catch
end
end


%%
function oFileIdMap = i_insertAllFilesInfo(hCodeModel, stArgs)
if (isfield(stArgs, 'sFileList') && exist(stArgs.sFileList, 'file'))
    oFileIdMap = i_insertCodegenInfo(hCodeModel, stArgs.sFileList);
else
    oFileIdMap = containers.Map;
end
end


%%
function bIsHidden = i_isHidden(stObject)
bIsHidden = i_getField(stObject, 'bIsHidden', false);
end


%%
function xValue = i_getField(stStruct, sField, xDefaultValue)
if isfield(stStruct, sField)
    xValue = stStruct.(sField);
else
    if (nargin > 2)
        xValue = xDefaultValue;
    else
        xValue = [];
    end
end
end


%%
function ahFuncNodes = i_insertAllFunctionsInfo(hParentNode, stModel, oFileIdMap, sOutputPath)
ahFuncNodes = repmat(hParentNode, 1, 0);

hFunctionsNode = mxx_xmltree('add_node', hParentNode, 'Functions');
mxx_xmltree('set_attribute', hFunctionsNode, 'archName', [stModel.sTlModel, ' [C-Code]']);

hScalingsNode = mxx_xmltree('add_node', hParentNode, 'Scalings');
i_handleScalings('init', hScalingsNode);
xOnExitCleanCache = onCleanup(@() i_handleScalings('init', []));

[casScopePaths, bFoundSharedFuncs] = ep_scope_code_paths_get(stModel.astSubsystems);

sBtcInitFile = fullfile(sOutputPath, 'btc__init_functions.c');
stInitFileHandler = ep_init_file_handler('create', sBtcInitFile);
for i = 1:length(stModel.astSubsystems)
    stSub = stModel.astSubsystems(i);
    sScopePath = casScopePaths{i};

    % skip subsystems
    %    * without step function --> DUMMY, VIRTUAL scopes
    %    * that are hidden (e.g. have been unselected by User)
    if (isempty(sScopePath) || i_isHidden(stSub))
        continue;
    end

    if bFoundSharedFuncs
        stSub.sCallStack = sScopePath;
    else
        stSub.sCallStack = '';
    end
    if strcmpi(stSub.sStorage, 'static')
        stSub.sFileRefID = i_getFilerefId(stSub.sModuleName, oFileIdMap);
    else
        stSub.sFileRefID = '';
    end

    hFuncNode = i_insertFuncInfo( ...
        hFunctionsNode, ...
        stSub, ...
        stModel.sUserInitFunc, ...
        stModel.bSetGlobalInitFuncForAutosar, ...
        stInitFileHandler);
    i_insertInterfaceInfo(hFuncNode, stSub, stModel.astCalVars, stModel.astDispVars, stModel.astDsmVars, oFileIdMap, stModel.bAdaptiveAutosar);

    ahFuncNodes(end + 1) = hFuncNode; %#ok<AGROW>
end
if exist(sBtcInitFile, 'file')
    i_addFile(hParentNode, sBtcInitFile, 'initID1');
end
end



%%
% Adds a Function node with some info to the XML
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle)  parent XML node for the Function node
%    - stSub              (string)  subsystem/function information
%    - bIsAutosarCode     (boolean) flag if we are in an AUTOSAR context
%    - stInitFileHandler  (struct)  a handler responsible for handling (special) cases in context of init functions
%   OUTPUT
%    - hFuncNode          (handle)  handle of the added Function node
%
function hFuncNode = i_insertFuncInfo(hParentNode, stSub, sUserInitFunc, bSetGlobalInitFuncForAutosar, stInitFileHandler)
hFuncNode = mxx_xmltree('add_node', hParentNode, 'Function');
mxx_xmltree('set_attribute', hFuncNode, 'name', stSub.sStepFunc);
if ~isempty(stSub.sCallStack)
    mxx_xmltree('set_attribute', hFuncNode, 'callStack', stSub.sCallStack);
end
if ~isempty(stSub.sFileRefID)
    mxx_xmltree('set_attribute', hFuncNode, 'fileref', stSub.sFileRefID);
end

casInitFunctions = {};

if bSetGlobalInitFuncForAutosar
    casInitFunctions{end + 1} = 'Rte_Start';
end

if ~isempty(sUserInitFunc)
    casInitFunctions{end + 1} = sUserInitFunc;
end

if ~isempty(stSub.sInitFunc)
    casInitFunctions{end + 1} = stSub.sInitFunc;
end

if ~isempty(stSub.sPostInitFunc)
    casInitFunctions{end + 1} = stSub.sPostInitFunc;
end

if (length(casInitFunctions) >= 3)
    if bSetGlobalInitFuncForAutosar
        % NOTE: Rte_Start needs to be handled specially because it is *not* a void-void function!
        % --> use declartation from "Rte_Main.h" AUTOSAR header
        ep_init_file_handler('add_include', stInitFileHandler, 'Rte_Main.h', casInitFunctions(1));
    end

    % create a group init function that is calling all the user's function inside our own C file
    sGroupInitFunc = ep_init_file_handler('add_group_init_func', stInitFileHandler, casInitFunctions);

    % replace the original init functions with the group init function
    casInitFunctions = {sGroupInitFunc};
end
if ~isempty(casInitFunctions)
    mxx_xmltree('set_attribute', hFuncNode, 'initFunc', casInitFunctions{1});
    if (length(casInitFunctions) > 1)
        mxx_xmltree('set_attribute', hFuncNode, 'postInitFunc', casInitFunctions{2});
    end
end

% TODO: info about the module of the proxyFunc is missing --> needs to be adapted in DTD
if (isfield(stSub, 'stProxyFunc') && isstruct(stSub.stProxyFunc) && ~isempty(stSub.stProxyFunc.sName))
    mxx_xmltree('set_attribute', hFuncNode, 'proxyFunc', stSub.stProxyFunc.sName);
end
if ~isempty(stSub.dSampleTime)
    % Note: use java Double object to make string more similar to user input
    mxx_xmltree('set_attribute', hFuncNode, ...
        'sampleTime', char(java.lang.Double(stSub.dSampleTime).toString()));
end

i_insertArgsInfo(hFuncNode, stSub);
end


%%
% Adds argument information to a Function node
%
%    - hParentNode        (handle) XML-node used to add arguments
%    - stSub              (string) subsystem information
%
function i_insertArgsInfo(hParentNode, stSub)
[aiExplicitArgs, aiArrayRefArgs] = i_getExplicitlySetArgs(stSub.stFuncInterface);
if (isempty(aiExplicitArgs) && isempty(aiArrayRefArgs))
    return;
end
hArgsNode = mxx_xmltree('add_node', hParentNode, 'Args');

for i = 1:length(aiExplicitArgs)
    iArg = aiExplicitArgs(i);
    stFormalArg = stSub.stFuncInterface.astFormalArgs(iArg);
    stArg = stSub.stFuncInterface.astArgs(iArg);

    i_addArg(hArgsNode, stFormalArg.sVarName, stArg.sVarName);
end

for i = 1:length(aiArrayRefArgs)
    iArg = aiArrayRefArgs(i);
    stFormalArg = stSub.stFuncInterface.astFormalArgs(iArg);
    stArg = stSub.stFuncInterface.astArgs(iArg);

    i_addArrayRefArg(hArgsNode, stFormalArg.sVarName, stArg.aiWidth);
end
end


%%
% If the function takes arguments, some of them need to be set explicitly to a specific variable while others may be
% left implicit. In the latter case the SIL harness has to declare its own variables to be used as arguments.
%
%   PARAMETER(S)         DESCRIPTION
%    - stFuncInterface    (struct) argument information about the function
%   OUTPUT
%    - aiExplicitArgs     (array) index of arguments needed to be set explicitly
%    - aiArrayRefArgs     (array) index of arguments for which an array reference is needed
%
function [aiExplicitArgs, aiArrayRefArgs] = i_getExplicitlySetArgs(stFuncInterface)
% Note: for now using a heuristic!
%       --> if name of provided argument starts with "__osc_", the explicit providing of the argument can be ommitted
if isempty(stFuncInterface.astArgs)
    aiExplicitArgs = [];
    aiArrayRefArgs = [];
else
    astArgs = stFuncInterface.astArgs;
    abIsExtraDefinedArgs = arrayfun(@(x) i_startsWith(x.sVarName, '__osc_'), astArgs);
    aiExplicitArgs = find(~abIsExtraDefinedArgs);

    abIsArrayArgs = arrayfun( ...
        @(bIsExtra, x) bIsExtra && (length(x.aiWidth) == 1) && (x.aiWidth > 0), abIsExtraDefinedArgs, astArgs);
    aiArrayRefArgs = find(abIsArrayArgs);
end
end


%%
function bStartsWith = i_startsWith(sString, sPrefix)
nPrefix = length(sPrefix);
if (length(sString) < nPrefix)
    bStartsWith = false;
else
    if (nPrefix == 0)
        bStartsWith = true; % cornercase: maybe return false?
    else
        bStartsWith = strcmp(sString(1:nPrefix), sPrefix);
    end
end
end


%%
function i_addArg(hParentNode, sArgName, sVarName)
hArgNode = mxx_xmltree('add_node', hParentNode, 'Arg');
mxx_xmltree('set_attribute', hArgNode, 'name', sArgName);
hVarNode = mxx_xmltree('add_node', hArgNode, 'Variable');
mxx_xmltree('set_attribute', hVarNode, 'name', sVarName);
end


%%
function i_addArrayRefArg(hParentNode, sArgName, iWidth)
hArgNode = mxx_xmltree('add_node', hParentNode, 'Arg');
mxx_xmltree('set_attribute', hArgNode, 'name', sArgName);
hArrayRefNode = mxx_xmltree('add_node', hArgNode, 'ArrayRef');
mxx_xmltree('set_attribute', hArrayRefNode, 'size', sprintf('%d', iWidth));
end


%%
function sFileRefID = i_getFilerefId(sModuleName, oFileIdMap)
sFileRefID = '';
if ~isempty(sModuleName)
    sFileRefID = '';
    if oFileIdMap.isKey(lower(sModuleName))
        sFileRefID = oFileIdMap(lower(sModuleName));
    end
end
end


%%
% Note: only return non-empty file references if the variable is static
function sFileRefID = i_getVariableFilerefId(stVarInfo, oFileIdMap)
bIsStatic = strcmpi(stVarInfo.stVarClass.sStorage, 'static');
if bIsStatic
    sFileRefID = i_getFilerefId(stVarInfo.sModuleName, oFileIdMap);
else
    sFileRefID = '';
end
end


%%
% Adds interface information
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (hanlde) XML-node used to add the interface information
%    - stSubsystem        (struct) subsystem information
%    - astCalVars         (array)  array of calibrations to be added
%    - astDispVars        (array)  array of displays to be added
%    - astDsmVars         (array)  array of DSMs to be added
%    - oFileIdMap         (obj)    map between file names and internal XML IDs
%
function i_insertInterfaceInfo(hParentNode, stSubsystem, astCalVars, astDispVars, astDsmVars, oFileIdMap, bSkipInt64BitInterface)
stInterface = stSubsystem.stInterface;
hCInterfaceNode = mxx_xmltree('add_node', hParentNode, 'Interface');

oFuncPtrArgsMap = i_getFuncPtrArgs(stSubsystem.stFuncInterface);

% --- Inputs ------
oMapAlias = containers.Map;
nInports = length(stInterface.astInports);
for i = 1:(nInports)
    stInport = stInterface.astInports(i);
    if ~i_skipInt64Interface(stInport, bSkipInt64BitInterface)
        i_addCcodePort(hCInterfaceNode, 'in', stInport, oMapAlias, oFuncPtrArgsMap);
    end
end

% --- Calibrations ------
nCalVars = length(stSubsystem.astCalRefs);
for i = 1:nCalVars
    iVarIdx = stSubsystem.astCalRefs(i).iVarIdx;
    stParameter = astCalVars(iVarIdx);

    % skip Parameters that are hidden (e.g. have been unselected by User)
    if i_isHidden(stParameter)
        continue;
    end

    sFileRefID = i_getVariableFilerefId(stParameter.stInfo, oFileIdMap);
    i_addCcodeParameter(hCInterfaceNode, stParameter.stInfo, sFileRefID);
end

% --- Outports ------
oMapAlias = containers.Map;
nOutports = length(stInterface.astOutports);
for i = 1:(nOutports)
    stOutport = stInterface.astOutports(i);
    if ~i_skipInt64Interface(stOutport, bSkipInt64BitInterface)
        i_addCcodePort(hCInterfaceNode, 'out', stOutport, oMapAlias, oFuncPtrArgsMap);
    end
end

% --- Displays ------
oMapAlias = containers.Map;
nDispVars = length(stSubsystem.astDispRefs);
for i = 1:nDispVars
    iVarIdx = stSubsystem.astDispRefs(i).iVarIdx;
    stLocal = astDispVars(iVarIdx);

    sFileRefID = i_getVariableFilerefId(stLocal.stInfo, oFileIdMap);
    i_addCcodeLocal(hCInterfaceNode, stLocal, sFileRefID, oMapAlias);
end

% --- DataStoreMemory blocks ------
nDsmVars = length(stSubsystem.astDsmRefs);
for i = 1:nDsmVars
    iVarIdx = stSubsystem.astDsmRefs(i).iVarIdx;
    stDsmVar = astDsmVars(iVarIdx);

    sFileRefID = i_getVariableFilerefId(stDsmVar.stInfo, oFileIdMap);
    i_addCcodeDsmPort(hCInterfaceNode, stDsmVar, sFileRefID);
end
end


%%
function bSkipInterface= i_skipInt64Interface(stPort, bSkipInt64BitInterface)
bSkipInterface = false;
if bSkipInt64BitInterface % True in Adaptive Autosar usecase
    astSignals= stPort.stCompInfo.astSignals;
    for i=1:numel(astSignals)
        sType = stPort.stCompInfo.astSignals(i).sType;
        if strcmp(sType, 'uint64') || strcmp(sType, 'int64')
            bSkipInterface = true;
            return;
        end
    end
end
end


%%
% Get a map of pointer arguments regarding a specific function
%
%   PARAMETER(S)         DESCRIPTION
%    - stFuncInterface    (struct) holds the information about the function interface
%
%   OUTPUT
%    - oFuncPtrArgsMap    (object) describes which function arguments are pointer
%
function oFuncPtrArgsMap = i_getFuncPtrArgs(stFuncInterface)
oFuncPtrArgsMap = containers.Map;

for i = 1:length(stFuncInterface.astFormalArgs)
    stArg = stFuncInterface.astFormalArgs(i);
    if stArg.bIsPointer
        oFuncPtrArgsMap(stArg.sVarName) = 1;
    end
end
end


%%
% Adds a Local to the C-Code architecture
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle) XML-Node used to add the local interface
%    - stLocal            (struct) holds the information about the local variable
%    - sFileRefID         (string) ID of the file this DISP variable is defined in (might be empty)
%    - oMapAlias          (object) alias map for already used variables
%
function i_addCcodeLocal(hParentNode, stLocal, sFileRefID, oMapAlias)
stVarInfo = stLocal.stInfo;

bIsMacro = i_isMacro(stVarInfo);

astProp = i_reduceUniformElements(stVarInfo.astProp);
hCurrentVar = [];
for ni = 1:length(astProp)
    stProp = astProp(ni);

    if ((ni < 2) || ~isequal(stProp.hVar, hCurrentVar))
        [sBaseType, bIsBaseFloat] = i_getBaseType(stVarInfo.oTypeMap(stProp.hVar));
        hCurrentVar = stProp.hVar;
    end

    sAccessPath = [stVarInfo.sAccessPath, stProp.sAccessPath];
    if isempty(sFileRefID)
        hIfObj = i_addCcodeInterface(hParentNode, 'disp', stVarInfo.sRootName, sAccessPath, oMapAlias);
    else
        hIfObj = i_addCcodeInterface(hParentNode, 'disp', stVarInfo.sRootName, sAccessPath);
    end
    i_setMacroAndFilerefProperties(hIfObj, bIsMacro, sFileRefID);
    i_setInterfaceProperties(hIfObj, sBaseType, bIsBaseFloat, stProp);
end
end


%%
% Note: Properties "astProp" are grouped according to their corresponding variable (field ".hVar"). In this function
% all elements belonging to one such group are reduced to one _representative_ that holds all the relevant information
% for the whole array/matrix. This is only done if the elements of the array are uniforam and do no have different
% individual info (e.g. LSB).
%
function astPropReduced = i_reduceUniformElements(astProp)
nProps = numel(astProp);
if (nProps < 2)
    astPropReduced = astProp;
    return;
end

% ASSUMPTION: Array "astProp" is *ordered* according to field ".hVar", i.e. all elements that have the same hVar are
% placed next to each other.
% Idea: Go over all properties group-wise and
abSelect = true(size(astProp));
iGroupStartIdx = 1;
hCurrentVar = astProp(1).hVar;
for i = 2:(nProps + 1)
    if ((i > nProps) || ~isequal(astProp(i).hVar, hCurrentVar)) % Note: order in "OR"-expression is very important!
        iGroupEndIdx = i - 1;

        nGroupSize = iGroupEndIdx - iGroupStartIdx + 1;
        if (nGroupSize > 1) && i_isUniform(astProp(iGroupStartIdx:iGroupEndIdx))
            % remove elemental access from the one element that we keep, i.e. <Var>[x][y] --> <Var>, ...
            astProp(iGroupStartIdx).sAccessPath = i_removeElementAccess(astProp(iGroupStartIdx).sAccessPath);

            % ... and remove all the additional elements of the same group
            abSelect(iGroupStartIdx + 1:iGroupEndIdx) = false;
        end

        % if necessary, start new group
        if (i > nProps)
            break;
        end
        iGroupStartIdx = i;
        hCurrentVar = astProp(i).hVar;
    end
end
astPropReduced = astProp(abSelect);
end


%%
% removes the element access from an access path, e.g. ".a.b.c[2][0]" --> ".a.b.c" or "[1]" --> ""
function sAccessPath = i_removeElementAccess(sAccessPath)
if ~isempty(sAccessPath)
    % remove all "[", "]", and digits from the *end* of the access path
    sAccessPath = regexprep(sAccessPath, '[\[\]0-9]+$', '');
end
end


%%
% Adds a DSM to the C-Code architecture
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle) XML-Node used to add the dsm interface
%    - stDsmVar           (struct) holds the information about the dsm variable (Data Store Memory)
%    - sFileRefID         (string) ID of the file this DSM variable is defined in (might be empty)
%
function i_addCcodeDsmPort(hParentNode, stDsmVar, sFileRefID)
if strcmpi(stDsmVar.stDsm.sKind, 'read')
    sKind = 'in';
else
    sKind = 'out';
end
stVarInfo = stDsmVar.stInfo;
[sBaseType, bIsBaseFloat] = i_getBaseType(stVarInfo.stVarType);

if i_isUniform(stVarInfo.astProp)
    astProp = stVarInfo.astProp(1); % since array is uniform, just use the properties of the first element for the parent
    astProp.sAccessPath = ''; % note: remove any sub-element access path (just referring to the parent element)
else
    astProp = stVarInfo.astProp;
end

bIsMacro = i_isMacro(stVarInfo);
for ni = 1:length(astProp)
    stProp = astProp(ni);

    sAccessPath = [stVarInfo.sAccessPath, stProp.sAccessPath];
    hIfObj = i_addCcodeInterface(hParentNode, sKind, stVarInfo.sRootName, sAccessPath);
    i_setMacroAndFilerefProperties(hIfObj, bIsMacro, sFileRefID);
    i_setInterfaceProperties(hIfObj, sBaseType, bIsBaseFloat, stProp);
end
end

%%
% Adds a parameter to the C-Code architecure
%   Note: for CALs assume that we always have non-uniform info because of the "initValue"
%         --> handle each element in C-Code variable individually
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle) XML-Node used to add the parameter interface
%    - stVarInfo          (struct) holds the information about the parameter interface
%    - sFileRefID         (string) ID of the file this CAL variable is defined in (might be empty)
%
function i_addCcodeParameter(hParentNode, stVarInfo, sFileRefID)
[sBaseType, bIsBaseFloat] = i_getBaseType(stVarInfo.stVarType);

bIsMacro = i_isMacro(stVarInfo);
for i = 1:length(stVarInfo.astProp)
    stProp = stVarInfo.astProp(i);

    sAccessPath = [stVarInfo.sAccessPath, stProp.sAccessPath];
    hIfObj = i_addCcodeInterface(hParentNode, 'cal', stVarInfo.sRootName, sAccessPath);
    i_setMacroAndFilerefProperties(hIfObj, bIsMacro, sFileRefID);
    i_setInterfaceProperties(hIfObj, sBaseType, bIsBaseFloat, stProp);
end
end


%%
function i_setMacroAndFilerefProperties(hIfObj, bIsMacro, sFileRefID)
% file reference only useful, if the variable is _not_ a macro
if bIsMacro
    mxx_xmltree('set_attribute', hIfObj, 'replaceable', 'yes');
else
    if ~isempty(sFileRefID)
        mxx_xmltree('set_attribute', hIfObj, 'fileref', sFileRefID);
    end
end
end


%%
% Manage the global scaling nodes to prevent duplicates
% % two modes:
% sCmd=='init': initialize
%               varargin{1} = hScalingsNode (root node for all generated scalings)
% sCmd=='get':  get/create global scaling
%               varargin{1} = hScalingsNode (root node for all generated scalings)
%
%   PARAMETER(S)         DESCRIPTION
%    - sCmd               (string)     see above
%    - varargin           (cell-array) see above
%
%   OUTPUT
%    -  varargout         (cell-array) see above
%
function varargout = i_handleScalings(sCmd, varargin)
persistent p_stCache;

if strcmp(sCmd, 'init')
    hScalingsRootNode = varargin{1};
    p_stCache = struct( ...
        'oScalingSet', containers.Map, ...
        'hScalingsRootNode', hScalingsRootNode);
else
    dLsb = varargin{1};
    dOffset = varargin{2};
    if (dOffset == 0.0)
        sInternalKey = sprintf('%.17g', dLsb);
    else
        sInternalKey = sprintf('%.17g_%.17g', dLsb, dOffset);
    end
    if p_stCache.oScalingSet.isKey(sInternalKey)
        varargout{1} = p_stCache.oScalingSet(sInternalKey);
    else
        sScalingID = ['scID', num2str(1 + p_stCache.oScalingSet.length)];
        i_addScalingNode(p_stCache.hScalingsRootNode, sScalingID, dLsb, dOffset);
        p_stCache.oScalingSet(sInternalKey) = sScalingID;
        varargout{1} = sScalingID;
    end
end
end


%%
% Adds a acaling node
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle) XML-Node used to add the scaling
%    - sScalingID         (string) Unique scaling id
%    - dLsb               (double) lsb value to be set
%    - dOffset            (double) offset value to be set
%
function i_addScalingNode(hParentNode, sScalingID, dLsb, dOffset)
hScaling = mxx_xmltree('add_node', hParentNode, 'Scaling');
mxx_xmltree('set_attribute', hScaling,  'id' , sScalingID);
i_setAttributeDouble(hScaling, 'lsb', dLsb);
i_setAttributeDouble(hScaling, 'offset', dOffset);
end


%%
% Adds an interface object to the C-Code model.
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle) XML-Node used to add the interface object
%    - sKind              (string) kind of the port e.g. 'in' or 'out'
%    - sVarName           (struct) name of the interface object
%
%   OUTPUT
%    - hIfObj             (handle) XML-Node handle of the added interface object

function hIfObj = i_add_interface_obj(hParentNode, sKind, sVarName)
hIfObj = mxx_xmltree('add_node', hParentNode, 'InterfaceObj');
mxx_xmltree('set_attribute', hIfObj, 'kind', sKind);
mxx_xmltree('set_attribute', hIfObj, 'var', sVarName);
end


%%
% Adds an Inport/Outport it the C-Code architecture
%
%   PARAMETER(S)         DESCRIPTION
%    - hParentNode        (handle) XML-Node used to add the port
%    - sKind              (string) kind of the port e.g. 'in' or 'out'
%    - stPort             (struct) port information
%    - oMapAlias          (object) alias map for already used variables
%    - oFuncPtrArgsMap    (object) describes which function arguments are pointer
%
function i_addCcodePort(hParentNode, sKind, stPort, oMapAlias, oFuncPtrArgsMap)
astSignals = stPort.astSignals;
nNumberOfSignals = length(stPort.astSignals);
for ni = 1:nNumberOfSignals
    stSignal = astSignals(ni);

    stVarInfo = stSignal.stVarInfo;
    if isempty(stVarInfo)
        continue;
    end
    [sBaseType, bIsBaseFloat] = i_getBaseType(stVarInfo.stVarType);

    bChangeToPtrAccess = false;
    if isfield(stVarInfo, 'stInterfaceVar')
        stIfVar = stVarInfo.stInterfaceVar;
        if strcmp(stIfVar.sKind, 'RETURN_VALUE')
            sName = '';
        else
            if (~isempty(stIfVar.iArgIdx) && (stIfVar.iArgIdx > 0))
                sName = stVarInfo.stInterfaceVar.sOrigRootName;
                if oFuncPtrArgsMap.isKey(sName)
                    bChangeToPtrAccess = true;
                end
            else
                if stVarInfo.bIsUsable
                    sName = stVarInfo.sRootName;
                else
                    sName = stIfVar.sOrigRootName;
                end
            end
        end
    else
        sName = stVarInfo.sRootName;
    end

    bAllElemsReferenced = i_allElementsReferenced(stSignal);
    if (i_isUniform(stVarInfo.astProp) && bAllElemsReferenced)
        astProp = stVarInfo.astProp(1); % since array is uniform, just use the properties of the first element for the parent
        astProp.sAccessPath = ''; % note: remove any sub-element access path (just referring to the parent element)
    else
        astProp = stVarInfo.astProp;
        if ~bAllElemsReferenced
            aiLinElements = i_getLinearElementsIdx(stVarInfo.aiWidth, stSignal.aiElements, stSignal.aiElements2);
            astProp = astProp(aiLinElements + 1); % note: zero-based index --> one-based index
        end
    end

    bIsMacro = i_isMacro(stVarInfo);
    for nk = 1:length(astProp)
        stProp = astProp(nk);

        sAccessPath = i_adaptFieldAccess([stVarInfo.sAccessPath, stProp.sAccessPath], bChangeToPtrAccess);
        hIfObj = i_addCcodeInterface(hParentNode, sKind, sName, sAccessPath, oMapAlias);
        i_setMacroAndFilerefProperties(hIfObj, bIsMacro, '');
        i_setInterfaceProperties(hIfObj, sBaseType, bIsBaseFloat, stProp);
    end
end
end


%%
function bIsMacro = i_isMacro(stVarInfo)
bIsMacro = stVarInfo.stVarClass.bIsMacro;
end


%%
function bAllReferenced = i_allElementsReferenced(stSignal)
bAllReferenced = isempty(stSignal.aiElements) && isempty(stSignal.aiElements2);
end


%%
function [sBaseType, bIsFloat] = i_getBaseType(stVarType)
if isempty(stVarType.sBaseDest)
    sBaseType = stVarType.sBase;
else
    sBaseType = stVarType.sBaseDest; % Note: for pointer types show the destination type
end
bIsFloat = stVarType.bIsFloat;
end


%%
function i_setInterfaceProperties(hIfObj, sBaseType, bIsFloat, stProp)
if ep_sil_scaling_needed(sBaseType, bIsFloat, stProp.dLsb, stProp.dOffset)
    sScalingID = i_handleScalings('get', stProp.dLsb, stProp.dOffset);
    if ~isempty(sScalingID)
        mxx_xmltree('set_attribute', hIfObj, 'scaling', sScalingID);
    end
end
if ~isempty(stProp.dUserMin)
    i_setAttributeDouble(hIfObj, 'min', stProp.dUserMin);
elseif strcmp(sBaseType, 'Bool')
    i_setAttributeDouble(hIfObj, 'min', stProp.dMin);
end
if ~isempty(stProp.dUserMax)
    i_setAttributeDouble(hIfObj, 'max', stProp.dUserMax);
elseif strcmp(sBaseType, 'Bool')
    i_setAttributeDouble(hIfObj, 'max', stProp.dMax);
end
if ~isempty(stProp.dInitValue)
    i_setAttributeDouble(hIfObj, 'initVal', stProp.dInitValue);
end
end


%%
function sAccess = i_adaptFieldAccess(sAccess, bChangeToPtrAccess)
if (bChangeToPtrAccess && ~isempty(sAccess))
    if (sAccess(1) == '.')
        sAccess = ['->', sAccess(2:end)];
    end
end
end


%%
% Adds a CodeInterface
%
%   PARAMETER(S)    DESCRIPTION
%    - hParentNode     (handle) Xml-Node used to add the CodeInterface
%    - sKind           (string) kind of the interface object e.g. 'in' or 'out'
%    - sName           (string) name of the interface object
%    - sAccessPath     (string) access path of the code interface
%    - oMapAlias       (object) Map of alias names. This is needed if the same variable is used multiple times for an
%                               interface definition. In this case an alias name is used to have an unique identifier
%                               for each interface object.
%   OUTPUT
%   - hIfObj           (handle) True, the array is uniform. Otherwise, false.
%
function hIfObj = i_addCcodeInterface(hParentNode, sKind, sName, sAccessPath, oMapAlias)
hIfObj = i_add_interface_obj(hParentNode, sKind, sName);

sCheckName = sName;
if ~isempty(sAccessPath)
    mxx_xmltree('set_attribute', hIfObj,  'access', sAccessPath);
    sCheckName = [sCheckName, sAccessPath];
end
if (nargin > 4)
    if oMapAlias.isKey(sCheckName)
        nNewAliasCount = oMapAlias(sCheckName) + 1;
        mxx_xmltree('set_attribute', hIfObj, 'alias', sprintf('%s:%d', sName, nNewAliasCount));
        oMapAlias(sCheckName) = nNewAliasCount; %#ok<NASGU> handle-like object
    else
        oMapAlias(sCheckName) = 1; %#ok<NASGU> handle-like object
    end
end
end


%%
% Checks if all array elements 'stVarInfo.astProp' are equal. Meaning an uniform array is detected, if all
% elements are equal.
%
function bIsUniform = i_isUniform(astProp)
if (length(astProp) < 2)
    bIsUniform = true;
    return;
end

casPropNames = { ...
    'dLsb', ...
    'dOffset', ...
    'dMin', ...
    'dMax', ...
    'dInitValue'};
for ni = 1:length(casPropNames)
    sPropName = casPropNames{ni};
    bIsUniform = i_doubleElementsEqual({astProp(:).(sPropName)});
    if ~bIsUniform
        return; % take a shortcut if a difference was already found
    end
end
end


%%
% Checks if double elements are equal
% note: for performance reasons no check for empty cell array
%
function bIsEqual = i_doubleElementsEqual(cadValues)
if (length(cadValues) < 2)
    bIsEqual = true;
    return;
end

% approach: handle "empty elements" use cases first and then, if no element is empty, compare
abIsEmpty = cellfun(@isempty, cadValues);

% 1) if all elements are empty --> elements are equal
if all(abIsEmpty)
    bIsEqual = true;
    return;
end
% 2) if only some of the elements are empty --> elements are not equal
if any(abIsEmpty)
    bIsEqual = false;
    return;
end
% 3) all elements are non-empty --> just compare them
bIsEqual = length(unique([cadValues{:}])) < 2;
end


%%
function i_setAttributeDouble(hNode, sAttName, dValue)
mxx_xmltree('set_attribute', hNode, sAttName, sprintf('%.16e', dValue));
end


%***********************************************************************************************************************
% The method inserts all files, include paths and defines of the CodeGeneration XML into the CodeModel XML.
%
function oFileIdMap = i_insertCodegenInfo(hCodeModel, sCodeGen)
oFileIdMap = containers.Map;

if isempty(sCodeGen)
    % if one of the two parameters is empty, nothing can be done
    return;
end

try
    hCodeGenDoc = mxx_xmltree('load', sCodeGen);
    xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hCodeGenDoc));

    hFunctions = mxx_xmltree('get_nodes', hCodeModel, './Functions');
    if isempty(hFunctions)
        hFilesNode = mxx_xmltree('add_node', hCodeModel, 'Files');
    else
        hFilesNode = mxx_xmltree('add_prev_sibling', hFunctions, 'Files');
    end

    % ---- Files ---------- %
    ahFiles = mxx_xmltree('get_nodes', hCodeGenDoc, '/cg:CodeGeneration/cg:FileList/cg:File');
    for i = 1:length(ahFiles)
        hFile = ahFiles(i);
        sID = ['fID', num2str(i)];

        sFileName = mxx_xmltree('get_attribute', hFile, 'name');
        sFileKind = mxx_xmltree('get_attribute', hFile, 'kind');
        if isempty(sFileKind)
            sFileKind = 'source';
        end

        oFileIdMap(lower(sFileName)) = sID;

        hNewFileNode = mxx_xmltree('add_node', hFilesNode, 'File');
        mxx_xmltree('set_attribute', hNewFileNode, 'path', mxx_xmltree('get_attribute', hFile, 'path'));
        mxx_xmltree('set_attribute', hNewFileNode, 'name', sFileName);
        mxx_xmltree('set_attribute', hNewFileNode, 'kind', sFileKind);
        mxx_xmltree('set_attribute', hNewFileNode, 'annotate', mxx_xmltree('get_attribute', hFile, 'annotate'));
        mxx_xmltree('set_attribute', hNewFileNode, 'id', sID);
    end

    % ---- Include Paths ---------- %
    hIncludePathsNode = mxx_xmltree('get_nodes', hCodeModel, './IncludePaths');
    if isempty(hIncludePathsNode)
        hIncludePathsNode = mxx_xmltree('add_next_sibling', hFilesNode, 'IncludePaths');
    end
    ahPaths = mxx_xmltree('get_nodes', hCodeGenDoc, '/cg:CodeGeneration/cg:IncludePaths/cg:IncludePath');
    for i = 1:length(ahPaths)
        hPath = ahPaths(i);
        hNewPathNode = mxx_xmltree('add_node', hIncludePathsNode, 'IncludePath');
        mxx_xmltree('set_attribute', hNewPathNode, 'path', mxx_xmltree('get_attribute', hPath, 'path'));
    end

    % ---- Defines ---------- %
    hDefinesNode = mxx_xmltree('get_nodes', hCodeModel, './Defines');
    if isempty(hDefinesNode)
        hDefinesNode = mxx_xmltree('add_next_sibling', hIncludePathsNode, 'Defines');
    end
    ahDefines = mxx_xmltree('get_nodes', hCodeGenDoc, './cg:Defines/cg:Define');
    for i = 1:length(ahDefines)
        hDefine = ahDefines(i);

        hNewDefineNode = mxx_xmltree('add_node', hDefinesNode, 'Define');
        mxx_xmltree('set_attribute', hNewDefineNode, 'name', mxx_xmltree('get_attribute', hDefine, 'name'));
        sValue = mxx_xmltree('get_attribute', hDefine, 'value');
        if ischar(sValue)
            mxx_xmltree('set_attribute', hNewDefineNode, 'value', sValue);
        end
    end

catch exception
    disp(getReport(exception));
    rethrow(exception);
end
end


%%
function aiLinElements = i_getLinearElementsIdx(aiWidth, aiElements, aiElements2)
if isempty(aiElements)
    aiLinElements = [];
    return;
end

if any(aiElements < 0)
    aiElements = 0:(aiWidth(1) - 1);
end

if isempty(aiElements2)
    aiLinElements = aiElements;
    return;
end

if any(aiElements2 < 0)
    aiElements2 = 0:(aiWidth(2) - 1);
end

iLen1 = length(aiElements);
iLen2 = length(aiElements2);

% create subindex of matrix (account for offset 1 by adding one)
aiSubIdx  = reshape(repmat(aiElements + 1, 1, iLen2), 1, []);
aiSubIdx2 = reshape(repmat(aiElements2 + 1, iLen1, 1), 1, []);

% create linear index (accound for offset 0 by subtracting one)
aiLinElements = sub2ind(aiWidth, aiSubIdx, aiSubIdx2) - 1;
end

