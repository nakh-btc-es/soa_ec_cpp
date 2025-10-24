function atgcv_m13_check_interface( stEnv, xSubsystem, hSubBlock )
% Checks whether the original extraction model matches with the
% description of the model analysis. Throws an exception when
% mismatches occeur.
%
% Parameters:
%    xSubsystem      (handle)    Subsystem of the model analysis.
%                                (see ModelAnalysis.dtd)
%    hSubBlock       (handle)    Orginal extraction model.
%
% Output:
%
% AUTHOR(S):
%   Remmer.Wilts@osc-es.de
% $$$COPYRIGHT$$$-2006
%
%%


%% evaluate the input and output variables
xInPorts = ep_em_entity_find( xSubsystem, ...
    'child::InPort');
 
nInPortsLength = length(xInPorts);

xOutPorts = ep_em_entity_find( xSubsystem, ...
    'child::OutPort');

nOutPortsLength = length(xOutPorts);

if any(strcmp(get_param(hSubBlock,'Type'),{'block'}))
    PortHandles = get_param(hSubBlock,'PortHandles');
    InPortHandles = PortHandles.Inport;
    OutPortHandles = PortHandles.Outport;
    
    if( nInPortsLength ~= length( InPortHandles ) )
        stErr = osc_messenger_add(stEnv, ...
            'ATGCV:MIL_GEN:MODEL_MISMATCH', ...
            'subsys', getfullname( hSubBlock ), ...
            'model', getfullname( bdroot(hSubBlock) ) );
        osc_throw(stErr);
    end
    
    if( nOutPortsLength ~= length( OutPortHandles ) )
        stErr = osc_messenger_add(stEnv, ...
            'ATGCV:MIL_GEN:MODEL_MISMATCH', ...
            'subsys', getfullname( hSubBlock ), ...
            'model', getfullname( bdroot(hSubBlock) ) );
        osc_throw(stErr);
    end
end

%**************************************************************************
% END OF FILE
%**************************************************************************