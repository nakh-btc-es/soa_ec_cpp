function sAbsPath = ep_core_get_abspath(sPath)
%  Returns the absolute/canonical path of the provided path. Root dir is always the current dir.
%
%   sAbsPath = ep_core_get_abspath(sPath)
%
%   INPUT               DESCRIPTION
%   - sPath               (string)    A file path that may be relative or absolute.
%
%   OUTPUT              DESCRIPTION
%   - sAbsPath            (string)    The absolute/canonical path.
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%


%%
if ((nargin < 1) || isempty(sPath))
    sPath = pwd;
else
    if ~ischar(sPath)
        oEx = MException('EP:API:ILLEGAL_ARG', 'A string path needs to be provided.');
        throw(oEx);
    end    
end

%%
try
    jFile = java.io.File(sPath);
    if ~jFile.isAbsolute
        jFile = java.io.File(pwd, sPath);
    end
    sAbsPath = char(jFile.getCanonicalPath());
catch oEx
    oEx = MException('EP:API:FAILED_ABS_TRAFO', ...
        'Failed to transform path %s.\n    %s', sPath, exception.message);
    throw(oEx);
end
end


