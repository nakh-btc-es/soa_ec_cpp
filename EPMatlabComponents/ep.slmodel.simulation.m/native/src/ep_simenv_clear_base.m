function ep_simenv_clear_base()
% Clears the workspace 'base' from the EP variables.
%
% function ep_simenv_clear_base()
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%  


%%
try evalin('base', 'clear i_if_*;'); catch, end
try evalin('base', 'clear o_if_*;'); catch, end
try evalin('base', ['clear ', ep_simenv_pause_name, ';']); catch, end
end
