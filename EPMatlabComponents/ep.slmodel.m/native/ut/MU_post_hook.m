function MU_POST_HOOK
% Clean up after unit test.
%
% function MU_POST_HOOK
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$

%  If the src directory has a private directory we have to copy all scripts to
%  call private functions directly
% if isdir('src')
%     %  remove path to copied sources
%     %  for m14 a simple rmpath(genpath(..)) would work, but to be compatible to m12
%     p = genpath([cd, '\src']);
%     while ~isempty(p)
%         [t,p] = strtok(p, ';');
%         rmpath(t);
%         %  remove ';'
%         p = p(2:end); 
%     end
%     %  remove copied sources
%     !rmdir /S /Q src;
% end

return;
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
