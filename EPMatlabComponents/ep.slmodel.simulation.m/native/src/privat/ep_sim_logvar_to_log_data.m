function astLogData = ep_sim_logvar_to_log_data(xEnv, hSubsystem, oLogVar)
% Extracts and returns structured logging information from the logging variable in context of the provided subsystem.
%
% function astLogData = ep_sim_logvar_to_log_data(xEnv, hSubsystem, oLogVar)
%
%   INPUTS               DESCRIPTION
%     xEnv               (object)     Environment object
%     hSubsystem         (handle)     subsystem to be analyzed
%     oLogVar            (object)     the logging variable
%
%   OUTPUT               DESCRIPTION
%     astLogData          (struct)    Logged data of the given subsytem
% 


%%
astLogData = [];
if isempty(oLogVar)
    return;
end

sSampleTime = mxx_xmltree('get_attribute', hSubsystem, 'sampleTime');
dSampleTime = str2double(sSampleTime);

i_evaluate_state_logger(xEnv, hSubsystem, oLogVar);

ahLogging = mxx_xmltree('get_nodes', hSubsystem, './Logging');
for i = 1:length(ahLogging)
    oSimLogData = i_get_sim_log_data_object(xEnv, ahLogging(i), oLogVar);
    bIsStateflowData = isa(oSimLogData,  'Stateflow.SimulationData.Data');
    bIsSimulinkSignal = isa( oSimLogData,  'Simulink.SimulationData.Signal');
    if(bIsStateflowData || bIsSimulinkSignal)
        ahAccess = mxx_xmltree('get_nodes', ahLogging(i), 'child::Access');
        sKind = mxx_xmltree('get_attribute', ahLogging(i), 'kind');
        for j = 1:length(ahAccess)
            sId = mxx_xmltree('get_attribute', ahAccess(j), 'identifier');
            sType = mxx_xmltree('get_attribute', ahAccess(j), 'signalType');
            [adTime, adData] =  i_get_sim_log_values(xEnv, ahLogging(i), ahAccess(j), oSimLogData.Values);
            stLogData = ep_sim_log_data_struct(sId, sType, adTime, adData, bIsStateflowData, sKind, dSampleTime);
            astLogData = [astLogData, stLogData]; %#ok
        end
    end
end
astLogData = i_handle_mapping_nodes(xEnv, hSubsystem, astLogData, dSampleTime);
end


%%
function sName = i_conform_sig_name(sSignal)
% remove leading/trainling whitespaces and replace the internal ones with underscore
sName = strrep(strtrim(sSignal), ' ', '_');
end


%%
function iStartIdx = i_get_stateflow_start_idx(hLoggingNode)
iStartIdx = [];
sStartIdx = mxx_xmltree('get_attribute', hLoggingNode, 'startIdx');
if ~isempty(sStartIdx)
    iStartIdx = str2double(sStartIdx);
end
end


%%
function iIdx = i_get_Index(iIdx, iStartIdx)
if ~isempty(iStartIdx)
    iIdx = iIdx + 1 - iStartIdx;
end
end

%%
function iSize = i_get_num_elements(oLogName)
if atgcv_version_compare('ML8.0') >= 0
    iSize =oLogName.numElements;
else
    iSize = oLogName.getLength;
end
end

%%
function oSimLogData = i_get_sim_log_data_object(xEnv, hLogging, oLogVar)
sLogName = mxx_xmltree('get_attribute', hLogging, 'name');

oSimLogData = oLogVar.get(sLogName);
if isempty(oSimLogData)
    i_print_logging_warning(xEnv, hLogging);
else
    if isa(oSimLogData, 'Simulink.SimulationData.Dataset')
        sLogPath = mxx_xmltree('get_attribute', hLogging, 'path');
        sLogVirtualPath = mxx_xmltree('get_attribute', hLogging, 'virtualPath');
        oSimLogData = i_getLogSignalFromDataset(oSimLogData, sLogPath, sLogVirtualPath);
    end
end
end


