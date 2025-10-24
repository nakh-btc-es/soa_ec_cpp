function casBusNames = ep_simenv_busnames_get( casSignalNames )
% Returns all bus names of the signal names
% function casBusNames = ep_simenv_busnames_get( casSignalNames )
%
%   INPUT               DESCRIPTION
%  	casSignalNames    (cell array)            Cell array of signal names.   
%       
%   OUTPUT              DESCRIPTION
%   casBusNames       (cell array)            Cell array of bus names.
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

nLength = length( casSignalNames );
casBusNames = cell(0);
for i = 1:nLength
    sSignalName = casSignalNames{i};
    sBusName = ep_simenv_busname_get( sSignalName );
    if( ~isempty(sBusName) )
        if(  ~any(strcmp(sBusName, casBusNames ) ) )
            casBusNames{end+1}= sBusName;
        end
    end
end

  
%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
