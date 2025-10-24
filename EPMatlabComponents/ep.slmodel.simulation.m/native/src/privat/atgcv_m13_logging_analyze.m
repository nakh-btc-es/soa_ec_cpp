function atgcv_m13_logging_analyze(stEnv, xSubsystem, nUsage, bFullLogging, hLoggingAnalysis, bBreakModelRefs)
% Analyze the logging for DISP variables and interface variables
%
% This method takes the ExtractionModel XML file to identify what should be
% logged in the extraction model. No logging annotations are added but the
% logging XML file is filled. This logging XML file is also used to derive
% the logged values from mat files for the logged signals. Everything that
% is added to the logging XML file will be logged and can be derived (but
% nothing else).
%
% function atgcv_m13_logging_analyze(stEnv, xSubsystem, nUsage, bFullLogging, hLoggingAnalysis)
%
%   INPUTS               DESCRIPTION
%     stEnv              (struct)     Environment
%     xSubsystem         (handle)     XML node subsystem.
%     nUsage             (integer)    1, if we handle a TargetLink model
%                                     2, if we handle a Simulink model
%                                        stored in result path.
%     bFullLogging       (boolean)    If subsystem logging shall be enabled
%     xLoggingAnalysis   (handle)     Logging analysis
%     iSub2RefConversion (number)     0 = no model reference conversion
%                                     1 = simple model reference conversion
%                                     2 = model reference conversion with one indirection


%%
sUidAttr = 'uid';
sIdAttr = 'id';

hTopSubsystemLog = mxx_xmltree('add_node', hLoggingAnalysis, 'Subsystem');

sId = ep_em_entity_attribute_get( xSubsystem, sUidAttr );
sSampleTime = ep_em_entity_attribute_get( xSubsystem, 'sampleTime' );

mxx_xmltree('set_attribute', hTopSubsystemLog, sIdAttr, sId);

mxx_xmltree('set_attribute', hTopSubsystemLog, 'sampleTime', sSampleTime);

jBlackListBlockPortKeys = i_getBlockPortsThatCannotBeLogged(atgcv_m13_object_block_get(xSubsystem, bBreakModelRefs));
i_analysis_display_objects(stEnv, xSubsystem, hTopSubsystemLog, jBlackListBlockPortKeys, bBreakModelRefs);

% now get all subsystems and evaluate the display and interface objects
if( bFullLogging )
    caxSubsystem = atgcv_m13_subsystem_children_get_all(xSubsystem);
    for i = 1:length(caxSubsystem)
        xSubSubsystem = caxSubsystem{i};
        
        sSubsystemLogging = mxx_xmltree('get_attribute', xSubSubsystem, 'subsystemLogging');
        % Extend this check by checking the value to decide if also
        % expected values shall be derived or not (EPDEV-37608).
        %
        % The current implementation takes any none empty string as a
        % marker to decide if the logging shall be activated for this
        % subsystem or not
        if isempty(sSubsystemLogging)
            continue;
        end
        
        xSubsystemLog = ep_em_entity_create(xSubsystem, 'Subsystem');
        hSubsystemLog = mxx_xmltree('add_node', hTopSubsystemLog, 'Subsystem');
        
        sId = ep_em_entity_attribute_get(xSubSubsystem, sUidAttr);
        sSampleTime = ep_em_entity_attribute_get(xSubSubsystem, 'sampleTime');
        
        ep_em_entity_attribute_set( xSubsystemLog, sUidAttr, sId);
        mxx_xmltree('set_attribute', hSubsystemLog, sIdAttr, sId);
        
        ep_em_entity_attribute_set( xSubsystemLog, 'sampleTime', sSampleTime);
        mxx_xmltree('set_attribute', hSubsystemLog, 'sampleTime', sSampleTime);
        i_add_statelogger(xSubSubsystem, xSubsystemLog, hSubsystemLog, bBreakModelRefs);
        
        i_analysis_display_objects(stEnv, xSubSubsystem, hSubsystemLog, jBlackListBlockPortKeys, bBreakModelRefs);
        
        i_analysis_input_port_objects(stEnv, xSubSubsystem, xSubsystemLog, nUsage, hSubsystemLog, jBlackListBlockPortKeys, bBreakModelRefs);
        
        i_analysis_output_port_objects(stEnv, xSubSubsystem, xSubsystemLog, nUsage, hSubsystemLog, jBlackListBlockPortKeys, bBreakModelRefs);
        
        i_analysis_calibration_objects(stEnv, xSubsystem, xSubSubsystem, xSubsystemLog, hSubsystemLog);
    end
