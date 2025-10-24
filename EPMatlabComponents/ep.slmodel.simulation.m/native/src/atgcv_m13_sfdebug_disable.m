function atgcv_m13_sfdebug_disable( stEnv, sDestMdl )
% Disable all SF debug settings for all SF machines
% 
% function atgcv_m13_sfdebug_disable( stEnv, sDestMdl )
%    
%
% Input:                                                              
%   sDestMdl    (string)  name of the destination model.                    
%                                                                          
% Output:                                                                  
%   - 
% AUTHOR(S):
%       marten.penning
%%



hDstMdl = get_param( sDestMdl, 'Handle');
root       = sfroot;
dstMachine = root.find( '-isa', 'Stateflow.Machine', ...
    '-and', 'Name', sDestMdl);
% return successfully if no Stateflow chart is in the destination model
% bugfix 4873 - Matlab crashes during model extraction
if isempty(dstMachine)
    return;
else
    
    hDstDebug = get(dstMachine,'Debug');
    hDstBreakOn = get(hDstDebug,'BreakOn');
    hDstRunTimeCheck = get(hDstDebug,'RunTimeCheck');
    hDstAnimation = get(hDstDebug,'Animation');
    
    dDisableAllBreakpointsDefault = 1;
    dDisableAllBreakpoints = get(hDstDebug, 'DisableAllBreakpoints');
    if( ~isequal(dDisableAllBreakpoints, dDisableAllBreakpointsDefault) )
        set( hDstDebug, ...
            'DisableAllBreakpoints', dDisableAllBreakpointsDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'DisableAllBreakpoints', ...
%             'val', num2str(dDisableAllBreakpointsDefault));
    end
    
    dChartEntryDefault = 0;
    dChartEntry = get(hDstBreakOn, 'ChartEntry');
    if( ~isequal(dChartEntry, dChartEntryDefault) )
        set(hDstBreakOn, 'ChartEntry', dChartEntryDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'ChartEntry', ...
%             'val', num2str(dChartEntryDefault));
    end
    
    dEventBroadcastDefault = 0;
    dEventBroadcast = get(hDstBreakOn, 'EventBroadcast');
    if( ~isequal(dEventBroadcast, dEventBroadcastDefault) )
        set(hDstBreakOn, 'EventBroadcast', dEventBroadcastDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'EventBroadcast', ...
%             'val', num2str(dEventBroadcastDefault));
    end
    
    
    dStateEntryDefault = 0;
    dStateEntry = get(hDstBreakOn, 'StateEntry');
    if( ~isequal(dStateEntry, dStateEntryDefault) )
        set(hDstBreakOn, 'StateEntry', dStateEntryDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'StateEntry', ...
%             'val', num2str(dStateEntryDefault));
    end
    
    dStateInconsistenciesDefault = 0;
    dStateInconsistencies = get(hDstRunTimeCheck, 'StateInconsistencies');
    if( ~isequal(dStateInconsistencies, dStateInconsistenciesDefault) )
        set( hDstRunTimeCheck, 'StateInconsistencies', dStateInconsistenciesDefault );
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'StateInconsistencies', ...
%             'val', num2str(dStateInconsistenciesDefault));
    end
    
    if atgcv_version_p_compare('ML8.5') < 0
        dTransitionConflictsDefault = 0;
        dTransitionConflicts = get(hDstRunTimeCheck, 'TransitionConflicts');
        if( ~isequal(dTransitionConflicts, dTransitionConflictsDefault) )
            set( hDstRunTimeCheck,'TransitionConflicts', dTransitionConflictsDefault );
            %         osc_messenger_add(stEnv, ...
            %             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
            %             'key', 'TransitionConflicts', ...
            %             'val', num2str(dTransitionConflictsDefault));
        end
    end
    dDataRangeChecksDefault = 0;
    dDataRangeChecks = get(hDstRunTimeCheck, 'DataRangeChecks');
    if( ~isequal(dDataRangeChecks, dDataRangeChecksDefault) )
        set( hDstRunTimeCheck,'DataRangeChecks',dDataRangeChecksDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'DataRangeChecks', ...
%             'val', num2str(dDataRangeChecksDefault));
    end
    
    dCycleDetectionDefault  = 0;
    dCycleDetection = get(hDstRunTimeCheck, 'CycleDetection');
    if( ~isequal(dCycleDetection, dCycleDetectionDefault) )
        set( hDstRunTimeCheck,'CycleDetection',dCycleDetectionDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'CycleDetection', ...
%             'val', num2str(dCycleDetectionDefault));
    end
    
    dEnabledDefault = 0;
    dEnabled = get(hDstAnimation, 'Enabled');
    if( ~isequal(dEnabled, dEnabledDefault) )
        set( hDstAnimation,'Enabled',dEnabledDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'Enabled', ...
%             'val', num2str(dEnabledDefault));
    end
    
    dDelayDefault = 0;
    dDelay = get(hDstAnimation, 'Delay');
    if( ~isequal(dDelay, dDelayDefault) )
        set( hDstAnimation,'Delay',dDelayDefault);
%         osc_messenger_add(stEnv, ...
%             'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%             'key', 'Delay', ...
%             'val', num2str(dDelayDefault));
    end
    
%     cfgDst = getActiveConfigSet(hDstMdl);
%     hDiag = cfgDst.getComponent('Simulation Target');
%     bActiveML77 = atgcv_version_compare('ML7.7') >= 0;
%     
%     if( bActiveML77 )
%         sSFSimEnableDebugDefault = 'off';
%         sSFSimEnableDebug = hDiag.get_param('SFSimEnableDebug');
%         if( ~strcmp(sSFSimEnableDebugDefault,sSFSimEnableDebug) )
%             hDiag.set_param( 'SFSimEnableDebug', sSFSimEnableDebugDefault );
%             osc_messenger_add(stEnv, ...
%                 'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
%                 'key', 'SFSimEnableDebug', ...
%                 'val', sSFSimEnableDebugDefault);
%         end
%     end
%     
%     i_deactivate_debug(stEnv,sDestMdl);
end

function i_deactivate_debug(stEnv, sDestMdl)
root      = sfroot;
saRtwData = root.find('-isa','Stateflow.Target','-and', 'Name','sfun');
nRtwData  = length(saRtwData);

% search for the destination chart
for idx=1:nRtwData
    hDest = saRtwData(idx);
    if ~isempty(hDest.Machine)
        sName = hDest.Machine(1).Name;
        
        if strcmp(sDestMdl,sName)
            if( hDest.getCodeFlag('debug' ) )
                osc_messenger_add(stEnv, ...
                    'ATGCV:MIL_GEN:SF_DEBUG_DISABLE', ...
                    'key', 'setCodeFlag("debug")', ...
                    'val', '0');
                hDest.setCodeFlag('debug',0);
            end
            break;
        end
    end
end
%**************************************************************************
% END OF FILE
%**************************************************************************
