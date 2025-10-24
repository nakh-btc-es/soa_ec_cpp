function [sVarType, bIsSimParam, bIsSimSignal] = atgcv_m13_evalmodel_vartype(sModel, sVarName, sAccessPath)
% evalutes the type of the variable with name sVarName in the model workspace 
%
% function  [sVarType, bIsSimParam, bIsSimSignal] = atgcv_m13_evalmodel_vartype(sModel, sVarName)
%
%   INPUTS               DESCRIPTION
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
% $$$COPYRIGHT$$$-2011
%
%   

%%
if (nargin < 3)
    sAccessPath = '';
end
hws = get_param(sModel, 'modelworkspace');

[sVarType, bIsSimParam, bIsSimSignal] = ...
    atgcv_m13_evalin_context_vartype(hws, sVarName, sAccessPath);
end

