function stResult = ep_ec_model_wrapper_mock_server_callers_create(stArgs)
% Creates Mockservers on the top-level of the Wrapper model. In addition, it creates fake callers of the mock servers inside the dummy block
%
%  function stResult = ep_ec_model_wrapper_mock_server_callers_create(stArgs)
%
%  INPUT                        DESCRIPTION
%   - stArgs
%       .sWrapperModelName      Name of the wrapper model
%       .xDummySub              Either path or handle of the dummy subblock to add the server SIL mocks
%       .aiMdlRefBlkPos         Position parameters of reference blocks                                 .
%       .stAutosarInfo          Short info struct with essential info about the AR style of the model
%       .sModelName             Name of the original model
%       .oWrapperData           Wrapper data dictionary object
%       .casIntRunnables        Cell array with blacklisted internal runnables
%
%  OUTPUT                       DESCRIPTION
%    stResult
%       .astDataStoreInfo         data stores of the mockservers
%       .astOpCallInfo            function-caller blocks Infos
%       .mCodeFuncUsedToRequired  map that provides info about code functions that could not be used as required because
%                                 they were violating some SL rules; Map: <used-name> --> <required-name>
%                                 note: can be empty if *all* functions could be used as required
%


%%
stResult = struct( ...
    'astDataStoreInfo',        [], ...
    'astOpCallInfo',           [], ...
    'mCodeFuncUsedToRequired', containers.Map);

%%
hDummySub = get_param(stArgs.xDummySub, 'handle'); % normalize as handle
sModelName = stArgs.sModelName;
nMdlRefBlkPos = stArgs.aiMdlRefBlkPos;
sWrapperModelName = stArgs.sWrapperModelName;

astOpCallInfo = ep_ec_cs_opcall_info_get(sModelName, stArgs.casIntRunnables); %collect function-caller properties
stPositions = struct( ...
    'AREA_WIDTH',      1000, ...
    'SLFUNBLK_HEIGHT', 80, ...
    'HSHIFT',          100, ...
    'VSHIFT',          30, ...
    'HQTY',            3, ...
    'P1_Min',          nMdlRefBlkPos(1),...
    'cnt',             0, ...
    'P2_Min',          nMdlRefBlkPos(4));

astDataStoreInfo = [];
% In case no callers exist no mockserver are generated
if isempty(astOpCallInfo)
    return;
end

% for Multi-Instance AUTOSAR models create a special Rte_Instance Alias type for the addional first argument in the mock
% functions
if stArgs.stAutosarInfo.bIsMultiInstance
    sRteInstanceType = i_createRteInstanceType(stArgs.oWrapperData);
else
    sRteInstanceType = '';
end
stArgs.sRteInstanceType = sRteInstanceType;

stResult.astOpCallInfo = astOpCallInfo;

% Get code mapping object
if verLessThan('matlab', '9.9') % use old API for ML2020a or less
    oMapping = coder.dictionary.internal.SimulinkFunctionMapping;
else
    oMapping = coder.mapping.utils.create(sWrapperModelName);
end
% Generate dummy block for calling the fake Rte_callers
sDummyCallerSubsys = 'dummy_caller_rte_funcs';
hDummyCallerSubsys = i_addEnabledSubsystem(hDummySub, sDummyCallerSubsys);
i_setPosFromTopLeft(hDummyCallerSubsys, stPositions);
set(hDummyCallerSubsys, 'ForegroundColor', 'Green');

% Iterate through function-caller blocks and generate mockservers. Then generate for theses Mocks fcn callers in the dummy block
sBlockSampleTime = i_deriveBlockSampleTimeFromModel(sWrapperModelName);
for k = 1:numel(astOpCallInfo)
    stOpCallInfo = astOpCallInfo(k);

    stPositions.cnt = stPositions.cnt + 1;
    astDataStoreInfo = ...
        [astDataStoreInfo i_createMockServer(oMapping, sWrapperModelName, stOpCallInfo, stPositions)]; %#ok<AGROW>
    stCaller = i_createMockServerRteCaller( ...
        oMapping, ...
        stArgs, ...
        stOpCallInfo, ...
        hDummyCallerSubsys, ...
        stPositions, ...
        sBlockSampleTime);
    if ~strcmp(stCaller.sRequiredCodeName, stCaller.sUsedCodeName)
        stResult.mCodeFuncUsedToRequired(stCaller.sUsedCodeName) = stCaller.sRequiredCodeName;
    end
end
stResult.astDataStoreInfo = astDataStoreInfo;
end


%%
function sRteInstanceType = i_createRteInstanceType(oWrapperData)
sRteInstanceType = 'Rte_Instance';
sContent = sprintf([ ...
    'Rte_Instance = Simulink.AliasType;\n', ...
    'Rte_Instance.DataScope = ''Imported'';\n', ...
    'Rte_Instance.HeaderFile = ''Rte_Type.h'';\n', ...
    'Rte_Instance.BaseType = ''double'';']);

