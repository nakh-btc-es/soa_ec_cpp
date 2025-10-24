function ep_simenv_logging_evaluate(xEnv, sTempDir, sAnalysisFile)
% Evaluates the logging results
%
% This method evaluates the logged values and stores them into mat files.
%
% function ep_simenv_logging_evaluate(xEnv, sTempDir, sAnalysisFile)
%
%   INPUTS               DESCRIPTION
%     xEnv               (object)     Environment object
%     sTempDir           (string)     full path to the temp dir of the mat
%                                     files
%     sAnalysisFile      (string)     full path file to analysis of logging
%   OUTPUT               DESCRIPTION
%     -                     -
%
%   REMARKS
%
%
%  REFERENCE(S):
%     Design Document:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%%
nExists = evalin('base','exist( ''et_logsout'', ''var'' );');
if( nExists ~= 1 )
    return;
end
sType = evalin('base', 'class(et_logsout)');
try
    % TODO check if the two methods can be merged
    if( strcmp( sType, 'Simulink.SimulationData.Dataset' ) )
        i_evalDataset(xEnv, sTempDir, sAnalysisFile);
    else
        i_evalModelDataLogs(xEnv, sTempDir, sAnalysisFile);
    end
catch e
    try evalin('base','clear et_logsout;'); catch end; %#ok
    xEnv.rethrowException(e);
end
end


