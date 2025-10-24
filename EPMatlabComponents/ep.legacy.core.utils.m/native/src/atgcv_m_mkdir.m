function [success,message,messageid] = atgcv_m_mkdir(parentdir,newdir)
%  Make new directory.
%
%  function [success,message,messageid] = atgcv_m_mkdir(PARENTDIR,NEWDIR)
%
%  [SUCCESS,MESSAGE,MESSAGEID] = atgcv_m_mkdir(PARENTDIR,NEWDIR) makes a new 
%  directory, NEWDIR, under the parent, PARENTDIR. While PARENTDIR may be an
%  absolute path, NEWDIR must be a relative path. When NEWDIR exists, 
%  atgcv_m_mkdir returns SUCCESS = 1. 
%  
%  [SUCCESS,MESSAGE,MESSAGEID] = atgcv_m_mkdir(NEWDIR) creates the directory
%  NEWDIR in the current directory, if NEWDIR represents a relative path.
%  Otherwise, NEWDIR represents an absolute path and MKDIR attempts to create
%  the absolute directory NEWDIR in the root of the current volume. An absolute
%  path starts in any one of a Windows drive letter or a UNC path '\\' string.
%
%  [SUCCESS,MESSAGE,MESSAGEID] = atgcv_m_mkdir(PARENTDIR,NEWDIR) creates the
%  directory NEWDIR in the existing directory PARENTDIR. 
%  
%  INPUT PARAMETERS:
%      PARENTDIR: string specifying the parent directory. See NOTE 1.
%      NEWDIR:    string specifying the new directory. 
%  
%  RETURN PARAMETERS:
%      SUCCESS:   logical scalar, defining the outcome of MKDIR. 
%                 1 : MKDIR executed successfully.
%                 0 : an error occurred.
%      MESSAGE:   string, defining the error or warning message. 
%                 empty string : MKDIR executed successfully.
%                 mescsage : an error or warning message, as applicable.
%      MESSAGEID: string, defining the error or warning identifier.
%                 empty string : MKDIR executed successfully.
%                 message id: the MATLAB error or warning message identifier
%                 (see ERROR, LASTERR, WARNING, LASTWARN).
%
%  NOTE 1: UNC paths are supported. 
%
%  AUTHOR(S):
%    Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$


%  create full path
switch nargin
case 1
    %  check type of parameter
    if ~ischar(parentdir)
        success   = 0;
        message   = 'Arguments must be strings.';
        messageid = 'OSC:OSC_M_MKDIR:ArgumentsMustBeStrings';
        return;
    end
    %  check value of  parameter
    if isempty(parentdir)
        success   = 0;
        message   = 'First directory argument is an empty string.';
        messageid = 'OSC:OSC_M_MKDIR:NewDirIsEmpty';
        return;
    end
    fname = parentdir;
case 2
    %  check type of parameters
    if ~ischar(parentdir) | ~ischar(newdir)
        success   = 0;
        message   = 'Arguments must be strings.';
        messageid = 'OSC:OSC_M_MKDIR:ArgumentsMustBeStrings';
        return;
    end
    %  check value of parameters
    if isempty(parentdir)
        success   = 0;
        message   = 'First directory argument is an empty string.';
        messageid = 'OSC:OSC_M_MKDIR:ParentDirIsEmpty';
        return;
    end
    if isempty(newdir)
        success   = 0;
        message   = 'Second directory argument is an empty string.';
        messageid = 'OSC:OSC_M_MKDIR:NewDirIsEmpty';
        return;
    end
    %  checking for non-absolute path of second parameter
    if length(newdir) > 1
        if newdir(2)==':' | strncmp(newdir,'\\',2)
            success   = 0;
            message   = ['Cannot create absolute directory inside ', parentdir];
            messageid = 'OSC:OSC_M_MKDIR:DirectoryContainsDriveLetter';
            return;
        end
    end

    fname = fullfile(parentdir, newdir);
end

%  check if already existing
if isdir(fname)
    %  already existing; handle this situation like success, just generate a message
    success   = 1;
    message   = ['Directory "', fname, '" already exists.'];
    messageid = 'OSC:OSC_M_MKDIR:DirectoryExists';
else
    %  call DOS command mkdir and check the result
    [osresult,message] = dos(['mkdir "', fname, '"']);

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
