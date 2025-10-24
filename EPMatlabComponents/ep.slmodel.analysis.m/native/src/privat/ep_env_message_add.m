function ep_env_message_add(xEnv, varargin)
% Wrapper for empty messenger object: printing message into ML console.
%
%

%%
if isempty(xEnv)
    casMsg = varargin;
    fprintf('\n[Message] %s\n', casMsg{1});
    for i = 2:2:numel(casMsg)
        fprintf('    "%s": %s\n\n', casMsg{i}, casMsg{i+1});
    end
else
    xEnv.addMessage(varargin{:});
end
end