end
end


%%
function jBlackListBlockPortKeys = i_getBlockPortsThatCannotBeLogged(sExtractionSubsystem)
jBlackListBlockPortKeys = java.util.HashSet;

astDrivingPortBlocks = ep_model_blocks_driving_merge_block_find(sExtractionSubsystem);
for i = 1:numel(astDrivingPortBlocks)
    stBlockPort = astDrivingPortBlocks(i);
    jBlackListBlockPortKeys.add(i_getBlockPortKey(stBlockPort.sBlockPath, stBlockPort.iPortNum));
end
end


%%
%**************************************************************************
% analysis for the calibration objects
%**************************************************************************
function i_analysis_calibration_objects(stEnv, xSubsystem, xSubSubsystem, xSubsystemLog, hSubsystemLog )
sSubsysPath = ep_em_entity_attribute_get( xSubSubsystem, 'path');

ahCalibribration = ep_em_entity_find( xSubSubsystem, 'child::Calibration');
for i = 1:length(ahCalibribration)
    hCalibration = ahCalibribration{i};
    i_map_calibration_objects( stEnv, hCalibration, xSubsystem,  xSubsystemLog, sSubsysPath, hSubsystemLog)
end
end

%%
function i_map_calibration_objects( stEnv, hCalibration, xSubsystem,  xSubsystemLog, sSubsysPath, hSubsystemLog)
ahIfName = ep_em_entity_find( hCalibration, './/ifName');
for i = 1:length(ahIfName)
    hIfName = ahIfName{i};
    i_map_ifname_object( stEnv, hIfName, hCalibration, xSubsystem,  xSubsystemLog, sSubsysPath, hSubsystemLog);
end
end

%%
function i_map_ifname_object( stEnv, hIfName, hCalibration, xSubsystem, xSubsystemLog, sSubsysPath, hSubsystemLog)
try
    sCalName = ep_em_entity_attribute_get(hCalibration, 'name');
    sCalPath = ep_em_entity_attribute_get(hCalibration, 'path');
    sName = atgcv_m13_display_name(hIfName);
    sIfId = ep_em_entity_attribute_get( hIfName, 'ifid');
    sIdentifier = ep_em_entity_attribute_get( hIfName, 'identifier');
    sSignalType = ep_em_entity_attribute_get( mxx_xmltree('get_nodes', hIfName, '..'), 'signalType' );
    
    
    sXpath = sprintf('./Calibration[@name="%s"]/Variable/ifName[@displayName="%s"]', sCalName, sName);
    ahIfNameCmp = ep_em_entity_find( xSubsystem, sXpath);
    
    if( isempty(ahIfNameCmp))
        sXpath = sprintf('./Calibration[@name="%s" and @path="%s"]/Variable/ifName', sCalName, sCalPath);
        ahIfNameCmp = ep_em_entity_find( xSubsystem, sXpath);
    end
    
    if( length(ahIfNameCmp) == 1 )
        xMapping = ep_em_entity_create( xSubsystemLog, 'Mapping');
        hMapping = mxx_xmltree('add_node', hSubsystemLog, 'Mapping');
        
        sIfIdRef = ep_em_entity_attribute_get( ahIfNameCmp{1}, 'ifid');
        ep_em_entity_attribute_set( xMapping, 'ifid', sIfId);
        mxx_xmltree('set_attribute', hMapping, 'ifid', sIfId);
        
        ep_em_entity_attribute_set( xMapping, 'refid', sIfIdRef);
        mxx_xmltree('set_attribute', hMapping, 'refid', sIfIdRef);
        
        ep_em_entity_attribute_set( xMapping, 'name', sName);
        mxx_xmltree('set_attribute', hMapping, 'name', sName);
        
        ep_em_entity_attribute_set( xMapping, 'identifier', sIdentifier);
        mxx_xmltree('set_attribute', hMapping, 'identifier', sIdentifier);
        
        ep_em_entity_attribute_set( xMapping, 'signalType', sSignalType);
        mxx_xmltree('set_attribute', hMapping, 'signalType', sSignalType);
        
    else
        stError = osc_messenger_add(stEnv, ...
            'ATGCV:MIL_GEN:CALIBRATION_LOGGING', ...
            'variable', sName, ...
            'subsystem', sSubsysPath );
        osc_throw(stError);
    end
