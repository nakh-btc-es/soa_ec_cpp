function sTempPath = sltu_context_tmpdir_get(sContextKey)
% Returns a temporary directory for a specific context (== key) that will be removed automatically.
%
%

persistent p_mContext2TempPath;
persistent p_jTmpRootManagedDir;


%% default context
if (nargin < 1)
    sContextKey = 'DEFAULT_GLOBAL_CONTEXT';
end

%% handling 0 output corner case and lock/unlock management
mlock;
if (nargout < 1)
    % special case: for unlocking this function user is calling "sltu_tempdir_get('unlock')"
    if strcmp(sContextKey, 'unlock')
        munlock;
    end
    if (strcmp(sContextKey, 'reset') && ~isempty(p_jTmpRootManagedDir))
        sTmpRoot = i_getDirPath(p_jTmpRootManagedDir);
        fprintf('\n[INFO] Removing root cache directory "%s" for the following contexts ...\n', sTmpRoot);

        casTempContexts = p_mContext2TempPath.keys;
        for i = 1:numel(casTempContexts)
            fprintf('\n[INFO] ... "%s"\n', casTempContexts{i})
        end

        if exist(sTmpRoot, 'dir')
            bSuccess = i_removeManagedDir(p_jTmpRootManagedDir);
            if bSuccess
                fprintf('\n[INFO] ... successful!\n\n');
            else
                fprintf('\n[INFO] ... failed!\n\n');
            end
        else
            fprintf('\n[INFO] ... not necessary!\n\n');
        end

        p_jTmpRootManagedDir = [];
        p_mContext2TempPath  = [];
    end
    return; % in general: if no output is requested, there is nothing to do --> early return
end


%% main
if isempty(p_jTmpRootManagedDir)
    [~, p_jTmpRootManagedDir] = sltu_tmpdir_get();
    p_mContext2TempPath = containers.Map();
end

if p_mContext2TempPath.isKey(sContextKey)
    sTempPath = p_mContext2TempPath(sContextKey);

else
    sTmpRoot = i_getDirPath(p_jTmpRootManagedDir);
    sTempPath = tempname(sTmpRoot);
    mkdir(sTempPath);
    
    p_mContext2TempPath(sContextKey) = sTempPath;
end
end


%%
function sPath = i_getDirPath(jManagedDir)
try
    sPath = char(jManagedDir.getPath().getCanonicalPath());
catch
    sPath = char(jManagedDir.getPath().getAbsolutePath());
end
end


%%
function bSuccess = i_removeManagedDir(jManagedDir)
bSuccess = true;
try
    jManagedDir.cleanup();
    
catch oEx
    fprintf('\nFailed removing managed directory:\n%s\n\n', oEx.getReport());
    bSuccess = false;
end
end