%%
function i_print_logging_warning(xEnv, hLogging)
ahAccess = mxx_xmltree('get_nodes', hLogging, 'child::Access');
for j = 1:length(ahAccess)
    hAccess = ahAccess(j);
    sDisplayName = mxx_xmltree('get_attribute', hAccess, 'displayName' );
    xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName);
end
end


%%
function oLogSignal = i_getLogSignalFromDataset(oLogDataset, sLogPath, sLogVirtualPath)
oLogSignal = [];

for j = 1:oLogDataset.numElements
    oLogSignal = oLogDataset.getElement(j);
    [sPath, sVirtualPath] = i_getPathAndVirtualPathOfLoggedSignal(oLogSignal.BlockPath);
    if ~isempty(sLogVirtualPath)
        if strcmp(sVirtualPath, sLogVirtualPath)
            return;
        end
    else
        if strcmp(sPath, sLogPath)
            return;
        end
    end
end
end


%%
% evaluating class Simulink.SimulationData.BlockPath
function [sPath, sVirtualPath] = i_getPathAndVirtualPathOfLoggedSignal(oBlockPath)
sPath = oBlockPath.getBlock(1);
sVirtualPath = sPath;
for i = 2:oBlockPath.getLength()
    sPath = oBlockPath.getBlock(i);
    sVirtualPath = [sVirtualPath, i_removeModelNamePrefixOfPath(sPath)]; %#ok<AGROW>
end
end


%%
function sPathWithoutModelNamePrefix = i_removeModelNamePrefixOfPath(sPath)
if any(sPath == '/')
    % RegExp: at the start of the string every character before a path separator '/' is removed
    % Example: 'A/B/C' --> '/B/C'
    sPathWithoutModelNamePrefix = regexprep(sPath, '^[^/]*', '');
else
    sPathWithoutModelNamePrefix = '';
end
end


%%
function [anTime, anData] = i_get_sim_log_data_series(oValues, xAccess)
sSignalName = mxx_xmltree('get_attribute', xAccess, 'signalName' );
sDisplayName = mxx_xmltree('get_attribute', xAccess, 'displayName' );
if isa(oValues, 'timeseries')
    anTime = oValues.Time;
    anData = oValues.Data;
else
    oSignalValues = oValues;
    if( ~isempty( sSignalName ) )
        casSignalNames = {sSignalName};
        casBusNames = ep_simenv_busnames_get( casSignalNames );
        sBusName = casBusNames{1};
        sSignalAccess = ep_simenv_regexprep(sSignalName, sBusName, '');
        asSigParts = ep_simenv_strread(sSignalAccess, '.');
        nLengthParts = length(asSigParts);
        for iPart=1:nLengthParts
            sPart = asSigParts{iPart};
            if( ~isempty(sPart) ) % this happens for the first access
                sField = i_conform_sig_name( sPart );
                if( ~isa(oSignalValues,'timeseries') )
                    try
                        oName = oSignalValues.(sField);
                        oSignalValues = oName;
                    catch
                        xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName );
                    end
                end
            end
        end
        anTime = oName.Time;
        anData = oName.Data;
    end
end
end


