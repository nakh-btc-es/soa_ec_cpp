function [success,message,messageid] = atgcv_m_rmdir(directory)
%  Removes a directory with all its subdirectories and files.
%
%  function [success,message,messageid] = atgcv_m_mkdir(PARENTDIR,NEWDIR)
%
%  [SUCCESS,MESSAGE,MESSAGEID] = atgcv_m_rmdir(DIRECTORY) removes a directory.
%  If the given directory could be successfully removed, atgcv_m_rmdir returns 
%  SUCCESS = 1.
%  
%  INPUT PARAMETERS:
%      DIR:       string specifying the directory to remove.
%  
%  RETURN PARAMETERS:
%      SUCCESS:   logical scalar, defining the outcome of RMDIR. 
%                 1 : RMDIR executed successfully.
%                 0 : an error occurred.
%      MESSAGE:   string, defining the error or warning message. 
%                 empty string : MKDIR executed successfully.
%                 mescsage : an error or warning message, as applicable.
%      MESSAGEID: string, defining the error or warning identifier.
%                 empty string : MKDIR executed successfully.
%                 message id: the MATLAB error or warning message identifier
%                 (see ERROR, LASTERR, WARNING, LASTWARN).
%
%  AUTHOR(S):
%    koopmann@osc-es.de
% $$$COPYRIGHT$$$

%  check type of parameter
if ~ischar(directory)
    success   = 0;
    message   = 'Arguments must be strings.';
    messageid = 'OSC:OSC_M_RMDIR:ArgumentsMustBeStrings';
    return;
end

%  check value of  parameter
if isempty(directory)
    success   = 0;
    message   = 'Directory argument is an empty string.';
    messageid = 'OSC:OSC_M_RMDIR:NewDirIsEmpty';
    return;
end

%  check if not existing
if ~isdir(directory)
    success   = 1;
    message   = ['Directory "', directory, '" does not exist.'];
    messageid = 'OSC:OSC_M_MKDIR:DirectoryExists';
else
    %  call DOS command mkdir and check the result
    [osresult,message] = dos(['rmdir /S /Q "', directory, '"']);

    if osresult
        success   = 0;
        messageid = 'OSC:OSC_M_MKDIR:OSError';
    else
        success   = 1;
        message   = '';
        messageid = '';
    end
end

return;
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************