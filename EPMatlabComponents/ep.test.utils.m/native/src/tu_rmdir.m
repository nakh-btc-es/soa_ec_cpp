function tu_rmdir(sFullDir)
% Removes a directory with all its subdirectories and files.
%
%******************************************************************************
%
% function tu_rmdir(sFullDir)
%
%   INPUT               DESCRIPTION
%     sFullDir              (string)  full path to dir that will be deleted
%
%   OUTPUT              DESCRIPTION
%
%   REMARKS

%   <et_copyright>
%******************************************************************************

%% internal
%
%   REFERENCE(S):
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Steffen Kollmann
% $$$COPYRIGHT$$$
%
%   $Revision$
%   Last modified: $Date$
%   $Author$
%
%

%% take a shortcut if possible
if ~exist(sFullDir, 'dir')
    return;
end

%% delete dir; throw if failed
[bSuccess, sMsg] = rmdir(sFullDir, 's');

iLoop = 0;
while (~bSuccess && (iLoop < 10))
    iLoop = iLoop + 1;
    pause(1);
    [bSuccess, sMsg] = rmdir(sFullDir, 's');
end

if (~bSuccess)
    error('TU:ERROR', 'Directory "%s" could not be removed: "%s".', sFullDir, sMsg);
end
end

