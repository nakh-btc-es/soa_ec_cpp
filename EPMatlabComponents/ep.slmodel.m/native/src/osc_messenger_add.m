function [stError] = osc_messenger_add(stEnv, sMessageId, varargin)
% Add an error to the error messenger.
%
% function [stError] = osc_messenger_add(stEnv, sMessageId, varargin)
%
% An error message is created and added to the active messenger. The error is
% identified by a GroupID, identifiying the module or 'STD' for general
% messages, and by the actual MessageId. Depending on the message, additional
% argument are needed to add context specific data, like a filename for a "file
% not found" message.
%
%   INPUT               DESCRIPTION
%     stEnv                (struct)
%       .hMessenger         (messenger Identifier) Messenger to use, 
%                           type TBD (JW 14.11.2006)
% 
%     sMessageID             (string) Symbolic error identifier. It has to
%                               consists of two parts, separated by a double
%                               colon, like Matlab's error identifiers.
%                               '<Tool>:STD:###' identifies default messages
%     varargin   - Optional Arguments in <parameter>, <value> format.
%
%     Optional arguments in arbitrary order
%     '<Name>', '<Value>'   Additonal parameter, used to substitute variables in
%                           messages. Depends on message, is string.
%
%     !! NOTE: Keywords 'type' and 'lang' must not be used as parameter names 
%        because they are interpreted by function as attributes of the added 
%        message. !!
%
%   OUTPUT              DESCRIPTION
%     stError
%     .identifier        (string) Message Identifier as given in sMessageID
%     .message           (string) Substituted message (brief)


%%
if (isfield(stEnv, 'hMessenger') && ~isempty(stEnv.hMessenger) && isa(stEnv.hMessenger, 'EPEnvironment'))
    oMessenger = stEnv.hMessenger;
else
    oMessenger = atgcv_global_messenger_get();
end
oMessenger.addMessage(sMessageId, varargin{:});

stError = struct( ...
    'message',    '', ...
    'identifier', sMessageId);
end
