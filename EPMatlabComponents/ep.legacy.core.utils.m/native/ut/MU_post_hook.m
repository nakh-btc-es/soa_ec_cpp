function MU_post_hook
% Clean up after unit test.
%
% function MU_post_hook
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$


% Remove path to osc_simenvlib sources.
path_ut = fileparts(cd); % one directory up
% path_ut = fullfile(path_ut,'src','osc_simenvlib');
% rmpath(path_ut);


% %  If the src directory has a private directory we have to copy all scripts to
% %  call private functions directly
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
% 
% return;
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
