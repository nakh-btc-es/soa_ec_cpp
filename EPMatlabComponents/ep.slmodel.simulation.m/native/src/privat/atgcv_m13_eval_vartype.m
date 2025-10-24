function [sVarType, bIsSimParam, bIsSimSignal, bIsBwVar, bIsMwVar, sVarPath, bIsNotDefined] = atgcv_m13_eval_vartype(stEnv, sBlock, sVarName, sInitValue)
% 
% function  [sVarType, bIsSimParam, bIsWsVar, bIsSimSignal, bIsMsVar, sVarPath] =
% atgcv_m13_eval_vartype(sBlock, sVarName)
%
%   INPUTS               DESCRIPTION
%     sBlock             (string)     block from where the search starts
%     sVarName           (string)     name of variable in workspace "base"
%
%   OUTPUTS              DESCRIPTION
%     sVarType           (string)     type of variable in workspace "base"
%     bIsSimParam        (bool)       true if type is "Simulink.Parameter" or
%                                     inhertited from it
%     


%% internal    
%
%   REMARKS
%
%   AUTHOR(S):
%     Remmer Wilts
%     BTS - Embedded Systems AG, GERMANY
% $$$COPYRIGHT$$$-2011
%
%
%%

sVarType = 'double';
bIsSimParam = false;
bIsSimSignal = false;
bIsBwVar = false;
bIsMwVar = false;
bIsNotDefined = false;

if ~ischar(sVarName)
    error('ATGCV:INTERNAL:ERROR', ...
        'Wrong usage. Function only for names of vars.');
end

sModel = bdroot(sBlock);
hBlock = get_param( sBlock, 'Handle');
sVarPath = atgcv_m13_find_mask_var(hBlock,sVarName);
if( isempty( sVarPath ) )
    bIsStoredMw = i_is_ms_variable(sModel,sVarName);
    if( bIsStoredMw )
        bIsMwVar = true;
        [sVarType, bIsSimParam, bIsSimSignal] = ...
            atgcv_m13_evalmodel_vartype(sModel,sVarName);
    else
        if( i_is_ws_variable(sVarName) )
            [sVarType, bIsSimParam, bIsSimSignal] = ...
                atgcv_m13_evalinbase_vartype(sVarName);
            bIsBwVar = true;
        else
            bIsMwVar = true; % Var will be defined later in Modelworkspace
            bIsBwVar = false;
            bIsNotDefined = true;
            if (~isempty(sInitValue))
                [sVarType, bIsSimParam, bIsSimSignal] = ...
                    i_evaluateExpressionType(sInitValue);
            else
                osc_messenger_add(stEnv, ...
                    'ATGCV:MIL_GEN:EVAL_VAR_TYPE', ...
                    'name', sVarName);
            end
        end
    end
else
    sValue = get_param(sVarPath, sVarName);
    [sVarType, bIsSimParam, bIsSimSignal] = i_evaluateExpressionType(sValue);
end
end






%**************************************************************************
%
%**************************************************************************
function bIsStoredMw = i_is_ms_variable(sModel,sVarName)
bIsStoredMw = false;
hws = get_param(sModel,'modelworkspace');
if isvarname(sVarName)
    astRes = hws.data;
    if( isempty(astRes ) )
        return;
    end
    for i = 1:length( astRes )
        stRes = astRes(i);
        if( strcmp(stRes.Name,sVarName) )
            bIsStoredMw = true;
            return;
        end
    end
end
end


%**************************************************************************
%
%**************************************************************************
function bIsStoredWv = i_is_ws_variable(sVarName)
try
    bIsStoredWv = evalin('base',sprintf('exist(''%s'',''var'')',sVarName));
catch
    bIsStoredWv = false;
end
end



%%
function [sType, bIsSimParam, bIsSimSignal] = i_evaluateExpressionType(xExpression)
bIsSimParam  = false;
bIsSimSignal = false;

if ischar(xExpression)
    try
        xExpression = evalin('base', xExpression);
    catch
        sType = 'double';
        return;
    end
end

try
    if isa(xExpression, 'Simulink.Parameter')
        bIsSimParam = true;
        sType = xExpression.DataType;   
        
    elseif isa(xExpression, 'Simulink.Signal')
        bIsSimSignal = true;
        sType = xExpression.DataType;
        
    else
        sType = class(xExpression);
        
    end
    sType = i_evaluateType(sType);
catch
    % now is default double
    sType = 'double';
end
end


%% 
function sEvalType = i_evaluateType(sType)
sEvalType = sType;
if ~i_isBuiltInSignalType(sEvalType)
    sEvalType = 'double';
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
        'boolean'};
end
bIsBuiltIn = any(strcmpi(sCheckType, casTypes));
end

%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************

