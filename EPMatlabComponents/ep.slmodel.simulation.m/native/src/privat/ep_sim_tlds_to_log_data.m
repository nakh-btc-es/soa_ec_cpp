function astLogData = ep_sim_tlds_to_log_data(xEnv, hLoggingSubsystemNode)
% Evaluate the TL TLDS database and transforms the logged signals into the struct logging format understood by mxx_mdf.
%
% function astLogData = ep_sim_tlds_to_log_data(xEnv, hLoggingSubsystemNode)
%
%   INPUT               DESCRIPTION
%     xEnv                   (obj)  Environment settings.
%     hLoggingSubsystemNode  (obj)  Subsystem node inside the LoggingAnalysis XML for which the TLDS signals shall be evaluated
%
%   OUTPUT              DESCRIPTION
%     astLogData         array of logging structs as required by MDF handling
%


%%
astLogData = [];

%%
if ~exist('tl_access_logdata', 'file')
    xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION');
    return;
end

sSimlabelTLDS = tl_access_logdata('GetLastSimulationLabel');
if isempty(sSimlabelTLDS)
    xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION');
    return;
end
i_simHandle('reset');

% NOTE: somewhere the cleanup should (maybe?) be done; 
% but not here, since we might still need the simlabel for further info
%oOnCleanupDeleteSim = onCleanup(@() tl_access_logdata('DeleteSimulation', stSimlabelTLDS));


dSampleTime = i_getSampleTime(hLoggingSubsystemNode);
ahLoggings = mxx_xmltree('get_nodes', hLoggingSubsystemNode, './Logging');
astLogData = i_arrayfun(@(h) i_evalLoggingData(xEnv, sSimlabelTLDS, dSampleTime, h), ahLoggings);
end


%%
function dSampleTime = i_getSampleTime(hSubNode)
sSampleTime = mxx_xmltree('get_attribute', hSubNode, 'sampleTime');
dSampleTime = str2double(sSampleTime);
end


%%
function axElem = i_cell2mat(caxElem)
caxElem(cellfun(@isempty, caxElem)) = []; % remove the empty elements from the cell array
if isempty(caxElem)
    axElem = [];
else
    nElem = numel(caxElem);
    axElem = reshape(caxElem{1}, 1, []);
    for i = 2:nElem
        axElem = [axElem, reshape(caxElem{i}, 1, [])]; %#ok<AGROW>
    end
end
end


%%
function astLogData = i_evalLoggingData(xEnv, sSimlabelTLDS, dSampleTime, hLoggingNode)
stLogObj = i_readLoggingNode(hLoggingNode);

ahAccess = mxx_xmltree('get_nodes', hLoggingNode, './Access');
astLogData = i_arrayfun(@(h) i_evalLoggingAccessData(xEnv, sSimlabelTLDS, dSampleTime, stLogObj, h), ahAccess);
end


%%
% note: this arrayfun function extends the normal one for a special use case
% --> resulting array elments have different sizes --> "UniformOutput" = false
% --> the resulting cell is merged into a simple array (before doing that, the empty elements are removed)
function axElemOut = i_arrayfun(hFunc, axElemIn)
caxElemOut = arrayfun(hFunc, axElemIn, 'uni', false);
axElemOut = i_cell2mat(caxElemOut);
end


%%
function stLogObj = i_readLoggingNode(hLoggingNode)
stLogObj = mxx_xmltree('get_attributes', hLoggingNode, '.', ...
    'kind', ...
    'block', ...
    'blockUsage', ...
    'startIdx', ...
    'stateflowVariable', ...
    'chart', ...
    'path', ...
    'module', ...
    'ddPath', ...
    'ddVarPath');

% note: replace startIdx by computed value
stLogObj.iStartIdx = 1; % default
if ~isempty(stLogObj.startIdx)
    stLogObj.iStartIdx = str2double(stLogObj.startIdx);
end
    
stLogObj = rmfield(stLogObj, {'startIdx'});
end



