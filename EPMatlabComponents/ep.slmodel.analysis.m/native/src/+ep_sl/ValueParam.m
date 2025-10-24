classdef ValueParam
    % Class represents an evaluated expression of a block property. It contains the value and the variable info(s) if
    % available.
    
    properties (SetAccess = private)
        Expression % only to show something to users on the console and for debugging
    end
    
    properties (Hidden, Access = private)
        bIsVar_  % does the expression represent a single variable
        stValue_ % the evaluated info about the expression
    end
    
    methods (Static)
        function oObj = getForBlockProperty(xBlock, sProperty)
            oObj = ep_sl.ValueParam();
            [oObj.Expression, oObj.stValue_, oObj.bIsVar_] = i_getVariableValueFromBlockUsage(xBlock, sProperty);
        end
    end
    
    methods
        function bIsVar = isVariable(oObj)
            bIsVar = oObj.bIsVar_;
        end
        
        function stVar = getVariable(oObj)
            if oObj.bIsVar_
                stVar = i_getVar(oObj.stValue_);
            else
                stVar = [];
            end
        end
        
        function stVal = getValue(oObj)
            stVal = oObj.stValue_;
        end
    end    
end


%%
function stVar = i_getVar(stObjVal)
stVar = stObjVal.astExpressionVars(1);
end


%%
function [sExpr, stValue, bIsVar] = i_getVariableValueFromBlockUsage(xBlock, sProperty)
stValue = [];
bIsVar  = false;

sExpr = i_getExpression(xBlock, sProperty);
if (isempty(sExpr) || ~ischar(sExpr))
    return;
end

aoUsages = i_getRelevantUsages(xBlock, sProperty);
[stValue, bIsVar] = i_getValueInfo(xBlock, sExpr, aoUsages);
end


%%
function aoUsages = i_getRelevantUsages(xBlock, sBlockProperty)
aoAllUsages = ep_core_feval('ep_model_variables_get', xBlock, 'cached', true);

sBlockID = getfullname(xBlock);

abSelect = false(size(aoAllUsages));
for i = 1:numel(aoAllUsages)
    aoUsageDetails = aoAllUsages(i).DirectUsageDetails;
    for k = 1:numel(aoUsageDetails)
        oDetails = aoUsageDetails(k);
        if (strcmp(oDetails.UsageType, 'Block') && strcmp(oDetails.Identifier, sBlockID))
            for m = 1:numel(oDetails.Properties)
                if strcmpi(oDetails.Properties{m}, sBlockProperty)
                    abSelect(i) = true;
                    break;
                end
            end
        end
        if abSelect(i)
            break;
        end
    end
end

aoUsages = aoAllUsages(abSelect);
end


%%
function sExpr = i_getExpression(xBlock, sUsage)
try
    sExpr = get_param(xBlock, sUsage);
    
catch oEx
    warning('EP:ERROR:USAGE_CONTEXT_INVALID', '%s', oEx.getReport());
    sExpr = '';
end
end


%%
function stVar = i_transformVarUsageIntoVar(oVarUsage)
[sName, sRawName] = i_getName(oVarUsage);
stVar = struct( ...
    'sName',       sName, ...
    'sRawName',    sRawName, ...
    'sSource',     oVarUsage.Source, ...
    'sSourceType', oVarUsage.SourceType);
end


%%
function [sName, sRawName] = i_getName(oVarUsage)
sRawName = oVarUsage.Name;
if strcmp(oVarUsage.SourceType, 'model workspace')
    sName = [oVarUsage.Source ':' oVarUsage.Name];
else
    sName = sRawName;
end
end


%%
function [stVal, bIsVar] = i_getValueInfo(xBlock, sExpr, aoUsages)
stVal  = [];
bIsVar = false;

xVal = slResolve(sExpr, xBlock);
if isempty(xVal)
    return;
end

astExpressionVars = arrayfun(@(o) i_transformVarUsageIntoVar(o), aoUsages);

% the property is representing a variable if there is exactly one single expression variable and its name equals the
% property expression
bIsVar = (numel(astExpressionVars) == 1) && strcmp(astExpressionVars.sRawName, sExpr);
stVal = struct( ...
    'xVal',              i_getPureValue(xVal), ...
    'astExpressionVars', astExpressionVars);
end


%%
function xVal = i_getPureValue(xVal)
if isobject(xVal)
    if isa(xVal, 'Simulink.Parameter')
        xVal = xVal.Value;

    elseif isa(xVal,'Simulink.Breakpoint')
        xVal = xVal.Breakpoints.Value;

    elseif isa(xVal,'Simulink.LookupTable')
        xVal = xVal.Table.Value;
    end
end
end

