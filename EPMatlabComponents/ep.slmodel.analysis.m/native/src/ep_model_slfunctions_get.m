function astSlFunctions = ep_model_slfunctions_get(xModelContext)
% Returns all Simulink functions used inside a model context (model or subsystem).
% 
% function astSlFunctions = ep_slfunctions_get(xModelContext)
%
%   INPUT               DESCRIPTION
%       xModelContext     (string/handle)   name/path/handle of the model or a subsystem inside an open/loaded model 
%                                           (note: the model is not expected to be in compiled mode)
%
%   OUTPUT              DESCRIPTION
%       astSlFunctions    (array struct)  see description below
%        .sFunctionName   (string)          function name of the SL Function
%        .sVisibility     (string)          visibility of the the SL Function: 'global' | 'scoped' (since ML2017b)
%        .sPath           (string)          full valid model path
%        .sVirtualPath    (string)          virtual model path (model references are treated as inlined)
%        .sPrototype      (string)          unique prototype for Simulink function
%        .nInports        (int)             number of "normal" inports
%        .nOutports       (int)             number of "normal" outports
%        .astCallers      (array struct)    callers of the Simulink function         
%           .sPath        (string)            full path to the caller
%           .sVirtualPath (string)            virtual path to the caller
%


%%
if (nargin < 1)
    xModelContext = bdroot(gcs);
end

astTree = atgcv_m01_model_tree_get(xModelContext);
astSlFunctions = i_getAllSlFunctionsFromSubsystemTree(astTree);
end


%%
function astSlFunctions = i_getAllSlFunctionsFromSubsystemTree(astTree)
if isempty(astTree)
    astSlFunctions = [];
    return;
end
    
casAllContexts = unique({astTree(:).sPath});
mModelFuncMap   = containers.Map('KeyType', 'char', 'ValueType', 'any');
mModelCallerMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:numel(casAllContexts)
    sContext = casAllContexts{i};
    
    mModelFuncMap(sContext) = i_getSlFunctionsFromModelContext(sContext);
    mModelCallerMap(sContext) = i_getCallersFromModelContext(sContext);
end

astSlFunctions = mModelFuncMap(astTree(1).sPath);
astCallers = mModelCallerMap(astTree(1).sPath);
for i = 2:numel(astTree)
    sContextPath = astTree(i).sPath;
    sContextVirtualPath = astTree(i).sVirtualPath;
    
    astSlFunctions = ...
        [astSlFunctions, i_adaptVirtualPaths(mModelFuncMap(sContextPath), sContextPath, sContextVirtualPath)]; %#ok<AGROW>
    astCallers = ...
        [astCallers, i_adaptVirtualPaths(mModelCallerMap(sContextPath), sContextPath, sContextVirtualPath)]; %#ok<AGROW>
end
if (isempty(astSlFunctions) || isempty(astCallers))
    return;
end

astSlFunctions = i_orderForOptimalSearch(astSlFunctions);
for i = 1:numel(astCallers)
    stCaller = astCallers(i);    
    
    [sQualifier, sRawCallerPrototype] = i_splitQualifierFromPrototype(stCaller.sPrototype);
    bHasQualifier = ~isempty(sQualifier);
    
    for k = 1:numel(astSlFunctions)
        stFunc = astSlFunctions(k);
        
        % if Prototypes are not matching, caller and function cannot be related --> skip to the next one
        if ~strcmp(stFunc.sPrototype, sRawCallerPrototype)
            continue;
        end
        
        % from here on, we have the same prototype; however, we need to find the SL function that is relevant for the
        % caller <--> SL Functions can ...
        % 1) ... shadow each other
        % OR
        % 2) ... be referred to via Qualifier
        %
        if bHasQualifier
            % a caller with a qualifier is *always* referring to a 'scoped' function --> skip the global ones
            if strcmp(stFunc.sVisibility, 'scoped')
                [bIsQualified, sContextPath] = i_getContextRootPathForSlFunction(stFunc.sVirtualPath, sQualifier);
                if bIsQualified && i_isPathSameOrAncestor(sContextPath, stCaller.sVirtualPath)
                    astSlFunctions(k).astCallers = i_extendArray(astSlFunctions(k).astCallers, stCaller);
                    
                    % found the right SL-Function for the caller; break out of the inner loop and continue with next caller
                    break;
                end
            end
        else
            if strcmp(stFunc.sVisibility, 'scoped')
                [~, sContextPath] = i_getContextRootPathForSlFunction(stFunc.sVirtualPath);
                if i_isPathSameOrAncestor(sContextPath, stCaller.sVirtualPath)
                    astSlFunctions(k).astCallers = i_extendArray(astSlFunctions(k).astCallers, stCaller);
                    
                    % found the right SL-Function for the caller; break out of the inner loop and continue with next caller
                    break;
                end
            else
                % after checking all the scoped SL-Function; we have now found a global function that matches via
                % Prototype --> this means that the caller is referring to this global function
                astSlFunctions(k).astCallers = i_extendArray(astSlFunctions(k).astCallers, stCaller);
                
                % found the right SL-Function for the caller; break out of the inner loop and continue with next caller
                break;
            end
        end
    end
end
end


%%
function [bIsQualified, sContextPath] = i_getContextRootPathForSlFunction(sSlFunctionPath, sQualifier)
sParentPath = fileparts(sSlFunctionPath);
if (nargin > 1)
    % in case we have a qualifier, the qualifier needs to be the name of the subsystem the SL-Function is part of
    % otherwise, the SL-Function is not qualified
    [sParentParentPath, sQualifierCandidate] = fileparts(sParentPath);
    bIsQualified = strcmp(sQualifier, sQualifierCandidate);
    if bIsQualified
        sContextPath = sParentParentPath;
    else
        sContextPath = '';
    end
