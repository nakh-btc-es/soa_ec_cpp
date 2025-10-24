function sPath = ep_core_canonical_path(sPath, sRootPath)
%  transform (a potentially) relative path into absolute/canonical path
%
% function sPath = ep_core_canonical_path(sPath, sRootPath)
%
%
%   INPUT               DESCRIPTION
%     sPath                (string)   arbitrary (e.g. relative) path 
%                                     (path is allowed to include filename)
%                                     (if path is empty, "." is assumed)
%     sRootPath            (string)   optional: if path is relativ, the 
%                                     root path is taken as context; if in
%                                     this case no root path is provided,
%                                     the current path is used as root path
%
%   OUTPUT              DESCRIPTION
%     sPath                (string)   canonical absolute path (path without any "." or "..")
%     
%   REMARKS
%     !! internal function: no input checks !!
%


%% check inputs
if ((nargin < 1) || isempty(sPath))
    sPath = '.';
end

%% main
jFile = java.io.File(sPath);

% if path was already absolute we can neglect the root path
if ~jFile.isAbsolute()
    if (nargin > 1)
        if isempty(sRootPath)
            sRootPath = '';
        end
        jRoot = java.io.File(sRootPath);
        if ~jRoot.isAbsolute()
            % if root path was provided as rel. path, assume the current
            % dir to be the root of the root path
            % --> maybe throw a warning here: root path should be always
            %     provided as absolute path
            jRoot = java.io.File(pwd(), sRootPath);
            try
                sRootPath = char(jRoot.getCanonicalPath());
            catch
                % Exception occured, continue with absolute path
                sRootPath = char(jRoot.getAbsolutePath());
            end
        end
    else
        % if root path was not provided assume the current dir to be root
        sRootPath = pwd();
    end
    jFile = java.io.File(sRootPath, sPath);
end

try
    sPath = char(jFile.getCanonicalPath());
catch
    % Exception occured, continue with absolute path
    sPath = char(jFile.getAbsolutePath());
end
end
