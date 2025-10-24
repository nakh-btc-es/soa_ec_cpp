function atgcv_e_rmdir(stEnv, sFullDir, bIgnoreFail)
% Removes a directory with all its subdirectories and files.
%
%******************************************************************************
%
% function atgcv_e_rmdir(stEnv, sFullDir, bIgnoreFail)
%
%   INPUT               DESCRIPTION
%     stEnv                 (struct)  environment for error handling (messenger)
%     sFullDir              (string)  full path to dir that will be deleted
%     bIgnoreFail           (boolean) optional: if TRUE, a failed attempt at
%                                     removing will not throw an exception
%                                     (default is FALSE)  
%
%   OUTPUT              DESCRIPTION
%     (none)                function throws exception if operation failed
%
%   REMARKS
%      !! internal function: no input checks !!
%
%   Note: Functions tries to compensate for sporadic failures to remove
%   directories/files in context of open file handles by other programs
%   outside of Matlab (e.g. VirusScanners, SVN caches, etc. ...).
%
%
%   <et_copyright>
%******************************************************************************

%% internal
%
%   REFERENCE(S):
%     EP5-Document
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 127078 $
%   Last modified: $Date: 2012-11-23 15:31:33 +0100 (Fr, 23 Nov 2012) $
%   $Author: ahornste $
%
%

%% check input
if (nargin < 3)
    bIgnoreFail = false;
end

%% take a shortcut if possible
if ~exist(sFullDir, 'dir')
    return;
end

%% delete dir; throw if failed
[bSuccess, sMsg] = rmdir(sFullDir, 's');

iLoop = 0;
while (~bSuccess && (iLoop < 10))
    iLoop = iLoop + 1;
    
    if atgcv_m_debug
        i_logWarning(iLoop, sFullDir, sMsg);
    end
    pause(1);
    
    [bSuccess, sMsg] = rmdir(sFullDir, 's');
end

if (~bSuccess && ~bIgnoreFail)
    stErr = osc_messenger_add(stEnv, 'ATGCV:STD:RMDIR', 'directory', sFullDir);
    osc_throw(stErr);
end
end


%%
function i_logWarning(nTry, sDirPath, sMsg)
sLogFile = fullfile(fileparts(atgcv_tempdir_get()), ...
    ['atgcv_', datestr(now, 'YYYYMMDDhh'), '_msg.log']);
hFid = fopen(sLogFile, 'at');
if (hFid > 0)
    fprintf(hFid, 'ERROR: %s -- Failed attempt #%d to remove dir: "%s".\nMessage: "%s".\n', ...
        datestr(now), nTry, sDirPath, sMsg);
    try
        flose(hFid);
    catch %#ok just ignore
        warning('ATGCV:INTERNAL', ...
            'ERROR: %s -- Failed attempt #%d to remove dir: "%s".\nMessage: "%s".\n', ...
            datestr(now), nTry, sDirPath, sMsg);
    end
else
    warning('ATGCV:INTERNAL', ...
        'ERROR: %s -- Failed attempt #%d to remove dir: "%s".\nMessage: "%s".\n', ...
        datestr(now), nTry, sDirPath, sMsg);
end
end