%%
function stLogData = i_evalLoggingAccessData(xEnv, sSimlabelTLDS, dSampleTime, stLogObj, hAccess)
stAccess = i_readAccessNode(hAccess, stLogObj.iStartIdx);
sDisplayName = stAccess.displayName;

if ~isempty(sSimlabelTLDS)
    try
        [adTimes, adValues] = i_getTimesAndValues(xEnv, sSimlabelTLDS, stLogObj, stAccess); 
        bSuccess = ~isempty(adTimes) &&  isequal(length(adTimes), length(adValues));
    catch
        bSuccess = 0;
    end
else
    bSuccess = 0;
end

if ~bSuccess
    % Empty arrays indicate, that the signal could not be logged successfully.
    adTimes = [];
    adValues = [];
end

bIsStateflowData = false;


% Note: The TLDS API is not always providing the values as "double", so the correct type name would be:
%          stAccess.signalType = class(axValues);
%       However, for now the "double" approach is working fine and can be kept until a better concept for the
%       TL-SIL and TL-PIL simulation is found.
%
stAccess.signalType = 'double';

stLogData = ep_sim_log_data_struct( ...
    stAccess.identifier, ...
    stAccess.signalType, ...
    adTimes, ...
    adValues, ...
    bIsStateflowData, ...
    stLogObj.kind, ...
    dSampleTime);
        
if ~bSuccess
    xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName);
end
end


%%
function stAccess = i_readAccessNode(hAccess, iStartIdx)
stAccess = mxx_xmltree('get_attributes', hAccess, '.', ...
    'identifier', ...
    'signalType', ...
    'displayName', ...
    'signalName', ...
    'index1', ...
    'index2');

% note: replace index1 and index2 by the effective index values (where the start index is considered)
[stAccess.iIdx1, stAccess.iIdx2] = i_getEffectiveIndices(iStartIdx, stAccess.index1, stAccess.index2);
stAccess = rmfield(stAccess, {'index1', 'index2'});
end


%%
function [iIdx1, iIdx2] = i_getEffectiveIndices(iStartIdx, sIdx1, sIdx2)
iIdx1 = [];
iIdx2 = [];
if ~isempty(sIdx1)
    iIdx1 = str2double(sIdx1) + 1 - iStartIdx;
    if ~isempty(sIdx2)
        iIdx2 = str2double(sIdx2) + 1 - iStartIdx;
    end
end
end


%%
function [adTimes, adValues] = i_getTimesAndValuesTLDS(stLogDataTLDS, iIdx1, iIdx2)
adTimes  = [];
adValues = [];

if ~isempty(stLogDataTLDS)
    stSigTLDS = stLogDataTLDS.signal;
    
    adTimes = stSigTLDS.t;
    values = stSigTLDS.y;
    
    if ~isempty(iIdx1)
        if ~isempty(iIdx2)
            adValues = values(iIdx1, iIdx2, :);
        else
            adValues = values(iIdx1, :);
        end
    else
        adValues = values;
    end
end
end


%%
function [adTimes, adValues] = i_getTimesAndValues(xEnv, stSimlabelTLDS, stLogObj, stAccess)
if strcmpi(stLogObj.kind, 'Parameter')
    [adTimes, adValues] = i_getTimesAndValuesParam(stLogObj, stAccess);
    if isempty(adValues)
        xEnv.addMessage('ATGCV:MIL_GEN:INTERNAL_ERROR', ...
            'script', mfilename(), ...
            'text',   sprintf('Value for "%s" could not be determined.', stAccess.identifier));
        
        %adTimes  = 0;
        %adValues = 0; % fake value; TODO: intermediate solution for EPDEV-56355; not sure if this is such a good idea
    end
else
    stLogDataTLDS = ep_simenv_tlds_get_logged_signal(stSimlabelTLDS, stLogObj.block, stAccess.signalName);
    [adTimes, adValues] = i_getTimesAndValuesTLDS(stLogDataTLDS, stAccess.iIdx1, stAccess.iIdx2);
end
end


%%
function [adTimes, adValues] = i_getTimesAndValuesParam(stLogObj, stAccess)
adTimes = [];
adValues = [];

