function [xVar, bExist] = ep_core_workspace_variable_get(oWorkspace, sVarName)
% Retrieve a variable from the provided workspace.
%
% function xVar = ep_core_workspace_variable_get(oWorkspace, sVarName)
%
%   INPUT
%      oWorkspace      (object)       a Simulink.ModelWorkspace object
%      sVarName        (string)       Expression that shall be evaluated.
%
%   OUTPUT
%      xVar            (???)          Individual output that depends on the specific variable.
%      bExist          (boolean)      TRUE if the variable exists, otherwise false.
%
%
% $$$COPYRIGHT$$$-2017


%%
xVar = [];
bExist = false;
if (isempty(oWorkspace) || isempty(sVarName))
    return;
end

%%
% Note: Matlab R2013b provides a better Simulink API
if i_isHighVersionML()
    try
        bExist = oWorkspace.hasVariable(sVarName);
    catch oEx
        bExist = false;
    end
    if bExist
        xVar = oWorkspace.getVariable(sVarName);
    end
else
    bExist = i_hasVariable(oWorkspace, sVarName);
    if bExist
        xVar = i_getVariable(oWorkspace, sVarName);
    end
end
end


%%
function bIsHighVersionML = i_isHighVersionML()
persistent p_bIsHighVersionML;

if isempty(p_bIsHighVersionML)
    p_bIsHighVersionML = ~verLessThan('Matlab', '8.2');
end
bIsHighVersionML = p_bIsHighVersionML;
end


%%
function bHasVariable = i_hasVariable(oWorkspace, sVarName)
try
    astVars = oWorkspace.whos;
    if isempty(astVars)
        bHasVariable = false;
    else
        bHasVariable = any(strcmp(sVarName, {astVars.name}));
    end
catch
    bHasVariable = false;
end
end


%%
function xVar = i_getVariable(oWorkspace, sVarName)
try
    xVar = oWorkspace.evalin(sVarName);
catch
    xVar = [];
end
end

