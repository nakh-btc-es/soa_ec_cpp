function stInterface = atgcv_m01_function_interface_get(stEnv, hFunction)
% Get interface of function in DD.
%
% function stInterface = atgcv_m01_function_interface_get(stEnv, hFunction)
%
%   INPUT           DESCRIPTION
%     stEnv         (struct)      error environment
%     hFunction     (handle)      DD handle of Function/FunctionInstance
%
%   OUTPUT          DESCRIPTION
%     stInterface   (struct)      info data for function
%       .xxx
%
%   REMARKS
%
%   <et_copyright>


%% default output
stInterface = struct( ...
    'astFormalArgs',      [], ...
    'astArgs',            [], ...
    'astVars',            [], ...
    'casInconsistencies', {{}});


%%
% early return for empty function
if isempty(hFunction)
    return;
end

% get Function/FunctionInstance
[hFunction, hInstance, hInstanceSub] = i_getFunctionInstance(stEnv, hFunction);

% formal/actual arguments
stInterface.astFormalArgs = i_getFormalArgs(stEnv, hFunction);
stInterface.astArgs = i_getActualArguments(stEnv, hInstance);

try
    i_assertArgumentsConsistent(stInterface.astArgs, stInterface.astFormalArgs)
    
catch oEx
    stInterface.casInconsistencies{end + 1} = oEx.message;
    return;
end

% interface vars
try
    stInterface.astVars = i_getInterfaceVariables(stEnv, ...
        hFunction, ...
        hInstance, ...
        stInterface.astFormalArgs);
    
catch oEx
    stInterface.casInconsistencies{end + 1} = oEx.message;
    return;
end

% combining interface vars and arguments
try
    [stInterface.astVars, stInterface.astArgs] = i_fillVariablesAndArgs(stEnv, ...
        stInterface.astVars, ...
        stInterface.astArgs, ...
        stInterface.astFormalArgs, ...
        hInstanceSub);
    
catch oEx
    stInterface.casInconsistencies{end + 1} = oEx.message;
end
end


%%
function i_assertArgumentsConsistent(astArgs, astFormalArgs)
if (numel(astArgs) ~= numel(astFormalArgs))
    error('MODEL_ANA:FUNC_INTERFACE:INCONSISTENCIES', ...
        'Found inconsistent information about the formal and the actual arguments of the step function.');
end
end


%%
function [astVars, astArgs] = i_fillVariablesAndArgs(stEnv, astVars, astArgs, astFormalArgs, hInstanceSub)
aiRefVars = [];
if ~isempty(astVars)
    aiRefVars = [astVars(:).iArgIdx];
end

nArgs = numel(astFormalArgs);