catch
    stError = osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:CALIBRATION_LOGGING', ...
        'variable', sName, ...
        'subsystem', sSubsysPath );
    osc_throw(stError);
end
end

%**************************************************************************
% analysis for the display objects
%**************************************************************************
function i_analysis_display_objects(stEnv, hExtractionSub, hSubsystemLog, jBlackListBlockPortKeys, bBreakModelRefs)
nLogCounter = 0;
ahExtrDisplays = mxx_xmltree('get_nodes', hExtractionSub, './Display');
for i = 1:length(ahExtrDisplays)
    hExtrDisp = ahExtrDisplays(i);
    
    sDispBlockPath = atgcv_m13_object_block_get(hExtrDisp, bBreakModelRefs);
    sVirtualBlockPath = atgcv_m13_object_block_get(hExtrDisp, true);
    
    sVariableSF = mxx_xmltree('get_attribute', hExtrDisp, 'stateflowVariable');    
    sDispPortNo = mxx_xmltree('get_attribute', hExtrDisp, 'portNumber');
    bIsSFVariable = isempty(sDispPortNo);    
    if bIsSFVariable
        bFound = i_sf_analysis_logging(stEnv, sDispBlockPath, sVariableSF);
        
    else
        nDispPortNum = str2double(sDispPortNo);
        [bFound, sBlockForLogging, nPortNumForLogging] = i_analysis_logging(stEnv, sDispBlockPath, nDispPortNum);
        if bFound
            sBlockPortKey = i_getBlockPortKey(sBlockForLogging, nPortNumForLogging); 
            bIsForbiddenBlock = jBlackListBlockPortKeys.contains(sBlockPortKey);
            if bIsForbiddenBlock
                osc_messenger_add(stEnv, ...
                    'ATGCV:MIL_GEN:PORT_LOGGING', ...
                    'block', sDispBlockPath, ...
                    'port',  sDispPortNo);
                bFound = false;

            else
                % If the block marked as Display is not the same one that is being logged --> replace it here
                if ~strcmp(sBlockForLogging, sDispBlockPath)
                    sOldBlockName = get_param(sDispBlockPath, 'Name');
                    sNewBlockName = get_param(sBlockForLogging, 'Name');

                    sDispBlockPath = sBlockForLogging;
                    sVirtualBlockPath = [sVirtualBlockPath(1:end-numel(sOldBlockName)), sNewBlockName];
                end
            end
        end
    end
    
    if bFound
        hLogging = mxx_xmltree('add_node', hSubsystemLog, 'Logging');
        mxx_xmltree('set_attribute', hLogging, 'kind', 'Local');
        
        nLogCounter = nLogCounter + 1;
        sLogName = sprintf('btc_ld_%d', nLogCounter);
        mxx_xmltree('set_attribute', hLogging, 'name', sLogName);
        
        sID = char(java.util.UUID.randomUUID());        
        mxx_xmltree('set_attribute', hLogging, 'id', sID);
        
        sStartIdx = mxx_xmltree('get_attribute', hExtrDisp, 'startIdx');
        if ~isempty(sStartIdx)
            mxx_xmltree('set_attribute', hLogging, 'startIdx', sStartIdx);
        end
        
        mxx_xmltree('set_attribute', hLogging, 'path', sDispBlockPath);
        mxx_xmltree('set_attribute', hLogging, 'virtualPath', sVirtualBlockPath);
        if isempty(sVariableSF)
            mxx_xmltree('set_attribute', hLogging, 'port', num2str(nPortNumForLogging));
        else
            mxx_xmltree('set_attribute', hLogging, 'stateflowVariable', sVariableSF);
        end
        
        ahIfName = mxx_xmltree('get_nodes', hExtrDisp, './/ifName');
        for j = 1:length(ahIfName)
            hIfName = ahIfName(j);
            sIfId = ep_em_entity_attribute_get( hIfName, 'ifid');
            hAccess = mxx_xmltree('add_node', hLogging, 'Access');
            
            sIndex1 = ep_em_entity_attribute_get( hIfName, 'index1');
            sIndex2 = ep_em_entity_attribute_get( hIfName, 'index2');
            
            mxx_xmltree('set_attribute', hAccess, 'ifid', sIfId);
            
            
            xVariable = ep_em_entity_find_first(hIfName,'parent::Variable');
            sSignalName = ep_em_entity_attribute_get( xVariable, 'signalName' );
            sDisplayName = atgcv_m13_display_name( hIfName );
            sIdentifier = ep_em_entity_attribute_get( hIfName, 'identifier');
            hVarNode = mxx_xmltree('get_nodes', hIfName, '..');
            sSignalType = ep_em_entity_attribute_get( hVarNode, 'signalType');
            mxx_xmltree('set_attribute', hAccess, 'displayName', sDisplayName);
            mxx_xmltree('set_attribute', hAccess, 'identifier', sIdentifier);
            mxx_xmltree('set_attribute', hAccess, 'signalType', sSignalType);
            if( ~isempty( sIndex1 ) )
                mxx_xmltree('set_attribute', hAccess, 'index1', sIndex1);
            end
            if( ~isempty( sIndex2 ) )
                mxx_xmltree('set_attribute', hAccess, 'index2', sIndex2);
            end
            if( ~isempty( sSignalName ) )
                mxx_xmltree('set_attribute', hAccess, 'signalName', sSignalName);
            else
                try
                    if (~isempty(sDispPortNo) && i_isSubsysBlock(sDispBlockPath))
                        casOutports = ep_find_system( sDispBlockPath, ...
                            'LookUnderMasks','on', ...
                            'Parent', sDispBlockPath, ...
                            'BlockType', 'Outport', ...
                            'Port', sDispPortNo );
                        if( ~isempty( casOutports ) )
                            sName = get_param( casOutports{1},'Name');
                            ep_em_entity_attribute_set( xAccess, 'signalName', sName);
                            mxx_xmltree('set_attribute', hAccess, 'signalName', sName);
                        end
                    end
                catch
                end
            end
        end
    end
