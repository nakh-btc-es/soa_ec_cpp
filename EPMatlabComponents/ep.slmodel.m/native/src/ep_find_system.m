function varargout = ep_find_system(xContext, varargin)
% Centralized version of find_system that takes care of removing inactive Variants from the search.
%
% function xRet = ep_find_system(xContext, varargin)
%
%   INPUT               DESCRIPTION
%     xContext          (handle/string)   handle or path/name to the model context from where the search is started
%     varargin          (...)             arguments that are passed uninterpreted to "find_system"
%                                         Note: Must not contain MatchFilter! This is not checked actively.
%
%   OUTPUT              DESCRIPTION
%     varargout              (...)        return arguments of the find_system call
%


%%
persistent p_bIsOldML;
persistent p_bIsIntermedML;
if isempty(p_bIsOldML)
    p_bIsOldML = verLessThan('matlab', '9.13');
end
if isempty(p_bIsIntermedML)
    p_bIsIntermedML = verLessThan('matlab', '23.2');
end

%%
if p_bIsOldML
    [varargout{1:nargout}] = find_system(xContext, varargin{:});
elseif p_bIsIntermedML
    % Since Variants handling is producing warnings, we have to deal with it!
    % --> Simulink:Commands:FindSystemVariantsOptionRemoval
     stCurrentWarnState = warning('off', 'all');
     oOnCleanupResetWarnState = onCleanup(@() warning(stCurrentWarnState));

    [varargout{1:nargout}] = find_system(xContext, varargin{:});
else
    %Now there is a replacement for the old Variant
    [varargout{1:nargout}] = find_system(xContext, 'MatchFilter',...
        @Simulink.match.legacy.filterOutInactiveVariantSubsystemChoices, varargin{:});
end
end
