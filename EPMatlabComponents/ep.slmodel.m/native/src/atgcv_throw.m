function atgcv_throw( stError )
% Raise a Matlab exception with the given error, registers the error as 
% EmbeddedTester error
%
% function atgcv_throw(stError)
%
%   See Matlab 'rethrow' for more information.
%
%   INPUT               DESCRIPTION
%     stError            (struct)
%       .message         (string) Error Message
%       .identifier      (string) Error identifier
%       <.fields>        User defined fields
%
%   OUTPUT              DESCRIPTION
%
%   THROWS
%           Itself
%
%   EXAMPLE
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
%   REMARKS
%     
%
%   <et_copyright>
%
%

%%
osc_throw( stError );


%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************
%******************************************************************************
% END OF FILE                                                             
%******************************************************************************
