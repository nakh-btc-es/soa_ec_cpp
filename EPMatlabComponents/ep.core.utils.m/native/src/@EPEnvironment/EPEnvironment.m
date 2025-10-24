classdef EPEnvironment < handle
    % This class handles the matlab environment for the embedded platform.
    % The following use cases are handled by this class:
    %  1. Messenger handling
    %  2. Progress handling
    %  3. Directory and file handling.
    
    %% hidden object properties
    properties (Hidden)
        sPath = '';            % The path to the env directory.
        sFilePath = '';        % The path to the messenger file.
        hProgress = [];        % The progress object.
        stProgress = struct( ...
            'nCurrent', 0, ...
            'nTotal',   0, ...
            'sMessage', '');
        sLastErrorId = '';     % The error ID of the last added message.
        bEchoMessages = false; % Shall added messages be displayed on ML console?
    end
    
    %% public object methods
    methods
        function oEnvObj = EPEnvironment(hProgress)
            % Creates a new environment object.
            %
            %  INPUT             DESCRIPTION
            %  - Progress         (handle)  An optional progress handle.
            
            if (nargin > 0)
                oEnvObj.hProgress = hProgress;
            end
            
            oEnvObj.sPath = EPEnvironment.getTempDirectory();
            if ~exist(oEnvObj.sPath, 'dir')
                throw(MException('EP:STD:INTERNAL_ERROR', 'Temporary managed directory does not exist.'));
            end
            
            % Generates a messenger xml for the logging.
            sMsgDir = i_createLocalTmpDir(oEnvObj.sPath);
            oEnvObj.sFilePath = fullfile(sMsgDir, 'error.xml');
            i_initMessageFile(oEnvObj.sFilePath);
        end
        
        %%
        function attachProgress(obj, hProgress)
            % Attach a progress object to the environment. Throws an exception if progress was already set.
            %  INPUT             DESCRIPTION
            %  - Progress         (handle)  A progress handle
            
            if isempty(hProgress)
                throw(MException('EP:STD:INTERNAL_ERROR', 'Progress is not a valid progress object.'));
            end
            if ~isempty(obj.hProgress)
                throw(MException('EP:STD:INTERNAL_ERROR', 'Environment has already set a progress object.'));
            end
            obj.hProgress = hProgress;
        end
        
        %%
        function value = getMessengerFilePath(obj)
            % Returns the absolute file path to the messenger.
            value = obj.sFilePath;
        end


        %%
        function sTmpDir = createLocalTmpDir(oObj)
            sTmpDir = i_createLocalTmpDir(oObj.sPath);
        end
        
        %%
        function setEchoMessages(obj, bEchoMessages)
            % Switches ON/OFF the echoing of added messages.
            obj.bEchoMessages = bEchoMessages;
        end
        
        %%
        function oMsgException = addMessage(obj, sMessageId, varargin)
            % Adds the message to the messenger and generates an exception that can be used for rethrowing.
            %
            %  INPUT             DESCRIPTION
            %  - sMessageID          (string)  Symbolic error identifier. It has to consist of two parts, separated by 
            %                                  a double colon, like Matlab's error identifiers.
            %  - varargin                      Optional string arguments in <parameter>, <value> format.
            %  OUTPUT            DESCRIPTION
            %  - oMsgException       (object)  An MException, holding the ID of the entered message but only an empty 
            %                                  text as the message text.
            
            obj.sLastErrorId = sMessageId;
            i_assertEnvValid(obj);
            try
                i_appendOneMessage(obj.sFilePath, sMessageId, varargin{:});
                if obj.bEchoMessages
                    i_echoMessage(sMessageId, varargin{:});
                end
            catch oEx
                obj.throwException(oEx);
            end
            oMsgException = MException(obj.sLastErrorId, '');
        end
        
        %%
        function oLastMsgException = addMessages(obj, casMessageIds, ccasMessageKeyValues)
            % Adds all messages in batch mode to the messenger and generates an exception for the last message that can be used for rethrowing.
            %
            %  INPUT             DESCRIPTION
            %  - casMessageIDs       (string)  Symbolic error identifiers ... (see addMessage)
            %  OUTPUT            DESCRIPTION
            %  - oMsgException       (object)  An MException, holding the ID of the last entered message but only an empty 
            %                                  text as the message text.
            
            nMsg = numel(casMessageIds);
            if (nMsg < 1)
                return;
            end
            if (numel(ccasMessageKeyValues) ~= nMsg)
                error('EP:USAGE:ERROR', 'Number of IDs and number of key-value cell arrays must be equal.');
            end
            i_assertEnvValid(obj);
            
            [hRootNode, oOnCleanupSaveAndClear] = i_openMessageFileForAppend(obj.sFilePath); %#ok<ASGLU> onCleanupObject
            for i = 1:nMsg
                sMessageId = casMessageIds{i};
                casKeyVals = ccasMessageKeyValues{i};
                
                i_appendMessage(hRootNode, sMessageId, casKeyVals{:});
                if obj.bEchoMessages
                    i_echoMessage(sMessageId, casKeyVals{:});
                end
            end
            obj.sLastErrorId = casMessageIds{end};
            oLastMsgException = MException(obj.sLastErrorId, '');
        end
        
        %%
        function value = getLastMessageEntry(obj)
            % Returns the ID of the last added message.            
            value = obj.sLastErrorId;
        end
        
        %%
        function value = isMessageAlreadyAdded(obj, sMessageId)
            % Verifies if the sMessageId is equal to the Id of the last added message.
            %
            %  INPUT             DESCRIPTION
            %  - sMessageIDd      (String)  Symbolic error identifier. It has to
            %                               consists of two parts, separated by a double
            %                               colon, like Matlab's error identifiers.
            %
            %  OUTPUT            DESCRIPTION
            %  - value            (boolean) True, if the sMessagId is equal to the id of the last added message.
            %                               Otherwise, false.
            value = strcmp(obj.sLastErrorId, sMessageId);
        end
        
        %%
        function throwException(obj, error) %#ok Maybe, a logging can be introduced. In this case, it sould be not static.
            % Throws an exception.
            %
            throw(error);
        end
        
        %%
        function rethrowException(obj, error) %#ok Maybe, a logging can be introduced. In this case, it sould be not static.
            % Rethrows an exception.
            %            
            rethrow(error);
        end
        
        %%
        function setProgress(obj, nCurrent, nTotal, sMessage)
            % Sets the progress of the progress object. If no progress object is set, the method will do nothing.
            %
            %   PARAMETER(S)    DESCRIPTION
            %   -  nCurrent         (int)    Current work
            %   -  nTotal           (int)    Total work
            %   -  nCurrent         (String) Messag to display
            %            
            if ~isempty(obj.hProgress)
                if (nargin < 4)
                    sMessage = obj.stProgress.sMessage;
                else
                    obj.stProgress.sMessage = sMessage;
                end
                if (nargin < 3)
                    nTotal = obj.stProgress.nTotal;
                else
                    obj.stProgress.nTotal = nTotal;
                end
                try
                    obj.hProgress.setProgress(nCurrent, nTotal, sMessage);
                catch oEx %#ok
                    %Progress could not be set.
                    %TODO: Maybe an error should be logged.
                end
            end
        end
        
        %%
        function exportMessages(obj, sExportPath)
            % Exports the logged messages to a given file.
            %
            %   PARAMETER(S)    DESCRIPTION
            %   - sExportPath       (String) Absolute file path for the messenger file.
            %
            if isempty(sExportPath)
                return;
            end
            i_assertEnvValid(obj);
            copyfile(obj.sFilePath, sExportPath);
        end
        
        %%
        function clearMessages(obj)
            % Removes all messages from the current error file.
            %
            i_initMessageFile(obj.sFilePath); % reset by re-creating the XML file
        end
        
        
        %%
        function attachMessages(obj, sImportFile)
            % Imports messages from the provided external messenger file.
            %
            %   PARAMETER(S)    DESCRIPTION
            %   - sImportFile       (String) Absolute of the messenger file to be imported.
            %
            i_importMessages(obj, sImportFile);
        end
        
        %%
        function clear(obj)
            % Clears the environment. After clearing the env, only static method can be used.

            if ~isempty(obj.sPath)
                obj.deleteDirectory(obj.sPath);
            end
            obj.sPath = '';
            obj.sFilePath = '';
            obj.hProgress = [];
            obj.sLastErrorId = '';
        end
    end
    
    %% static properties
    properties (Constant)
        managedDirectory = java.util.HashMap();
    end
    
    %% static public class methods
    methods (Static)
        function [sTempPath, jManagedDir] = getTempDirectory()
            % Creates a new empty temp directory and returns the abosolute path to it.
            %
            try
                jManagedDir = i_createManagedDir();

                sTempPath = i_normalizeFileAbsPath(jManagedDir.getPath().getAbsolutePath());
                EPEnvironment.managedDirectory.put(sTempPath, jManagedDir);
            catch exc
                warning(['EPEnvironment exception when creating an empty temp directory:', exc.message]);
            end
        end
        
        %%
        function sMsg = getReport(oEx)
            % Pretty print the message of an MException with less details compared to the inherent MException method "getReport"
            %
            sMsg = i_getReport(oEx);
        end
        
        %%
        function bSuccess = deleteDirectory(sFullDir)
            % Deletes a directory with its subdirectories.
            %
            if isempty(sFullDir)
                bSuccess = true;
                return;
            end
            sFullDir = i_normalizeFileAbsPath(sFullDir);
            
            jManagedDir = EPEnvironment.managedDirectory.get(sFullDir);
            if ~isempty(jManagedDir)
                jManagedDir.cleanup();
                EPEnvironment.managedDirectory.remove(sFullDir);
                if (exist(sFullDir, 'dir') || ~isempty(EPEnvironment.managedDirectory.get(sFullDir)))
                    bSuccess = false;
                else
                    bSuccess = true;
                end
            else
                bSuccess = rmdir(sFullDir, 's');
                iLoop = 0;
                while (~bSuccess && (iLoop < 10))
                    iLoop = iLoop + 1;
                    bSuccess = rmdir(sFullDir, 's');
                end
            end
        end
        
        %%
        function bSuccess = createDirectory(sFullDir)
            % Creates a directory at the provided location.
            %
            bSuccess = mkdir(sFullDir);
        end
        
        %%
        function bSuccess = moveFile(sFileFrom, sFileTo)
            % Moves a file.
            %
            %   PARAMETER(S)    DESCRIPTION
            %   - sFileFrom            (string)  full path to source file
            %   - sFileTo              (string)  full path to destination file
            %
            %   OUTPUT          DESCRIPTION
            %   bSuccess             (boolean) True, the operation was successful. Otherwise, false.
            %
            
            % if name exactly equal --> nothing to do
            if strcmpi(sFileFrom, sFileTo)
                bSuccess = true;
            else
                try
                    bSuccess = movefile(sFileFrom, sFileTo, 'f');
                catch oEx %#ok
                    bSuccess = false;
                end
            end
        end
        
        %%
        function cleanAndAddException(oEnv, oException, sExportPathMessages)
            % Adds exception to the environment, after exporting the messages, the environment will be cleaned
            %
            % This method should be used by the application layer in order to clean the environment and
            % export the messages.
            %
            % Behavior:
            %   1. Exceptions not added to the messenger are added to the messenger. (Only if oEnv != null)
            %   2. Cleans the given environment.
            %   3. Throws a proper exception for other layers. (RCP or M-API)
            %       - 'EP:STD:INTERNAL_ERROR_NO_ENV' is thrown if oEnv is null. Hence, no error log exists.
            %       - 'EP:STD:INTERNAL_ERROR' is thrown if the exception must not be added to the messenger.
            %       - 'EP:STD:INTERNAL_ERROR' is thrown if the exception must be added to the messenger.
            %
            %   PARAMETER(S)    DESCRIPTION
            %   - oEnv                 (object) An EPEnvironment object or null
            %   - oException           (object) An MException. Must not be null.
            %   - sExportPathMessages  (String) Absolute export path for the messenger. Before the environment
            %                                   is cleaned up, all messages are exported to the given file.
            %                                   Can be null.
            %
            if (nargin < 3)
                sExportPathMessages = '';
            end
            if isempty(oEnv)
                % This exception is a special one, because it is not added to the error log.
                error('EP:STD:INTERNAL_ERROR_NO_ENV', '%s', oException.message);
            else
                oEnv.attachMessages(sExportPathMessages);
                if ~oEnv.isMessageAlreadyAdded(oException.identifier)
                    addGenericMatlabExceptionAsMessage(oEnv, oException);
                end
                oEnv.exportMessages(sExportPathMessages);
                oEnv.clear();
            end
        end
        
        %%
        function cleanAndThrowException(oEnv, oException, sExportPathMessages)
            % Cleans the environment and throws a proper exception for other layers.
            %
            % This method should be used by the application layer in order to clean the environment and
            % to throw a proper exception for other layers.
            %
            % Behavior:
            %   1. Exceptions not added to the messenger are added to the messenger. (Only if oEnv != null)
            %   2. Cleans the given environment.
            %   3. Throws a proper exception for other layers. (RCP or M-API)
            %       - 'EP:STD:INTERNAL_ERROR_NO_ENV' is thrown if oEnv is null. Hence, no error log exists.
            %       - 'EP:STD:INTERNAL_ERROR' is thrown if the exception must not be added to the messenger.
            %       - 'EP:STD:INTERNAL_ERROR' is thrown if the exception must be added to the messenger.
            %
            %   PARAMETER(S)    DESCRIPTION
            %   - oEnv                 (object) An EPEnvironment object or null
            %   - oException           (object) An MException. Must not be null.
            %   - sExportPathMessages  (String) Absolute export path for the messenger. Before the environment
            %                                   is cleaned up, all messages are exported to the given file.
            %                                   Can be null.
            %
            if (nargin < 3)
                sExportPathMessages = '';
            end
            EPEnvironment.cleanAndAddException(oEnv, oException, sExportPathMessages);
            if (nargin >= 3)
                % Add message xml path informations to the exception so that the file can be accessed even if the
                % consumer does not have knowlodge about the file or acccess to the EPEnvironment
                % Most prominent usecase: EPI Architecture update
                oException = addCause(oException, MException( ...
                    'EP:INTERNAL:MSGXML', ['Message log: ', strrep(sExportPathMessages, '\', '\\')]));
            end
            rethrow(oException);
        end
    end
    
    %% hidden object methods
    methods (Hidden = true)
        function addGenericMatlabExceptionAsMessage(oObj, oEx)
            oObj.addMessage('EP:STD:MATLAB_EXCEPTION', 'msg', i_getReport(oEx));
        end
    end    
end



%%
% prepare a report for an MException object but with less details compared to the inherent MException method "getReport"
function sMsg = i_getReport(oEx)
sMsg = i_filterOutHyperlinks(oEx.message);
if ~isempty(oEx.cause)
    sMsg = sprintf('%s\n\nCaused by:\n', sMsg);
    for i = 1:length(oEx.cause)
        sMsg = i_extendMessageWithCause(sMsg, oEx.cause{i}, 1);
    end
end
end


%%
function sMsg = i_extendMessageWithCause(sMsg, oEx, nLevel)
sTabs = repmat('  ', 1, nLevel);
sMsg = sprintf('%s\n%s%s', sMsg, sTabs, i_filterOutHyperlinks(oEx.message));
for i = 1:length(oEx.cause)
    sMsg = i_extendMessageWithCause(sMsg, oEx.cause{i}, nLevel + 1);
end
end


%%
function sText = i_filterOutHyperlinks(sText)
sText = regexprep(sText, '<[^>]+>', '');
end


%%
function i_appendOneMessage(sErrFile, sMessageId, varargin)
[hRootNode, oOnCleanupSaveAndClear] = i_openMessageFileForAppend(sErrFile); %#ok<ASGLU> onCleanupObject
i_appendMessage(hRootNode, sMessageId, varargin{:});
end


%%
function i_appendMessage(hDoc, sMessageId, varargin)
hNode = mxx_xmltree('add_node', hDoc, 'Message');
mxx_xmltree('set_attribute', hNode, 'id', sMessageId);
for i = 1:2:length(varargin)
    sKey   = varargin{i};
    sValue = varargin{i + 1};
    if ~ischar(sValue)
        error('EP:API:INTERNAL_ERROR', 'Only string values expected.');
    end
    if ~ischar(sKey)
        error('EP:API:INTERNAL_ERROR', 'Only string keys expected.');
    end
    
    hNodeKeyValue = mxx_xmltree('add_node', hNode, 'KeyValue');
    mxx_xmltree('set_attribute', hNodeKeyValue, 'key',   sKey);
    mxx_xmltree('set_attribute', hNodeKeyValue, 'value', sValue);    
end
end


%%
function [hRootNode, oOnCleanupSaveAndClear] = i_openMessageFileForAppend(sErrFile)
hDoc = mxx_xmltree('load', sErrFile);
hRootNode = mxx_xmltree('get_root', hDoc);
oOnCleanupSaveAndClear = onCleanup(@() i_saveAndClear(hDoc, sErrFile));
end


%%
function i_saveAndClear(hDoc, sFile)
mxx_xmltree('save', hDoc, sFile);
mxx_xmltree('clear', hDoc);
end


%%
function i_assertEnvValid(oObj)
if isempty(oObj.sPath)
    error('EP:STD:INTERNAL_ERROR', 'EPEnvironment was cleared.');
end
if ~exist(oObj.sPath, 'dir')
    error('EP:STD:INTERNAL_ERROR', 'Temporary managed directory does not exist.');
end
if ~exist(oObj.sFilePath, 'file')
    error('EP:STD:INTERNAL_ERROR', 'Internal message file does not exist.');
end
end


%%
function i_importMessages(oObj, sImportFile)
if (isempty(sImportFile) || ~exist(sImportFile, 'file'))
    return;
end
hDoc = mxx_xmltree('load', sImportFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

ahMessages = mxx_xmltree('get_nodes', hDoc, '//Message');
for i = 1:length(ahMessages)
    hMessage = ahMessages(i);
    
    sMessageId = mxx_xmltree('get_attribute', hMessage, 'id');
    astKeyValues = mxx_xmltree('get_attributes', hMessage, './KeyValue', 'key', 'value');
    if isempty(astKeyValues)
        casParams = {};
    else
        casParams = reshape([{astKeyValues.key}; {astKeyValues.value}], 1, []);
    end
    addMessage(oObj, sMessageId, casParams{:});
end
end


%%
function sPath = i_normalizeFileAbsPath(xPath)
if isempty(xPath)
    sPath = '';
else
    sPath = '';
    if ischar(xPath)
        sPath = xPath;
    elseif isjava(xPath)
        if isa(xPath, 'java.lang.String')
            sPath = char(xPath);
        elseif isa(xPath, 'java.io.File')
            sPath = char(xPath.getAbsolutePath());
        end
    end
            
    jFile = java.io.File(sPath);
    if ~jFile.isAbsolute()
        sRootPath = pwd();
        jFile = java.io.File(sRootPath, sPath);
    end

    try
        sPath = char(jFile.getCanonicalPath());
    catch oEx %#ok
        % Exception occured, continue with absolute path
        sPath = char(jFile.getAbsolutePath());
    end
end
end


%%
function i_initMessageFile(sFilePath)
hRootNode = mxx_xmltree('create', 'Messages');
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRootNode));

mxx_xmltree('save', hRootNode, sFilePath);
end


%%
function i_echoMessage(sMessageId, varargin)
fprintf('%s\n', i_formatMessage(sMessageId, varargin{:}));
end


%%
function sMessage = i_formatMessage(sMessageId, varargin)
sMessage = sprintf('[%s] ', sMessageId);
casArgs = varargin;
for i = 1:2:numel(casArgs)
    sKey = casArgs{i};
    sVal = casArgs{i + 1};
    sMessage = [sMessage, sprintf('\n  %s = "%s"', sKey, sVal)]; %#ok<AGROW>
end
end


%%
function jManagedDir = i_createManagedDir(sParentDir)
if (nargin < 1)
    sParentDir = i_getTmpRootDir();
end

jParentDir = java.io.File(sParentDir);
jManagedDir = ct.nativeaccess.ResourceServiceFactory.getInstance().createManagedTempDirectory(jParentDir, false);

% i_printDebugWithStackTrace(i_normalizeFileAbsPath(jManagedDir.getPath().getAbsolutePath()));
end


%%
function sRootDir = i_getTmpRootDir()
sDebugDir = getenv('EP_DEBUG_TEMP');
if ~isempty(sDebugDir) && isfolder(sDebugDir)
    sRootDir = sDebugDir;
else
    sRootDir = tempdir();
end
end


% %%
% function i_printDebugWithStackTrace(sTmpDir)
% astStackTrace = dbstack;
% 
% % Print each element of the stack trace
% fprintf('\nTempdir = "%s" ---- Current Stack Trace:\n', sTmpDir);
% for i = 1:length(astStackTrace)
%     fprintf('File: %s, Function: %s, Line: %d\n', ...
%         astStackTrace(i).file, astStackTrace(i).name, astStackTrace(i).line);
% end
% fprintf('\n\n');
% end


%%
function sTmpDir = i_createLocalTmpDir(sRootDir)
sTmpDir = tempname(sRootDir);
mkdir(sTmpDir);
end
