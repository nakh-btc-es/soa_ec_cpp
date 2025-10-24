function varargout = ep_libinfo(sModel)
% Centralized version of libinfo that takes care of removing inactive Variants from the search.
%
% function varargout = ep_libinfo(sModel)
%
%   INPUT               DESCRIPTION
%     sModel            (string)         name of the model
%
%   OUTPUT              DESCRIPTION
%     varargout         (...)            return arguments of the libinfo call
%


%%
persistent p_bIsOldML;
if isempty(p_bIsOldML)
    p_bIsOldML = verLessThan('matlab', '9.13');
end


%%
if p_bIsOldML
    [varargout{1:nargout}] = libinfo(sModel);
else
    [varargout{1:nargout}] = libinfo(sModel, 'MatchFilter', @Simulink.match.activeVariants);
end
end
