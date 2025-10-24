function [result,success,errmsg] = osc_mtl_evalinws(expression, modelname)
% Evaluate a Matlab expression in a specific workspace.
%
% function [result,success,errmsg] = osc_mtl_evalinws(expression, modelname)
%
% This function evaluates an expression either in the base workspace or
% optionally in a model workspace. Variables occuring in the expression are
% searched in the workspaces in a defined order. The functions result is equal
% to the computed values in a simulation run, where the model refers to
% workspace variables.
%
%   PARAMETER(S)    DESCRIPTION
%   - expression    String containing the expression to be evaluated.
%   - modelname     (String) If parameter isn´t given, then the expression is
%                   evaluated in the base workspace. If the parameters contains
%                   a valid model name, then variables of the expression are
%                   searched first in the model workspace and if not successful
%                   in the bas workspace.
%
%   OUTPUT
%   - result        The evaluation result or NaN if not successful.
%   - success       1 if successful, 0 otherwise
%   - errmsg        Empty string if successful, an error message otherwise.
%
% NOTE1: Model workspaces have been introduced in Matlab 14. For earlier
% versions the second parameter has no effect and is therefor ignored.
%
% NOTE2: If evaluating expressions for a Simulink model you should always fill
% the parameter "modelname". For model references you must use the name of the
% referenced system.
%
% NOTE3: It is possible only to evaluate expression that return a value. You
% cannot evaluate expression that return no or more than one output parameters.
% Example: Not possible: osc_mtl_evalinws('save matlab.mat') which does not return
% anything.
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$-2003
%
% $Revision: 141162 $ Last modified: $Date: 2013-05-02 20:22:46 +0200 (Do, 02 Mai 2013) $ $Author: lochman $ 


%  initialize output parameters
result  = NaN;
success = 0;
errmsg  = '';

%  check parameter types
if ~ischar(expression)
    builtin('error', 'Parameter "expression" must be a string.');
end

%  check for 2nd parameter
if nargin == 1
    model_workspace = [];
else
    %  check 2nd parameter type
    if ~ischar(modelname)
        builtin('error', 'Parameter "modelname" must be a string.');
    end
    %  get model workspace
    try
        model_workspace = get_param(modelname,'modelworkspace');
    catch
        %  model could not be found
        errmsg = 'Invalid model name.';
        return;
    end
end
i_model_ws(model_workspace);

%  optimization:
%  if expression contains no variables, just evaluate
%  if expression is a variable, search the variable
if any(isletter(expression))
    %  expression contains letters (maybe variables)
    %  remove .Value access of Simulink Parameters
    expression = strrep(expression, '.Value' ,'');
    if isvarname(expression)
        %  expression is just a variable name
        %  1. try in model workspace
        if ~isempty(model_workspace)
            try
                result  = model_workspace.evalin(expression);
                success = 1;
            catch
                %  variable unknown in workspace, try base workspace next
                success = 0;
            end
        end
        %  if not successful try base workspace next
        if ~success
            i_error_status(0);
            result  = builtin('evalin', 'base',expression,'i_error_status(1)');
            if ~i_error_status
                success = 1;
            end
        end
        %  check evaluation was successful
        if success
            %  successful, result is a value or a Simulink.Paramter
            if strcmp(class(result),'Simulink.Parameter')
                %  evaluation was successful
                if (atgcv_version_compare('ML7.14')>=0)
                    result = result.Value;
                else
                    result = result.value;
                end
            end
        else
            result = NaN;
            errmsg = builtin('lasterr'); 
        end
        return;
    end
else
    %  expression contains no letters and is therefor variable free
    %  =>  just evaluate
    i_error_status(0);
    result  = eval(expression,'i_error_status(1)');
    if i_error_status
        result = NaN;
        errmsg = builtin('lasterr');
    else
        success = 1;
    end
    return;
end

%  set expression
i_expression(expression);
%  evaluate expression
i_eval_in_local_ws;
%  get evaluation result
result = i_evaluated;

if i_error_status
    %  evaluation wasn´t successful
    result = NaN;
    errmsg = 'Expression can´t be evaluated in workspaces.';
    return;
else
    success = 1;
end
return


%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                           ***
%                                                                           ***
%******************************************************************************

