function ut_epenvironment_methods()
% Tests the public methods of EPEnv.
%
%  function ut_epenvironment_methods()
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%
try
    % Test create empty env
    xEnv = EPEnvironment();
    MU_ASSERT(exist(xEnv.getMessengerFilePath(), 'file'), 'No messenger file has been created.');

    % Get error dtd
    oMessengerImpl = ep.core.messenger.impl.MessengerImpl;
    oErrorDtdFile = ct.nativeaccess.ResourceServiceFactory.getInstance().getResourceAsFile(oMessengerImpl.getClass, 'spec/message_codes.dtd');
    
    % Test add message
    err = xEnv.addMessage('EP:Group:Test', 'key', 'value');
    MU_ASSERT(isa(err, 'MException'), 'No MException object has been created.');
    MU_ASSERT(strcmp(err.identifier, 'EP:Group:Test'), 'ID of created MException is wrong.');
    hDoc = mxx_xmltree('load' , xEnv.getMessengerFilePath());
    
    MU_ASSERT_EQUAL(true, mxx_xmltree('validate', hDoc, char(oErrorDtdFile.getAbsolutePath())), ...
        'Error Code Xml does not validate');
    
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hDoc, '//Message[@id=''EP:Group:Test'']')), 'No message added.');
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_nodes', hDoc, '//KeyValue')), 'No KeyValue added.' );
    mxx_xmltree('clear', hDoc);

    % Test last message entry
    MU_ASSERT_TRUE(strcmp(xEnv.getLastMessageEntry(), 'EP:Group:Test'), 'Last message not registered.');
    MU_ASSERT_TRUE(xEnv.isMessageAlreadyAdded('EP:Group:Test'), 'Last message not registered.');

    % Test export messages
    sTmpDir = EPEnvironment.getTempDirectory();
    sTmpFile = fullfile(sTmpDir, 'error.xml');
    MU_ASSERT_TRUE(~exist(sTmpFile, 'file'), 'Tmp file for messages already exists.')
    xEnv.exportMessages(sTmpFile);
    MU_ASSERT_TRUE(exist(sTmpFile, 'file'), 'Messages have not been exported.')
    EPEnvironment.deleteDirectory(sTmpDir);

    %% Test throw and rethrow exception
    try
        xEnv.throwException(MException('EP:Test:Msg', 'Test'));
        MU_FAIL('Exception expected.');
    catch exception
        try
            xEnv.rethrowException(exception)
            MU_FAIL('Exception expected.');
        catch exception
            MU_ASSERT_TRUE(strcmp(exception.identifier, 'EP:Test:Msg'), 'Wrong exception has been thrown.')
        end
    end

    % Test setProgress, if no progress object has been set.
    try
        xEnv.setProgress(0,100,'No progress');
        MU_PASS('No exception expected.');
    catch
        MU_FAIL('Unexpected exception.');
    end
    
    % Test env clear
    xEnv.clear();
    MU_ASSERT(~exist(xEnv.getMessengerFilePath(), 'file'), 'Clear env does not work correctly.');
catch exception
    %% Unexpected exception
    MU_FAIL(exception.message);
    xEnv.clear();
    EPEnvironment.deleteDirectory(sTmpDir);
end
end