%% i_evalDataset(xEnv, sAnalysisFile)
function i_evalDataset(xEnv, sTempDir, sAnalysisFile)
try
    xLoggingInfo = mxx_xmltree('load', sAnalysisFile );
    xLoggingAnalysis = mxx_xmltree('get_root', xLoggingInfo);
    sKind = mxx_xmltree('get_attribute', xLoggingAnalysis, 'kind');
    if( strcmp(sKind,'TL'))
        return; %TL logging not supported here
    end
    % Iterate over all subsystems
    ahSubsystem = mxx_xmltree('get_nodes', xLoggingAnalysis, '//Subsystem');
    for index = 1:length(ahSubsystem)
        xSubsystem = ahSubsystem(index);
        sSubId = mxx_xmltree('get_attribute', xSubsystem, 'id');
        sSubId = strrep(sSubId, '^', '');
        sSampleTime = mxx_xmltree('get_attribute', xSubsystem, 'sampleTime');
        ahStateLogger = mxx_xmltree('get_nodes', xSubsystem, './StateLogger');
        
        % Evaluate the StateLogger, if exists
        for i = 1:length(ahStateLogger)
            xLogging = ahStateLogger(i);
            sLogName = mxx_xmltree('get_attribute', xLogging, 'name');
            sEvalTrace = mxx_xmltree('get_attribute', xLogging, 'evaluate');
            
            sLogsAccess = sprintf('et_logsout.get(''%s'')',sLogName);
            oLogName = evalin('base', sLogsAccess);
            if( isempty( oLogName ) )
                sSubSystemLength = sprintf( 'btc_%s_length', sSubId );
                assignin('base', sSubSystemLength, -1);
            else
                if( isa( oLogName,  'Stateflow.SimulationData.Data') || ...
                        isa( oLogName,  'Simulink.SimulationData.Signal') )
                    bEvalTrace = strcmp(sEvalTrace,'1');
                    nSampleTime = str2double(sSampleTime);
                    oLogValue = oLogName.Values;
                    nLength = ep_simenv_statelogger_eval( ...
                        oLogValue, bEvalTrace, nSampleTime );
                    sSubSystemLength = sprintf( 'btc_%s_length', sSubId );
                    assignin('base', sSubSystemLength, nLength);
                else
                    sDisplayName = mxx_xmltree('get_attribute', ...
                        xLogging, 'displayName' );
                    xEnv.addMessage('ATGCV:SLAPI:LOGGING_STATE_LENGTH', ...
                        'name', sDisplayName);
                end
            end
        end
        
        % Evaluate the interfaces
        ahLogging = mxx_xmltree('get_nodes', xSubsystem, './Logging');
        for i = 1:length(ahLogging)
            xLogging = ahLogging(i);
            sLogName = mxx_xmltree('get_attribute', xLogging, 'name');
            sLogsAccess = sprintf('et_logsout.get(''%s'')',sLogName);
            oLogName = evalin('base', sLogsAccess);
            
            if( isempty( oLogName ) )
                ahAccess = mxx_xmltree('get_nodes', xLogging, 'child::Access');
                for j = 1:length(ahAccess)
                    xAccess = ahAccess(j);
                    sDisplayName = mxx_xmltree('get_attribute', xAccess, 'displayName' );
                    xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', ...
                        'name', sDisplayName);
                end
                continue;
            end
            if isa( oLogName, 'Simulink.SimulationData.Dataset')
                sLogPath = mxx_xmltree('get_attribute', xLogging, 'path');
                for j = 1:i_get_num_elements(oLogName)
                    if strcmp(oLogName.get(j).BlockPath.getBlock(1), sLogPath)
                        oLogName = oLogName.get(j);
                        break;
                    end
                end
            end
            if( isa( oLogName,  'Stateflow.SimulationData.Data') || ...
                    isa( oLogName,  'Simulink.SimulationData.Signal') )
                oValues = oLogName.Values;
                
                iStartIdx = i_getStateflowStartIdx(xLogging);
                
                ahAccess = mxx_xmltree('get_nodes', xLogging, 'child::Access');
                nAccessLength = length(ahAccess);
                for j = 1:nAccessLength
                    xAccess = ahAccess(j);
                    sIfId = mxx_xmltree('get_attribute', xAccess, 'ifid');
                    index1 = mxx_xmltree('get_attribute', xAccess, 'index1');
                    index2 = mxx_xmltree('get_attribute', xAccess, 'index2');
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
                                            xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', ...
                                                'name', sDisplayName );
                                        end
                                    end
                                end
                            end
                            anTime = oName.Time;
                            anData = oName.Data;
                        end
                    end
                    try
                        
                        % Special handling for the new logging format
                        % The case 'logging multiple data values for a given time step'
                        % is handled here.
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
                            nIndex1 = i_getIndex(str2double(index1), iStartIdx);
                            if( ~isempty( index2 ) )
                                nIndex2 = i_getIndex(str2double(index2), iStartIdx);
                                anData = anData(:, :, anTimeTmp);
                                tmpMatrix = anData(nIndex1, nIndex2, :);
                                adValues = reshape( tmpMatrix, [length(tmpMatrix) 1]);
                            else
                                anData= anData(anTimeTmp,:);
                                adValues = anData(:, nIndex1);
                            end
                        else
                            adValues = [];
                            sDisplayName = mxx_xmltree('get_attribute', ...
                                xAccess, 'displayName' );
                            xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', ...
                                'name', sDisplayName );
                        end
                        sMatFile = ep_simenv_values2mat(sTempDir, sIfId, adTimes, adValues);
                        mxx_xmltree('set_attribute', xAccess, 'matFile', sMatFile);
                    catch
                        sDisplayName = mxx_xmltree('get_attribute', ...
                            xAccess, 'displayName' );
                        xEnv.addMessage( ...
                            'ATGCV:SLAPI:LOGGING_WARNING', ...
                            'name', sDisplayName );
                        
                    end
                end
            end
        end
    end
    
    evalin('base','clear et_logsout;');
    
    ahMapping = mxx_xmltree('get_nodes', xLoggingAnalysis, '//Mapping');
    
    for i = 1:length(ahMapping)
        xMapping = ahMapping(i);
        sIfId = mxx_xmltree('get_attribute', xMapping, 'ifid');
        sIfIdRef = mxx_xmltree('get_attribute', xMapping, 'refid' );
        sName = mxx_xmltree('get_attribute', xMapping, 'name' );
        try
            oIfIdRef = evalin('base', ['i_',sIfIdRef]);
            dValue = oIfIdRef(1,2);
            sMatFile = ep_simenv_values2mat(sTempDir, sIfId, 0, dValue);
            hAccess = mxx_xmltree('add_node', xMapping, 'Access');
            mxx_xmltree('set_attribute', hAccess, 'ifid', sIfId);
            mxx_xmltree('set_attribute', hAccess, 'name', sName);
            mxx_xmltree('set_attribute', hAccess, 'matFile', sMatFile);
        catch
            xEnv.addMessage( ...
                'ATGCV:SLAPI:LOGGING_WARNING', ...
                'name', sName ) ;
        end
    end
    mxx_xmltree('save',xLoggingAnalysis, sAnalysisFile);
    mxx_xmltree('clear',xLoggingAnalysis);
