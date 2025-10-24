function [ahBlkBlackListRunnable, cahBlksBlackListInRunnable] = ep_ec_autosar_scope_reduce(stArgs)
% Reduces all runnable subsystems to triggered dummy subsystems and removes all other blocks except for the root IOs.
%
%  function [ahBlkBlackListRunnable, cahBlksBlackListInRunnable] = ep_ec_autosar_scope_reduce(stArgs)
%
%  INPUT                        Type                         DESCRIPTION
%   - stArgs
%       .Scope                  (block/handle)               Either model path or handle of the scope (model/subsystem)
%                                                            to be reduced.
%       .mTriggRunnables        (map)                        Map: runnable trigger-name--> runnable name
%       .mRunnableSymbols       (map)                        Map: runnable name -> runnable symbol (function name)
%
%  OUTPUT                                                    DESCRIPTION
%   - ahBlkBlackListRunnable      array                      array of runnable blocks to be deleted at the end of wrapper creation
%   - cahBlksBlackListInRunnable  cell array of arrays       blocks inside of the dummy block to be deleted at the end of wrapper creation
%
%

%%
hScope = get_param(stArgs.Scope, 'handle'); % normalize as handle
sScopePath = getfullname(hScope);

ahOutFuncInports = ep_find_system(hScope, ...
    'SearchDepth',          1, ...
    'IncludeCommented',     'on', ...
    'BlockType',            'Inport', ...
    'OutputFunctionCall',   'on');

mPortNumToInports = i_createMapPortNumToPorts(stArgs.astInports);
mPortNumToOutports = i_createMapPortNumToPorts(stArgs.astOutports);


[astRunnables, ahLinesWhiteList, ahTracedBlocks] = i_traceConnectionToRunnables( ...
    ahOutFuncInports, ...
    stArgs.mTriggRunnables, ...
    stArgs.mRunnableSymbols);
ahAllLines = ep_find_system(hScope, ...
    'SearchDepth', 1, ...
    'FindAll',     'on', ...
    'type',        'line');
ahAllBlocks = ep_find_system(hScope, ...
    'SearchDepth',      1, ...
    'IncludeCommented', 'on');
ahRootInports = ep_find_system(hScope, ...
    'SearchDepth',      1, ...
    'IncludeCommented', 'on', ...
    'BlockType',        'Inport');
ahRootOutports = ep_find_system(hScope, ...
    'SearchDepth',      1, ...
    'IncludeCommented', 'on', ...
    'BlockType',        'Outport');

ahLinesBlackList = setdiff(ahAllLines, ahLinesWhiteList);
delete_line(ahLinesBlackList);
for i = 1:numel(ahRootInports)
    hRootInport = ahRootInports(i);
    set_param(hRootInport, 'SampleTime', '-1');
    if strcmp(get_param(hRootInport, 'OutputFunctionCall'), 'on')
        set_param(hRootInport, 'OutDataTypeStr', 'Inherit: auto')
    else
        sPort = get_param(hRootInport, 'Port');
        if mPortNumToInports.isKey(sPort)
            stPort = mPortNumToInports(sPort);
            i_setPortDimensionIfNotNumeric(hRootInport, stPort.nDim)
        end
    end
end
for i = 1:numel(ahRootOutports)
    hRootOutport = ahRootOutports(i);

    sPort = get_param(hRootOutport, 'Port');
    if mPortNumToOutports.isKey(sPort)
        stPort = mPortNumToOutports(sPort);
        i_setPortDimensionIfNotNumeric(hRootOutport, stPort.nDim)
    end
end

ahFullWhiteList = [ ...
    reshape(ahRootInports, 1, []), ...
    reshape(ahRootOutports, 1, []), ...
    reshape([astRunnables(:).hSubsystem], 1, []) ...
    reshape(ahTracedBlocks, 1, []), ...
    hScope];

%  ahBlkBlackListRunnable: will be deleted later in the ep_ec_wrapper_create.m
ahBlkBlackListRunnable = setdiff(ahAllBlocks, ahFullWhiteList);

cahBlksBlackListInRunnable = [];
if ~isempty(astRunnables)
    cahBlksBlackListInRunnable = i_customizeRunnableContents(astRunnables);
    i_addSlDummyFunction(sScopePath);
    delete(ep_find_system(sScopePath, 'FindAll', 'on', 'type', 'annotation'));
end
end


%%
function i_setPortDimensionIfNotNumeric(hPortBlock, sDimString)
sCurrentDimString = get_param(hPortBlock, 'PortDimensions');
if i_isSymbol(sCurrentDimString)
    set_param(hPortBlock, 'PortDimensions', sDimString);
end
end


%%
% isSymbol currently only checks for symbols that are also valid variable names, i.e. literals like "root.field" are
% not considered at the moment; that may be a wrong heuristic for future cases and in that case needs to be revised
function bIsSymbol = i_isSymbol(sString)
bIsSymbol = isvarname(sString);
end


