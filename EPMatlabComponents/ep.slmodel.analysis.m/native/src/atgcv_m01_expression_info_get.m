function stInfo = atgcv_m01_expression_info_get(sExpression, xBlockContext, bWithExtendedInfo)
% Get info about provided expression evaluated inside the global workspace or in the Simulink block context.
%
% function stInfo = atgcv_m01_expression_info_get(sExpression, xBlockContext, bDoFullResolve)
%
%   INPUT               DESCRIPTION
%     sExpression        (string)          some arbitrary expression
%     xBlockContext      (string|handle)   optional: block path or handle
%     bWithExtendedInfo  (boolean)         optional: if TRUE, the evaluation yields the full information 
%                                          (default = FALSE)
%
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)   
%        .sExpression    (handle)   provided expression repeated in trimmed version
%        .xValue         (xxx)      return value when evaluating the expression (might be empty)
%        .sValueClass    (string)   class of the return value (might be empty)
%        .bIsValid       (bool)     can expression be evaluated successfully?
%      --- extended ------------------------------------------------------------------------------------------
%        .sFuncName      (string)   if the expression represents a function call, the name of the function
%                                   (might be empty)
%        .bIsLValue      (bool)     can a value be assigned to the expression?
%        .bIsVar         (bool)     special case of L-Value: is Expression a variable in a global workspace?
%
%   REMARKS
%     Main UseCase of function is to evaluate Expression found in Model attributes.
%
%   <et_copyright>


%% internal
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 87354 $
%   Last modified: $Date: 2011-05-16 10:06:55 +0200 (Mo, 16 Mai 2011) $
%   $Author: ahornste $


%%
if (nargin < 2)
    xBlockContext = [];
else
    try
        % normalize input (use handle) and _check_ validity at the same time
        xBlockContext = get_param(xBlockContext, 'handle');
    catch
        error('ATGCV:STD:WRONG_USAGE', 'Provided Block context is not valid.');        
    end
end
if (nargin < 3)
    % default behavior: do a full info gathering only in non-model context
    bWithExtendedInfo = isempty(xBlockContext);
end


%% default output
stInfo = struct( ...
    'sExpression', '', ...
    'xValue',      '', ...
    'sValueClass', '', ...
    'sFuncName',   '', ...
    'bIsValid',    false, ...
    'bIsLValue',   false, ...
    'bIsVar',      false);


%% check input consistency
if ~ischar(sExpression)
    error('ATGCV:STD:WRONG_USAGE', 'Only string expressions allowed as argument.');
end
sExpression = strtrim(sExpression);
stInfo.sExpression = sExpression;


%% special case: empty expression
if isempty(sExpression)
    % nothing to evaluate here
    stInfo.bIsValid = true; % TODO: not sure -- is '' a valid expression or not?
    return; 
end


%%
if bWithExtendedInfo
    stInfo = i_fillValueInfoWithoutResolve(stInfo, sExpression, xBlockContext);    
    if ~stInfo.bIsValid
        return;
    end
else
    stInfo = i_fillValueInfoWithResolve(stInfo, sExpression, xBlockContext);
    return;
end


%% check if the expresion is a variable AND currently existing in global workspace
stInfo.bIsVar = i_isGlobalVar(sExpression, xBlockContext); 
if stInfo.bIsVar
    % note: a variable is an L-Value and no Function call --> so early return here
    stInfo.bIsLValue = true;
    return;
end

%% check if the expression is a function call
stInfo.sFuncName = i_extractFuncName(sExpression);
if ~isempty(stInfo.sFuncName)    
    % note: function call is not an L-Value --> so early return here
    return;
end

%% check explicitly if expression is an L-Value
stInfo.bIsLValue = i_checkGlobalLValue(sExpression, stInfo.xValue, xBlockContext);
end



%%
function stInfo = i_fillValueInfoWithResolve(stInfo, sExpression, xBlockContext)
if isempty(xBlockContext)
    try
        hEvalFunc = atgcv_m01_global_evaluator_get();
        stInfo.xValue = feval(hEvalFunc, sExpression);
        stInfo.sValueClass = class(stInfo.xValue);
        stInfo.bIsValid = true;
    catch
        stInfo.bIsValid = false;
    end
else
    try
        stInfo.xValue = slResolve(sExpression, xBlockContext);
        stInfo.sValueClass = class(stInfo.xValue);
        stInfo.bIsValid = true;
    catch
        stInfo.bIsValid = false;
    end
end
end


%%
function stInfo = i_fillValueInfoWithoutResolve(stInfo, sExpression, xBlockContext)
hEvalFunc = atgcv_m01_global_evaluator_get(xBlockContext);
try
    stInfo.xValue = feval(hEvalFunc, sExpression);
    stInfo.sValueClass = class(stInfo.xValue);
    stInfo.bIsValid = true;
catch
    stInfo.bIsValid = false;
end
end


%%
function bIsGlobalVar = i_isGlobalVar(sExpression, xBlockContext)
bIsGlobalVar = false;
if isvarname(sExpression)
    if isempty(xBlockContext)
        hResolverFunc = atgcv_m01_symbol_resolver_get();
    else
        hResolverFunc = atgcv_m01_symbol_resolver_get(xBlockContext);
    end
    
    [~, nScope] = feval(hResolverFunc, sExpression);
    bIsGlobalVar = (nScope == 1);
end
end


%%
function sFuncName = i_extractFuncName(sExpression)
sFuncName = '';

% assuming we have a trimmed Expression, try looking for a pontential function
% name directly at the beginning
casParse = regexp(sExpression, '^([a-z_A-Z]\w*)', 'tokens', 'once');
if isempty(casParse)
    return;
end

sPotentialName = casParse{1};
% return values of "exist":
%  2 -- M-file
%  3 -- MEX-file
%  5 -- builtin
%  6 -- P-file
if any(exist(sPotentialName) == [2, 3, 5, 6]) %#ok<EXIST>
    % maybe check also if we can get a function_handle ???
    sFuncName = sPotentialName;
end
end


%%
function bIsLValue = i_checkGlobalLValue(sExpression, xValue, xBlockContext) %#ok<INUSL> xValue used in eval!
bIsLValue = false;

% idea: trying to find the root variable
%   Example: Expression = "x(1).y{2,3}" --> RootVar = "x"

% assuming we have a trimmed Expression, try looking for a pontential function
% name directly at the beginning
casParse = regexp(sExpression, '^([a-z_A-Z]\w*)(.*)$', 'tokens', 'once');
if isempty(casParse)
    return;
end
sRoot  = casParse{1};
sTrail = casParse{2};

hGlobalEvalFunc = atgcv_m01_global_evaluator_get(xBlockContext);
try
    % try to create a local copy of the root variable
    xRootCopy = feval(hGlobalEvalFunc, sRoot); %#ok<NASGU> note: used in "eval"!
    
    % try to assign the local copy some compatible value
    eval(['xRootCopy', sTrail, ' = xValue;']); 
    
    % if we are here, everything was fine --> we have an L-Value
    bIsLValue = true;
catch
    return;
end
end