catch e
    try
        mxx_xmltree('clear',xLoggingAnalysis);
    catch
    end
    rethrow(e);
end
end


%% i_evalModelDataLogs(xEnv, sAnalysisFile)
function i_evalModelDataLogs(xEnv, sTempDir, sAnalysisFile)
try
    xLoggingInfo = mxx_xmltree('load', sAnalysisFile );
    xLoggingAnalysis = mxx_xmltree('get_root', xLoggingInfo);
    sKind = mxx_xmltree('get_attribute', xLoggingAnalysis, 'kind');
    if( strcmp(sKind,'TL'))
        return; %TL logging not supported here
    end
    ahSubsystem = mxx_xmltree('get_nodes', xLoggingAnalysis, '//Subsystem');
    for index = 1:length(ahSubsystem)
        xSubsystem = ahSubsystem(index);
        sSubId = mxx_xmltree('get_attribute', xSubsystem, 'id');
        sSubId = strrep(sSubId, '^', '');
        sSampleTime = mxx_xmltree('get_attribute', xSubsystem, 'sampleTime');
        ahStateLogger = mxx_xmltree('get_nodes', xSubsystem, './StateLogger');
        for i = 1:length(ahStateLogger)
            xLogging = ahStateLogger(i);
            sLogName = mxx_xmltree('get_attribute', xLogging, 'name');
            sBlock = mxx_xmltree('get_attribute', xLogging, 'path');
            sPortNo = mxx_xmltree('get_attribute', xLogging, 'port');
            sEvalTrace = mxx_xmltree('get_attribute', xLogging, 'evaluate');
            
            bPort = ~isempty( sPortNo );
            sLogPath = i_logging_path_get(sBlock, sLogName, bPort);
            sLogsAccess = sprintf('et_logsout.%s',sLogPath);
            oLogName = evalin('base', sLogsAccess);
            if( isempty( oLogName ) )
                sSubSystemLength = sprintf( 'btc_%s_length', sSubId );
                assignin('base', sSubSystemLength, -1);
            else
                if( isa(oLogName,'Simulink.Timeseries') )
                    bEvalTrace = strcmp(sEvalTrace,'1');
                    nSampleTime = str2double(sSampleTime);
                    nLength = ep_simenv_statelogger_eval( oLogName, bEvalTrace, nSampleTime );
                    sSubSystemLength = sprintf( 'btc_%s_length', sSubId );
                    assignin('base', sSubSystemLength, nLength);
                    
                else
                    sDisplayName = mxx_xmltree('get_attribute', xLogging, 'displayName' );
                    xEnv.addMessage( ...
                        'ATGCV:SLAPI:LOGGING_STATE_LENGTH', ...
                        'name', sDisplayName );
                end
            end
        end
        ahLogging = mxx_xmltree('get_nodes', xSubsystem, './Logging');
        
        for i = 1:length(ahLogging)
            xLogging = ahLogging(i);
            sLogName = mxx_xmltree('get_attribute', xLogging, 'name');
            sBlock = mxx_xmltree('get_attribute', xLogging, 'path');
            sPortNo = mxx_xmltree('get_attribute', xLogging, 'port');
            bPort = ~isempty( sPortNo );
            sLogPath = i_logging_path_get(sBlock, sLogName, bPort);
            bValidPath = i_evalLogPath(sLogPath);
            sLogsAccess = sprintf('et_logsout.%s',sLogPath);
            if bValidPath
                oLogName = evalin('base', sLogsAccess);
            else
                % Logging not possible
                oLogName = [];
            end
            
            iStartIdx = i_getStateflowStartIdx(xLogging);

            if( isempty( oLogName ) )
                ahAccess = mxx_xmltree('get_nodes', xLogging, 'child::Access');
                for j = 1:length(ahAccess)
                    xAccess = ahAccess(j);
                    sDisplayName = mxx_xmltree('get_attribute', xAccess, 'displayName' );
                    xEnv.addMessage( ...
                        'ATGCV:SLAPI:LOGGING_WARNING', ...
                        'name', sDisplayName);
                end
                continue;
            end
            if( isa( oLogName, 'Simulink.Timeseries') )
                adTimes = oLogName.Time;
                
                anData = oLogName.Data;
                ahAccess = mxx_xmltree('get_nodes', xLogging, 'child::Access');
                for j = 1:length(ahAccess)
                    xAccess = ahAccess(j);
                    sIfId = mxx_xmltree('get_attribute', xAccess, 'ifid');
                    index1 = mxx_xmltree('get_attribute', xAccess, 'index1');
                    index2 = mxx_xmltree('get_attribute', xAccess, 'index2');
                    
                    try                       
                        if( isempty( index1 ) )
                            adValues = anData;
                        else
                            nIndex1 = i_getIndex(str2double(index1), iStartIdx);
                            if( ~isempty( index2 ) )
                                nIndex2 = i_getIndex(str2double(index2), iStartIdx);
                                tmpMatrix = anData(nIndex1, nIndex2, :);
                                adValues = reshape( tmpMatrix, [length(tmpMatrix) 1]);
                            else
                                adValues = anData(:, nIndex1);
                            end
                        end
                        
                        sMatFile = ep_simenv_values2mat(sTempDir, sIfId, ...
                            adTimes, adValues);
                        mxx_xmltree('set_attribute', xAccess, 'matFile', sMatFile);
                    catch
                        sDisplayName = mxx_xmltree('get_attribute', xAccess, 'displayName' );
                        xEnv.addMessage( ...
                            'ATGCV:SLAPI:LOGGING_WARNING', ...
                            'name', sDisplayName );
                        
                    end
                end
            else
                ahAccess = mxx_xmltree('get_nodes', xLogging, 'child::Access');
                for j = 1:length(ahAccess)
                    xAccess = ahAccess(j);
                    sIfId = mxx_xmltree('get_attribute', xAccess, 'ifid');
                    index1 = mxx_xmltree('get_attribute', xAccess, 'index1');
                    index2 = mxx_xmltree('get_attribute', xAccess, 'index2');
                    sSignalName = mxx_xmltree('get_attribute', xAccess, 'signalName' );
                    sDisplayName = mxx_xmltree('get_attribute', xAccess, 'displayName' );
                    
                    oLogName = evalin('base', sLogsAccess);
                    
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
                                if( ~isa(oLogName,'Simulink.Timeseries') )
                                    try
                                        oName = oLogName.(sField);
                                        oLogName = oName;
                                    catch
                                        xEnv.addMessage( ...
                                            'ATGCV:SLAPI:LOGGING_WARNING', ...
                                            'name', sDisplayName );
                                    end
                                end
                            end
                        end
                    end
                    
                    try
                        if( isa( oLogName, 'Simulink.Timeseries') )
                            anTime = oLogName.Time;
                            if( ~isempty( anTime ) ) % NOT LOGGED
                                adTimes = anTime;
                                
                                if( isempty( index1 ) )
                                    adValues = oLogName.Data;
                                else
                                    nIndex1 = i_getIndex(str2double(index1), iStartIdx);
                                    if( ~isempty( index2 ) )
                                        nIndex2 = i_getIndex(str2double(index2), iStartIdx);
                                        tmpMatrix  = oLogName.Data(nIndex1, nIndex2, :);
                                        adValues = reshape( tmpMatrix, [length(tmpMatrix) 1]);
                                    else
                                        adValues = oLogName.Data(:, nIndex1);
                                    end
                                end
                                sMatFile = ep_simenv_values2mat(sTempDir, sIfId, ...
                                    adTimes, adValues);
                                mxx_xmltree('set_attribute', xAccess, 'matFile', sMatFile);
                            end
                        end
                    catch
                        xEnv.addMessage( ...
                            'ATGCV:SLAPI:LOGGING_WARNING', ...
                            'name', sDisplayName );
                    end
                end
            end
        end
    end
    
    evalin('base','clear et_logsout;');
    
    ahMapping = mxx_xmltree('get_nodes', xLoggingAnalysis, '//Mapping');
    
    for i = 1:length(ahMapping)
        xMapping = ahMapping(i);
        sIfId = mxx_xmltree('get_attribute', xMapping, 'ifid');
        sIfIdRef = mxx_xmltree('get_attribute', xMapping, 'refid' );
        sName = mxx_xmltree('get_attribute', xMapping, 'name' );
        try
            
            oIfIdRef = evalin('base', ['i_',sIfIdRef]);
            dValue = oIfIdRef(1,2);
            sMatFile = ep_simenv_values2mat(sTempDir, sIfId, 0, dValue);
            hAccess = mxx_xmltree('add_node', xMapping, 'Access');
            mxx_xmltree('set_attribute', hAccess, 'ifid', sIfId);
            mxx_xmltree('set_attribute', hAccess, 'name', sName);
            mxx_xmltree('set_attribute', hAccess, 'matFile', sMatFile);
        catch
            xEnv.addMessage( ...
                'ATGCV:SLAPI:LOGGING_WARNING', ...
                'name', sName );
        end
    end
    mxx_xmltree('save',xLoggingAnalysis, sAnalysisFile);
    mxx_xmltree('clear',xLoggingAnalysis);