end
end


%%
function sBlockPortKey = i_getBlockPortKey(sRealBlockPath, iPortNum)
sBlockPortKey = sprintf('%s:%d', sRealBlockPath, iPortNum);
end


%%
function bIsSub = i_isSubsysBlock(sBlock)
bIsSub = i_hasPropEqual(sBlock, 'Type', 'block') && i_hasPropEqual(sBlock, 'BlockType', 'SubSystem');
end


%%
function bHasProp = i_hasPropEqual(sBlock, sPropName, sPropValue)
bHasProp = false;
try
    bHasProp = strcmpi(get_param(sBlock, sPropName), sPropValue);
catch
end
end

%% function i_add_statelogger
function i_add_statelogger(xSubsystem, xSubsystemLog, hSubsystemLog, bBreakModelRefs)

sSubsystemPath = atgcv_m13_object_block_get(xSubsystem, bBreakModelRefs);
sSubsystemVirtualPath = atgcv_m13_object_block_get(xSubsystem, true);

hSub = get_param(sSubsystemPath, 'Handle' );

cahTriggerPorts = ep_find_system( hSub,...
    'FollowLinks', 'off', ...
    'SearchDepth', 1,...
    'BlockType',   'TriggerPort');

sName = 'btc_state_logger';
[hLogger, sLoggerBlock, nPort] = atgcv_m13_logger_state_create(hSub, sName);
sRelPath = sLoggerBlock(length(sSubsystemPath)+1:end);
sLoggerBlockVirtualPath = [sSubsystemVirtualPath, sRelPath];

x = 500;
y = 10;
anPosition = [ x y x+25 y+12];
set_param( hLogger, 'Position', anPosition );
xLogging = ep_em_entity_create( xSubsystemLog, 'StateLogger');
hLogging = mxx_xmltree('add_node', hSubsystemLog, 'StateLogger');

bEvaluateTrace = ~isempty(cahTriggerPorts);
ep_em_entity_attribute_set( xLogging, 'evaluate', num2str(bEvaluateTrace));
mxx_xmltree('set_attribute', hLogging, 'evaluate', num2str(bEvaluateTrace));

ep_em_entity_attribute_set( xLogging, 'path', sLoggerBlock);
mxx_xmltree('set_attribute', hLogging, 'path', sLoggerBlock);
ep_em_entity_attribute_set( xLogging, 'virtualPath', sLoggerBlockVirtualPath);
mxx_xmltree('set_attribute', hLogging, 'virtualPath', sLoggerBlockVirtualPath);
ep_em_entity_attribute_set( xLogging, 'port', num2str(nPort));
mxx_xmltree('set_attribute', hLogging, 'port', num2str(nPort));
ep_em_entity_attribute_set( xLogging, 'displayName', sLoggerBlock);
mxx_xmltree('set_attribute', hLogging, 'displayName', sLoggerBlock);
ep_em_entity_attribute_set( xLogging, 'name', sName);
mxx_xmltree('set_attribute', hLogging, 'name', sName);
end

