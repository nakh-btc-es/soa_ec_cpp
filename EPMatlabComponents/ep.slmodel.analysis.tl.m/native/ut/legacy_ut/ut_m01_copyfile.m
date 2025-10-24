function varargout = ut_m01_copyfile(varargin)
% wrapper for copyfile --> deleting the copied version of .svn directory
%
% function varargout = ut_m01_copyfile(varargin)
%
%   Usage: see "help copyfile"
%
%
%   <et_copyright>

%% internal 
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 66223 $
%   Last modified: $Date: 2010-03-30 12:13:32 +0200 (Di, 30 Mrz 2010) $ 
%   $Author: ahornste $
%

%% main
switch nargout
    case 0
        copyfile(varargin{:});
    case 1
        varargout{1} = copyfile(varargin{:});
    case 2
        [varargout{1}, varargout{2}] = copyfile(varargin{:});
    case 3
        [varargout{1}, varargout{2}, varargout{3}] = copyfile(varargin{:});
    otherwise
        error('UT:M01', 'Wrong usage: only 3 output arguments allowed.');
end

% post process: delete directory .svn in target dir 
% BUT: only for the UseCase copyfile(sSrcDir, sDestDir)
if (nargin > 1)
    sSrc  = varargin{1};
    sDest = varargin{2};
    if (isdir(sSrc) && isdir(sDest))
        i_removeSvn(sDest);
    end
end
end

%% remove recursively all .svn
function i_removeSvn(sCurrentDir)
astDir = dir(sCurrentDir);
for i = 1:length(astDir)
    if astDir(i).isdir
        sName = astDir(i).name;
        
        if any(strcmp(sName, {'.', '..'}))
            continue;
        end
        
        sFull = fullfile(sCurrentDir, sName);        
        if strcmpi(sName, '.svn')
            rmdir(sFull, 's');
        else
            i_removeSvn(sFull);
        end
    end
end
end