dCalValue = [];
if ~isempty(stLogObj.stateflowVariable)
    hDDVar = i_findStateflowVar(stLogObj.ddVarPath, stLogObj.module, stLogObj.path, stLogObj.stateflowVariable);
    if ~isempty(hDDVar)
        nDDVarIndex = 0;
        sDDVarPath = dsdd('GetAttribute', hDDVar, 'path');
        dCalValue = i_evalCalDdvarData(sDDVarPath, nDDVarIndex, stAccess.iIdx1, stAccess.iIdx2);
    end
else
    if ~isempty(stLogObj.blockUsage)
        dCalValue = i_evalCalBlockData(stLogObj.block, stLogObj.blockUsage, stAccess.iIdx1, stAccess.iIdx2);
    end
end

% fallback solution if not found yet
if isempty(dCalValue)
    sDDPath = stLogObj.ddPath;
    sModel = i_getModel(stLogObj.path);
    sDDVarPath = i_getDDVarSubsysPath(sModel, sDDPath);
    if ~isempty(sDDVarPath) && dsdd('Exist', sDDVarPath)
        nDDVarIndex = 0;
        if ~isempty(sDDPath)
            nDDVarIndex = i_getActiveVariantIndexForReferencesWithAutorename(sDDPath);
        end
        dCalValue = i_evalCalDdvarData(sDDVarPath, nDDVarIndex, stAccess.iIdx1, stAccess.iIdx2);
    end
end

if ~isempty(dCalValue)
    adTimes  = 0;
    adValues = dCalValue;
end
end


%%
function sDDVarSubsysPath = i_getDDVarSubsysPath(sModel, sDDVarPoolPath)
sDDVarSubsysPath = '';

astRefs = tlFindDDReferences(sDDVarPoolPath, 'system', sModel);
for i = 1:numel(astRefs)
    stRef = astRefs(i);
    
    % use the first DD reference found
    if strcmp(stRef.objectKind, 'ddobject')
        sDDVarSubsysPath = stRef.object;
        break;
    end
end
end

%%
function sModel = i_getModel(sPath)
sParent = get_param(sPath, 'Parent');
if isempty(sParent)
    sModel = sPath;
else
    sModel = i_getModel(sParent);
end
end


%%
function iActiveIdx = i_getActiveVariantIndexForReferencesWithAutorename(sDdPath)
iActiveIdx = 0; % default index=0 if no active idx found

hDataVariant = dsdd('GetDataVariant', sDdPath);
if isempty(hDataVariant)
    return;
end

% NOTE: currently it's not possible to determine the correct instance of the VariantVariableRef
% pointing to exactly the CAL variant instance that was used by the code
% --> for now it's OK to use the first found one (because the Harness of EP is setting *all* instances
% to the same calibration value)
iActiveIdx = 1;
end


%%
function dValue = i_evalCalBlockData(sTLBlock, sTLBlockVariable, iIdx1, iIdx2)
dValue = [];

[simHandle, msgStruct] = i_simHandle('get');
if (~isempty(msgStruct) || isempty(simHandle))
    return;
end

[varInfo, msgStruct] = tlSimInterface('GetBlockVarAddr', simHandle, ...
    'TLBlock',         sTLBlock, ...
    'TLBlockVariable', sTLBlockVariable);
if (~isempty(msgStruct) || isempty(varInfo))
    return;
end

[adValues, msgStruct] = tlSimInterface('Read', simHandle, 'VarInfos', varInfo);
if isempty(msgStruct)
    dValue = i_getValuesVar(adValues, iIdx1, iIdx2);
end
end


%%
function dValue = i_evalCalDdvarData(sDDVarPath, nDDVarIndex, iIdx1, iIdx2)
dValue = [];

[simHandle, msgStruct] = i_simHandle('get');
if (~isempty(msgStruct) || isempty(simHandle))
    return;
end

iRenameIdx = [];
aiIdx = dsdd('GetAutoRenamePropertyIndices', sDDVarPath, 'VariantVariableRef');
if ~isempty(aiIdx)
    if (nDDVarIndex > 0) && (numel(aiIdx) >= nDDVarIndex)
        iRenameIdx = aiIdx(nDDVarIndex);
    else
        iRenameIdx = aiIdx(1);
    end