% expression and definition
for i = 1:nArgs
    stFormalArg = astFormalArgs(i);
    stArg       = astArgs(i);
    astUsedVars = astVars((i == aiRefVars)); % all interface vars referencing argument index i
    
    % if we have a return value, we have to define var ourselves but _no_ expression; always assume we have usage='val'
    if strcmpi(stFormalArg.sKind, 'RETURN_VALUE')
        [sBaseType, sUserType] = i_getVarType(stEnv, stFormalArg.hVar);
        sVarName  = sprintf('__osc_fcn_parameter_%d_', i);
        
        astArgs(i).sVarName     = sVarName;
        astArgs(i).sTypeName    = sBaseType;
        astArgs(i).sUserType    = sUserType;
        astArgs(i).sUsage       = 'val';
        astArgs(i).sDeclaration = sprintf('%s %s;', sBaseType, sVarName);
        
        continue;
    end
    
    % If we have a call-by-value or call-by-reference on a primitive type AND
    % the variable can safely be replaced, avoid using the original variable as argument.
    % This can lead to problems of initializing multiple function parameters with the same argument
    % variables (see BTS/25740 and BTS/34956)
    bUsingPrimitive = ~stFormalArg.bIsStruct;
    bIsInputOrOutput = any(strcmpi(stFormalArg.sKind, {'FORMAL_ARGIN', 'FORMAL_ARGOUT'}));
    bReplaceVars = ...
        bUsingPrimitive ...
        && bIsInputOrOutput ...
        && i_areAllInterfaceVariablesReplaceable(stEnv, astUsedVars, hInstanceSub);
    
    % if we do not have an expression as an input and we have the
    % variable of the actual argument, we can try to use the original input variable of function
    % however, try not to use something like a.b->c[3].x
    % this means do not accept Components and check for hRoot == hVar
    if (isempty(regexp(stArg.sKind, 'EXPRESSION$', 'once')) && ...
            ~isempty(stArg.hVar) && ...
            i_isNotComponent(stEnv, stArg.hVar) && ...
            ~bReplaceVars)
        [bIsModuleValid, sModuleName] = i_checkModule(stEnv, stArg.hVar);
        
        if (bIsModuleValid && i_isVarGlobal(stEnv, stArg.hVar))
            sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stArg.hVar, 'name');
            if ~isvarname(sVarName)
                % note: variable names in DD can have artificial extensions, i.e. xxx(#2)
                % ---> for such a case, refer to the argument name (TODO: maybe always do that?)
                sVarName = stArg.sArgName;
            end
            astArgs(i).sModule = sModuleName;
            
            [sBaseType, sUserType] = i_getVarType(stEnv, stArg.hVar);
            sWidth = i_getWidthArrayExtension(stEnv, stArg.hVar);
            
            astArgs(i).sVarName  = sVarName;
            astArgs(i).sTypeName = sBaseType;
            astArgs(i).sUserType = sUserType;
            
            bIsPointer = ~isempty(regexp(stArg.sKind, 'REFERENCE$', 'once'));
            if bIsPointer
                astArgs(i).sUsage = 'ref';
            else
                astArgs(i).sUsage = 'val';
            end
            
            if (isempty(sWidth) && bIsPointer)
                astArgs(i).sExpression = sprintf('&(%s)', sVarName);
            else
                astArgs(i).sExpression = sVarName;
            end
            
            % ! no declaration needed here !
            continue;
        end
    end
    
    %%------------------------------------------------------
    % from here on we have an expression or a local variable as an input
    % in both cases we have to define new input var ourselves
    
    % return value was the only arg that has no corresponding interface
    % variable! now find all variables referencing this arg
    
    % get representative var
    hInterfaceVar = stFormalArg.hVar;
    [sBaseType, sUserType]  = i_getVarType(stEnv, hInterfaceVar);
    
    % 1) if reference var is a pointer, we create the global var and provide a pointer in the function interface
    bIsPointer = i_isPointerType(stEnv, hInterfaceVar);
    
    % 2) if reference var is not a pointer, the argument may be provided as a pointer in the function interface
    if ~bIsPointer
        bIsPointer = ~isempty(regexp(stArg.sKind, 'REFERENCE$', 'once'));
    end
    
    % check if we can keep up consistency
    casIncons = i_checkInterfaceConsistency(stEnv, astUsedVars, hInstanceSub);
    if ~isempty(casIncons)
        sAllIncons = sprintf('%s\n', casIncons{:});
        sAllIncons(end) = []; % remove last linefeed
        error('MODEL_ANA:FUNC_INTERFACE:INCONSISTENCIES', '%s', sAllIncons);
    end
    
    sVarName = sprintf('__osc_fcn_parameter_%d_', i);
    astArgs(i).sVarName  = sVarName;
    astArgs(i).sTypeName = sBaseType;
    astArgs(i).sUserType = sUserType;
    if bIsPointer
        astArgs(i).sUsage = 'ref';
    else
        astArgs(i).sUsage = 'val';
    end
    
    [sWidth, aiWidth] = i_getWidthArrayExtension(stEnv, hInterfaceVar);
    
    % PROM-17057: TL versions before TL4.0 provide a wrong width info for the actual argument
    % --> replace it with the width info for the interface variable
    astArgs(i).aiWidth = aiWidth;
    
    if (isempty(sWidth) && bIsPointer)
        astArgs(i).sExpression = sprintf('&(%s)', sVarName);
    else
        astArgs(i).sExpression = sprintf('%s', sVarName);
    end
    
    astArgs(i).sDeclaration = sprintf('%s %s%s;', sBaseType, sVarName, sWidth);
end

% fill additional variable info
for i = 1:numel(astVars)
    if ((astVars(i).iArgIdx > 0) && ~astVars(i).bIsReuseComp)
        astVars(i).sName = astArgs(astVars(i).iArgIdx).sVarName;
    else
        if ~isempty(astVars(i).hVarRef)
            hRootVarRef = i_getRootVar(stEnv, astVars(i).hVarRef);
            astVars(i).sName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hRootVarRef, 'name');
        end
    end
end
end


%%
function astVars = i_getInterfaceVariables(stEnv, hFunction, hInstance, astFormalArgs)
stTemplateVar = struct( ...
    'sName',        '', ...
    'sOrigName',    '', ...
    'sOrigRootName','', ...
    'iArgIdx',      [], ...
    'sKind',        [], ...
    'hVar',         [], ...
    'hRootVar',     [], ...
    'hVarRef',      [], ...
    'ahBlockVars',  [], ...
    'bIsReuseComp', false);

