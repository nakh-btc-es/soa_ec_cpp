function sBusName = atgcv_m13_busname_get( sSignalName )
% Returns all bus names of the signal names
% function sBusName = atgcv_m13_busname_get( sSignalName )
%
%   INPUT               DESCRIPTION
%  	sSignalName       (string)                Signal name
%       
%   OUTPUT              DESCRIPTION
%   sBusName          (string)                Bus name
%      
%   REMARKS
%
%   REFERENCE(S):
%     Design Document: 
%        Section : M13
%        Download:
%        
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

sBusName = '';
asParts = atgcv_m13_strread(sSignalName, '.');
if( ~isempty(asParts) )
    sBusName = asParts{1};
end


  
%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