oWrapperData.persistContent(sContent);
end


%%
%TODO refactor for better modularity
function astDataStoreInfo = i_createMockServer(oMapping, sWrapperModelName, stOpCallInfo, stPositions)
astDataStoreInfo = [];
cntArgIn = 0;
cntArgOut = 0;
sFunName = stOpCallInfo.sFunName;

%Look for existing SL Function blocks
sSlFuncBlkName = ['Mock_' sFunName];
%Add Simulink Function block
hSlFunBlk = add_block('simulink/User-Defined Functions/Simulink Function', [sWrapperModelName '/' sSlFuncBlkName]);
set(hSlFunBlk, 'ForegroundColor', 'Blue');
%Arrange positions
i_setPosFromTopLeft(hSlFunBlk, stPositions);
%Set Function name and visibility
sSlFunPath = getfullname(hSlFunBlk);
sTriggerBlk = ep_find_system(sSlFunPath, 'BlockType', 'TriggerPort', 'IsSimulinkFunction', 'on');
set_param(char(sTriggerBlk), 'FunctionName', sFunName);
set_param(char(sTriggerBlk), 'FunctionVisibility', 'global');
set_param(char(sTriggerBlk), 'Name', sFunName);

casInOrderedArgsName = stOpCallInfo.casInArgsName;
casInOrderedArgsDT = stOpCallInfo.casInArgsDT;
casInOrderedArgsDim = stOpCallInfo.casInArgsDim;
casOutOrderedArgsName = stOpCallInfo.casOutArgsName;
casOutOrderedArgsDT = stOpCallInfo.casOutArgsDT;
casOutOrderedArgsDim = stOpCallInfo.casOutArgsDim;

%-delete line in the added block
hLines = ep_find_system(sSlFunPath, 'FindAll', 'on', 'Type', 'Line');
for iL = 1:numel(hLines)
    delete_line(hLines(iL));
end
%-delete Argument Inport if no input arguments
sDummyInLibBlk = i_getLibArgs(sSlFunPath, 'ArgIn');
if isempty(casInOrderedArgsName)
    delete_block(char(sDummyInLibBlk));
else
    %-else add as many needed and connect DataStore block
    nInPos = get_param(sDummyInLibBlk, 'Position');
    nInPos = nInPos{1};
    w = nInPos(3)-nInPos(1);
    h = nInPos(4)-nInPos(2);
    delete_block(char(sDummyInLibBlk));
    for iArg = 1:numel(casInOrderedArgsName)
        cntArgIn = cntArgIn+1;
        sPortName = ['argIn_' casInOrderedArgsName{iArg}];
        nInPos = [nInPos(1) nInPos(2)+h+(20)*iArg nInPos(1)+w nInPos(2)+2*h+(20)*iArg];
        sArgInLibBlk=[sSlFunPath '/' sPortName];
        hArgInBlk = add_block('built-in/ArgIn',sArgInLibBlk, 'ArgumentName', casInOrderedArgsName{iArg}, 'Name', sPortName);
        set(hArgInBlk, 'Position', nInPos);
        sArgInBlk = getfullname(hArgInBlk);
        sInArgsDT = char(casInOrderedArgsDT{iArg});
        if ~isempty(enumeration(sInArgsDT)) % special handling for enums
            sInArgsDT = ['Enum:' sInArgsDT]; %#ok<AGROW>
        end
        set_param(sArgInBlk, 'OutDataTypeStr', sInArgsDT);

        aiArgDim = stOpCallInfo.casInArgsDim{iArg};
        set_param(sArgInBlk, 'PortDimensions', ['[' num2str(aiArgDim) ']'])
        %-add Data Store Write block
        nDSWritePos = [nInPos(1)+w+20 nInPos(2) nInPos(3)+w+20 nInPos(4)];
        sDSWriteName = ['dsout_' sFunName '_' casInOrderedArgsName{iArg}];
        if numel(sDSWriteName) > 63
            sDSWriteName = [sDSWriteName(1:60) '_' num2str(cntArgIn)];
        end
        hDSWrite = add_block('simulink/Signal Routing/Data Store Write', [sSlFunPath '/' sDSWriteName]);
        set(hDSWrite, 'Position', nDSWritePos);
        set(hDSWrite, 'DataStoreName', sDSWriteName);
        add_line(sSlFunPath, [sPortName '/1'], [sDSWriteName '/1'], 'autorouting', 'on');

        stTmp.sDSName = sDSWriteName;
        stTmp.sDSDataType = sInArgsDT;
        stTmp.nDSDim = casInOrderedArgsDim{iArg};
        astDataStoreInfo = [astDataStoreInfo stTmp]; %#ok<AGROW>
    end
end
%-delete Argument Outport if not Output arguments
sDummyOutLibBlk = i_getLibArgs(sSlFunPath, 'ArgOut');
if isempty(casOutOrderedArgsName)
    delete_block(char(sDummyOutLibBlk)); %delete the signal ArgIn block provided with the library block
