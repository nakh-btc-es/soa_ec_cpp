function varargout = atgcv_dd_open(varargin)
% Open DD.
%
% function varargout = atgcv_dd_open(varargin)
%
%   INPUT               DESCRIPTION
%     varargin            (any)    arguments passed directly and uninterpreted to dsdd --> dsdd('Open', varargin{:})
%
%   OUTPUT              DESCRIPTION
%     varargout           (any)    outputs returned directly and uniterpreted from dsdd('Open', ...)
%
%   REMARKS
%     After loading the DD, the function is calling the POST_LOAD_DD hook with the inputs
%     and the output of the dsdd('Open', ...) call.
%    
%   <et_copyright>


%% internal 
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 206137 $
%   Last modified: $Date: 2015-11-16 15:02:51 +0100 (Mo, 16 Nov 2015) $ 
%   $Author: ahornste $
%


%%
caxInputs = varargin;
xOutput   = dsdd('Open', caxInputs{:});
varargout = {xOutput};
i_evalHookPostLoadDD('Input', caxInputs, 'Output', xOutput);
end


%%
% Note: A little bit dirty to reference the EP2.x functionality "ep_core_eval_hook". However, not a hard dependency. If
%       not found, the hook evaluation is not triggered. This is the behavior as "seen" in EP1.x.
function i_evalHookPostLoadDD(varargin)
if ~isempty(which('ep_core_eval_hook'))
    ep_core_eval_hook('ep_hook_post_load_dd', varargin{:});
end
end