catch e
    
    try
        mxx_xmltree('clear',xLoggingAnalysis);
    catch
    end
    rethrow(e);
end
end


%%
function bValid = i_evalLogPath(sLogPath)
try
    sPathEvalRegex = '\(''([^'']+)''\)';
    casPathElements = regexp(sLogPath, sPathEvalRegex, 'tokens');
    casPathElements = [casPathElements{:}];
    
    bValid = true;
    sPath = 'et_logsout';
    if evalin('base', ['isempty(', sPath, ')'])
        bValid = false;
        return;
    end
    casWho = evalin('base', sprintf('%s.who', sPath));
    for i = 1:length(casPathElements)-1
        casWho = regexprep(casWho, '\(''|''\)', '');
        if ismember(casPathElements{i}, casWho)
            sPath = [sPath, '.(''', casPathElements{i}, ''')']; %#ok
            casWho = evalin('base', sprintf('%s.who', sPath));
            casWho = regexprep(casWho, '\(''|''\)', '');
        else
            bValid = false;
            return;
        end
    end
    if ~ismember(casPathElements{end}, casWho)
        bValid = false;
    end
catch
    % The logsout path/object is completely unexpected
    bValid = false;
end
end


%%
function sName = i_conform_sig_name( sSignal )
while( strcmp(sSignal(end), char(32) ) )
    if( length( sSignal ) > 1 )
        sSignal = sSignal(1:end-1);
    else
        break;
    end
end
while( strcmp(sSignal(1), char(32) ) )
    if( length( sSignal ) > 1 )
        sSignal = sSignal(2:end);
    else
        break;
    end
end
sName = sSignal;
end


%%
function sLogPath = i_logging_path_get(sBlock, sLogName, bPort)
sParent = get_param( sBlock, 'Parent' );
if( bPort )
    sLogPath = sprintf('(''%s'')',sLogName);
else
    sName = get_param( sBlock, 'Name' );
    sLogPath = sprintf('(''%s'').(''%s'')', ...
        i_conform_sig_name(sName), sLogName);
end
while( ~isempty(sParent) )
    sName = get_param( sParent, 'Name' );
    sParent = get_param( sParent, 'Parent' );
    if( ~isempty( sParent ) )
        sLogPath = sprintf('(''%s'').%s', ...
            i_conform_sig_name(sName), sLogPath);
    end
end
sLogPath = strrep(sLogPath, char(10) ,' ');
end


%%
function iStartIdx = i_getStateflowStartIdx(hLoggingNode)
iStartIdx = [];
sStartIdx = mxx_xmltree('get_attribute', hLoggingNode, 'startIdx');
if ~isempty(sStartIdx)
    iStartIdx = str2double(sStartIdx);
end
end


%%
function iIdx = i_getIndex(iIdx, iStartIdx)
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