end

if ~isempty(iRenameIdx)
    hDDVar = dsdd('GetVariantVariableRef', sDDVarPath, iRenameIdx);
    if ~isempty(hDDVar)
        [varInfo, msgStruct] = tlSimInterface('GetDDVarAddr', simHandle, 'DDVariables', hDDVar);
    else
        return;
    end
else
    [varInfo, msgStruct] = tlSimInterface('GetDDVarAddr', simHandle, 'DDVariables', sDDVarPath);
end
if (~isempty(msgStruct) || isempty(varInfo))
    return;
end

[adValues, msgStruct] = tlSimInterface('Read', simHandle, 'VarInfos', varInfo);
if isempty(msgStruct)
    dValue = i_getValuesVar(adValues, iIdx1, iIdx2);
end
end


%%
function hDDVar = i_findStateflowVar(sDDChart, sModule, sChartPath, sStateflowVar)
hDDVar = [];
hDDChart = i_findChartDD(sDDChart, sModule, sChartPath);

if ~isempty(hDDChart)
    hDDBlockVar = i_findBlockVarInChart(hDDChart, sStateflowVar);
    if ~isempty(hDDBlockVar)
        hDDVar = dsdd('GetVariableRef', hDDBlockVar);
    end
end
end


%%
function hDDChart = i_findChartDD(sDDChart, sModule, sChartPath)
[bExist, hDDChart] = dsdd('Exist', sDDChart);
if bExist
    return;
end
hDDChart = [];

sDDRoot = ['//DD0/Subsystems/', sModule];
[bExist, hDDRoot] = dsdd('Exist', sDDRoot);
if bExist
    [~, sChartName] = fileparts(sChartPath);
    hDDChart = dsdd('Find', hDDRoot, ...
        'property', {'Name', 'BlockType', 'Value' 'Stateflow'}, ...
        'property', {'Name', 'BlockName', 'Value', sChartName});
    if ~isempty(hDDChart)
        if (numel(hDDChart) > 1)
            hDDChart = hDDChart(1); % taking the first found Chart! TODO: compare with sChartPath to find the correct one
        end
    end
end
end


%%
function hDDBlockVar = i_findBlockVarInChart(hDDChart, sVar)
hDDBlockVar = [];

hDDSfNodes = dsdd('GetStateflowNodes', hDDChart);
if ~isempty(hDDSfNodes)
    casNodes = {'Input', 'Output', 'BlockVariable'};
    for i = 1:length(casNodes)
        sCmd = ['Get', casNodes{i}, 'RefTarget'];
        hDDBlockVar = dsdd(sCmd, hDDSfNodes, sVar);
        if ~isempty(hDDBlockVar)
            return;
        end        
    end
end
end


%%
function adValues = i_getValuesVar(adValues, iIdx1, iIdx2)
if ~isempty(iIdx1)
    if ~isempty(iIdx2)
        adValues = adValues(iIdx1, iIdx2);
    else
        adValues = adValues(iIdx1);
    end
end
end


%%
function [simHandle, msgStruct] = i_simHandle(sCmd)
persistent p_simHandle;
persistent p_msgStruct;

switch sCmd
    case 'reset'
        [p_simHandle, p_msgStruct] = i_getSimHandle();
        simHandle = p_simHandle;
        msgStruct = p_msgStruct;
        
    case 'get'
        if (isempty(p_simHandle) && isempty(p_msgStruct))
            [simHandle, msgStruct] = i_simHandle('reset');
        else
            simHandle = p_simHandle;
            msgStruct = p_msgStruct;
        end
        
    otherwise
        error('ATGCV:INTERNAL:ERROR', 'Unknown command "%s".', sCmd);
end
end


%%
function [simHandle, msgStruct] = i_getSimHandle()
sBoardName = 'HostPC';
[simHandle, msgStruct] = tlSimInterface('ConnectToSimPlatform', 'BoardName', sBoardName);
end