[sFirstInstanceRoot, sThisRoot] = i_getInstanceRoots(stEnv, hInstance);


hInterface = atgcv_mxx_dsdd(stEnv, 'GetInterfaceVariables', hFunction);
ahVars = i_getInterfaceVars(stEnv, hInterface);

nVars        = length(ahVars);
astVars      = repmat(stTemplateVar, nVars, 1);
ahFormalArgs = [astFormalArgs(:).hArg];
for i = 1:nVars
    hIfVar     = ahVars(i);
    hIfRootVar = i_getRootVar(stEnv, hIfVar);
    
    astVars(i).hVar          = hIfVar;
    astVars(i).hRootVar      = hIfRootVar;
    astVars(i).sKind         = atgcv_mxx_dsdd(stEnv, 'GetKind', hIfVar);
    astVars(i).aiElements    = i_getInterfaceVarElements(stEnv, hIfVar);
    
    astVars(i).sOrigName = i_getCleanVarName(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hIfVar, 'Name'));
    astVars(i).sOrigRootName = i_getCleanVarName(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hIfRootVar, 'Name'));
    
    % match with corresponding interface arguments
    iArgIdx = find(hIfRootVar == ahFormalArgs);
    if isempty(iArgIdx)
        % first assume we have a global variable
        % Re-check later
        iArgIdx = 0;  % index = 0 for global pass_through interface
    end
    
    if dsdd('Exist', hIfVar, 'property', {'name', 'BlockVariable'})
        astVars(i).ahBlockVars = i_getBlockVars(stEnv, hIfVar, sFirstInstanceRoot, sThisRoot);
    end
    if strcmpi(astVars(i).sKind, 'RETURN_VALUE')
        astVars(i).hVarRef = hIfVar;
        if dsdd('Exist', hIfVar, 'property', 'Variable')
            astVars(i).hVarRef = atgcv_mxx_dsdd(stEnv, 'GetVariable', hIfVar);
        end
    else
        hVarRef = [];
        if dsdd('Exist', hIfVar, 'property', 'Variable')
            hVarRef = atgcv_mxx_dsdd(stEnv, 'GetVariable', hIfVar);
        end
        if (isempty(hVarRef) && ~isempty(astVars(i).ahBlockVars))
            if dsdd('Exist', astVars(i).ahBlockVars, 'property', 'VariableRef')
                hBlockVarRef = atgcv_mxx_dsdd(stEnv, 'GetVariableRef', astVars(i).ahBlockVars(1));
                hVarRef = hBlockVarRef;
            end
        end
        astVars(i).hVarRef = hVarRef;
        
        if ~isempty(hVarRef)
            % check if we have a local variable here
            if (iArgIdx == 0)
                if ~i_isVarGlobal(stEnv, hVarRef)
                    iArgIdx = -1; % index = -1 for local variable
                end
            else
                % if a structure-component is passed through the interface of
                % the function, check that the variable reference is consistent
                % --> othwerwise may be an Auxiliary Variable (see BTS/28691)
                if (hIfVar ~= hIfRootVar)
                    if ~i_isStructComponent(stEnv, hVarRef)
                        iArgIdx = -1; % dummy component variable
                    end
                end
            end
        else
            iArgIdx = -1; % dummy component variable
        end
    end
    astVars(i).iArgIdx = iArgIdx;
    
    if (isempty(astVars(i).ahBlockVars) && (iArgIdx > 0) && (hIfVar ~= hIfRootVar))
        % special case: interface_vars without corresponding block_var
        % --> maybe indicating components of a reuse_struct (pISV)
        % <--> shared subsystems
        % strategy: we have to use the actual arguments for retrieving info
        sVarPath  = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hIfVar, 'path');
        sRootPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hIfRootVar, 'path');
        
        astVars(i).bIsReuseComp = true;
        
        stArg = astArgs(iArgIdx);
        
        % workaround is only possible if we have any Variable that was used as actual Argument
        if ~isempty(stArg.hVar)
            sAccessPath = sVarPath(length(sRootPath)+2:end);
            sTargetVar  = [atgcv_mxx_dsdd(stEnv, 'GetAttribute', stArg.hVar, 'path'), '/', sAccessPath];
            if ~dsdd('Exist', sTargetVar)
                % if heuristic did not work, try one more indirection
                aiComp = regexp(sAccessPath, 'Components/');
                if (length(aiComp) < 2)
                    sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hIfVar, 'name');
                    error('MODEL_ANA:FUNC_INTERFACE:INCONSISTENCIES', 'Cannot find block for variable "%s".', sVarName);
                end
                sAccessPathDest = sAccessPath(1:aiComp(2)-2);
                sAccessPath(1:aiComp(2)-1) = [];
                
                stArg = astArgs(iArgIdx);
                sCompPointerVar = [atgcv_mxx_dsdd(stEnv, 'GetAttribute', stArg.hVar, 'path'), '/', sAccessPathDest];
                hDestVar = atgcv_mxx_dsdd(stEnv, 'GetPointerDest', sCompPointerVar, -1);
                
                sTargetVar = [atgcv_mxx_dsdd(stEnv, 'GetAttribute', hDestVar, 'path'), '/', sAccessPath];
            end
            
            hVarRef = atgcv_mxx_dsdd(stEnv, 'GetAttribute', sTargetVar, 'hDDObject');
            astVars(i).hVarRef = hVarRef;
            
            % try to get block_var from var (include also the SL blocks
            % <--> needed for TL_Ports)
            if ~isempty(hVarRef)
                bIncludeSl = true;
                casBlockPaths = atgcv_m01_origin_srcref_get(stEnv, hVarRef, bIncludeSl);
                nBlockRefs = length(casBlockPaths);
                if (nBlockRefs > 1)
                    abSelect = false(size(casBlockPaths));
                    for k = 1:nBlockRefs
                        % select only the block vars lying in our subsystem
                        if ~isempty(regexpi(casBlockPaths{k}, regexptranslate('escape', sThisRoot), 'once'))
                            abSelect(k) = true;
                        end
                    end
                    if any(abSelect)
                        casBlockPaths = casBlockPaths(abSelect);
                    end
                end
                nBlockRefs = length(casBlockPaths);
                
                astVars(i).ahBlockVars = zeros(1, nBlockRefs);
                for j = 1:nBlockRefs
                    astVars(i).ahBlockVars(j) = atgcv_mxx_dsdd(stEnv, 'GetAttribute', casBlockPaths{j}, 'hDDObject');
                end
            end
        end
    end
