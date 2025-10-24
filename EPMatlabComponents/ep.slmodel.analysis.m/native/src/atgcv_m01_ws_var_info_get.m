function [stProps, bIsValid] = atgcv_m01_ws_var_info_get(sVarName, hResolverFunc)
% Returns the Properties of a Workspace Variable.
%
% function [stProps, bIsValid] = atgcv_m01_ws_var_info_get(sVarName, hResolverFunc)
%
%   INPUT               DESCRIPTION
%       sVarName           (string)   name of the Variable
%       hResolverFunc      (handle)   function handle for Symbol resolver
%                                     if not provided, the Variable is resolved inside the base workspace
%
%   OUTPUT              DESCRIPTION
%        stProps                 (struct)   struct with following info:
%         .sClass                  (string)    class of the Variable
%         .sUserType               (string)    user type of Variable (might be an alias)
%         .sType                   (string)    base type of Variable (for simple DataTypes equivalent to sClass)
%         .aiWidth                 (array)     Variable's Dimensions
%         .sMin                    (string)    Min value as String (non-empty only if defined)
%         .sMax                    (string)    Max value as String (non-empty only if defined)
%         .stCoderInfo             (struct)    Code related properties of the parameter
%           .sStorageClass           (string)    the StorageClass
%           .sCustomStorageClass     (string)    the CustomeStorageClass (for non-custom classed == "Default")
%
%        bIsValid                (bool)   flag if the variable is existing and is a valid Parameter variable
%
%
%   <et_copyright>


%%
if ((nargin < 2) || isempty(hResolverFunc))
    hResolverFunc = atgcv_m01_generic_resolver_get();
end

%%
if (~isempty(sVarName) && ischar(sVarName))
    [xVar, nScope] = feval(hResolverFunc, sVarName);
    if (nScope < 1)
        xVar = [];
    end
else
    xVar = [];
end

[stProps, bIsValid] = i_getVariableProperties(xVar, hResolverFunc);
end


%%
function stProps = i_getInitProperties()
stCoderInfo = struct( ...
    'sStorageClass',       '', ...
    'sCustomStorageClass', '');
stProps = struct( ...
    'sClass',      '', ...
    'sType',       '', ...
    'sUserType',   '', ...
    'xValue',      [], ...
    'aiWidth',     [], ...
    'sMin',        '', ...
    'sMax',        '', ...
    'stCoderInfo', stCoderInfo);
end


%%
function [stProps, bIsValid] = i_getVariableProperties(xVar, hResolverFunc)
stProps  = i_getInitProperties();
bIsValid = ~isempty(xVar);
if ~bIsValid
    return;
end

stProps.sClass = class(xVar);
if isa(xVar, 'Simulink.Parameter')
    stProps.stCoderInfo = i_getCoderInfo(xVar);
    [stProps, bIsValid] = i_tansferObjectToProps(xVar, stProps, hResolverFunc);
    
elseif isa(xVar, 'Simulink.Breakpoint')
    stProps.stCoderInfo = i_getCoderInfo(xVar);
    [stProps, bIsValid] = i_tansferObjectToProps(xVar.Breakpoints, stProps, hResolverFunc);
    
elseif isa(xVar, 'Simulink.LookupTable')
    stProps.stCoderInfo = i_getCoderInfo(xVar);
    [stProps, bIsValid] = i_tansferObjectToProps(xVar.Table, stProps, hResolverFunc);
    
else
    if (isnumeric(xVar) || islogical(xVar))
        stProps.sUserType = class(xVar);
        stProps.sType     = i_evaluateType(stProps.sUserType, hResolverFunc);
        stProps.xValue    = xVar;
        stProps.aiWidth   = size(xVar);
        
    else
        bIsValid = false;
    end
end
end


%%
function [stProps, bIsValid] = i_tansferObjectToProps(oObjectSL, stProps, hResolverFunc)
stProps.aiWidth   = oObjectSL.Dimensions;
stProps.sUserType = oObjectSL.DataType;
if strcmp(stProps.sUserType, 'auto')
    stProps.sUserType = class(oObjectSL.Value);
end
[stProps.sType, bIsValid] = i_evaluateType(stProps.sUserType, hResolverFunc);
if bIsValid
    stProps.xValue = oObjectSL.Value;
    if ~isinf(oObjectSL.Min)
        oMinVal = ep_sl.Value(oObjectSL.Min);
        stProps.sMin = oMinVal.toString();
    end
    if ~isinf(oObjectSL.Max)
        oMaxVal = ep_sl.Value(oObjectSL.Max);
        stProps.sMax = oMaxVal.toString();
    end
end
end


%%
function stCoderInfo = i_getCoderInfo(oObj)
stCoderInfo = struct( ...
    'sStorageClass',       oObj.CoderInfo.StorageClass, ...
    'sCustomStorageClass', oObj.CoderInfo.CustomStorageClass);
end


%%
function [sEvalType, bIsValid] = i_evaluateType(sType, hResolverFunc)
bIsValid = true;
sEvalType = sType;
if ~strcmp(sType, 'auto')
    stTypeInfo = ep_sl_type_info_get(sType, hResolverFunc);
    if stTypeInfo.bIsValidType
        sEvalType = stTypeInfo.sEvalType;
    end
    bIsValid = stTypeInfo.bIsValidType;
end
end