else
    %-else add as many needed and connect DataStore block
    nOutPos = get_param(sDummyOutLibBlk, 'Position');
    nOutPos = nOutPos{1};
    w = nOutPos(3)-nOutPos(1);
    h = nOutPos(4)-nOutPos(2);
    nOutPos(1) = nOutPos(1) + 100; %shift block further more on right side
    nOutPos(3) = nOutPos(3) + 100;
    delete_block(char(sDummyOutLibBlk));
    for iArg = 1:numel(casOutOrderedArgsName)
        cntArgOut = cntArgOut+1;
        sPortName = ['argOut_' casOutOrderedArgsName{iArg}];
        nOutPos = [nOutPos(1) nOutPos(2)+h+(20)*(iArg) nOutPos(1)+w nOutPos(2)+2*h+(20)*(iArg) ];
        sArgOutLibBlk=[sSlFunPath '/' sPortName];
        hArgOutBlk= add_block('built-in/ArgOut',sArgOutLibBlk, 'ArgumentName', casOutOrderedArgsName{iArg}, 'Name', sPortName);
        set(hArgOutBlk, 'Position', nOutPos);
        sArgOutBlk = getfullname(hArgOutBlk);
        sOutArgsDT = char(casOutOrderedArgsDT{iArg});
        if ~isempty(enumeration(sOutArgsDT)) % special handling for enums
            sOutArgsDT= ['Enum:' sOutArgsDT]; %#ok<AGROW>
        end
        set_param(sArgOutBlk, 'OutDataTypeStr', sOutArgsDT);
        aiArgDim=stOpCallInfo.casOutArgsDim{iArg};
        set_param(sArgOutBlk, 'PortDimensions', ['[' num2str(aiArgDim) ']']);
        %-add Data Store Write block
        nDSReadPos = [nOutPos(1)-(nOutPos(3)-nOutPos(1))-20 nOutPos(2) nOutPos(3)-(nOutPos(3)-nOutPos(1))-20 nOutPos(4)];
        sDSReadName = ['dsin_' sFunName '_' casOutOrderedArgsName{iArg}];
        if numel(sDSReadName) > 63
            sDSReadName = [sDSReadName(1:60) '_' num2str(cntArgOut)];
        end
        hDSRead = add_block('simulink/Signal Routing/Data Store Read', [sSlFunPath '/' sDSReadName]);
        set(hDSRead, 'Position', nDSReadPos);
        set(hDSRead, 'DataStoreName', sDSReadName);
        add_line(sSlFunPath, [sDSReadName '/1'], [sPortName '/1'], 'autorouting', 'on');

        stTmp.sDSName = sDSReadName;
        stTmp.sDSDataType = sOutArgsDT;
        stTmp.nDSDim = casOutOrderedArgsDim{iArg};
        astDataStoreInfo = [astDataStoreInfo stTmp]; %#ok<AGROW>
    end
end

if (length(sSlFuncBlkName) < 64)
    sCodeFuncName = sSlFuncBlkName;
else
    % use a random unique name for the C-code mock function
    sCodeFuncName = i_generateUniqueName('Mock_', sFunName);
end
i_setFunctionInterfaceArgumentsMockServers(oMapping, sWrapperModelName, hSlFunBlk, sFunName, sCodeFuncName);

%Arrange automatically block positions (from ML2018a)
if ~verLessThan('matlab', '9.4')
    try %#ok<TRYNC>
        i_safelyArrangeSubsystems(sSlFunPath);
    end
end
end


%%
% create a random name deterministically from the basis name with less than 40 chars
function sName = i_generateUniqueName(sPrefix, sBasisName)
if (length(sPrefix) > 20)
    error('EP:USAGE_ERROR:PREFIX_NOT_SUPPORTED', 'Currently only supporting prefix with max length 20.');
end

sHash = i_stringToHash(sBasisName);

sName = [sPrefix, sHash, sBasisName];
if (length(sName) > 40)
    sName = sName(1:39);
end
end


%%
function sHash = i_stringToHash(sString)
jString = java.lang.String(sString);
sHash = sprintf('%d', jString.hashCode);
sHash(sHash == '-') = 'm';
end


%%
function sPrototype = i_getDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFunName)
if verLessThan('matlab', '9.9') % use old API for ML2020a or less
    sPrototype = oMapping.createDefaultFunctionPrototypeFromBlock(hSlFuncBlock);
else
    sPrototype = i_getPrototypeWorkaround(sWrapperModelName, sFunName, 5);
    if isempty(sPrototype)
        %for new ML versions we get an empty argument string, so we mock the prototype string. Otherwise,
        %it would be just an empty string and yield problems when parsing it
        sPrototype = '$N( )';
    end
end
end


%%
function sPrototype = i_getPrototypeWorkaround(sWrapperModelName, sFunName, nCount)
sPrototype = '';
if (nCount < 1)
    return;