end
end



%%
function astArgs = i_getActualArguments(stEnv, hInstance)
stTemplateArg = struct( ...
    'sKind',        '',  ...
    'hArg',         [],  ...
    'sArgName',     '',  ...
    'hVar',         [],  ...
    'sVarName',     '',  ...
    'sTypeName',    '',  ...
    'aiWidth',      [],  ...
    'sUserType',    '',  ...
    'sUsage',       '',  ...
    'sExpression',  '',  ...
    'sDeclaration', '',  ...
    'sModule',      '');

hArguments   = atgcv_mxx_dsdd(stEnv, 'GetActualArguments', hInstance);
ahActualArgs = atgcv_mxx_dsdd(stEnv, 'GetChildren', hArguments);
nArgs = length(ahActualArgs);

astArgs = repmat(stTemplateArg, nArgs, 1);
for i = 1:nArgs
    hArg = ahActualArgs(i);
    astArgs(i).hArg  = hArg;
    astArgs(i).sArgName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hArg, 'Name');
    astArgs(i).sKind = atgcv_mxx_dsdd(stEnv, 'GetKind', hArg);
    if dsdd('Exist', hArg, 'property', {'name', 'Variable'})
        astArgs(i).hVar = atgcv_mxx_dsdd(stEnv, 'GetVariable', hArg);
        astArgs(i).aiWidth = i_getVarWidth(stEnv, astArgs(i).hVar);
    end
end
end



%%
% Check if after replacing some argument/expression to the function the
% interface is still consistent, i.e. is the function still stimulated with
% consistent values by some harness.
% If not: return an inconsistency message describing the Problem.
%
function casInconsistencies = i_checkInterfaceConsistency(stEnv, astIfVars, hInstanceSub)
casInconsistencies = {};
nVars = length(astIfVars);
for j = 1:nVars
    stVar = astIfVars(j);
    
    % check if input can be safely replaced with a newly created variable
    bIsReplaceable = i_isInterfaceVariableReplaceable(stEnv, stVar, hInstanceSub);
    if ~bIsReplaceable
        sName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stVar.hVar, 'name');
        if ~isempty(stVar.ahBlockVars)
            sBlockPath = dsdd_get_block_path(stVar.ahBlockVars(1));
            sText = sprintf('Cannot determine value for interface variable "%s" corresponding to block "%s".', ...
                sName, sBlockPath);
        else
            if (stVar.hVar ~= stVar.hRootVar)
                sRootVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', stVar.hRootVar, 'name');
                sText = sprintf('Cannot determine value for component "%s" of interface variable "%s".', ...
                    sName, sRootVar);
            else
                sText = sprintf('Cannot determine value for interface variable "%s".', sName);
            end
        end
        casInconsistencies{end + 1} = sText; %#ok<AGROW>
    end
