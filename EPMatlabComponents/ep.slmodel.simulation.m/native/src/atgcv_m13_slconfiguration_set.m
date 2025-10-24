function atgcv_m13_slconfiguration_set(stEnv,hSrcMdl,hDstMdl,sSampleTime)
% Function sets the Simulink configuration for the extracted model.
%
% function atgcv_m13_slconfiguration_set(stEnv,hSrcMdl,hDstMdl,sSampleTime)
%
%   PARAMETER(S)    DESCRIPTION
%   hSrcMdl         (handle)  the user model
%   hDstMdl         (handle)  the extraced model
%   sSampleTime     (string)  the models sample time
%
%   OUTPUT
%
% AUTHOR(S):
%   Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%%



cfgSrc = getActiveConfigSet(hSrcMdl);
if isa(cfgSrc, 'Simulink.ConfigSetRef')
    try
        cfgSrc = cfgSrc.getRefConfigSet;
    catch
        osc_messenger_add(stEnv, ...
            'ATGCV:MIL_GEN:CONFIGURATION_SET_NOT_FOUND', ...
            'name', cfgSrc.Name);
        cfgSrc = getConfigSet(hSrcMdl, 'Configuration');
    end
end
cfgDst = getActiveConfigSet(hDstMdl);
i_SetSolver(stEnv, cfgDst, cfgSrc, sSampleTime );
i_SetWorkspace(stEnv, cfgDst, cfgSrc);
i_SetOptimization(stEnv, cfgDst,cfgSrc);
i_SetHardware(stEnv,cfgDst,cfgSrc);
i_SetDiagnostics(stEnv, cfgDst,cfgSrc);
i_SetModelReferencing(stEnv, cfgDst,cfgSrc);
i_SetSimulationTarget(stEnv,cfgDst,cfgSrc);
%i_SetRTW(stEnv,cfgDst,cfgSrc);


%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                           ***
%                                                                           ***
%******************************************************************************


function i_SetSolver(stEnv, cfgDst, cfgSrc, sSampleTime )
hDiagSrc = cfgSrc.getComponent('Solver');
hDiag = cfgDst.getComponent('Solver');
atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, 'Solver' );
casProperties = hDiagSrc.getPossibleProperties();
for i= 1:length(casProperties)
     sProperty = casProperties{i};
     atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
end

if( ~isempty(sSampleTime) )
    hDiag.StartTime = '0.0';
    hDiag.StopTime  = 'inf';
    hDiag.FixedStep = sSampleTime;
    hDiag.MaxStep = 'auto';
    hDiag.MinStep = 'auto';
    sSampleTimeConstraintSrc = hDiag.SampleTimeConstraint;
    hDiag.SampleTimeConstraint = 'Unconstrained';
    if( ~strcmp(sSampleTimeConstraintSrc, 'Unconstrained') )
        osc_messenger_add(stEnv, ...
            'ATGCV:MIL_GEN:SL_SETTINGS_INFO', ...
            'key', 'SampleTimeConstraint', ...
            'val', 'Unconstrained');
    end
end



function i_SetWorkspace(stEnv, cfgDst, cfgSrc)
hData = cfgDst.getComponent('Data Import/Export');
hDataSrc = cfgSrc.getComponent('Data Import/Export');

casProperties = hDataSrc.getPossibleProperties();
for i= 1:length(casProperties)
     sProperty = casProperties{i};
     % BTS/34596 - disable 'save simulation output as single object' 
     % (available since ML 2010a
     if ~strcmp(sProperty,'ReturnWorkspaceOutputs')
        atgcv_m13_property_copy( stEnv, hDataSrc, hData, sProperty );
     else
         hData.set( sProperty, 'off')
     end
end




function i_SetOptimization(stEnv,cfgDst,cfgSrc)

hDiagSrc = cfgSrc.getComponent('Optimization');
hDiag    = cfgDst.getComponent('Optimization');
casProperties = hDiagSrc.getPossibleProperties();
for i= 1:length(casProperties)
     sProperty = casProperties{i};     
     atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
end
sInlineParamsSrc = hDiag.InlineParams;
hDiag.InlineParams = 'off';
if( ~strcmp(sInlineParamsSrc, 'off') )
    if ep_core_version_compare('ML8.6') >= 0
        % Since ML2015b the option is named differently (EP-1032)
        sKey = 'DefaultParameterBehavior';
        sValue = 'Tunable';
    else
        sKey = 'InlineParams';
        sValue = 'off';
    end
    osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:SL_SETTINGS_INFO', ...
        'key', sKey, ...
        'val', sValue);
end
% sBlockReductionSrc = hDiag.BlockReduction;
% hDiag.BlockReduction = 'off';
% if( ~strcmp(sBlockReductionSrc, 'off') )
%     osc_messenger_add(stEnv, ...
%         'ATGCV:MIL_GEN:SL_SETTINGS_INFO', ...
%         'key', 'BlockReduction', ...
%         'val', 'off');
% end


function i_SetHardware(stEnv,cfgDst,cfgSrc)
hDiagSrc = cfgSrc.getComponent('Hardware Implementation');
hDiag    = cfgDst.getComponent('Hardware Implementation');
casProperties = hDiagSrc.getPossibleProperties();
for i= 1:length(casProperties)
     sProperty = casProperties{i};
     atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
end


function i_SetDiagnostics(stEnv,cfg,cfgSrc)
hDiag    = cfg.getComponent('Diagnostics');
hDiagSrc = cfgSrc.getComponent('Diagnostics');
casProperties = hDiagSrc.getPossibleProperties();
for i= 1:length(casProperties)
     sProperty = casProperties{i};
     atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
end


function i_SetModelReferencing(stEnv,cfg,cfgSrc)
hDiag    = cfg.getComponent('Model Referencing');
hDiagSrc = cfgSrc.getComponent('Model Referencing');
casProperties = hDiagSrc.getPossibleProperties();
for i= 1:length(casProperties)
     sProperty = casProperties{i};
     atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
end


function i_SetSimulationTarget(stEnv,cfgDst,cfgSrc)
hDiag    = cfgDst.getComponent('Simulation Target');
hDiagSrc = cfgSrc.getComponent('Simulation Target');
if( ~isempty( hDiagSrc ) )
    casProperties = hDiagSrc.getPossibleProperties();
    for i= 1:length(casProperties)
        sProperty = casProperties{i};
        atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
    end
end

function i_SetRTW(stEnv,cfgDst,cfgSrc)
hDiag    = cfgDst.getComponent('Real-Time Workshop');
hDiagSrc = cfgSrc.getComponent('Real-Time Workshop');
if( ~isempty( hDiagSrc ) )
    casProperties = hDiagSrc.getPossibleProperties();
    for i= 1:length(casProperties)
        sProperty = casProperties{i};
        atgcv_m13_property_copy( stEnv, hDiagSrc, hDiag, sProperty );
    end
end




%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************