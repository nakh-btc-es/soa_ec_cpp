function varargout = ep_core_toolcall(sToolName, sEnvArray, varargin)
% Execute an EmbeddedPlatform executable.
%
% function [bSuccess, sError, sOutput] = ep_core_toolcall(sToolName, sEnvArray, varargin)
%
%   INPUT               DESCRIPTION
%   - sToolName            (string)  Case sensitive name of the executable.
%                                    Must not contain OS specific suffix (".exe").
%   - sEnvArray            (string[])
%                                    Environment key value pairs
%   - varargin             (string)  Parameters for the tool call as strings.
%
%   OUTPUT              DESCRIPTION
%   - bSuccess             (boolean) true on success, false otherwise
%   - sOutput              (string)  Content of output stream.
%   - sError               (string)  Content of error stream.
%

% create working directory
[jManagedTempDir, oOnCleanupRemoveDir] = i_createManagedDir(); %#ok<ASGLU> onCleanup object
jWorkDirFile = jManagedTempDir.getPath();
jToolName = java.lang.String(sToolName);

% create process builder
jList = java.util.ArrayList();
jList.add(jToolName);
for i = 1:length(varargin)
    sParameter = varargin{i};
    jParameter = java.lang.String(sParameter);
    jList.add(jParameter);
end

jOutputFile = [];
jErrorFile  = [];

try
    % create OS depending suffix for executables
    bIsWindows = ct.system.OS.isWindows();
    
    sSuffix = '';
    if bIsWindows
        sSuffix = '.exe';
    end
    jNativeExecutor = ct.nativeaccess.NativeExecutorFactory.getInstance();
    jNativeExecutor.provideNativeFile([], [sToolName, sSuffix]);
    jProcessBuilder = jNativeExecutor.command([], jList);
    
    for i = 1:2:length(sEnvArray)
        jMap = jProcessBuilder.environment();
        jKey = java.lang.String(sEnvArray{i});
        jValue = java.lang.String(sEnvArray{i + 1});
        jMap.put(jKey, jValue);
    end
    
    % set working directory
    jProcessBuilder.directory(jWorkDirFile);
    
    % stdout and stderr redirected to a file
    jOutputFile = java.io.File(jWorkDirFile, java.lang.String('out.log'));
    jErrorFile  = java.io.File(jWorkDirFile, java.lang.String('err.log'));
    jProcessBuilder.redirectOutput(jOutputFile);
    jProcessBuilder.redirectError(jErrorFile);
    
    % now start csourcescollect synchronously
    jProcess = jProcessBuilder.start();
    jProcess.waitFor();
    
    % prepare result parameters
    varargout{1}  = jProcess.exitValue;
    
    if nargout >= 2
        varargout{2} = fileread(char(jErrorFile.getAbsolutePath()));
    end
    if nargout >= 3
        varargout{3}  = fileread(char(jOutputFile.getAbsolutePath()));
    end
    
catch oEx
    varargout{1}  = false;
    varargout{2}  = oEx.message;
    varargout{3} = '';
end

% cleanup
if ~isempty(jOutputFile)
    jOutputFile.delete(); 
end
if ~isempty(jErrorFile)
    jErrorFile.delete()
end
end


%%
function [jManagedTempDir, oOnCleanupRemove] = i_createManagedDir()
[~, jManagedTempDir] = EPEnvironment.getTempDirectory();
oOnCleanupRemove = onCleanup(@() jManagedTempDir.cleanup());
end
