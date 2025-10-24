function atgcv_m46_evaluate_ports(sModel)
% Evaluates the ports of the model
%
% function atgcv_m46_evaluate_ports(sModel)

%   INPUT               DESCRIPTION
%   sModel               (string)    Model name of the TL model
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%
%   REFERENCE(S):
%     Design Document:
%        Section : M46
%        Download:
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

casTopSub = ep_find_system(sModel, ...
    'LookUnderMasks','on', 'Tag','MIL Subsystem');

sTopSub = getfullname( casTopSub{1} );

casOutPorts = ep_find_system(sTopSub, 'LookUnderMasks','all',...
    'FollowLinks', 'on',...
    'SearchDepth',1,...
    'MaskType','TL_Outport');

nTotal = length( casOutPorts);
castResult = cell( 0 );
for iPort = 1:nTotal
    sOutPort = char(casOutPorts(iPort));
    hOutPort = get_param( sOutPort, 'Handle' );
    cahSources = atgcv_m46_tlport_handling( sModel, hOutPort );
    if( ~isempty( cahSources ) )
        stAnalysisRes.hPort = hOutPort;
        stAnalysisRes.cahSources = cahSources;
        castResult{end+1} = stAnalysisRes;
    end
end
nResTotal = length( castResult );

for iSource = 1:nResTotal
    stAnalysisRes = castResult{iSource};
    hPort = stAnalysisRes.hPort;
    cahSources = stAnalysisRes.cahSources;
    atgcv_m46_tlclass_settings( hPort, cahSources );
end



%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************

