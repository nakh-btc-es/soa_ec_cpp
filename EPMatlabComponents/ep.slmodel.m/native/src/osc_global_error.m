function get_object =osc_global_error(update_object)
% Store a persistent variable resistant to clear command.
%
% function get_object = osc_global_error(update_object)
%
% This function can store and load data which is resistant to clear command such
% as CLEAR GLOBAL and CLEAR ALL.
%
%   PARAMETER(S)    DESCRIPTION
%   - update_object If the parameter is given, it´s value is stored.
%
%   OUTPUT
%   - get_object    Return the latest stored data if called with no arguments.
%

% USAGE COMMENT
%
% This function will store a single variable content. It is recommended to 
% copy and rename it for each global variable.
% For example 'atgcv_m31_global_dbname' could be used to store dbname globally
% in Module M31.
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$-2003
%
% $Revision: 11008 $ Last modified: $Date: 2006-11-22 18:08:40 +0100 (Mi, 22 Nov 2006) $ $Author: jensw $ 

%  lock the persistent data in this file
if ~mislocked
    mlock;
end

persistent object;

switch nargin
    case 0
        %  get data
        get_object = object;
    case 1
        %  set data
        object = update_object;
        lasterror(object);
end

return
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
