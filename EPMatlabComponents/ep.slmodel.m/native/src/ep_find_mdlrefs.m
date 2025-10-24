function varargout = ep_find_mdlrefs(xContext, varargin)
% Centralized version of find_mdlrefs that takes care of removing inactive Variants from the search.
%
% function varargout = ep_find_mdlrefs(xContext, varargin)
%
%   INPUT               DESCRIPTION
%     xContext          (handle/string)   handle or path/name to the model context from where the search is started
%     varargin          (...)             arguments that are passed uninterpreted to "find_mdlrefs"
%                                         Note: Must not contain MatchFilter! This is not checked actively.
%
%   OUTPUT              DESCRIPTION
%     varargout         (...)             return arguments of the find_mdlrefs call
%


%%
persistent p_bIsOldML;
if isempty(p_bIsOldML)
    p_bIsOldML = verLessThan('matlab', '9.13');
end


%%
if p_bIsOldML
    [varargout{1:nargout}] = find_mdlrefs(xContext, varargin{:});
else
    % Note: currently using MatchFilter yields different results from find_mdrefs without it; the problem occurs in
    % locations where the caller did not bring the model into a compiled mode
    % --> do not use matching filter for now until data-flow for callers guarentee that the model is/was in compiled
    %     mode
    %[varargout{1:nargout}]  = find_mdlrefs(xContext, 'MatchFilter', @Simulink.match.codeCompileVariants, varargin{:});

    % Since Variants handling is producing warnings, we have to deal with it!
    % --> Simulink:Commands:FindMdlrefsDefaultVariantsOptionWithVariantModel
    stCurrentWarnState = warning('off', 'all');
    oOnCleanupResetWarnState = onCleanup(@() warning(stCurrentWarnState));

    [varargout{1:nargout}] = find_mdlrefs(xContext, varargin{:});    
end
end