end

pause(0.5); % need to wait some time; otherwise the API call will give wrong results
oMapping = coder.mapping.api.get(sWrapperModelName);
try
    sPrototype = getFunction(oMapping, ['SimulinkFunction:' sFunName], 'Arguments');

catch oEx %#ok<NASGU>
    fprintf('\n[INFO] Trying to find function "%s" in attempt #%d failed.\n', sFunName, 6-nCount);
    fprintf('\n[INFO] Found only:\n');
    casFuncs = oMapping.find('Functions');
    fprintf('%s\n', casFuncs{:});

    sPrototype = i_getPrototypeWorkaround(sWrapperModelName, sFunName, nCount - 1);
end
end


%%
function stParsedProto = i_getParsedDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFunName)
sPrototype = i_getDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFunName);
stParsedProto = ep_ec_func_interface_settings_parse(sPrototype);
end


%%
%TODO check if can be combined with i_createMockServers
function stResult = i_createMockServerRteCaller(oMapping, stArgs, stOpCallInfo, hDummyCallerSubsys,...
    stPositions, sBlockSampleTime)
stResult = struct( ...
    'sRequiredCodeName', '', ...
    'sUsedCodeName',     '');

%Needed arguments
sWrapperModelName = stArgs.sWrapperModelName;
hDummySub = get_param(stArgs.xDummySub, 'handle');
oWrapperData = stArgs.oWrapperData;
sFunName = stOpCallInfo.sFunName;
sDstBlkName = ['Rte_' sFunName];
if (length(sDstBlkName) < 64)
    sSlFuncName = sDstBlkName;
else
    sSlFuncName = i_generateUniqueName('Rte_', sFunName);
end
casInOrderedArgsName = stOpCallInfo.casInArgsName;
casOrderedArgName = stOpCallInfo.casOrderedArgName;
casOutOrderedArgsName = stOpCallInfo.casOutArgsName;
casInOrderedArgsDT = stOpCallInfo.casInArgsDT;
casInOrderedArgsDim = stOpCallInfo.casInArgsDim;
casOutOrderedArgsDT = stOpCallInfo.casOutArgsDT;
casOutOrderedArgsDim = stOpCallInfo.casOutArgsDim;

% Add SL Function
hSlFunc = i_addSlFunction(hDummySub, sDstBlkName, sSlFuncName);

% Generate function callers for every mock server
hFunCallerBlk = i_addFuncCallBlk(hSlFunc, sFunName, stOpCallInfo, oWrapperData, false, stArgs.stAutosarInfo.bIsMultiInstance);
sSlFuncBlkPath = getfullname(hSlFunc);
sFcnCallerName = get_param(hFunCallerBlk, 'Name');

% Generate dummy fcn caller for rte callers in a deactivated subsystem
[hDummyFuncCallerBlk, sErrName] = i_addFuncCallBlk(hDummyCallerSubsys, sSlFuncName, stOpCallInfo,...
    oWrapperData, true, stArgs.stAutosarInfo.bIsMultiInstance);

% if the created caller block has no inports, it is considered a source block and needs to get a sample time on its own
% EPDEV-75159: for multi-instance models there is always an input to a function caller block --> never a source block
bIsSourceBlock = ~stArgs.stAutosarInfo.bIsMultiInstance && isempty(stOpCallInfo.casInArgsName);
if (bIsSourceBlock && ~isempty(sBlockSampleTime))
    set_param(hDummyFuncCallerBlk, 'SampleTime', sBlockSampleTime);
end

% Arrange positions
i_setPosFromTopLeft(hSlFunc, stPositions);
i_setPosFromTopLeft(hDummyFuncCallerBlk, stPositions);
set(hSlFunc, 'ForegroundColor', 'Green');

hDummyInLibBlk = i_getLibArgs(hSlFunc, 'ArgIn'); % get library block for estimating positions

if stArgs.stAutosarInfo.bIsMultiInstance
    hSelfArgBlk = add_block('built-in/ArgIn', [sSlFuncBlkPath '/self'], 'ArgumentName', 'self');
    set_param(hSelfArgBlk, 'OutDataTypeStr', stArgs.sRteInstanceType);
    add_block('simulink/Sinks/Terminator', [sSlFuncBlkPath '/term']);
    add_line(sSlFuncBlkPath, 'self/1', 'term/1', 'autorouting', 'on');
end

