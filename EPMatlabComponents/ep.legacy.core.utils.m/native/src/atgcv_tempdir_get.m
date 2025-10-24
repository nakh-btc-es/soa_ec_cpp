function sTempDirectory = atgcv_tempdir_get(varargin)
% get name of directory where ATG/CV may create temporary files
%
% function sTempDirectory = atgcv_tempdir_get(varargin)
%
%   INPUT               DESCRIPTION
%       varargin: (key, value) pairs
%
%         KEY-string         VALUE
%         'useDos83'         (bool)   if "true", return the abbreviated DOS 8.3 
%                                     notation; otherwise the original Windows
%                                     name  (default = true)
%
%   OUTPUT              DESCRIPTION
%     sTempDirectory      (string)    full path to the temporary directory
%                                     used by ET to store intermediate data
%
%   REMARK
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
%   $Revision: 65157 $
%   Last modified: $Date: 2010-03-10 12:15:01 +0100 (Mi, 10 Mrz 2010) $ 
%   $Author: ahornste $
%

%% cache
persistent sWinPathCache;
persistent sDosPathCache;

%% main
stArgs = i_parseArgs(varargin);

sTempDirectory = atgcv_global_data('get', 'sTempDir');
if (isempty(sTempDirectory) || ~isdir(sTempDirectory))
    atgcv_tempdir_set();
    sTempDirectory = atgcv_global_data('get', 'sTempDir');
end
if stArgs.bUseDos83
    % try to use cached names to avoid using the costly atgcv_m_dospath
    if (~isempty(sWinPathCache) && strcmp(sWinPathCache, sTempDirectory))
        sTempDirectory = sDosPathCache;
    else
        sWinPathCache  = sTempDirectory;
        sTempDirectory = atgcv_m_dospath(sTempDirectory);
        sDosPathCache  = sTempDirectory;
    end
end
end




%% internal functions

%% i_parseArgs
function stArgs = i_parseArgs(caxArgs)
stArgs = struct('bUseDos83', true);
nArgs = length(caxArgs);
if ((nArgs > 0) && (mod(nArgs, 2) == 0))
    for i = 1:2:length(caxArgs)
        sKey = caxArgs{i};
        switch sKey
            case 'useDos83'
                stArgs.bUseDos83 = caxArgs{i + 1};
            otherwise
                error('ATGCV:API:ERROR', 'Unknown key "%s".', sKey);
        end
    end
end
end
