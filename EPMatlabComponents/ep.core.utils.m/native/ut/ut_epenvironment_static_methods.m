function ut_epenvironment_static_methods()
% Tests the static method of EPEnv.
%
%  function ut_epenvironment_static_methods()
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

% Create tmp directory
sTmpDirecory = EPEnvironment.getTempDirectory();
MU_ASSERT_TRUE(exist(sTmpDirecory, 'dir'), 'Tmp dir not created.');

% Delete tmp directory
MU_ASSERT_TRUE(EPEnvironment.deleteDirectory(sTmpDirecory), 'Dir not deleted.');
MU_ASSERT_TRUE(~exist(sTmpDirecory, 'dir'), 'Temp dir not deleted.');

% Create directory 
EPEnvironment.createDirectory(sTmpDirecory);
MU_ASSERT_TRUE(exist(sTmpDirecory, 'dir'), 'Dir not created');

% Move file
sTmpFileSrc = fullfile(sTmpDirecory, 'test.txt');
sTmpFileTarget = fullfile(sTmpDirecory, 'test2.txt');
MU_ASSERT_TRUE(~exist(sTmpFileSrc, 'file'), 'Tmp file already exists.');
fd = fopen(sTmpFileSrc, 'w');
fclose(fd);
MU_ASSERT_TRUE(exist(sTmpFileSrc, 'file'), 'Tmp file not created.');
EPEnvironment.moveFile(sTmpFileSrc, sTmpFileTarget);
MU_ASSERT_TRUE(~exist(sTmpFileSrc, 'file'), 'Tmp file has not been moved,');
MU_ASSERT_TRUE(exist(sTmpFileTarget, 'file'), 'Tmp file has not been moved.');

% Delete directory
EPEnvironment.deleteDirectory(sTmpDirecory)
MU_ASSERT_TRUE(~exist(sTmpDirecory, 'dir'), 'Dir not deleted.');

% Exception handling: Add message and clean up env.
try 
    xEnv  = EPEnvironment();
    throw(MException('EP:STD:INTERNAL_ERROR', 'Internal Error')); % Induce failure
catch exception    
    try  
        EPEnvironment.cleanAndThrowException(xEnv, exception);
        MU_FAIL('Exception expected');
    catch exception
        MU_ASSERT_TRUE(~exist(xEnv.getMessengerFilePath, 'dir'), 'Cleaning Environment failed');
        MU_ASSERT_EQUAL(exception.identifier, 'EP:STD:INTERNAL_ERROR', ...
            ['Wrong exception has been thrown: ', exception.identifier]);
    end
end

% Exception handling: Throw exception if no env is given.
xEnv = [];
exception = MException('EP:STD:INTERNAL_ERROR', 'Internal Error');
try  
    EPEnvironment.cleanAndThrowException(xEnv, exception);
    MU_FAIL('Exception expected');
catch exception
    MU_ASSERT_EQUAL(exception.identifier, 'EP:STD:INTERNAL_ERROR_NO_ENV', ...
        ['Wrong exception has been thrown: ', exception.identifier]);
end

% Exception handling: Add message, export messages and cleaning up env.
try 
    sTmpDir = EPEnvironment.getTempDirectory();
    sTmpFile = 'error.xml';
    sFullExportPathForMsg = fullfile(sTmpDir, sTmpFile);
    xEnv  = EPEnvironment();
    throw(MException('EP:STD:INTERNAL_ERROR', 'Internal Error')); % Induce failure
catch exception    
    try  
        EPEnvironment.cleanAndThrowException(xEnv, exception, sFullExportPathForMsg);
        MU_FAIL('Exception expected');
    catch exception
        MU_ASSERT_TRUE(exist(sFullExportPathForMsg, 'file'), 'Message file has not been exported.');
        MU_ASSERT_TRUE(~exist(xEnv.getMessengerFilePath, 'dir'), 'Cleaning Environment failed');
        MU_ASSERT_EQUAL(exception.identifier, 'EP:STD:INTERNAL_ERROR', ...
            ['Wrong exception has been thrown: ', exception.identifier]);
        EPEnvironment.deleteDirectory(sTmpDir);
    end
end
end