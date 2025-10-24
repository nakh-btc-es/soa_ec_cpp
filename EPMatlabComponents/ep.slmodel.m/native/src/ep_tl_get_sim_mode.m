function varargout = ep_tl_get_sim_mode(varargin)
% Centralized version of original TL script tl_get_sim_mode.
%
% Note: Same usage as original tl_get_sim_mode.
%
% Note2: Mainly used to avoid warnings in ML console for ML2022b in context of Variants (find_system).
%


%%
persistent p_bIsOldML;
if isempty(p_bIsOldML)
    p_bIsOldML = verLessThan('matlab', '9.13');
end


%%
if ~p_bIsOldML
    stCurrentWarnState = warning('off', 'all');
    oOnCleanupResetWarnState = onCleanup(@() warning(stCurrentWarnState));
end
[varargout{1:nargout}] = tl_get_sim_mode(varargin{:});    
end