% Iterate through all inports, generate these within server fcn callers and bind to correponding block
if ~isempty(casInOrderedArgsName)
    nInPos = get_param(hDummyInLibBlk, 'Position');
    w = nInPos(3)-nInPos(1);
    h = nInPos(4)-nInPos(2);
    delete_block(hDummyInLibBlk);
    for iArg = 1:numel(casInOrderedArgsName)
        nInPos = [nInPos(1) nInPos(2)+h+(20)*iArg nInPos(1)+w nInPos(2)+2*h+(20)*iArg];
        sPortName = ['argIn_' casInOrderedArgsName{iArg}];
        sArgInLibBlk = [sSlFuncBlkPath '/' sPortName];
        hArgInBlk = add_block('built-in/ArgIn',sArgInLibBlk, 'ArgumentName', casInOrderedArgsName{iArg});
        set(hArgInBlk, 'Position', nInPos);
        sInArgsDT = char(casInOrderedArgsDT{iArg});
        if ~isempty(enumeration(sInArgsDT)) % special handling for enums
            sInArgsDT = ['Enum:' sInArgsDT]; %#ok<AGROW>
        end
        set_param(hArgInBlk, 'OutDataTypeStr', sInArgsDT);
        aiArgDim = stOpCallInfo.casInArgsDim{iArg};
        set_param(hArgInBlk, 'PortDimensions', ['[' num2str(aiArgDim) ']'])
        set_param(hArgInBlk, 'Name', sPortName);
        add_line(sSlFuncBlkPath, [sPortName '/1'], [sFcnCallerName '/' num2str(iArg)], 'autorouting', 'on');
    end
else
    delete_block(hDummyInLibBlk);
end
% Iterate through all outports, generate these within server fcn callers and bind to correponding block
sDummyOutLibBlk = i_getLibArgs(hSlFunc, 'ArgOut'); % get library block to estimating positions
% check if ErrorArgument is existent, if not add it
if ~isempty(casOutOrderedArgsName)
    nOutPos = get_param(sDummyOutLibBlk, 'Position');
    w = nOutPos(3)-nOutPos(1);
    h = nOutPos(4)-nOutPos(2);
    nOutPos(1) = nOutPos(1) + 100; %shift block further more on right side
    nOutPos(3) = nOutPos(3) + 100;
    delete_block(sDummyOutLibBlk);
    for iArg = 1:numel(casOutOrderedArgsName)
        nOutPos = [nOutPos(1) nOutPos(2)+h+(20)*(iArg) nOutPos(1)+w nOutPos(2)+2*h+(20)*(iArg) ];
        sPortName = ['argOut_' casOutOrderedArgsName{iArg}];
        sArgOutLibBlk = [sSlFuncBlkPath '/' sPortName];
        hArgOutBlk = add_block('built-in/ArgOut', sArgOutLibBlk, 'ArgumentName', casOutOrderedArgsName{iArg});
        set(hArgOutBlk, 'Position', nOutPos);
        aiArgDim = stOpCallInfo.casOutArgsDim{iArg};
        set_param(hArgOutBlk, 'PortDimensions', ['[' num2str(aiArgDim) ']']);
        sOutArgsDT = char(casOutOrderedArgsDT{iArg});
        if ~isempty(enumeration(sOutArgsDT)) % special handling for enums
            sOutArgsDT = ['Enum:' sOutArgsDT]; %#ok<AGROW>
        end
        set_param(hArgOutBlk, 'OutDataTypeStr', sOutArgsDT);
        set_param(hArgOutBlk, 'Name', sPortName);
        add_line(sSlFuncBlkPath, [sFcnCallerName '/' num2str(iArg)], [sPortName '/1'], 'autorouting', 'on');
    end
else
    delete_block(sDummyOutLibBlk);
end
if ~stOpCallInfo.bHasErrorArguments
    i_addErrorArgsBlock(hSlFunc, sErrName);
else
    sErrName = stOpCallInfo.sErrArgName; % take the orig name of autosar Arg with type Error
end

sCodeFuncName = stOpCallInfo.sRteCallFunName;
if i_isSLFuncCodeNameValid(sCodeFuncName)
    stResult.sRequiredCodeName = sCodeFuncName;
    stResult.sUsedCodeName = sCodeFuncName;
else
    % note: if CodeName is not valid, use the function name of the glocal SL Function
    % why: this name always has to be short (below 64 chars) and globally unique
    sAlternativeName = sSlFuncName;
    stResult.sRequiredCodeName = sCodeFuncName;
    stResult.sUsedCodeName = sAlternativeName;
    sCodeFuncName = sAlternativeName;
end
if stArgs.stAutosarInfo.bIsMultiInstance
    casOrderedArgName = [{'self'}, casOrderedArgName];
end

% TODO: <under construction>
%
% IMPROVEMENT IDEA: split this part into an extra loop over the Operation calls to avoid the expensive pause() calls
%                   for each operation
i_setFunctionInterfaceArgumentsDummy( ...
    oMapping, ...
    sWrapperModelName, ...
    hSlFunc, ...
    sSlFuncName, ...
    sCodeFuncName, ...
    casOrderedArgName, ...
    sErrName);

addterms(hDummyCallerSubsys);
%Arrange automatically block positions (from ML2018a)
if ~verLessThan('matlab', '9.4')
    try %#ok<TRYNC>
        i_safelyArrangeSubsystems(getfullname(hSlFunc));
    end
end
end


