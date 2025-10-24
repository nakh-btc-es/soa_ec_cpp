function [sTmpDir, jManagedDir] = sltu_tmpdir_get(sParentDir)
% Return a newly created managed temp directory that is removed automatically when closing Matlab.
%
% function [sTmpDir, jManagedDir] = sltu_tmpdir_get(sParentDir)
%
%
%  INPUT                        DESCRIPTION
%   sParentDir                     (string)   path to an existing(!) directory where the managed directory shall be
%                                             placed (default == tempdir)
%
%  OUTPUT                       DESCRIPTION
%   sTmpDir                        (string)   the path to the created managed directory
%   jManagedDir                    (java)     the ManagedDirectory Java object if a more detailed handling (e.g. manual
%                                             removal) is needed by the caller
%


%%
if (nargin < 1)
    sParentDir = i_getTmpRootDir();
end

jParentDir = java.io.File(sParentDir);
jManagedDir = ct.nativeaccess.ResourceServiceFactory.getInstance().createManagedTempDirectory(jParentDir, false);
sTmpDir = char(jManagedDir.getPath().getCanonicalPath());

% i_printDebugWithStackTrace(sTmpDir);
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


%%
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