end
end


%%
function bAllReplaceable = i_areAllInterfaceVariablesReplaceable(stEnv, astVars, hInstanceSub)
bAllReplaceable = true;
for i = 1:length(astVars)
    bAllReplaceable = bAllReplaceable && i_isInterfaceVariableReplaceable(stEnv, astVars(i), hInstanceSub);
end
end


%%
% check if the original argument variable can be replaced by some other global
% variable that is newly created by some external harness function
function bIsReplaceable = i_isInterfaceVariableReplaceable(stEnv, stVar, hInstanceSub)

% if there is a Variable reference but no block reference, the variable can be replaced
% AlHo TODO: why? check this out ...
if (~isempty(stVar.hVarRef) && isempty(stVar.ahBlockVars))
    bIsReplaceable = true;
    return;
end

bIsReplaceable = false;
if isempty(regexpi(stVar.sKind, 'ARGIN', 'once'))
    % variable is *not* an input argument to the function but an output --> can be replaced, since not carrying info
    bIsReplaceable = true;
    
else
    % variable is an input argument to the step function
    % --> can only be replaced, if it's also set inside the harness
    % --> this is only true for Inport variables
    for k = 1:length(stVar.ahBlockVars)
        hBlock = i_getBlock(stEnv, stVar.ahBlockVars(k));
        sBlockType = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock);
        
        % accept all kinds of inports because the MIL/SIL harness has them under control (i.e. sets their values)
        % Note: check that the inport block is actually belonging to the instance subsystem
        if any(strcmp(sBlockType, {'TL_Inport', 'TL_BusInport'}))
            bIsReplaceable = (i_getParentSub(stEnv, hBlock) == hInstanceSub);
            if bIsReplaceable
                break;
            end
        end
        if strcmp(sBlockType, 'Stateflow')
            bIsReplaceable = (hBlock == hInstanceSub);
            if bIsReplaceable
                break;
            end
        end
    end
end
end


%%
function hSub = i_getParentSub(stEnv, hBlock)
hSub = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlock, 'hDDParent');
end


%%
function [sWidth, aiWidth] = i_getWidthArrayExtension(stEnv, hVar)
aiWidth = i_getVarWidth(stEnv, hVar);
if isempty(aiWidth)
    sWidth = '';
elseif (length(aiWidth) == 1)
    nCodeWidth1 = aiWidth(1);
    sWidth = sprintf('[%i]', nCodeWidth1);
else
    nCodeWidth1 = aiWidth(1);
    nCodeWidth2 = aiWidth(2);
    sWidth = sprintf('[%i][%i]', nCodeWidth1, nCodeWidth2);
end
end


%%
function aiWidth = i_getVarWidth(stEnv, hVar)
if dsdd('Exist', hVar, 'property', {'name', 'Width'})
    aiWidth = atgcv_mxx_dsdd(stEnv, 'GetWidth', hVar);
else
    aiWidth = [];
end
end


%%
function bIsNotComponent = i_isNotComponent(stEnv, hVar)
bIsNotComponent = (hVar == i_getRootVar(stEnv, hVar));
end


%%
function [hFunction, hInstance, hInstanceSub] = i_getFunctionInstance(stEnv, hFunction)
sKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFunction, 'objectKind');
if strcmpi(sKind, 'FunctionInstance')
    hInstance = hFunction;
    hFunction = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hInstance, 'hDDParent');
else
    ahInstances = atgcv_mxx_dsdd(stEnv, 'GetInstanceData', hFunction);
    
    if isempty(ahInstances)
        % AH TODO: replace error by messenger entry
        error('ATGCV:MODEL_ANA:INTERNAL_ERROR', 'No instance found for function "%s".', ...
            atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFunction, 'Name'));
    end
    hInstance = ahInstances(1); % use the first instance
end

hInstanceSub = -1; % use an *invalid* value as default
if dsdd('Exist', hInstance, 'property', 'BlockGroupRef') % for Subsystems
    hInstanceSub = atgcv_mxx_dsdd(stEnv, 'GetBlockGroupRefTarget', hInstance, 0);
    
elseif dsdd('Exist', hInstance, 'property', 'BlockRef') % for SF-Charts
    hInstanceSub = atgcv_mxx_dsdd(stEnv, 'GetBlockRefTarget', hInstance, 0);
end
end


%%
% essentially for struct_vars in interface
function hRootVar = i_getRootVar(stEnv, hVar)
sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
sRootPath = regexprep(sPath, '(.*Variables/.*?)(/Components.*)', '$1');
hRootVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', sRootPath, 'hDDObject');
end