%%
function sBlockSampleTime = i_deriveBlockSampleTimeFromModel(sModelName)
sBlockSampleTime = '';

oConfigSet = getActiveConfigSet(sModelName);
sModelSampleTime = get_param(oConfigSet, 'FixedStep');
dModelSampleTime = str2double(sModelSampleTime);
bIsValid = (~isempty(dModelSampleTime)  && ~isequal(dModelSampleTime, -1) && isfinite(dModelSampleTime));
if bIsValid
    sBlockSampleTime = sModelSampleTime;
end
end


%%
function bIsValid = i_isSLFuncCodeNameValid(sCodeFuncName)
bIsValid = (numel(sCodeFuncName) < 64);
end


%%
function i_setFunctionInterfaceArgumentsMockServers(oMapping, sWrapperModelName, hSlFuncBlock, sFuncName, sCodeFuncName)
stParsedProto = i_getParsedDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFuncName);
stParsedProto.sFuncName = sCodeFuncName;
i_setFunctionInterfaceSettings(sWrapperModelName, sFuncName, stParsedProto);
end


%%
function i_setFunctionInterfaceArgumentsDummy(oMapping, sWrapperModelName, hSlFuncBlock, sFuncName,...
    sRteCallFunName, casOrderedArgName, sErrName)
stParsedProto = i_getParsedDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFuncName);
stConformPrototype = i_makeFuncCallAutosarConform(stParsedProto, sRteCallFunName, casOrderedArgName, sErrName);
i_setFunctionInterfaceSettings(sWrapperModelName, sFuncName, stConformPrototype);
end


%%
function stIfSettings = i_makeFuncCallAutosarConform(stParseIfSettings, sRteCallFunName, casOrderedArgName, sErrName)
stParseIfSettings.sReturn = sErrName;
stParseIfSettings.sFuncName = sRteCallFunName;
idx = i_findArrayStruct(sErrName,  stParseIfSettings.astArgs) ; %get index of the ERR token in the astArgs
stParseIfSettings.astArgs(idx) = []; %rm ERR Token since already set as return Argument.
% remove error Args from ordered array to make ordering possible
idxErr = strcmp(casOrderedArgName, sErrName);
casOrderedArgName(idxErr) = [];

for i = 1:numel(casOrderedArgName)
    if ~isempty(stParseIfSettings.astArgs(i).sName)
        if ~strcmp(stParseIfSettings.astArgs(i).sName, casOrderedArgName(i))
            %get index of current Args in the astArgs
            idx2 = i_findArrayStruct(char(casOrderedArgName(i)), stParseIfSettings.astArgs);
            stParseIfSettings.astArgs = i_swapArrayCells(stParseIfSettings.astArgs, i, idx2);
        end
    end
end
stIfSettings = stParseIfSettings;
end

%%
function astArgsRes = i_swapArrayCells(astArgs, idx1,idx2)
astTmp = astArgs(idx1);
astArgs(idx1) = astArgs(idx2);
astArgs(idx2) = astTmp;
astArgsRes = astArgs;
end

%%
function idx = i_findArrayStruct(sToken, astArgs)
abField = strcmp(arrayfun(@(sas) sas.sName, astArgs, 'uni', false), {sToken});
idx = find(abField, 1);
end

%%
function i_setFunctionInterfaceSettings(sWrapperModelName, sFuncName, stInterfaceSettings)
sFunctionInterfaceSettings = ep_ec_func_interface_settings_create(stInterfaceSettings);
if verLessThan('matlab', '9.9') % use old API for ML2020a or less
    drawnow;
    coder.dictionary.api.set(sWrapperModelName, 'SimulinkFunction', sFuncName, 'CodePrototype', sFunctionInterfaceSettings);
else
    oMapping = coder.mapping.api.get(sWrapperModelName);
    setFunction(oMapping, ['SimulinkFunction:' sFuncName], 'Arguments', sFunctionInterfaceSettings)
end
end

%%
function i_addErrorArgsBlock(hSlFunc, sErrName)
sSlFuncBlkPath = getfullname(hSlFunc);
hErrorBlk = add_block('built-in/ArgOut', [sSlFuncBlkPath '/' sErrName],'ArgumentName', sErrName );
set(hErrorBlk, 'ArgumentName', sErrName);
set(hErrorBlk, 'OutDataTypeStr', 'uint8')
sConsBlk ='ConsBlk';
hConsBlk =  add_block('simulink/Commonly Used Blocks/Constant', [sSlFuncBlkPath '/' sConsBlk]);
set(hConsBlk, 'Value', 'uint8(0)');
sArgPort = strcat(sErrName, '/1');
add_line(sSlFuncBlkPath ,strcat(sConsBlk,'/1'),sArgPort);
end