%% function i_analysis_output_port_objects
function i_analysis_output_port_objects(stEnv, xSubsystem, xSubsystemLog, nUsage, hSubsystemLog, jBlackListBlocks, bBreakModelRefs)


ahPort = ep_em_entity_find( xSubsystem, 'child::OutPort | child::DataStoreWrite');

for i = 1:length(ahPort)
    hPort = ahPort{i};
    bIsBusPort = atgcv_m13_isbusport( hPort );
    
    sName = ep_em_entity_attribute_get(hPort, 'name');
    sBlock = i_get_extraction_port_path(xSubsystem, hPort, bBreakModelRefs);
    
    if( isempty( sBlock ) && (nUsage==2) )
        % Note: When the sVarFullName is empty, the model analysis does not contain
        % any path information about the simulink block. This means the block is not available
        % in the Original Simulink Model.
        continue;
    end
    
    sPortNo = ep_em_entity_attribute_get( hPort, 'portNumber');
    nPort = str2double( sPortNo );
    [bFound, sBlockForLogging, nPortForLogging] = i_analysis_outport_logging(stEnv, sBlock, nPort);
    if bFound
        sBlockPortKey = i_getBlockPortKey(sBlockForLogging, nPortForLogging); 
        bIsForbiddenBlock = jBlackListBlocks.contains(sBlockPortKey);
        if bIsForbiddenBlock
            bFound = false;
        end
        
        if (~bIsBusPort && bFound)
            [bFound, sBlockForLogging, nPortForLogging] = ...
                i_analysis_outport_in_logging(stEnv, sBlockForLogging, nPortForLogging, sName);
        end
    end
    
    
    if( bFound )
        ahIfName = ep_em_entity_find( hPort, './/ifName');
        xLogging = ep_em_entity_create( xSubsystemLog, 'Logging');
        hLogging = mxx_xmltree('add_node', hSubsystemLog, 'Logging');
        mxx_xmltree('set_attribute', hLogging, 'kind', 'Output');
        
        ep_em_entity_attribute_set( xLogging, 'visit', '0');
        mxx_xmltree('set_attribute', hLogging, 'visit', '0');
        ep_em_entity_attribute_set( xLogging, 'path', sBlockForLogging);
        mxx_xmltree('set_attribute', hLogging, 'path', sBlockForLogging);
        
        ep_em_entity_attribute_set( xLogging, 'name', strrep(sName, char(10), '_'));
        mxx_xmltree('set_attribute', hLogging, 'name', strrep(sName, char(10), '_'));
        
        ep_em_entity_attribute_set( xLogging, 'port', num2str(nPortForLogging));
        mxx_xmltree('set_attribute', hLogging, 'port', num2str(nPortForLogging));
        sID = char(java.util.UUID.randomUUID());
        ep_em_entity_attribute_set( xLogging, 'id', sID);
        mxx_xmltree('set_attribute', hLogging, 'id', sID);
        
        for j = 1:length(ahIfName)
            hIfName = ahIfName{j};
            sIfId = ep_em_entity_attribute_get( hIfName, 'ifid');
            xAccess = ep_em_entity_create( xLogging, 'Access');
            hAccess = mxx_xmltree('add_node', hLogging, 'Access');
            
            sIndex1 = ep_em_entity_attribute_get( hIfName, 'index1');
            sIndex2 = ep_em_entity_attribute_get( hIfName, 'index2');
            
            ep_em_entity_attribute_set( xAccess, 'ifid', sIfId);
            mxx_xmltree('set_attribute', hAccess, 'ifid', sIfId);
            
            xVariable = ep_em_entity_find_first(hIfName,'parent::Variable');
            sSignalName = ep_em_entity_attribute_get( xVariable, 'signalName' );
            sDisplayName = atgcv_m13_display_name( hIfName );
            sIdentifier = ep_em_entity_attribute_get( hIfName, 'identifier' );
            hVar = mxx_xmltree('get_nodes', hIfName, '..');
            sSignalType = ep_em_entity_attribute_get( hVar, 'signalType' );
            ep_em_entity_attribute_set( xAccess, 'displayName', sDisplayName);
            mxx_xmltree('set_attribute', hAccess, 'displayName', sDisplayName);
            ep_em_entity_attribute_set( xAccess, 'identifier', sIdentifier);
            ep_em_entity_attribute_set( hAccess, 'identifier', sIdentifier);
            ep_em_entity_attribute_set( xAccess, 'signalType', sSignalType);
            ep_em_entity_attribute_set( hAccess, 'signalType', sSignalType);
            if( ~isempty( sIndex1 ) )
                ep_em_entity_attribute_set( xAccess, 'index1', sIndex1);
                mxx_xmltree('set_attribute', hAccess, 'index1', sIndex1);
            end
            if( ~isempty( sIndex2 ) )
                ep_em_entity_attribute_set( xAccess, 'index2', sIndex2);
                mxx_xmltree('set_attribute', hAccess, 'index2', sIndex2);
            end
            if( ~isempty( sSignalName ) )
                ep_em_entity_attribute_set( xAccess, 'signalName', sSignalName);
                mxx_xmltree('set_attribute', hAccess, 'signalName', sSignalName);
            end
        end
    end