%%
function bIsPointer = i_isPointerType(stEnv, hVar)
hType      = atgcv_mxx_dsdd(stEnv, 'GetType', hVar);
sBaseType  = atgcv_mxx_dsdd(stEnv, 'GetBaseType', hType);
bIsPointer = strcmpi(sBaseType, 'Pointer');
end


%%
function [bIsPointer, bIsStruct] = i_getVarUsage(stEnv, hVar)
hType      = atgcv_mxx_dsdd(stEnv, 'GetType', hVar);
sBaseType  = atgcv_mxx_dsdd(stEnv, 'GetBaseType', hType);
bIsPointer = strcmpi(sBaseType, 'Pointer');

if (nargout < 2)
    return;
end

if bIsPointer
    hType = atgcv_mxx_dsdd(stEnv, 'GetPointerDestType', hType);
    sBaseType = atgcv_mxx_dsdd(stEnv, 'GetBaseType', hType);
    bIsPointer = true;
end
bIsStruct = strcmpi(sBaseType, 'Struct');
end


%%
function [sBaseType, sUserType] = i_getVarType(stEnv, hVar)
stInfo = atgcv_m01_variable_type_get(stEnv, hVar);
if ~isempty(stInfo.sStructTag)
    sBaseType = stInfo.sStructTag;
    sUserType = stInfo.sStructTag;
else
    if strcmpi(stInfo.sBase, 'Pointer')
        sBaseType = stInfo.sBaseDest;
        sUserType = stInfo.sUserDest;
    else
        sBaseType = stInfo.sBase;
        sUserType = stInfo.sUser;
    end
    if strcmpi(sBaseType, 'Struct')
        sBaseType = sUserType;
    end
end
end


%%
function ahVars = i_getInterfaceVars(stEnv, hInterface)
ahVars = i_findObjectKind(stEnv, hInterface, 'InterfaceVariable');
ahVars = i_filterOutKind(stEnv, 'FORMAL_ARG', ahVars);
end


%%
function ahVars = i_filterOutKind(stEnv, sKind, ahVars)
abSelect = arrayfun(@(x)(~strcmpi(sKind, atgcv_mxx_dsdd(stEnv, 'GetKind', x))), ahVars);
ahVars = ahVars(abSelect);
end


%%
function ahObjs = i_findObjectKind(stEnv, hRootObj, sObjKind)
ahObjs = atgcv_mxx_dsdd(stEnv, 'Find', hRootObj, 'objectKind', sObjKind);
end


%%
function [bIsModuleValid, sModuleName] = i_checkModule(stEnv, hVar)
% init values
bIsModuleValid = false;
sModuleName    = '';

sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
iFind = regexp(sPath, '/Variables/', 'once');
if isempty(iFind)
    % Variable handle is not inside a Module (maybe in Pool area of DD)
    return;
end

sModulePath = sPath(1:iFind-1);
bIsModuleValid = atgcv_m01_module_check(stEnv, sModulePath);
if ~bIsModuleValid
    return;
end

% if we are here, module is valid and we have to look for its C-code file name
hModuleInfo = atgcv_mxx_dsdd(stEnv, 'GetModuleInfo', sModulePath);
ahFileInfo  = atgcv_mxx_dsdd(stEnv, 'Find', hModuleInfo, ...
    'objectKind', 'FileInfo', ...
    'property',   {'name', 'FileType'});
nFiles = length(ahFileInfo);
for i = 1:nFiles
    hFileInfo = ahFileInfo(i);
    sFileKind = atgcv_mxx_dsdd(stEnv, 'GetFileKind', hFileInfo);
    if strcmpi(sFileKind, 'SourceFile')
        sModuleName = atgcv_mxx_dsdd(stEnv, 'GetFileName', hFileInfo);
        break;
    end
end
end


%%
function aiElements = i_getInterfaceVarElements(stEnv, hInterfaceVar)
if dsdd('Exist', hInterfaceVar, 'property', {'name', 'VariableElements'})
    aiElements = atgcv_mxx_dsdd(stEnv, 'GetVariableElements', hInterfaceVar, -1);
    
elseif dsdd('Exist', hInterfaceVar, 'property', {'name', 'Element'})
    aiElements = atgcv_mxx_dsdd(stEnv, 'GetElement', hInterfaceVar);
    
else
    aiElements = [];
end
end


%%
function [sFirstInstanceRoot, sThisRoot] = i_getInstanceRoots(stEnv, hInstance)
hParent = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hInstance, 'hDDParent');
hFirstInstance = atgcv_mxx_dsdd(stEnv, 'Find', hParent, ...
    'objectKind', 'FunctionInstance', ...
    'RegExp',     'InstanceData$');
