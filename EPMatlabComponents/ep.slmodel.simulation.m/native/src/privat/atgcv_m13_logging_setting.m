function atgcv_m13_logging_setting(stEnv, xLoggingAnalysis)
% Setting of the logging for DISP variables and interface variables
%
% This method creates the logging annotations in the extraction model
% according to the logging XML file for state logger (one for each scope)
% and logger for each port.
%
% function atgcv_m13_logging_setting(stEnv, xLoggingAnalysis, bEnableTLLogging)
%
%   INPUTS               DESCRIPTION
%     stEnv              (struct)     Environemnt
%     xLoggingAnalysis   (handle)     Logging analysis
%     bEnableTLLogging   (bool)       Enable TL Logging mode
%   OUTPUT               DESCRIPTION
%     -                     -
%


%%
ahLogging = ep_em_entity_find( xLoggingAnalysis, '//Logging');
i_logging_setting(stEnv, ahLogging);

ahStatelogger = ep_em_entity_find(xLoggingAnalysis, '//StateLogger');
i_logging_setting(stEnv, ahStatelogger);
end


%%
function i_logging_setting(stEnv, ahLogging)
for i = 1:length(ahLogging)
    xLogging = ahLogging{i};
    sLogName = ep_em_entity_attribute_get(xLogging, 'name');
    sBlock = ep_em_entity_attribute_get(xLogging, 'path');
    sPortNo = ep_em_entity_attribute_get(xLogging, 'port');
    stateflowVariable = ep_em_entity_attribute_get(xLogging, 'stateflowVariable');
    
    if( isempty( sPortNo ) )%SF-Variable
        i_sf_enable_logging(sBlock, stateflowVariable, sLogName);
    else
        %port assumed
        nPort = str2double(sPortNo);
        ports = get_param(sBlock, 'PortHandles');
        
        % Check if logging name is already defined by
        % corresponding port (direct connection)
        sMode = get_param( ports.Outport(nPort), 'DataLoggingNameMode');
        sLogging = get_param( ports.Outport(nPort), 'DataLogging');
        if strcmp(sLogging, 'on') && strcmp(sMode, 'Custom')
            % Custom logging is already set
            % If the inport is directly connected to the outport the
            % logging is defined for both with the same name (identity)
            sName = get_param( ports.Outport(nPort),'DataLoggingName');
            if ~strcmp(sLogName, sName)
                ep_em_entity_attribute_set( xLogging, 'name', sName);
            end
        else
            i_enable_logging(stEnv, sBlock, nPort, sLogName );
        end
    end
end
end


%%
function i_sf_enable_logging(sBlock, stateflowVariable, sOutput)
sp = get_param(sBlock, 'AvailSigsInstanceProps');
for i = 1 : sp.Signals.length
    if strcmp(sp.Signals(i).SigName, stateflowVariable)
        sp.Signals(i).LogSignal = 1;
        
        % SF6.3 does not support this sKind of field
        if( atgcv_m_version_is_greater_or_equal('SF6.4') )
            sp.Signals(i).UseCustomName = 1;
        end
        sp.Signals(i).LogName = sOutput;
        break;
    end
end
set_param(sBlock,'AvailSigsInstanceProps',sp);
end


%%
function i_enable_logging(stEnv, sBlock, nPort, sOutput)
try
    ports = get_param(sBlock, 'PortHandles');
    set_param( ports.Outport(nPort), 'DataLoggingNameMode', 'Custom');
    set_param( ports.Outport(nPort), 'DataLoggingName', sOutput);
    set_param( ports.Outport(nPort), 'DataLogging', 'on');
catch %# ok
    stError = osc_messenger_add(stEnv, 'ATGCV:MIL_GEN:PORT_LOGGING', ...
        'block', sBlock, ...
        'port',  num2str(nPort));
    osc_throw(stError);
end
end
