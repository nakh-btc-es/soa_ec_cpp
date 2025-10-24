function stInfo = ep_sim_check_dictionary_param(sVarName, hDictionary)
% Check if a Parameter is available in linked SLDD.
%
% function stInfo = ep_sim_check_dictionary_param(sVarName, hDictionary)
%
%   INPUT               DESCRIPTION
%     sVarName          (string)          name to check in dictionary
%     hDictionary       (handle)          handle to SLDD
%   
%   OUTPUT              DESCRIPTION
%     stInfo             (struct)   
%        .bCachedInWs    (bool)     can expression be evaluated successfully?
%        .bIsParamType   (bool)     we deal with a Simulink.Parameter here
%        .bFromSLDD      (bool)     usage originates from SLDD
%        .sVarType       (string)   type information for the parameter
%        .sVarAccess     (string)   full string path of the value
%
%   REMARKS
%     Checks if a given Parameter originates in a certain SLDD and evaluates the class of the Parameter value
%
%   <et_copyright>


%% default output
stInfo = struct( ...
    'bCachedInWs',   false,...
    'bFromSLDD',     false,...
    'sVarType',      '',...
    'sVarAccess',    '',...
    'bIsParamType',  false,...
    'bEmbeddedFi',   false,...
    'stTypeInfo',    []);


%% check input consistency
if ~ischar(sVarName)
    error('ATGCV:STD:WRONG_USAGE', 'Queried Parameter name has to be a string.');
end

%get section Design Data from Dictionary
if ~isempty(hDictionary)
    hSection = getSection(hDictionary, 'Design Data');
else
    hSection = [];
end

try 
    hEntry = getEntry(hSection, sVarName);
catch
    stInfo.bCachedInWs = true;
    hEntry = [];
end
if ~isempty(hEntry)
    stInfo.bCachedInWs = true;
    stInfo.bFromSLDD = true;
    hObj = getValue(hEntry);
    if ~isempty(hObj)
        stInfo.sVarType = class(hObj);
        stInfo.bIsParamType = strcmpi(stInfo.sVarType, 'Simulink.Parameter');
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
    stInfo.bFromSLDD = false;
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