if dsdd('Exist', hFirstInstance, 'property', {'name', 'BlockGroupRef'})
    % for SUBSYSTEM
    hFirstRef = atgcv_mxx_dsdd(stEnv, 'GetBlockGroupRef', hFirstInstance, 0);
    hThisRef  = atgcv_mxx_dsdd(stEnv, 'GetBlockGroupRef', hInstance, 0);
elseif dsdd('Exist', hFirstInstance, 'property', {'name', 'BlockRef'})
    % for STATEFLOW
    hFirstRef = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', hFirstInstance, 0);
    hThisRef  = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', hInstance, 0);
else
    hFirstRef = [];
    hThisRef  = [];
end
if isempty(hFirstRef)
    sFirstInstanceRoot = '';
else
    sFirstInstanceRoot = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hFirstRef, 'path');
end
if isempty(hThisRef)
    sThisRoot = '';
else
    sThisRoot = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hThisRef, 'path');
end
end


%%
function astFormalArgs = i_getFormalArgs(stEnv, hFunction)
stTemplateFormalArg = struct( ...
    'hArg',         [],  ...
    'sArgName',     '',  ...
    'nPos',         [],  ...
    'sKind',        '',  ...
    'hVar',         [],  ...
    'sVarName',     '',  ...
    'sTypeName',    '',  ...
    'aiWidth',      [],  ...
    'bIsStruct',    [],  ...
    'bIsPointer',   [],  ...
    'bIsConst',     []);

hFormal = atgcv_mxx_dsdd(stEnv, 'GetFormalArguments', hFunction);
if dsdd('Exist', hFormal, 'property', {'name', 'FormalArgument'})
    casProp = atgcv_mxx_dsdd(stEnv, 'GetPropertyNames', hFormal);
    
    nFormalInputs   = length(casProp);
    ahFormalInputs  = zeros(1, nFormalInputs);
    for i = 1:nFormalInputs
        ahFormalInputs(i) = atgcv_mxx_dsdd(stEnv, 'Get', hFormal, {'name', casProp{i}});
    end
else
    ahFormalInputs = [];
end
ahFormalArgs = ahFormalInputs;

% check if there is a return value
hInterface = atgcv_mxx_dsdd(stEnv, 'GetInterfaceVariables', hFunction);
hFormalOutput = atgcv_mxx_dsdd(stEnv, 'Find', hInterface, ...
    'objectKind', 'InterfaceVariable', ...
    'property', {'name', 'Kind', 'value', 'RETURN_VALUE'});
ahFormalArgs = [ahFormalArgs, hFormalOutput];

% now get info for all the formal arguments of function
nFormalArg = length(ahFormalArgs);
astFormalArgs = repmat(stTemplateFormalArg, nFormalArg, 1);
for i = 1:nFormalArg
    hArg = ahFormalArgs(i);
    
    astFormalArgs(i).hArg  = hArg;
    astFormalArgs(i).sArgName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hArg, 'Name');
    astFormalArgs(i).sKind = atgcv_mxx_dsdd(stEnv, 'GetKind', hArg);
    
    % special case: RETURN_VALUE:  has no extra variable
    if strcmpi(astFormalArgs(i).sKind, 'RETURN_VALUE')
        if dsdd('Exist', hArg, 'property', 'Type')
            astFormalArgs(i).hVar = hArg; % has no variable name
        else
            astFormalArgs(i).hVar = atgcv_mxx_dsdd(stEnv, 'GetVariable', hArg);
        end
        astFormalArgs(i).nPos = -1;
    else
        astFormalArgs(i).hVar = atgcv_mxx_dsdd(stEnv, 'GetVariable', hArg);
        astFormalArgs(i).nPos = i;
    end
    astFormalArgs(i).sVarName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', astFormalArgs(i).hVar, 'Name');
    
    astFormalArgs(i).sTypeName = i_getVarType(stEnv, astFormalArgs(i).hVar);
    astFormalArgs(i).aiWidth   = i_getVarWidth(stEnv, astFormalArgs(i).hVar);
    [astFormalArgs(i).bIsPointer, astFormalArgs(i).bIsStruct] = i_getVarUsage(stEnv, astFormalArgs(i).hVar);
    
    if (astFormalArgs(i).hVar ~= astFormalArgs(i).hArg)
        astFormalArgs(i).bIsConst = i_isVarConst(stEnv, astFormalArgs(i).hVar);
    else
        % for RETURN_VALUES we assume const == false
        astFormalArgs(i).bIsConst = false;
    end
end
end