%%
function [adTimes, adValues] = i_get_sim_log_values(xEnv, hLogging, hAccess, oSimLogDataValues)
try
    iStartIdx = i_get_stateflow_start_idx(hLogging);
    index1 = mxx_xmltree('get_attribute', hAccess, 'index1');
    index2 = mxx_xmltree('get_attribute', hAccess, 'index2');
    [anTime, anData] = i_get_sim_log_data_series(oSimLogDataValues, hAccess);
    
    % Special handling for the new logging format
    % The case 'logging multiple data values for a given time step' is handled here.
    anTimeTmp = [find((anTime(1:end-1) < anTime(2:end))'), length(anTime)]';
    anTime = unique(anTime);
    adTimes = anTime;
    if( isempty( index1 ) && ~isempty(anData) )
        if ndims(anData) > 2 %#ok
            adValues = anData(:,:,anTimeTmp);
        else
            adValues = anData(anTimeTmp,:);
        end
    elseif( ~isempty(anData) )
        nIndex1 = i_get_Index(str2double(index1), iStartIdx);
        if( ~isempty( index2 ) )
            nIndex2 = i_get_Index(str2double(index2), iStartIdx);
            anData = anData(:, :, anTimeTmp);
            tmpMatrix = anData(nIndex1, nIndex2, :);
            adValues = reshape( tmpMatrix, [length(tmpMatrix) 1]);
        else
            anData= anData(anTimeTmp,:);
            adValues = anData(:, nIndex1);
        end
    else
        adValues = [];
        sDisplayName = mxx_xmltree('get_attribute', hAccess, 'displayName' );
        xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName );
    end
catch
    adTimes = [];
    adValues = [];
    sDisplayName = mxx_xmltree('get_attribute', hAccess, 'displayName' );
    xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName );
end
end


%%
function i_evaluate_state_logger(xEnv, hSubsystem, oLogVar)
sSubId = mxx_xmltree('get_attribute', hSubsystem, 'id');
sSubId = strrep(sSubId, '^', '');
sSampleTime = mxx_xmltree('get_attribute', hSubsystem, 'sampleTime');
ahStateLogger = mxx_xmltree('get_nodes', hSubsystem, './StateLogger');

% Evaluate the StateLogger, if exists
for i = 1:length(ahStateLogger)
    hLogging = ahStateLogger(i);
    sLogName = mxx_xmltree('get_attribute', hLogging, 'name');
    sEvalTrace = mxx_xmltree('get_attribute', hLogging, 'evaluate');
    
    oSimLogData = oLogVar.get(sLogName);
    if( isempty( oSimLogData ) )
        sSubSystemLength = sprintf( 'btc_%s_length', sSubId );
        assignin('base', sSubSystemLength, -1);
    else
        if isa(oSimLogData, 'Simulink.SimulationData.Dataset')
            sLogPath = mxx_xmltree('get_attribute', hLogging, 'path');
            sLogVirtualPath = mxx_xmltree('get_attribute', hLogging, 'virtualPath');
            oSimLogData = i_getLogSignalFromDataset(oSimLogData, sLogPath, sLogVirtualPath);
        end
        if (isa(oSimLogData, 'Stateflow.SimulationData.Data') || isa(oSimLogData, 'Simulink.SimulationData.Signal'))
            bEvalTrace = strcmp(sEvalTrace, '1');
            nSampleTime = str2double(sSampleTime);
            oLogValue = oSimLogData.Values;
            nLength = ep_simenv_statelogger_eval(oLogValue, bEvalTrace, nSampleTime);
            sSubSystemLength = sprintf( 'btc_%s_length', sSubId );
            assignin('base', sSubSystemLength, nLength);
        else
            sDisplayName = mxx_xmltree('get_attribute', hLogging, 'displayName' );
            xEnv.addMessage('ATGCV:SLAPI:LOGGING_STATE_LENGTH', 'name', sDisplayName);
        end
    end
end
end


%%
function astValues = i_handle_mapping_nodes(xEnv, hSubsystem, astValues, dSampleTime)
ahMapping = mxx_xmltree('get_nodes', hSubsystem, './Mapping');
for i = 1:length(ahMapping)
    sId = mxx_xmltree('get_attribute', ahMapping(i), 'identifier');
    sType = mxx_xmltree('get_attribute', ahMapping(i), 'signalType');
    sIfIdRef = mxx_xmltree('get_attribute', ahMapping(i), 'refid' );
    sName = mxx_xmltree('get_attribute', ahMapping(i), 'name' );
    try
        oIfIdRef = evalin('base', ['i_', sIfIdRef]);
        dValue = oIfIdRef(1,2);
        stValues = ep_sim_log_data_struct(sId, sType, 0, dValue, false, 'Parameter', dSampleTime);
        astValues = [astValues, stValues]; %#ok
    catch oEx %#ok
        xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sName ) ;
    end
end
end