end
end

%% function i_analysis_input_port_objects
function i_analysis_input_port_objects(stEnv, xSubsystem, xSubsystemLog, nUsage, hSubsystemLog, jBlackListBlocks, bBreakModelRefs)


ahPort = ep_em_entity_find( xSubsystem, 'child::InPort | child::DataStoreRead');

for i = 1:length(ahPort)
    hPort = ahPort{i};
    bIsBusPort = atgcv_m13_isbusport( hPort );
    
    sName = ep_em_entity_attribute_get(hPort, 'name');
    sBlock = i_get_extraction_port_path(xSubsystem, hPort, bBreakModelRefs);
    
    if( isempty( sBlock ) && (nUsage==2) )
        % Note: when the sVarFullName is empty, the
        % model anaylsis does not contain
        % any path information about the simulink block
        % This means the block is not available
        % in the Original Simulink Model
        continue;
    end
    if( bIsBusPort )
        bFound = true;
        sFoundBlock = sBlock;
        nFoundPort = 1;
    else
        nPort = 1; % inport blocks have only one single output
        sBlockPortKey = i_getBlockPortKey(sBlock, nPort); 
        bIsForbiddenBlock = jBlackListBlocks.contains(sBlockPortKey);
        if bIsForbiddenBlock
            bFound = false;
        else
            [bFound, sFoundBlock, nFoundPort] = i_analysis_inport_logging(stEnv, sBlock);
        end
    end
    
    
    if( bFound )
        ahIfName = ep_em_entity_find( hPort, './/ifName');
        xLogging = ep_em_entity_create( xSubsystemLog, 'Logging');
        hLogging = mxx_xmltree('add_node', hSubsystemLog, 'Logging');
        mxx_xmltree('set_attribute', hLogging, 'kind', 'Input');
        
        ep_em_entity_attribute_set( xLogging, 'visit', '0');
        mxx_xmltree('set_attribute', hLogging, 'visit', '0');
        ep_em_entity_attribute_set( xLogging, 'path', sFoundBlock);
        mxx_xmltree('set_attribute', hLogging, 'path', sFoundBlock);
        ep_em_entity_attribute_set( xLogging, 'port', num2str(nFoundPort));
        mxx_xmltree('set_attribute', hLogging, 'port', num2str(nFoundPort));
        ep_em_entity_attribute_set( xLogging, 'name', strrep(sName, char(10), '_'));
        mxx_xmltree('set_attribute', hLogging, 'name', strrep(sName, char(10), '_'));
        
        sID = char(java.util.UUID.randomUUID());
        ep_em_entity_attribute_set( xLogging, 'id', sID);
        mxx_xmltree('set_attribute', hLogging, 'id', sID);
        
        for j = 1:length(ahIfName)
            hIfName = ahIfName{j};
            sIfId = ep_em_entity_attribute_get( hIfName, 'ifid');
            xAccess = ep_em_entity_create( xLogging, 'Access');
            hAccess = mxx_xmltree('add_node', hLogging, 'Access');
            
            sIndex1 = ep_em_entity_attribute_get( hIfName, 'index1');
            sIndex2 = ep_em_entity_attribute_get( hIfName, 'index2');
            
            ep_em_entity_attribute_set( xAccess, 'ifid', sIfId);
            mxx_xmltree('set_attribute', hAccess, 'ifid', sIfId);

            sIdentifier = ep_em_entity_attribute_get( hIfName, 'identifier');
            ep_em_entity_attribute_set( xAccess, 'identifier', sIdentifier);
            mxx_xmltree('set_attribute', hAccess, 'identifier', sIdentifier);

            sSignalType = ep_em_entity_attribute_get( mxx_xmltree('get_nodes', hIfName, '..'), 'signalType' );
            ep_em_entity_attribute_set( xAccess, 'signalType', sSignalType);
            ep_em_entity_attribute_set( hAccess, 'signalType', sSignalType);
            
            xVariable = ep_em_entity_find_first(hIfName,'parent::Variable');
            sSignalName = ep_em_entity_attribute_get( xVariable, 'signalName' );
            sDisplayName = atgcv_m13_display_name( hIfName );
            ep_em_entity_attribute_set( xAccess, 'displayName', sDisplayName);
            mxx_xmltree('set_attribute', hAccess, 'displayName', sDisplayName);
            if( ~isempty( sIndex1 ) )
                ep_em_entity_attribute_set( xAccess, 'index1', sIndex1);
                mxx_xmltree('set_attribute', hAccess, 'index1', sIndex1);
            end
            if( ~isempty( sIndex2 ) )
                ep_em_entity_attribute_set( xAccess, 'index2', sIndex2);
                mxx_xmltree('set_attribute', hAccess, 'index2', sIndex2);
            end
            if( ~isempty( sSignalName ) )
                ep_em_entity_attribute_set( xAccess, 'signalName', sSignalName);
                mxx_xmltree('set_attribute', hAccess, 'signalName', sSignalName);
            end
        end
    end
