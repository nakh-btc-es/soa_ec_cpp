function sltu_copy_file(sOrigDataDir, sTargetDir)
% Copying the file or directory to target directory.
% Necessary since copyfile() often causes a ML Bug under Linux.
%
% function varargout = sltu_tmp_env(varargin)
%
%   PARAMETER(S)    DESCRIPTION
%   sOrigDataDir    The original file or directory canonical path.
%   sTargetDir      The destination file or direcotry canonical path.

%%
try
    copyfile(sOrigDataDir, sTargetDir);
catch oEx
    if strcmp(oEx.identifier, 'MATLAB:COPYFILE:OSError') ...
            && strcmp(oEx.message, 'Invalid cross-device link') ...
            && isunix
        if isdir(sTargetDir)
            if ~exist(sTargetDir, 'dir')
                mkdir(sTargetDir);
            end
        else
            sPath = fileparts(sTargetDir);
            if ~exist(sPath, 'dir')
                mkdir(sPath);
            end
        end
        if ~exist(sOrigDataDir,'dir') && exist(sOrigDataDir, 'file')
            system(['cp -R "', sOrigDataDir, '" "', sTargetDir, '"']);
        else
            system(['cp -R "', sOrigDataDir, '"/* "', sTargetDir, '"']);
        end
    else
        throw(oEx);
    end
end