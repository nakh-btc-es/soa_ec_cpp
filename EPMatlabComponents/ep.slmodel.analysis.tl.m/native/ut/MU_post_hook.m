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

sStubDir = fullfile(pwd, 'stubs');
if exist(sStubDir, 'dir')
    rmpath(sStubDir);
end
end