end
end


%% function i_get_extraction_model_path
function sExtractionPortPath = i_get_extraction_port_path(xSubsystem, xPort, bBreakModelRefs)
bHasPath = ~isempty(ep_em_entity_attribute_get(xPort, 'path'));
if bHasPath
   sExtractionPortPath = atgcv_m13_object_block_get(xPort, bBreakModelRefs);
else
   sSubsystemPath = atgcv_m13_object_block_get(xSubsystem, bBreakModelRefs);
   sExtractionPortPath = [sSubsystemPath, '/', ep_em_entity_attribute_get(xPort, 'name')];
end
end


%%
%**************************************************************************
% analysis the logging for state flow entities
%**************************************************************************
function bFound = i_sf_analysis_logging(stEnv, sStateChart, stateflowVariable)
bFound = false;
sp = get_param(sStateChart, 'AvailSigsInstanceProps');
if strcmp(sp.Type, 'Stateflow')
    if ~isempty(get(sp, 'Signals'))
        for i = 1 : sp.Signals.length
            if strcmp(sp.Signals(i).SigName, stateflowVariable) 
                bFound = true;
                break;
            end
        end
    end
end
if ~bFound
    osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:STATEFLOW_LOGGING', ...
        'sfVariable', stateflowVariable, ...
        'chart', sStateChart);
end
end


%%
function [bFound, sFoundBlock, nFoundPort] = i_analysis_logging(stEnv, sBlock, nPort)
bFound = false;
sFoundBlock = sBlock;
nFoundPort = nPort;

try
    % special treatment for Outports --> Use the corresponding Port of the Source block
    if strcmp(get_param(sBlock, 'BlockType'), 'Outport')
        [sSrcBlock, nSrcPort] = i_getSrcBlockOfOutportBlock(sBlock);
        
        if ~isempty(sSrcBlock)
            [bFound, sFoundBlock, nFoundPort] = i_analysis_logging(stEnv, sSrcBlock, nSrcPort);
        end
    else
        stPorts = get_param(sBlock, 'PortHandles');
        bFound = (length(stPorts.Outport) >= nPort);
    end
catch oEx
    % this can happen when some blocks do not support logging or when nPort or block does not exists
    stError = osc_messenger_add(stEnv, 'ATGCV:MIL_GEN:PORT_LOGGING', 'block', sBlock, 'port', num2str(nPort));
    osc_throw(stError);
end
end


%%
% return the block path and port number of the block connected to the outport block
function [sSrcBlock, nSrcPort] = i_getSrcBlockOfOutportBlock(xOutportBlock)

% find the needed src connection
stPortCon = get_param(xOutportBlock, 'PortConnectivity');
if isempty(stPortCon.SrcBlock) || (stPortCon.SrcBlock == -1)
    % outport block is not connected to anything
    sSrcBlock = '';
    nSrcPort = [];
