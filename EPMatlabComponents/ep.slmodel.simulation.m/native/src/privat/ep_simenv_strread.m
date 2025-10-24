function casParts = ep_simenv_strread(sString, sDelimiter)
% Utility function to separate the string with the delimiter
%
% function casParts = ep_simenv_strread(sString, sDelimiter)
%
%%

casParts = {};
sRemain = sString;
while( ~isempty( sRemain ) )
   [sPart, sRemain] = strtok(sRemain, sDelimiter); %#ok
   casParts{end+1} = sPart;%#ok
end



%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************