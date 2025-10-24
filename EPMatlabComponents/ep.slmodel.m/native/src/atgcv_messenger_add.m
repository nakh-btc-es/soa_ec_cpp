function [stError] = atgcv_messenger_add(hMessenger, sErrorId, varargin)
% Add an error to the EmbeddedTester error messenger system.
%
% function [stError] = atgcv_messenger_add(hMessenger, sErrorId, varargin)
%
% An error message is created and added to the active messenger. The error 
% is identified by a GroupID, identifiying the module or 'STD' for general
% messages, and by the actual MessageId. Depending on the message, 
% additional argument are needed to add context specific data, 
% like a filename for a "file not found" message.
%
%   INPUT               DESCRIPTION
%
%     hMessenger        (handle)    EmbeddedTester messenger handle to use
% 
%     sErrorId          (string)    Symbolic error identifier. It has to
%                                   consists of two parts, separated by a 
%                                   double colon, like Matlab's error 
%                                   identifiers.
%                                   '<Tool>:STD:###' identifies default
%                                   messages.
%
%     varargin   - Optional Arguments in <parameter>, <value> format.
%
%     Optional arguments in arbitrary order
%     '<Name>', '<Value>'   Additonal parameter, used to substitute variables in
%                           messages. Depends on message, is string.
%
%
%     !! NOTE: Keywords 'type' and 'lang' must not be used as parameter names 
%        because they are interpreted by function as attributes of the added 
%        message. !!
%
%
%   OUTPUT              DESCRIPTION
%
%     stError
%     .identifier        (string) Message Identifier as given in sErrorID
%     .message           (string) Substituted message (brief)
%
%   THROWS
%
%   EXAMPLE
%
%
%   .... % oProfile is defined
%   stInfo = atgcv_profile_info_get( oProfile );
%
%   hMessenger = stInfo.hMessenger;
%
%   stError = atgcv_messenger_add( hMessenger, ...
%       'API:STD:FILE_NOT_FOUND','file','file.xml');
%   atgcv_throw(stError); // throws itself 
%
%
%   REMARKS
%     
%
%   <et_copyright>
%
%

%%

stEnv.hMessenger = hMessenger;
stError = osc_messenger_add(stEnv, sErrorId, varargin{:});


%**************************************************************************
% END OF FILE                                                             
%**************************************************************************
