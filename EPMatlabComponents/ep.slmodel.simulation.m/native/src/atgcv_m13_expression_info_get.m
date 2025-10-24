function stInfo = atgcv_m13_expression_info_get(sExpression, xBlockContext)
% Get info about provided expression evaluated in the base workspace or in the Simulink block context.
%
% function stInfo = atgcv_m13_expression_info_get(sExpression)
%
%   INPUT               DESCRIPTION
%     sExpression        (string)          some arbitrary expression
%     xBlockContext      (string|handle)   optional: block path or handle
%   
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)   
%        .sExpression    (handle)   provided expression repeated in trimmed
%                                   version
%        .xValue         (<undef>)  return value when evaluating the expression
%                                   (might be empty)
%        .sValueClass    (string)   class of the return value
%                                   (might be empty)
%        .sFuncName      (string)   if the expression represents a function
%                                   call, the name of the function
%                                   (might be empty)
%        .bIsValid       (bool)     can expression be evaluated successfully?
%        .bIsLValue      (bool)     can a value be assigned to the expression?
%        .bIsVar         (bool)     special case of L-Value: is Expression a
%                                   variable in base workspace?
%
%   REMARKS
%     Main UseCase of function is to evaluate Expression found in Model
%     attributes.
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
bUseBlockContext = false;
if (nargin > 1)
    try
        % normalize input (use handle) and _check_ validity at the same time
        xBlockContext = get_param(xBlockContext, 'handle');
        bUseBlockContext = true;
    catch
        error('ATGCV:STD:WRONG_USAGE', ...
            'Provided Block context is not valid.');        
    end
else
    xBlockContext = [];
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
    error('ATGCV:STD:WRONG_USAGE', ...
        'Only string expressions allowed as argument.');
end
sExpression = strtrim(sExpression);
stInfo.sExpression = sExpression;

%% check if expression can be evaluated == valid
if isempty(sExpression)
    % nothing to evaluate here
    stInfo.bIsValid = true; % TODO: not sure -- is '' a valid expression or not?
    return;
else
    if bUseBlockContext
        try
            stInfo.xValue = slResolve(sExpression, xBlockContext);
            stInfo.sValueClass = class(stInfo.xValue); 
            stInfo.bIsValid = true;
        catch
            stInfo.bIsValid = false;
        end
        % !note: when in block context the result is _never_
        %        a variable nor an L-value nor a func name
        % --> therefore, just return here early
        return;
    else
        try
            stInfo.xValue = evalin('base', sExpression);
            stInfo.sValueClass = class(stInfo.xValue); 
            stInfo.bIsValid = true;
        catch
            stInfo.bIsValid = false;
        end
    end
end

%% check if expresion is a variable currently existing in base workspace
stInfo.bIsVar = i_isVar(sExpression); 
if stInfo.bIsVar
    % note: variable is an L-Value and no Function call --> so early return here
    stInfo.bIsLValue = true;
    return;
end

%% check if expression is a function call
stInfo.sFuncName = i_extractFuncName(sExpression);
if ~isempty(stInfo.sFuncName)    
    % note: function call is not an L-Value --> so early return here
    return;
end

%% check explicitly if expression is an L-Value
stInfo.bIsLValue = i_checkLValue(sExpression, stInfo.xValue);
end



%%
function bIsVar = i_isVar(sExpression)
bIsVar = false;
if isvarname(sExpression)
    bIsVar = ...
        evalin('base', sprintf('exist(''%s'', ''var'')', sExpression)) ~= 0; 
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
function bIsLValue = i_checkLValue(sExpression, xValue) %#ok<INUSD> note: used in "eval"!
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

try
    % try to create a local copy of the root variable
    xRootCopy = evalin('base', sRoot); %#ok<NASGU> note: used in "eval"!
    
    % try to assign the local copy some compatible value
    eval(['xRootCopy', sTrail, ' = xValue;']); 
    
    % if we are here, everything was fine --> we have an L-Value
    bIsLValue = true;
catch
    return;
end
end