else
    sSrcBlock = getfullname(stPortCon.SrcBlock);
    nSrcPort = stPortCon.SrcPort + 1;
end
end


%%
function [bFound, sFoundBlock, nFoundPort] = i_analysis_outport_in_logging(stEnv, sBlock, nPort, sBlockToBeLogged)
bFound = false;
try
    sBlockName = get_param( sBlock, 'Name');
    ports = get_param( sBlock,'PortHandles');
    hPort = ports.Outport(nPort);
    anOrgPos = get_param( hPort, 'Position' );
    sParent = get_param( sBlock, 'Parent');
    hDestBlock = get_param( sParent, 'Handle');
    sName = sprintf( 'btc_%s_%s_%s_log', strrep(sBlockName, char(10), '_'), num2str(nPort), sBlockToBeLogged );
    [hLogger,sFoundBlock,nFoundPort] = ...
        atgcv_m13_logger_create(hDestBlock, sName);
    x = anOrgPos(1)+ 15;
    y = anOrgPos(2)- 15;
    if( y < 0 )
        y = 10;
    end
    anPosition = [ x y x+25 y+12];
    set_param( hLogger, 'Position', anPosition );
    atgcv_m13_add_line( sParent, sBlockName, nPort, sName, 1);
    bFound = true;
catch
    % this can happen when some blocks does not support logging or when nPort or block does not exists
    stError = osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:PORT_LOGGING', ...
        'block', sBlock, ...
        'port', num2str(nPort) );
    osc_throw(stError);
end
end

%%
function [bFound, sFoundBlock, nFoundPort] = i_analysis_outport_logging(stEnv, sBlock, nPort)
bFound = false;
sFoundBlock = sBlock;
nFoundPort = nPort;
try
    stPort = get_param( sBlock, 'PortHandles');
    hInport = stPort.Inport;
    hOutportLine = get_param( hInport, 'Line' );
    hBlock = get_param( hOutportLine, 'SrcBlockHandle' );
    stLineHandles = get_param( hBlock, 'LineHandles');
    ahOutputs = stLineHandles.Outport;
    for nPortIndex = 1:length(ahOutputs)
        hSourceLine = ahOutputs(nPortIndex);
        bFound = i_is_same_edge(hSourceLine, hOutportLine);
        if bFound
            sFoundBlock = getfullname( hBlock );
            nFoundPort = nPortIndex;
            break;
        end
    end
catch
    % this can happen when some blocks does not support logging
    % or when nPort or block does not exists
    stError = osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:PORT_LOGGING', ...
        'block', sBlock, ...
        'port', num2str(nPort) );
    osc_throw(stError);
end
end

%%
function bFound = i_is_same_edge(hSourceLine, hTargetLine)
bFound = false;

if( isequal( hSourceLine, hTargetLine ) )
    bFound = true;
else
    ahLineChildren = get_param(hSourceLine,'LineChildren');
    for i=1:length(ahLineChildren)
        bFound = i_is_same_edge(ahLineChildren(i), hTargetLine);
        if bFound
            break;
        end
    end
end
end

%%
function [bFound, sFoundBlock, nFoundPort] = i_analysis_inport_logging(stEnv, sBlock)
bFound = false;
try
    sBlockName = get_param( sBlock, 'Name');
    ports = get_param( sBlock,'PortHandles');
    hPort = ports.Outport(1);
    anOrgPos = get_param( hPort, 'Position' );
    sParent = get_param( sBlock, 'Parent');
    hDestBlock = get_param( sParent, 'Handle');
    sName = sprintf( 'btc_%s_log', strrep(sBlockName, char(10), '_') );
    [hLogger, sFoundBlock, nFoundPort] = atgcv_m13_logger_create(hDestBlock, sName);
    x = anOrgPos(1)+ 15;
    y = anOrgPos(2)- 15;
    if( y < 0 )
        y = 10;
    end
    anPosition = [ x y x+25 y+12];
    set_param( hLogger, 'Position', anPosition );
    atgcv_m13_add_line( sParent, sBlockName, 1, sName, 1);
    bFound = true;
    
catch
    % this can happen when some blocks does not support logging or when nPort or block does not exists
    stError = osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:PORT_LOGGING', ...
        'block', sBlock, ...
        'port', num2str(1) );
    osc_throw(stError);
end
end
