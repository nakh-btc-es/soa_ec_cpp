function stInfo = ep_ec_autosar_short_info_get(sModelName)
% Giving back short info about AUTOSAR model style.
%
% function stInfo = ep_ec_autosar_short_info_get(sModelName)
%
%   INPUT                              DESCRIPTION
%    sModelName                       (string)    name of the open model to be analysed
%
%  OUTPUT                              DESCRIPTION
%    stInfo                           (struct)    result of the analysis with the following fields
%       .sStyle                         (string)     'function-call-based' | 'rate-based' | 'non-autosar'
%       .sComponentName                 (string)     name of the AUTOSAR component
%       .bIsAdaptiveAutosar             (bool)       flag if model is Adaptive AUTOSAR
%       .sInitRunnable                  (string)     name of the init runnable C function
%       .casRunnables                   (cell)       list of step runnable C function names (excluding server, init, terminate, ...)
%       .bIsMultiInstance               (boolean)    flag, if the AUTOSAR model represents a multi-instance component or not       
%

%%
if (nargin < 1)
    sModelName = i_getCurrentModel();
end

stInfo = struct( ...
    'sStyle',            'non-autosar', ...
    'sComponentName',     '', ...
    'bIsAdaptiveAutosar', false, ...
    'sInitRunnable',      '', ...
    'casRunnables',       {{}}, ...
    'bIsMultiInstance',   false);

if i_isAutosarModel(sModelName)
    if i_isExportedFunctionStyle(sModelName)
        stInfo.sStyle = 'function-call-based';
    else
        stInfo.sStyle = 'rate-based';
    end
    [stInfo.sComponentName, mRunnableToSymbol] = i_getComponentAndRunnableSymbolMap(sModelName);

    oMapping = autosar.api.Utils.modelMapping(sModelName);
    stInfo.bIsAdaptiveAutosar = isa(oMapping, 'Simulink.AutosarTarget.AdaptiveModelMapping');
    if ~stInfo.bIsAdaptiveAutosar
        [stInfo.sInitRunnable, stInfo.casRunnables] = i_getInitAndStepRunnables(oMapping, mRunnableToSymbol);
    end
    stInfo.bIsMultiInstance = i_isMultiInstanceSWC(sModelName);
end
end


%%
function bIsMultiInstance = i_isMultiInstanceSWC(sModelName)
oConfig = getActiveConfigSet(sModelName);
sInterfacePackaging = oConfig.get_param('CodeInterfacePackaging');
bIsMultiInstance = strcmp(sInterfacePackaging, 'Reusable function');
end


%%
function [sInitRunnableSymbol, casRunnableSymbols] = i_getInitAndStepRunnables(oMapping, mRunnableToSymbol)
casRunnableNames = arrayfun(@(o) o.MappedTo.Runnable, oMapping.StepFunctions, 'UniformOutput', false);
casRunnableSymbols = cellfun(@(s) mRunnableToSymbol(s), casRunnableNames, 'UniformOutput', false);

casInitRunnableNames = arrayfun(@(o) o.MappedTo.Runnable, oMapping.InitializeFunctions, 'UniformOutput', false);
casInitRunnableSymbols = cellfun(@(s) mRunnableToSymbol(s), casInitRunnableNames, 'UniformOutput', false);

if ~isempty(casInitRunnableSymbols)
    sInitRunnableSymbol = casInitRunnableSymbols{1};
else
    sInitRunnableSymbol = '';
end
end


%%
function [sComponentName, mRunnableToSymbol] = i_getComponentAndRunnableSymbolMap(sModelName)
mRunnableToSymbol = containers.Map;

oAutosarProps = autosar.api.getAUTOSARProperties(sModelName);
sArComponentPath = oAutosarProps.get('XmlOptions', 'ComponentQualifiedName');
sComponentName = oAutosarProps.get(sArComponentPath, 'Name');

casRunnablePaths = find(oAutosarProps, sArComponentPath, 'Runnable', 'PathType', 'FullyQualified');
for i = 1:numel(casRunnablePaths)
    sRunnablePath = casRunnablePaths{i};
    
    sName = get(oAutosarProps, sRunnablePath, 'Name');
    sSymbol = get(oAutosarProps, sRunnablePath, 'symbol');
    
    mRunnableToSymbol(sName) = sSymbol;
end
end


%%
function sModel = i_getCurrentModel()
try
    sModel = bdroot(gcs);
catch
    sModel = '';
end
end


%%
function bIsAutosar = i_isAutosarModel(sModelName)
bIsAutosar = ~isempty(i_getAutosarVersion(sModelName));
end


%%
function sAutosarVersion = i_getAutosarVersion(sModelName)
try
    sAutosarVersion = get_param(sModelName, 'AutosarSchemaVersion');
catch
    sAutosarVersion = '';
end
end


%%
function bIsExpFuncStyle = i_isExportedFunctionStyle(sModelName)
bIsExpFuncStyle = i_hasFuncCallInports(sModelName) || i_hasSLFunctions(sModelName);
end


%%
function bHasFuncCallInports = i_hasFuncCallInports(sModelName)
bHasFuncCallInports = ~isempty(ep_find_system(sModelName, ...
    'SearchDepth',        1, ...
    'BlockType',          'Inport', ...
    'OutputFunctionCall', 'on'));
end


%%
function bHasSLFuncs = i_hasSLFunctions(sModelName)
bHasSLFuncs = false;

casSubs = ep_find_system(sModelName, ...
    'SearchDepth',        1, ...
    'BlockType',          'SubSystem', ...
    'IsSubsystemVirtual', 'off');
for i = 1:numel(casSubs)
    if i_isSLFunction(casSubs{i})
        bHasSLFuncs = true;
        break;
    end
end
end


%%
function bIsSLFunc = i_isSLFunction(xSubsystem)
bIsSLFunc = ~isempty(ep_find_system(xSubsystem, ...
    'SearchDepth',        1, ...
    'BlockType',          'TriggerPort', ...
    'IsSimulinkFunction', 'on'));
end
