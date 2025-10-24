function [sVarType, bIsSimParam, bIsSimSignal, bEmbeddedFi, sVarAccess, stTypeInfo] = atgcv_m13_evalin_context_vartype(xEvalContext, sVarName, sAccessPath)
% Evaluates type of variable with name sVarName (and AcccessPath in some context workspace.
%
% function  [sVarType, bIsSimParam, bIsSimSignal, sVarAccess] = atgcv_m13_evalmodel_vartype(sModel, sVarName)
%
%   INPUTS               DESCRIPTION
%     sVarName           (string)     name of variable in workspace "base"
%
%   OUTPUTS              DESCRIPTION
%     sVarType           (string)     type of variable in workspace "base"
%     bIsSimParam        (bool)       true if type is "Simulink.Parameter" or
%                                     inhertited from it
%     sVarAccess         (string)     Access to the value of the given
%                                     variable name



%% internal
%
%   REMARKS
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%

%%
if (nargin < 3)
    sAccessPath = '';
end

%% just to be sure some checks
if ~ischar(sVarName)
    error('ATGCV:INTERNAL:ERROR', ...
        'Wrong usage. Function only for names of vars.');
end

%% init default output
sVarType     = '';
bIsSimParam  = false;
bIsSimSignal = false;
bEmbeddedFi = false;
stTypeInfo = [];
sVarAccess = sVarName;
if ~i_checkExistence(xEvalContext, sVarName)
    return;
end


%% main
try
    if i_eval(xEvalContext, sprintf('isa(%s, ''Simulink.Signal'')', sVarName))
        bIsSimSignal = true;
        [sVarType, stTypeInfo]  = i_evaluateType(i_eval(xEvalContext, sprintf('%s.DataType', sVarName)));
        
    elseif i_eval(xEvalContext, sprintf('isa(%s, ''Simulink.Parameter'')', sVarName))
        bIsSimParam = true;
        [sVarType, stTypeInfo]= i_evaluateType(i_eval('base', sprintf('%s.DataType', sVarName)));
        sVarAccess = sprintf('%s.Value', sVarName);
        xValue = i_eval('base', sVarAccess);
        bEmbeddedFi = isa(xValue, 'embedded.fi');
    elseif i_eval(xEvalContext, sprintf('isa(%s, ''Simulink.Breakpoint'')', sVarName))
        bIsSimParam = true;
        [sVarType, stTypeInfo]= i_evaluateType(i_eval('base', sprintf('%s.Breakpoints.DataType', sVarName)));
        sVarAccess = sprintf('%s.Breakpoints.Value', sVarName);
        xValue = i_eval('base', sVarAccess);
        bEmbeddedFi = isa(xValue, 'embedded.fi');
    elseif i_eval(xEvalContext, sprintf('isa(%s, ''Simulink.LookupTable'')', sVarName))
        bIsSimParam = true;
        [sVarType, stTypeInfo]= i_evaluateType(i_eval('base', sprintf('%s.Table.DataType', sVarName)));
        sVarAccess = sprintf('%s.Table.Value', sVarName);
        xValue = i_eval('base', sVarAccess);
        bEmbeddedFi = isa(xValue, 'embedded.fi');
    else
        sVarType = i_eval(xEvalContext, sprintf('class(%s)', sVarName));
        if (strcmpi(sVarType, 'struct') && ~isempty(sAccessPath))
            try
                sVarAccess = [sVarName, sAccessPath];
                sVarType = i_eval(xEvalContext, sprintf('class(%s)', sVarAccess));
            catch
                sVarType = '';
                return;
            end
        elseif strcmpi(sVarType, 'embedded.fi')
            bEmbeddedFi = true;
        end
        [sVarType, stTypeInfo] = i_evaluateType(sVarType);
    end
catch
    sVarType = 'double';
end
end



%%
function [sEvalType, stTypeInfo] = i_evaluateType(sType)
sEvalType = sType;
stTypeInfo = [];
if ~i_isBuiltInSignalType(sEvalType)
    clear ep_sl_type_info_get;
    stTypeInfo = ep_sl_type_info_get(sType);
    sEvalType = stTypeInfo.sBaseType;
    if stTypeInfo.dLsb ~= 1
        sEvalType = 'double';
    end
end
end


%%
function bIsBuiltIn = i_isBuiltInSignalType(sCheckType)
persistent casTypes;

if isempty(casTypes)
    casTypes = {  ...
        'double', ...
        'single', ...
        'int8',   ...
        'uint8',  ...
        'int16',  ...
        'uint16', ...
        'int32',  ...
        'uint32', ...
        'boolean', ...
        'logical', ...
        'struct'};
end
bIsBuiltIn = any(strcmp(sCheckType, casTypes));
end


%%
function xOut = i_eval(xEvalContext, sEvalString)
if ischar(xEvalContext)
    xOut = evalin(xEvalContext, sEvalString);
else
    xOut = xEvalContext.evalin(sEvalString);
end
end


%%
function bExists = i_checkExistence(xEvalContext, sVarName)
try
    if ischar(xEvalContext)
        x = evalin(xEvalContext, sprintf('who(''%s'')', sVarName));
        bExists = ~isempty(x);
    else
        x = xEvalContext.evalin(sVarName);
        bExists = ~isempty(x);
    end
    if( ~bExists)
        stExpressionResult = atgcv_m13_expression_info_get(sVarName);
        bExists = stExpressionResult.bIsLValue;
    end
catch
    stExpressionResult = atgcv_m13_expression_info_get(sVarName);
    bExists = stExpressionResult.bIsLValue;
end
end
