function [sVarType, bIsSimParam, bIsSimSignal, bEmbeddedFi, sVarAccess, stTypeInfo] = atgcv_m13_evalinbase_vartype(sVarName)
% Evalutes the type of the variable with name sVarName in the workspace "base".
%
% function  [sVarType, bIsSimParam, bIsSimSignal,sVarAccess] = atgcv_m13_evalinbase_vartype(sVarName)
%
%   INPUTS               DESCRIPTION
%     sVarName           (string)     name of variable in workspace "base"
%
%   OUTPUTS              DESCRIPTION
%     sVarType           (string)     type of variable in workspace "base"
%     bIsSimParam        (bool)       true if variable is a 
%                                     "Simulink.Parameter" or inherited
%                                     from it
%     bIsSimSignal       (bool)       true if variable is a 
%                                     "Simulink.Signal" or inherited
%                                     from it
%     sVarAccess         (string)     Access to the value of the given
%                                     variable name


%% internal    
%
%   REMARKS
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$-2008
%
%   


%%


[sVarType, bIsSimParam, bIsSimSignal, bEmbeddedFi, sVarAccess, stTypeInfo] = ...
    atgcv_m13_evalin_context_vartype('base', sVarName, '');

if ~bIsSimParam && ~bIsSimSignal
    if(strcmp(sVarType,'struct'))
        sField = 'Value';
        if evalin('base',sprintf('isfield(%s,''%s'')',sVarName, sField)) 
            [sVarType, bIsSimParam, bIsSimSignal, bEmbeddedFi, sVarAccess, stTypeInfo] = ...
                atgcv_m13_evalin_context_vartype('base', sVarName, ['.',sField]);
        end
    end
end
end
