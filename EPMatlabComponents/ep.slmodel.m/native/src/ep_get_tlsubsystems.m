function varargout = ep_get_tlsubsystems(varargin)
% Centralized version of original TL script get_tlsubsystems.
%
% Note: Same usage as original get_tlsubsystems.
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
[varargout{1:nargout}] = get_tlsubsystems(varargin{:});    
end
