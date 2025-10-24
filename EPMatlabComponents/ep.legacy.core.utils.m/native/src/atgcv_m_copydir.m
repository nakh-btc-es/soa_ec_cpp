function [status,message] = atgcv_m_copydir(source,dest)
%   Copies the directory source to dest.
%
%   function [status,message] = osc_mtl_copyfile(source,dest,mode)
%
%   SOURCE and DEST may be an absolute pathname or a pathname relative to the
%   current directory. 
%
%   status = atgcv_m_copydir(...) will return 1 if the directory is copied
%   successfully and 0 otherwise.
%
%   [status,message] = atgcv_m_copydir(...) will return a non-empty error
%   message string if an error occurred.
%
% AUTHOR(S):
%   koopmann@osc-es.de, lochmann@osc-es.de
% $$$COPYRIGHT$$$


%  be pessimistic
status = 0;

%  check parameters
if ~ischar(source)
    message = 'Directory name must be a string.';
    return;
end
if ~ischar(dest)
    message = 'Directory name must be a string.';
    return;
end

if isempty(source) | isempty(dest)
    message = 'All arguments must be one-dimensional strings.';
    return;
end

%  check if source is a directory, otherwise, refuse operation
if ~isdir(source)
    message = sprintf(['Source file, %s, is not a directory and can''t be copied.\n'], source);
    return;
end

%  check for wildcards '*'
if ~isempty(strfind([source,dest],'*'))
    message = sprintf(['wildcards not supported']);
    return;
end

[s, w] = dos(['xcopy "', source,'" "', dest, '" /Y /S /E /I /Q']);
if s ~= 0
    message = w;
    return;
else
    status = 1;
    message = '';
    return;
end

return
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
