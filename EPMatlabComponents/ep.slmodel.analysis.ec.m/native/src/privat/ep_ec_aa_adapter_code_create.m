function stAdapterInfo = ep_ec_aa_adapter_code_create(sModelName, sAdapterSourceFile)
% Create the adapter layer for an AA model.
%

%%
if (nargin < 2)
    if (nargin < 1)
        sModelName = bdroot(gcs);
    end
    sAdapterSourceFile = fullfile(pwd, [sModelName, '_adapter.cpp']);
end

[p, f] = fileparts(sAdapterSourceFile);
sAdapterHeader = [f, '.h'];
sAdapterHeaderFile = fullfile(p, sAdapterHeader);

stClassInfo = i_getClassInfoModel(sModelName);
[stAdapterInfo, casSourceContent, casHeaderContent]  = i_createAdapterContent(stClassInfo);
i_createHeaderFileCPP(sAdapterHeaderFile, casHeaderContent, {});
i_createSourceFileCPP(sAdapterSourceFile, casSourceContent, {stClassInfo.sHeader, sAdapterHeader})
end


%%
function stClassInfo = i_getClassInfoModel(sModelName)
[casStepMethods, casProvidedMethods] = i_getMethods(sModelName);

bIsFunctionCallStyle = ~isempty(casStepMethods) || ~isempty(casProvidedMethods);
if ~bIsFunctionCallStyle
    casStepMethods = i_getStepFuncsForRateBasedModel(sModelName);
    if (numel(casStepMethods) > 1)
        error('EP:ECAA:RATE_BASED_MULTI_STEP', 'Rate-based AA models with more than one step function are not supported.');
    end
end

casStepMethods = i_appendMessageTriggeredMethods(casStepMethods, sModelName);

[sHeader, sClassName] = i_getHeaderAndClassInfo(sModelName);
stClassInfo = struct( ...
    'sHeader',            sHeader, ...
    'sClassName',         sClassName, ...
    'sInitMethod',        'initialize', ...
    'casStepMethods',     {casStepMethods}, ...
    'casProvidedMethods', {casProvidedMethods});
end


%%
function [sHeader, sClassName] = i_getHeaderAndClassInfo(sModelName)
try
    oCD = coder.getCodeDescriptor(sModelName);
    oComp = oCD.getFullComponentInterface;
    oConstructorPrototype = oComp.ConstructorFunction.Prototype;
    sHeader = oConstructorPrototype.HeaderFile;
    sClassName = oConstructorPrototype.Name;

catch oEx
    warning('EP:UNEXPECTED:ERROR', 'Could not read constructor for main class of AA model: %s', oEx.getReport());

    % continue with defaults
    sHeader    = sprintf('%s.h', sModelName);
    sClassName = sModelName;
end
end


%%
function casStepMethods = i_getStepFuncsForRateBasedModel(sModelName)
try
    oCD = coder.getCodeDescriptor(sModelName);
    aoFuncs = oCD.getFunctionInterfaces('Output');
    casStepMethods = arrayfun(@(o) o.Prototype.Name, aoFuncs, 'UniformOutput', false);

catch oEx
    warning('EP:UNEXPECTED:ERROR', 'Could not read out step functions for rate-based AA model: %s', oEx.getReport());

    % continue with default
    casStepMethods = {'step'};
end
end


%%
function [casStepMethods, casProvidedMethods] = i_getMethods(sModelName)
hModel = get_param(sModelName, 'handle');
casStepMethods = i_getStepMethods(hModel);
casProvidedMethods = i_getProvidedMethods(hModel);
end

%%
function casStepMethods = i_getStepMethods(hModel)
ahCallInports = ep_find_system(hModel, ...
    'SearchDepth',        1, ...
    'LookUnderMasks',     'all', ...
    'OutputFunctionCall', 'on', ...
    'BlockType',          'Inport');

casStepMethods = arrayfun(@(h) get_param(h, 'Name'), ahCallInports, 'UniformOutput', false);
end


%%
function casProvidedMethods = i_getProvidedMethods(hModel)
ahTriggerPortBlocks = ep_find_system(hModel, ...
    'BlockType',          'TriggerPort', ...
    'IsSimulinkFunction', 'on', ...
    'FunctionVisibility', 'port');

casProvidedMethods = arrayfun(@i_getPortScopeFunctionName, ahTriggerPortBlocks, 'UniformOutput', false);
end

%%
function casStepMethods = i_appendMessageTriggeredMethods(casStepMethods, hModel)
ahMessageTriggerPorts = ep_find_system(hModel, ...
    'BlockType',   'TriggerPort', ...
    'TriggerType', 'message', ...
    'TriggerTime', 'on message available', ...
    'ScheduleAsAperiodic', 'on');

