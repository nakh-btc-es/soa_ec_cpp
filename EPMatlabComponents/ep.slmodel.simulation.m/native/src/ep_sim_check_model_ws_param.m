function stInfo = ep_sim_check_model_ws_param(sVarName, sModelName)
% Check meta information for parameters from model workspace
%
% function stInfo = ep_sim_check_model_ws_param(sVarName, hModel)
%
%   INPUT               DESCRIPTION
%     sVarName          (string)          variable name to check in workspace
%     sModelName        (string)          name of the model
%   
%   OUTPUT              DESCRIPTION
%     stInfo            (struct)   
%        .bIsParamType  (bool)     we deal with a Simulink.Parameter here
%        .bEmbeddedFi   (bool)     we deal with an Embedded fi type
%        .bIsValid      (bool)     we got valid information from model workspace
%        .sVarType      (string)   type information for the parameter
%        .sVarAccess    (string)   full string path of the value
%   REMARKS
%     Checks if a given Parameter originates in a certain model workspace and fills meta information
%
%   <et_copyright>


%% internal
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Kristof.Woll@btc-es.de
% $$$COPYRIGHT$$$
%


%% default output
stInfo = struct( ...
    'sVarType',      '',...
    'sVarAccess',    '',...
    'bIsParamType',  false,...
    'bEmbeddedFi',   false,...
    'bIsValid',      false,...
    'stTypeInfo',    []);


%% check input consistency
if ~ischar(sVarName)
    error('ATGCV:STD:WRONG_USAGE', ...
        'Queried Parameter name has to be a string.');
end

%get section Design Data from Dictionary
if ~isempty(sModelName)
    hWorkspace= get_param(sModelName, 'ModelWorkspace');
else
    hWorkspace = [];
end

try 
    hObj = hWorkspace.getVariable(sVarName);
catch
    hObj = [];
end
if ~isempty(hObj)
    stInfo.bIsValid = true;
    if ~isempty(hObj)
        stInfo.sVarType = class(hObj);
        stInfo.bIsParamType = isa(hObj, 'Simulink.Parameter');
        if isa(hObj,'Simulink.Parameter')
            [stInfo.sVarType, stInfo.stTypeInfo] = i_evaluateType(hObj.DataType);
            stInfo.sVarAccess = sprintf('%s.Value', sVarName);
            xValue = hObj.Value;
            stInfo.bEmbeddedFi = isa(xValue, 'embedded.fi');
        elseif isa(hObj,'Simulink.Breakpoint')
            [stInfo.sVarType, stInfo.stTypeInfo] = i_evaluateType(hObj.Breakpoints.DataType);
            stInfo.sVarAccess = sprintf('%s.Breakpoints.Value', sVarName);
            xValue = hObj.Breakpoints.Value;
            stInfo.bEmbeddedFi = isa(xValue, 'embedded.fi');
        elseif isa(hObj,'Simulink.LookupTable')
            [stInfo.sVarType, stInfo.stTypeInfo] = i_evaluateType(hObj.Table.DataType);
            stInfo.sVarAccess = sprintf('%s.Table.Value', sVarName);
            xValue = hObj.Table.Value;
            stInfo.bEmbeddedFi = isa(xValue, 'embedded.fi');
        else %handling for other variables within SLDD
            [stInfo.sVarType, stInfo.stTypeInfo] = i_evaluateType(class(hObj));
            stInfo.sVarAccess = sVarName;
            xValue = hObj;
            stInfo.bEmbeddedFi = isa(xValue, 'embedded.fi');
        end
    end
else
    stInfo.bIsValid = false;
end   
end

%%
function [sEvalType, stTypeInfo] = i_evaluateType(sType)
sEvalType = sType;
stTypeInfo = [];
if ~i_isBuiltInSignalType(sEvalType)
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