%%
function ahBlockVars = i_getBlockVars(stEnv, hIfVar, sFirstInstanceRoot, sThisRoot)
ahBlockVars = [];
if dsdd('Exist', hIfVar, 'property', {'name', 'BlockVariable'})
    hBlockVar   = atgcv_mxx_dsdd(stEnv, 'GetBlockVariable', hIfVar);
    sBlockPath  = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'path');
    sBlockPath  = strrep(sBlockPath, sFirstInstanceRoot, sThisRoot);
    ahBlockVars = atgcv_mxx_dsdd(stEnv, 'GetAttribute', sBlockPath, 'hDDObject');
end

% try to get additional block vars from reference variable and put them behind (!!) the direct block var
if (atgcv_verLessThan('TL4.0') && dsdd('Exist', hIfVar, 'property', 'Variable'))
    hVarRef = atgcv_mxx_dsdd(stEnv, 'GetVariable', hIfVar);
else
    return;
end

if dsdd('Exist', hVarRef, 'Property', {'name', 'SrcRefs'})
    casSrcRefs = atgcv_mxx_dsdd(stEnv, 'GetSrcRefs', hVarRef);
    ahAddBlockVars = [];
    sEscThisRoot = regexptranslate('escape', sThisRoot);
    for i = 1:length(casSrcRefs)
        if isempty(regexpi(casSrcRefs{i}, sEscThisRoot, 'once'))
            continue;
        end
        
        sKind = atgcv_mxx_dsdd(stEnv, 'GetAttribute', casSrcRefs{i}, 'ObjectKind');
        if strcmpi(sKind, 'BlockVariable')
            ahAddBlockVars(end + 1) = atgcv_mxx_dsdd(stEnv, 'GetAttribute', casSrcRefs{i}, 'hDDObject'); %#ok<AGROW>
        end
    end
    ahAddBlockVars = setdiff(ahAddBlockVars, ahBlockVars);
    ahBlockVars = [ahBlockVars, ahAddBlockVars];
elseif dsdd('Exist', 'BlockVariableRefs', 'Parent', hVarRef)
    nLen = length(sThisRoot);
    
    ahAddBlockVars = dsdd('GetBlockVariables', hVarRef);
    abSelect = false(size(ahBlockVars));
    for i = 1:length(ahAddBlockVars)
        sSrcRef = atgcv_mxx_dsdd(stEnv, 'GetAttribute', ahAddBlockVars(i), 'Path');
        if strncmpi(sSrcRef, sThisRoot, nLen)
            abSelect(i) = true;
        end
    end
    % use only selected additional vars and exclude vars alread in block_vars
    ahAddBlockVars = setdiff(ahAddBlockVars(abSelect), ahBlockVars);
    ahBlockVars = [ahBlockVars, ahAddBlockVars];
end
end


%%
function hBlock = i_getBlock(stEnv, hBlockVar)
while strcmpi(atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'objectKind'), 'BlockVariable')
    hBlockVar = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hBlockVar, 'hDDParent');
end
% kind should be Block here!
hBlock = hBlockVar;
end


%%
function bIsGlobal = i_isVarGlobal(stEnv, hVar)
stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
if strcmp(stInfo.sScope, 'struct_component')
    % cannot determine scope from struct_component, need the root var
    hStructVar = hVar;
    hVar = i_getRootVar(stEnv, hVar);
    if (hVar ~= hStructVar)
        stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
    else
        % RARE CASE:
        % if scope is "struct_component" AND hVar == hRootVar,
        % we have probably a VariantVariable --> most probably it's global
        bIsGlobal = true;
        return;
    end
end
bIsGlobal = strcmpi(stInfo.sScope, 'global');
if bIsGlobal
    % do not count MACROs as global
    if stInfo.bIsMacro
        bIsGlobal = false;
    end
end
end


%%
function bIsComponent = i_isStructComponent(stEnv, hVar)
stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
bIsComponent = strcmp(stInfo.sScope, 'struct_component');
if ~bIsComponent
    % Note: sometimes components do not have the Scope "struct_component" --> check for parent name
    sPath = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVar, 'path');
    [~, sParentName] = fileparts(fileparts(sPath));
    bIsComponent = ~isempty(regexp(sParentName, '^Components$|Components\(#\d+\)$', 'once'));
end
end


%%
function bIsConst = i_isVarConst(stEnv, hVar)
stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
bIsConst = stInfo.bIsConst;
end


%%
% note: remove the (#<%d>) post-fix from the variable name
function sVarName = i_getCleanVarName(sVarName)
sVarName = regexprep(sVarName, '\(#\d+\)$', '');
end
