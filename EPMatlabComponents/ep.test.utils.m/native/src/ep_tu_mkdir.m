function ep_tu_mkdir(sFullDir)
% Creates a directory
%
% function ep_tu_mkdir(sFullDir)
%
%   INPUT               DESCRIPTION
%     sFullDir              (string)  full path to dir that will be created
%
%   OUTPUT              DESCRIPTION
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author$
%  $Date$
%  $Revision$
%%

%% take a shortcut if possible
if exist(sFullDir, 'dir')
    return;
end
mkdir(sFullDir);