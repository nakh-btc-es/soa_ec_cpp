function casParts = atgcv_m13_strread(sString, sDelimiter)
% 
%
% function casParts = atgcv_m13_strread(sString, sDelimiter)
%
%   INPUTS               DESCRIPTION
%     
%   OUTPUTS              DESCRIPTION
%     
%%
%   REMARKS
%
%
%   REFERENCE(S):
%     Design Document:
%        Section : M13
%        Download:
%
%   RELATED MODULES:
%     -
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%   
%%


casParts = {};
sRemain = sString;
while( ~isempty( sRemain ) )
   [sPart, sRemain] = strtok(sRemain, sDelimiter);
   casParts{end+1} = sPart;
end




%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************