%%
%  Info needed about the exact original signal dimensions!
%    --> special handling for Mx1 (or 1xN) signals
function sFormatedArgsSpec = i_formatArgsSpec(casOrderedArgsDT, casOrderedArgsDim, oWrapperData)
casArgsSpec = cell(1, numel(casOrderedArgsDT));
sFormatedArgsSpec = ''; %#ok<NASGU>
for i = 1:numel(casOrderedArgsDT)
    sArgsDt = casOrderedArgsDT{i};
    aiArgsDim = casOrderedArgsDim{i};
    aiArgsDim = [numel(aiArgsDim) aiArgsDim]; %#ok<AGROW>
    casArgsSpec{i} = oWrapperData.getTypeInstance(sArgsDt, aiArgsDim);
end

sFormatedArgsSpec = strjoin (casArgsSpec , ', ');
end

%%
function [hFunCallerBlk, sErrName] = i_addFuncCallBlk(hSlBlock, sFunName, stOpCallInfo, oWrapperData, bIsDummy, bIsMultiInstance)
casInOrderedArgsName = stOpCallInfo.casInArgsName;
casInOrderedArgsDT   = stOpCallInfo.casInArgsDT;
casInOrderedArgsDim  = stOpCallInfo.casInArgsDim;
if (bIsDummy && bIsMultiInstance)
    casInOrderedArgsName = [{'self'}, casInOrderedArgsName];
    casInOrderedArgsDT   = [{'Rte_Instance'}, casInOrderedArgsDT];
    casInOrderedArgsDim  = [{1}, casInOrderedArgsDim];
end

casOutOrderedArgsName = stOpCallInfo.casOutArgsName;
casOutOrderedArgsDT   = stOpCallInfo.casOutArgsDT;
casOutOrderedArgsDim  = stOpCallInfo.casOutArgsDim;

casCallerProps = {};

%  Set function prototype
if bIsDummy
    bHasNoErrorArgument = ~stOpCallInfo.bHasErrorArguments;
    [sFuncPrototype, sErrName] = ...
        i_getFuncPrototype(sFunName, casOutOrderedArgsName, casInOrderedArgsName, bHasNoErrorArgument);
else
    % false: no need to add ERR argument here
    [sFuncPrototype, sErrName] = i_getFuncPrototype(sFunName, casOutOrderedArgsName, casInOrderedArgsName, false);
end
casCallerProps = [casCallerProps, {'FunctionPrototype', char(sFuncPrototype)}];

if ~isempty(casInOrderedArgsName)
    sFormattedInArgsSpec = i_formatArgsSpec(casInOrderedArgsDT, casInOrderedArgsDim, oWrapperData);
    casCallerProps = [casCallerProps, {'InputArgumentSpecifications', sFormattedInArgsSpec}];
end

if ~isempty(casOutOrderedArgsName)
    sFormattedOutArgsSpec = i_formatArgsSpec(casOutOrderedArgsDT, casOutOrderedArgsDim, oWrapperData);
    % Add ERR type if not existent
    if ~isempty(sErrName)
        sFormattedOutArgsSpec = [sFormattedOutArgsSpec ', uint8(0)'];
    end
    casCallerProps = [casCallerProps, {'OutputArgumentSpecifications', sFormattedOutArgsSpec}];
else
    if bIsDummy
        casCallerProps = [casCallerProps, {'OutputArgumentSpecifications', 'uint8(0)'}];
    end
end

sSlFuncBlkPath = getfullname(hSlBlock);
sSlFuncBlkPath = [sSlFuncBlkPath '/caller_' sFunName];
hFunCallerBlk = add_block('simulink/User-Defined Functions/Function Caller', sSlFuncBlkPath, casCallerProps{:});
end


%%
function hSlFunc = i_addSlFunction(hParentBlock, sDstBlockName, sSlFuncName)
sDummyBlkPath = getfullname(hParentBlock);
sLibraryBlockPath = 'simulink/User-Defined Functions/Simulink Function';
sNewSlFuncBlock = [sDummyBlkPath '/' sDstBlockName];

hSlFunc = add_block(sLibraryBlockPath, sNewSlFuncBlock);

% config block
% rename the function-call trigger port
sDefaultFuncTriggerBlock = strcat(sNewSlFuncBlock, '/f');
set_param(sDefaultFuncTriggerBlock, 'Name', sDstBlockName);
sFuncTriggerBlock = strcat(sNewSlFuncBlock, '/', sDstBlockName);
set_param(sFuncTriggerBlock, 'FunctionName', sSlFuncName);
set_param(sFuncTriggerBlock, 'FunctionVisibility', 'global');

% Delete the default line between the inArg and outArg block
hLine = ep_find_system(hSlFunc, 'FindAll', 'on', 'type', 'line');
delete_line(hLine);
end