else
    % in case we don't have a qualifier, the function is automatically qualified and the context path is simply the
    % parent of the the SL-Function
    bIsQualified = true;
    sContextPath = sParentPath;
end
end


%%
function bIsSameOrAncestor = i_isPathSameOrAncestor(sPotentialAncestorPath, sPath)
nAncestorLen = length(sPotentialAncestorPath);
nPathLen = length(sPath); 

bIsSameOrAncestor = ...
    strcmp(sPotentialAncestorPath, sPath) || ...
    ((nPathLen > nAncestorLen) && strncmp([sPotentialAncestorPath, '/'], sPath, nAncestorLen + 1));
end


%%
function astArray = i_extendArray(astArray, stElem)
if isempty(astArray)
    astArray = stElem;
else
    astArray = [astArray, stElem];
end
end


%%
% example for split: 'y = my_qual.func_name(u)' --> ['my_qual', 'y = func_name(u)']  
function [sQualifier, sRawPrototype] = i_splitQualifierFromPrototype(sPrototype)
casFound = regexp(sPrototype, '(\w+)[.]', 'tokens', 'once');
if isempty(casFound)
    sQualifier = '';
    sRawPrototype = sPrototype;
else
    sQualifier = casFound{1};
    sRawPrototype = regexprep(sPrototype, '\w+[.]', '');
end
end


%%
function astSlFunctions = i_orderForOptimalSearch(astSlFunctions)
abIsGlobal = strcmp('global', {astSlFunctions.sVisibility});

astGlobalFuncs = astSlFunctions(abIsGlobal);
astOrderedScopedFuncs = i_orderFromLongestToShortestVirtualPath(astSlFunctions(~abIsGlobal));
astSlFunctions = [astOrderedScopedFuncs, astGlobalFuncs];
end


%%
function astSlFunctions = i_orderFromLongestToShortestVirtualPath(astSlFunctions)
if ~isempty(astSlFunctions)
    aiLength = cellfun(@length, {astSlFunctions.sVirtualPath});
    [~, aiSortedIdx] = sort(aiLength, 'descend');
    astSlFunctions = astSlFunctions(aiSortedIdx);
end
end


%%
function astData = i_adaptVirtualPaths(astData, sRefModel, sRefBlock)
sRegExp = ['^', regexptranslate('escape', sRefModel)];
astData = arrayfun(@(stData) i_regexpReplaceVirtualPathsForBlock(stData, sRegExp, sRefBlock), astData);
end


%%
function stBlock = i_regexpReplaceVirtualPathsForBlock(stBlock, sRegExp, sReplacement)
stBlock.sVirtualPath = regexprep(stBlock.sVirtualPath, sRegExp, sReplacement, 'once');
end


%%
function astSlFunctions = i_getSlFunctionsFromModelContext(xModelContext)
hModelContext = get_param(xModelContext, 'Handle');

ahSlFuncTriggerPorts = ep_find_system(hModelContext, ...
    'LookUnderMasks',     'all', ...
    'FollowLinks',        'on',  ...
    'BlockType',          'TriggerPort',     ...
    'isSimulinkFunction', 'on');

astSlFunctions = reshape(arrayfun(@i_getSlFunctionInfo, ahSlFuncTriggerPorts), 1, []);
end


%%
function stSlFunc = i_getSlFunctionInfo(hSlFuncTriggerPort)
sSlFuncPath = get_param(hSlFuncTriggerPort, 'Parent');

stSlFunc = struct( ...
    'sFunctionName',      get_param(hSlFuncTriggerPort, 'FunctionName'), ...
    'sVisibility',        i_getVisibility(hSlFuncTriggerPort),   ...
    'sPath',              sSlFuncPath, ...
    'sVirtualPath',       sSlFuncPath, ...
    'sPrototype',         get_param(hSlFuncTriggerPort, 'FunctionPrototype'), ...
    'nInports',           [],   ... 
    'nOutports',          [],   ...
    'astCallers',         []);

[stSlFunc.nInports, stSlFunc.nOutports] = i_getNumberOfPorts(sSlFuncPath);
end


%%
function sVisibility = i_getVisibility(hSlFuncTriggerPort)
if verLessThan('matlab', '9.3')
    sVisibility = 'global';
else
    sVisibility = get_param(hSlFuncTriggerPort, 'FunctionVisibility');
end
end


%%
function [nIn, nOut] = i_getNumberOfPorts(xSlFunction)
stPorts = get_param(xSlFunction, 'PortHandles');
nIn  = numel(stPorts.Inport);
nOut = numel(stPorts.Outport);
end


%%
function astCallers = i_getCallersFromModelContext(xModelContext)
hModelContext = get_param(xModelContext, 'Handle');

ahCallers = ep_find_system(hModelContext, ...
    'LookUnderMasks',     'all', ...
    'FollowLinks',        'on',  ...
    'BlockType',          'FunctionCaller');

astCallers = reshape(arrayfun(@i_getCallerInfo, ahCallers), 1, []);
end


%%
function stCaller = i_getCallerInfo(xCallerBlock)
sPath = getfullname(xCallerBlock);
stCaller = struct( ...
    'sPrototype',   get_param(xCallerBlock, 'FunctionPrototype'), ...
    'sPath',        sPath, ...
    'sVirtualPath', sPath);
end