%%
function mPortNumToPorts = i_createMapPortNumToPorts(astPorts)
mPortNumToPorts = containers.Map;
for i = 1:numel(astPorts)
    mPortNumToPorts(sprintf('%d', astPorts(i).nPortNum)) = astPorts(i);
end
end


%%
%  cahBlksBlackListInRunnable: will be deleted later
function cahBlksBlackListInRunnable = i_customizeRunnableContents(astRunnables)
cahBlksBlackListInRunnable = cell(1, numel(astRunnables));
for i = 1:numel(astRunnables)
    hSubsystem = astRunnables(i).hSubsystem;
    
    ahLinesInRunnable = ep_find_system(hSubsystem, 'SearchDepth', 1, 'FindAll', 'on', 'type', 'line');
    delete_line(ahLinesInRunnable);
    
    ahBlksSubsystems = Simulink.findBlocks(hSubsystem);
    ahBlksWhiteList = Simulink.findBlocksOfType(hSubsystem, 'TriggerPort');
    cahBlksBlackListInRunnable{i} = setdiff(ahBlksSubsystems, ahBlksWhiteList);
    
    i_addFuncCaller(hSubsystem);
    i_setRunnablesCode(hSubsystem, astRunnables(i).sFunc);
end
end


%%
function i_addFuncCaller(hSubsystem)
sNewBlockPath = [getfullname(hSubsystem), '/Call_fake_caller'];
hFunCallerBlk = add_block('simulink/User-Defined Functions/Function Caller', sNewBlockPath);
set(hFunCallerBlk, 'FunctionPrototype', 'ep_dummy_code_func()');
end


%%
function i_setRunnablesCode(hSubsystem, sAutosarFuncName)
set(hSubsystem, 'RTWSystemCode',   'Nonreusable function');
set(hSubsystem, 'RTWFcnNameOpts',  'User specified');
set(hSubsystem, 'RTWFcnName',      sAutosarFuncName);
set(hSubsystem, 'RTWFileNameOpts', 'User specified');
set(hSubsystem, 'RTWFileName',     'ep_dummy_code');
end


%%
function i_addSlDummyFunction(sSubsysDummyPath)
libraryBlockPath = 'simulink/User-Defined Functions/Simulink Function';
sNewBlockPath = strcat(sSubsysDummyPath, '/fake_funcl');
% Add a MATLAB Function to the model
add_block(libraryBlockPath, sNewBlockPath);
% Clean the default blocks to make it void void
delete_block(strcat(sNewBlockPath, '/y'));
delete_block(strcat(sNewBlockPath, '/u'));
hLine = ep_find_system(sNewBlockPath, 'FindAll', 'on', 'type', 'line');
delete_line(hLine);
% config block
sFuncName = 'ep_dummy_code_func';
set_param(strcat(sNewBlockPath,'/f'), 'Name', sFuncName);
sNewBlockPath= strcat(sNewBlockPath, '/', sFuncName);
set_param(sNewBlockPath,'FunctionName', sFuncName);
set_param(sNewBlockPath,'FunctionVisibility', 'global');
end


%%
%  find all signal lines leaving the Inports from OutFuncInports  --> Set OutFuncLines
function [astRunnables, ahAllLines, ahAllBlocks] = i_traceConnectionToRunnables(ahOutFuncInports, mTriggRunnables, mRunnableSymbols)
stRunnableTemplate = struct( ...
    'hSubsystem', '', ...
    'sName',      '', ...
    'sFunc',      '');
ahAllLines   = [];
ahAllBlocks  = [];

aiMissingIdx = []; 
astRunnables = repmat(stRunnableTemplate, 1, numel(ahOutFuncInports));
for i = 1:numel(ahOutFuncInports)
    [sRunnableSub, ahLines, ahBlocks] = ep_ec_trigger_port_subsystem_trace(ahOutFuncInports(i));
    if ~isempty(sRunnableSub)
        sTriggerPortName = get_param(ahOutFuncInports(i), 'name');
        sRunnableName = mTriggRunnables(sTriggerPortName);
        sRunnableFunc = mRunnableSymbols(sRunnableName);
        
        astRunnables(i).hSubsystem = get_param(sRunnableSub, 'handle');
        astRunnables(i).sName      = sRunnableName;
        astRunnables(i).sFunc      = sRunnableFunc;
        
        ahAllLines  = [ahAllLines,  reshape(ahLines, 1, [])]; %#ok<AGROW>
        ahAllBlocks = [ahAllBlocks, reshape(ahBlocks, 1, [])]; %#ok<AGROW>
    else
        aiMissingIdx = [aiMissingIdx, i]; %#ok<AGROW>
    end
end
astRunnables(aiMissingIdx) = [];
end
