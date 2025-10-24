function varargout = atgcv_global_data(varargin)
%  manage global internal data of ATG/CV
%
% function varargout = atgcv_global_data(varargin)
%
%
%   INPUT               DESCRIPTION
%     varargin                possible input:
%       ('set', stData)         set whole structure of gobal data to new value  
%                               (stData has to be a struct, otherwise command
%                                is ignored)
%       ('set', sAttr, val)     set specific attribute of global data to new value  
%                               (if attribute does not exist, it is created)          
%       ('get')                 get whole structure of global data             
%       ('get', sAttr)          get specific attribute of global data
%                               (empty return value if attribute does not exist)             
%
%   OUTPUT              DESCRIPTION
%     varargout              result of unspecified type depending on input
%                           'set'         ---> (empty)
%                           'get'         ---> (struct)
%                           'get', sAttr  ---> (any type possible)
%     
%   REMARKS
%     
%
%   <et_copyright>


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

%% init persistent data 
persistent stGlobalData;
if ~mislocked
    % prevent this function from clearing
    mlock;
    stGlobalData = struct();
end


%% main
sCmd = varargin{1};
switch lower(sCmd)
    case 'set'
        if (length(varargin) > 2)
            stGlobalData.(varargin{2}) = varargin{3};
        else
            if ((length(varargin) > 1) && isstruct(varargin{2}))
                stGlobalData = varargin{2};
            end
        end
    case 'get'
        if (length(varargin) > 1)
            if isfield(stGlobalData, varargin{2})
                varargout{1} = stGlobalData.(varargin{2});
            else
                varargout{1} = [];
            end
        else
            varargout{1} = stGlobalData;
        end
    otherwise
        error('ATGCV:API:INTERNAL_ERROR', 'Unknown command flag.');
end
end
