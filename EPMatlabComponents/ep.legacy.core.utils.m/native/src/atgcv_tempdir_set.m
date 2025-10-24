function atgcv_tempdir_set(sTempPath)
% set path of the directory where ET may create temporary files
%
% function atgcv_tempdir_set(sTempPath)
%
%   INPUT               DESCRIPTION
%     sTempPath           (string)    optional: path to temporary directory
%                                     (existence is required and checked; if 
%                                     not provided, user's TEMP path is used)
%
%   OUTPUT              DESCRIPTION
%
%   REMARK
%      Function will create a subdirectory 'atgcv' in sTempPath and use that
%      for saving temporary files.
%
% 
%  <et_copyright>


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
%   $Revision: 62891 $
%   Last modified: $Date: 2010-01-27 18:13:05 +0100 (Mi, 27 Jan 2010) $ 
%   $Author: ahornste $
%

if (nargin < 1)
    sTempPath = tempdir();
end
sTempPath = i_checkPath(sTempPath);

% create atgcv subdirectory 
sTempDir = fullfile(sTempPath, 'atgcv');
if ~isdir(sTempDir)
    stEnv = 0;
    atgcv_api_mkdir(stEnv, sTempDir);
end

% store tempdir in the global data of ET-API
atgcv_global_data('set', 'sTempDir', sTempDir);
end



%% internal functions

%% i_checkPath
% check path and get abs name
function sTempPath = i_checkPath(sTempPath)
if isdir(sTempPath)
    sPwd = pwd();
    try
        cd(sTempPath);
        sTempPath = pwd();
        
        % get LFN (long file name) via Java
        jFile = java.io.File(sTempPath);
        sTempPath = char(jFile.getCanonicalPath());
        
    catch
        % ignore
    end
    cd(sPwd);
else
    error('ATGCV:API:ERROR', 'Could not find directory "%s".', sTempPath);
end
end