%%
function hEnabledSubsys = i_addEnabledSubsystem(hDummyBlk, sDstBlkName)
sDummyBlkPath= getfullname(hDummyBlk);
libraryBlockPath = 'simulink/Ports & Subsystems/Enabled Subsystem';
sNewBlockPath=[sDummyBlkPath '/' sDstBlkName];
% Add a MATLAB Function to the model
hEnabledSubsys=add_block(libraryBlockPath, sNewBlockPath);
% Clean the default line
hLine = ep_find_system(sNewBlockPath, 'FindAll', 'on', 'type', 'line');
delete_line(hLine);
% Clean the default blocks
delete_block(strcat(sNewBlockPath,'/', 'In1'));
delete_block(strcat(sNewBlockPath,'/', 'Out1'));
%Connect to a constant 0 to disable activation
hConsBlk=  add_block('simulink/Commonly Used Blocks/Constant', [sDummyBlkPath '/'  'never_call']);
hConsBlkPorts = get_param(hConsBlk,'PortHandles');
hEnSubsysPorts = get_param(hEnabledSubsys,'PortHandles');
set(hConsBlk, 'Value', '0');
% bind both blocks with line
add_line(sDummyBlkPath ,hConsBlkPorts.Outport(1), hEnSubsysPorts.Enable);
%  *set Code settings like in confluence
set(hEnabledSubsys, 'RTWSystemCode', 'Nonreusable function');
set(hEnabledSubsys, 'RTWFcnNameOpts', 'User specified');
set(hEnabledSubsys, 'RTWFcnName', sDstBlkName);
set(hEnabledSubsys, 'RTWFileNameOpts', 'User specified');
set(hEnabledSubsys, 'RTWFileName', 'ep_dummy_code');
end


%%
function [sFuncPrototype, sErrName] = i_getFuncPrototype(sFunName, casOutArgsName, casInArgsName, bHasNoErrorArgument)
sOut = ''; %#ok<NASGU>
sErrName = '';
if all(bHasNoErrorArgument) % special handling for missing ERR arguments
    casOutArgsName{numel(casOutArgsName)+1} = 'ERR';
    casOutArgsName= matlab.lang.makeUniqueStrings(casOutArgsName, numel(casOutArgsName));
    sErrName= casOutArgsName{numel(casOutArgsName)};
end
if  (numel(casOutArgsName) > 1)
    sOut = '[';
    for i = 1:numel(casOutArgsName)
        sOut = strcat(sOut, casOutArgsName(i),',');
    end
    sOut = regexprep(sOut, '.$', '');
    sOut = strcat(sOut, ']=');
else
    if isempty(casOutArgsName)
        sOut = '';
    else
        sOut = strcat(casOutArgsName, '=');
    end
end

if numel(casInArgsName) >1
    sIn='(';
    for i=1:numel(casInArgsName)
        sIn=strcat(sIn, casInArgsName(i),',');
    end
    sIn=regexprep(sIn, '.$', '');
    sIn=strcat(sIn,')');
else
    if isempty(casInArgsName)
        sIn=strcat('()');
    else
        sIn=strcat('(',casInArgsName, ')');
    end

end
sFuncPrototype = strcat(sOut, sFunName, sIn);
end

%%
function i_setPosFromTopLeft(hdl_or_sys, stPositions)
cntSLFBlk=stPositions.cnt; %used to shift position
stPositions.P2_Min=stPositions.P2_Min+stPositions.VSHIFT;
SLFUNBLK_WIDTH =floor(stPositions.AREA_WIDTH/stPositions.HQTY) - stPositions.HSHIFT;
pt1=stPositions.P1_Min + (stPositions.HSHIFT + SLFUNBLK_WIDTH)*(mod(cntSLFBlk-1, stPositions.HQTY));
pt2=stPositions.P2_Min + floor((cntSLFBlk-1)/stPositions.HQTY)*(stPositions.SLFUNBLK_HEIGHT+stPositions.VSHIFT);
l=SLFUNBLK_WIDTH;
h=stPositions.SLFUNBLK_HEIGHT;
nPos=[pt1, pt2, pt1+l, pt2+h];
if ischar(hdl_or_sys)
    set_param(hdl_or_sys,'Position',nPos);
else
    set(hdl_or_sys,'Position',nPos);
end
end

%%
function sArgLibBlk = i_getLibArgs(hFunCallerBlk, sType)
sArgLibBlk = ep_find_system(hFunCallerBlk, 'BlockType', sType);
end

%%
function i_safelyArrangeSubsystems(sSubsystem)
if verLessThan('matlab', '9.13')
    % workaround for calling Simulink.BlockDiagram.arrangeSystem in ML<2022b
    % it corrupts the current folder as long as the matlab instance is running
    sTmp = getenv('TMP');
    if ~isempty(sTemp)
        sDummyDir = fullfile(sTmp,'BTC','Cleanup');
        if ~exist(sDummyDir,'dir')
            mkdir(sDummyDir);
        end
    else
        sDummyDir = pwd;
    end
    sLocation = pwd;
    cd(sDummyDir);
    Simulink.BlockDiagram.arrangeSystem(sSubsystem);
    cd(sLocation);
else
    Simulink.BlockDiagram.arrangeSystem(sSubsystem);
end
end