%******************************************************************************
%  Create a local copy of a workspace and evaluate the expression.          ***
%  Remark: since the local ws of this function holds a copy of a            ***
%  certain workspace, it should not declare any variables or use any        ***
%  input or output parameters.                                              ***
%                                                                           ***
% Parameters:                                                               ***
%   -                                                                       ***
% Output:                                                                   ***
%   -                                                                       ***
%                                                                           ***
%******************************************************************************
function i_eval_in_local_ws
try
    i_create_local_ws;
    %  reset error flag
    i_error_status(0);
    %  get expression of calling function and evaluate in current ws
    i_evaluated(eval(i_expression,'i_error_status(1)'));
catch
    %  just to be safe
    i_error_status(1);
end
return
% END i_eval_in_local_ws


%******************************************************************************
% Fill the workspace of the calling function.                               ***
%                                                                           ***
% Parameters:                                                               ***
%   -                                                                       ***
% Output:                                                                   ***
%   -                                                                       ***
%                                                                           ***
%******************************************************************************
function i_create_local_ws

base_data = builtin('evalin', 'base','whos');

%  base workspace first
for i=1:length(base_data)
    val = builtin('evalin', 'base',base_data(i).name);
    if strcmp(base_data(i).class, 'Simulink.Parameter')
        assignin('caller', base_data(i).name, val.Value);
    else
        assignin('caller', base_data(i).name, val);
    end
end

%  in a model workspace, define their variables which will
%  eventually override base workspace variables. This is intended.
workspace = i_model_ws;
if ~isempty(workspace)
    data=workspace.data;
    for i=1:length(data)
        %  check for Simulink.Parameter
        if strcmp(class(data(i).Value),'Simulink.Parameter')
            assignin('caller',data(i).Name, data(i).Value.Value);
        else
            %  normal workspace variable
            assignin('caller',data(i).Name, data(i).Value);
        end
    end
end
return
% END i_create_local_ws


%******************************************************************************
% Set/get the error status for an evaluation.                               ***
%                                                                           ***
% Parameters:                                                               ***
%   - e  Set error status: 0 means no error, 1 means error.                 ***
%        If called without parameter, the function just return the current  ***
%        error status.                                                      ***
% Output:                                                                   ***
%   - status Current status if called with no arguments or previous status  ***
%            if called with argument                                        ***
%                                                                           ***
%******************************************************************************
function status = i_error_status(e)
%  initialize persistent variable
persistent pe;
if nargin == 1
    %  set status
    pe = e;
end
%  return current status always
status = pe;
return
% END i_error_status


%******************************************************************************
% Set/get the expression to be evaluated.                                   ***
%                                                                           ***
% Parameters:                                                               ***
%   - expr_in  If called with argument, current the expression is set.      ***
% Output:                                                                   ***
%   - expr     If called without argument, the current expression is        ***
%              returned.                                                    ***
%                                                                           ***
%******************************************************************************
function expr = i_expression(expr_in)
%  initialize persistent variable
persistent ex;
if nargin == 1
    %  set expression
    ex = expr_in;
else
    %  return current expression
    expr = ex;
end
return
% END i_expression


%******************************************************************************
% Set/get the evaluation result.                                            ***
%                                                                           ***
% Parameters:                                                               ***
%   - eval_in  If called with argument, current evaluation is set.          ***
% Output:                                                                   ***
%   - eval     If called without argument, the current evaluation is        ***
%              returned.                                                    ***
%                                                                           ***
%******************************************************************************
function eval = i_evaluated(eval_in)
%  initialize persistent variable
persistent ev;
if nargin == 1
    %  set expression
    ev = eval_in;
else
    %  return current expression
    eval = ev;
end
return
% END i_evaluated


%******************************************************************************
% Set/get the model workspace.                                              ***
%                                                                           ***
% Parameters:                                                               ***
%   - mws_in   If called with argument, current workspace is set.           ***
% Output:                                                                   ***
%   - mws      If called without argument, the current workspace is         ***
%              returned.                                                    ***
%                                                                           ***
%******************************************************************************
function mws = i_model_ws(mws_in)
%  initialize persistent variable
persistent ws;
if nargin == 1
    %  set expression
    ws = mws_in;
else
    %  return current expression
    mws = ws;
end
return
% END i_model_ws

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************

