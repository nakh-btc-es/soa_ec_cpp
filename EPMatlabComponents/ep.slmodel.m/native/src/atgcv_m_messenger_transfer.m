function atgcv_m_messenger_transfer(stEnv, sMessengerFile)
% Transfer the messages current error message system.
%
% function atgcv_m_messenger_transfer(stEnv, sMessengerFile)
%
%   INPUT              DESCRIPTION
%     stEnv              (struct)  Environment structure with a component
%                                  ".hMessenger"
%     sMessengerFile     (string)  Message file
%
%   OUTPUT             DESCRIPTION
%
%   REFERENCE(S):
%     ---
%
%   RELATED MODULES:
%     ---
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2010
%%



xDocInit = mxx_xmltree('load', sMessengerFile );
ahMessage = mxx_xmltree('get_nodes', xDocInit, '//Message');

for i=1:length(ahMessage)
    hMessage = ahMessage(i);
    sNr = mxx_xmltree('get_attribute', hMessage, 'nr');
    sType = mxx_xmltree('get_attribute', hMessage, 'type');
    sMessage = mxx_xmltree('get_attribute', hMessage, 'msg');
    sDate = mxx_xmltree('get_attribute', hMessage, 'date');

    sRemark = '';
    sHint = '';
    hRemarkNode = mxx_xmltree('get_nodes', hMessage, 'child::Remark');
    if( ~isempty( hRemarkNode ) )
        sRemark = mxx_xmltree('get_content', hRemarkNode(1));
    end
    hHintNode = mxx_xmltree('get_nodes', hMessage, 'child::Hint');
    if( ~isempty( hHintNode ) )
        sHint = mxx_xmltree('get_content', hHintNode(1));
    end
    

    atgcv_m_messenger( stEnv.hMessenger, 'copy', sNr, sType,...
                       sMessage, sDate, sRemark, sHint);
end

mxx_xmltree('clear',xDocInit);

%**************************************************************************
% END OF FILE
%**************************************************************************
