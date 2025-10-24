function oMessenger = atgcv_m_messenger_create(oParent, sName)
% Create a new Messenger-Instance
%
% function oMessenger = atgcv_m_messenger_create(oParent, sName)
%
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%     hMessenger         (Messenger) A new messenger identifier suitable for the
%                           atgcv_messenger_### - group of functions.
%
%   EXAMPLE
%       hMessenger = atgcv_messenger_create;
%
%   REMARKS
%     
%
%   (c) 2006 by OSC Embedded Systems AG, Germany


%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%        $ModuleDirectory/m/doc/DocumentName.odt
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Jens Wilken
% $$$COPYRIGHT$$$-2005
%
%   $Revision: 18748 $
%   Last modified: $Date: 2007-04-11 18:44:26 +0200 (Mi, 11 Apr 2007) $ 
%   $Author: ahornste $
%%


oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oMessenger = oAPI.createMessenger(oParent, sName);


%******************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                         
%                                                                         
%******************************************************************************


%******************************************************************************
% END OF FILE                                                             
%******************************************************************************
