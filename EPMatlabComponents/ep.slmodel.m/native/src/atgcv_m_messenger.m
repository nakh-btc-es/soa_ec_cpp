function [varargout] = atgcv_m_messenger( hMessenger, varargin )
%  Internal messenger main function.
%
%  varargout = atgcv_m_messenger.m(varargin)
%
%   INPUT                   DESCRIPTION
%    hMessenger         (messenger Identifier) Messenger to use,
%                           type TBD (JW 14.11.2006)
%    'init'         init the internal data structure
%    'reset' sDate  reset the internal data structure (suitable for unit tests)
%                   The parameter 'sDate' is optional. Only messages with
%                   the timestamp or new messages will be deleted.
%    'open' sFile   open existing xml file, the internal data structure will be initialized with the contents
%    'save' sFile   open existing xml file, the internal data structure will be initialized with the contents
%           sDate   The parameter 'sDate' is optional. Only messages with
%                   the same timestamp or newer messages will be saved.
%    'insert',  sNr         (string) error number
%               sType       (string) error|warning|note
%               sMessage    (string) error message
%               sRemark     (string) optional remark (otherwise empty string)
%               sHint       (string) optional hint (otherwise empty string)
%    'status'   sStatus     (string) get the current status
%    'number'   sDate       (string) return the messages amount
%
%   OUTPUT                  DESCRIPTION
%     bPresent (numerical)  current status exists in message stack
%     nNumber  (numerical)  amount of messages found with error number
%
%   If a message should be inserted but the messenger wasn't initialized, an automatic initialization would be perfomed.
%
%   REFERENCE(S):
%     Design Document:
%        Section : M18
%        Download:
%        http://pcosc29/dp2004/Download.aspx?ID=1cd1982c-9a3f-4a8d-a155-ce05bc5d84a6
%
%   RELATED MODULES:
%     -
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%   $Revision: 9134 $ Last modified: $Date: 2006-10-19 18:11:34 +0200 (Do, 19 Okt 2006) $ $Author: hilger $



%%
error('ERROR:DEPRACTED', 'Script "%s" is deprecated and shall never be called.', mfilename);


% check parameter

sCmd = varargin{1};


% short-cut for special case
if strcmpi(sCmd, 'close_global')
    com.btc.et.api.impl.MessengerUtils.disposeGlobalMessenger();
    return;
end

if isnumeric(hMessenger)
    if( hMessenger == 0 )      
        hMessenger = com.btc.et.api.impl.MessengerUtils.getGlobalMessenger();
    end
end

switch lower(sCmd)
    case 'get_global'
        varargout{1} = hMessenger;
%     case 'close_global'
%         if( ~isempty(xtree) )
%             em_manager_close(xtree);
%         end
%         xtree = [];
    case 'reset'
        if( isequal( nargin , 3 ) )
            i_reset(hMessenger,varargin{2});
        else
            i_reset_full(hMessenger);
        end
        
    case 'save'
        if( isequal( nargin , 4 ) )
            i_save(hMessenger,varargin{2}, varargin{3});
        else
            i_export( hMessenger,varargin{2});
        end
    case 'copy'
        i_Copy(hMessenger, varargin{2},...
            varargin{3}, varargin{4}, varargin{5}, varargin{6}, varargin{7});
    case 'remove'
        i_Remove(hMessenger, varargin{2}, varargin{3});
    case 'delete'
        i_Delete(hMessenger, varargin{2}, varargin{3}, varargin{4});
    case 'status'
        varargout{1} = i_GetStatus(hMessenger,varargin{2});
    case 'number'
        if( isequal( nargin , 3 ) )
            varargout{1} = i_GetNumberAttributes(hMessenger, varargin{2});
        else
            varargout{1} = i_GetNumberAttributes(hMessenger );
        end
    otherwise
        error( 'ATGCV:API:ERROR', 'Unkown command: %s!', sCmd );
end


%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************



%%
function i_Remove(oMessenger, sNr, sDate )
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oAPI.deleteAfter( oMessenger, sNr, sDate);
return;

%%
function i_Delete(oMessenger, sNr, sMsg, sDate )
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oMessageList = oAPI.getMessagesAfter(oMessenger, sDate);

for i = 0:oMessageList.size()-1
    oMessage = oMessageList.get(i);
    
    if strcmp(char(oMessage.getDate()), sDate) && ...
        strcmp(char(oMessage.getNr()), sNr) && ...
        strcmp(char(oMessage.getText()), sMsg)
        oMessenger.deleteMessage(oMessage);
    end
end
return;


%%
function i_Copy(oMessenger, sNr, sType, sMessage, sDate, sRemark, sHint)
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oAPI.copy(oMessenger, sNr, sType, sMessage, sDate, sRemark, sHint);
return;

%%
function bPresent = i_GetStatus(oMessenger,sType)
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
bPresent = oAPI.getStatus(oMessenger,sType);
return;




%%
function nNumber = i_GetNumberAttributes( oMessenger, sDate )
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
if( isequal( nargin , 2 ) )
    oList = oAPI.getMessagesAfter(oMessenger,sDate);
else
    oList = oAPI.getAllMessages(oMessenger);
end
nNumber = oList.size();
return;

%%
function i_reset_full( oMessenger )
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oAPI.reset(oMessenger);
return;

%%
function i_reset( oMessenger, sDate )
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oAPI.resetAfter(oMessenger,sDate);
return;


%%
function i_save( oMessenger, sFile, sDate )
oFile = java.io.File(sFile);
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oAPI.exportMessagesAfter(oMessenger, oFile, sDate);
return;

%%
function i_export( oMessenger, sFile )
oFile = java.io.File(sFile);
oAPI = com.btc.et.messenger.MessengerAPIFactory.getInstance();
oAPI.export(oMessenger, oFile);
return;


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