casMessageTriggeredMethods = cellfun(@(x) get_param(x, 'FunctionName'), ahMessageTriggerPorts, 'UniformOutput', false);
for i = 1:numel(casMessageTriggeredMethods)
    casStepMethods{end+1} = casMessageTriggeredMethods{i}; %#ok
end
end

%%
function sFuncName = i_getPortScopeFunctionName(hTriggerPortBlock)
sFuncName = [get_param(hTriggerPortBlock, 'ScopeName'), '.', get_param(hTriggerPortBlock, 'FunctionName')];
end


%%
function [stAdapterInfo, casSourceContent, casHeaderContent] = i_createAdapterContent(stClassInfo)
stAdapterInfo = struct( ...
    'sInitFunc', '', ...
    'sStepFunc', '', ...
    'casMessageTriggeredFunc', {{}});

% define the application object as a global variable "sut"
casSourceContent = { ...
    sprintf('%s sut;', stClassInfo.sClassName), ...
    ''};
casHeaderContent = {};

% declare and define the init function
sGlobalInitFunc = i_getGlobalFunc(stClassInfo.sInitMethod);
casSourceContent = [casSourceContent, { ...
    sprintf('void %s() {', sGlobalInitFunc), ...
    sprintf('  sut.%s();', stClassInfo.sInitMethod), ...
    '}', ...
    ''}];
casHeaderContent = [casHeaderContent, { ...
    sprintf('void %s();', sGlobalInitFunc), ...
    ''}];
stAdapterInfo.sInitFunc = sGlobalInitFunc;


if ~isempty(stClassInfo.casStepMethods)

    casHeaderStepDeclarations = {};
    for i = 1:numel(stClassInfo.casStepMethods)
        sStepMethod = stClassInfo.casStepMethods{i};
        sGlobalStepFunc = i_getGlobalFunc(sStepMethod);

        % set the first found step function as the returned global step function
        if isempty(stAdapterInfo.sStepFunc)
            stAdapterInfo.sStepFunc = sGlobalStepFunc;
        else
            stAdapterInfo.casMessageTriggeredFunc = [stAdapterInfo.casMessageTriggeredFunc, sGlobalStepFunc];          
        end

        casSourceContent = [casSourceContent, { ...
            sprintf('void %s() {', sGlobalStepFunc), ...
            sprintf('  sut.%s();', sStepMethod), ...
            '}', ...
            ''}]; %#ok<AGROW>

        casHeaderStepDeclarations = [casHeaderStepDeclarations, { ...
            sprintf('void %s();', sGlobalStepFunc), ...
            ''}]; %#ok<AGROW>
    end

    casHeaderStepDeclarations = i_surroundCodeLinesWithExternC(casHeaderStepDeclarations);
    casHeaderContent = [casHeaderContent, casHeaderStepDeclarations];
end
end


%%
function casLines = i_surroundCodeLinesWithExternC(casLines)
casExternCPrefix = { ...
    '#ifdef __cplusplus', ...
    'extern "C" {', ...
    '#endif'};

casExternCPostfix = { ...
    '#ifdef __cplusplus', ...
    '}', ...
    '#endif'};

casLines = [casExternCPrefix, casLines, casExternCPostfix];
end


%%
function sGlobalFunc = i_getGlobalFunc(sMethodName)
sGlobalFunc = sprintf('sut_%s', sMethodName);
end


%%
function i_createHeaderFileCPP(sFile, casContent, casIncludeFileNames)
[sDir, sFileName] = fileparts(sFile);
if ~exist(sDir, 'dir')
    mkdir(sDir);
end
hFid = fopen(sFile, 'w');
oOnCleanupCloseFile = onCleanup(@() fclose(hFid));

sGuardMacro = sprintf('_%s_EP_H_', upper(sFileName));
fprintf(hFid, '#ifndef %s\n', sGuardMacro);
fprintf(hFid, '#define %s\n', sGuardMacro);
fprintf(hFid, '\n');

casIncludeFileNames = cellstr(casIncludeFileNames);
if ~isempty(char(casIncludeFileNames))
    fprintf(hFid, '#include "%s"\n',  casIncludeFileNames{:});
end

fprintf(hFid, '\n');
fprintf(hFid, '%s\n', casContent{:});
fprintf(hFid, '\n');

fprintf(hFid, '#endif //%s\n', sGuardMacro);
end


%%
function i_createSourceFileCPP(sFile, casContent, casIncludeFileNames)
sDir = fileparts(sFile);
if ~exist(sDir, 'dir')
    mkdir(sDir);
end
hFid = fopen(sFile, 'w');
oOnCleanupCloseFile = onCleanup(@() fclose(hFid));

casIncludeFileNames = cellstr(casIncludeFileNames);
if ~isempty(char(casIncludeFileNames))
    fprintf(hFid, '#include "%s"\n',  casIncludeFileNames{:});
end

fprintf(hFid, '\n');
fprintf(hFid, '%s\n', casContent{:});
fprintf(hFid, '\n');
end


