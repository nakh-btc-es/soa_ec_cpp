function atgcv_exec(stEnv, sToolName, casArguments, bUseMLDll)
% Asynchron execution of a tool with arguments.
%
%
%   INPUT              DESCRIPTION
%     stEnv                (struct)  environment data
%        .sTmpPath         (string)  temporary path ssed for temporary data
%                                    (full path, existence is assumed)
%        .sResultPath      (string)  result path where outputs are placed
%                                    (full path, existence is assumed)
%        .hMessenger       (handle)  handle for error messenger
%     sToolName          (string)  name of the tool
%     bUseMLDll            (boolean) Use of Matlab DLL's
%
%   OUTPUT             DESCRIPTION
%
%   REMARKS
%
%   <et_copyright>

%% internal
%
%   REFERENCE(S):
%     EP5-Document
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$
%
%   $Revision: 54800 $
%   Last modified: $Date: 2009-07-08 10:24:57 +0200 (Mi, 08 Jul 2009) $
%   $Author: rwilts $
%
%%


%% Check Parameters




%% main
try
    sPwd = pwd;
    
    sTmpPath    = stEnv.sTmpPath;
    
    cd(sTmpPath); % work in tmp path
    
    
    sMessageFile  = fullfile(sTmpPath, 'RuntimeMessages.xml');
    
    oExecutor =  ct.nativeaccess.NativeExecutorFactory().getInstance();
    oList = atgcv_m2j(casArguments);
    oList.add(0,atgcv_m2j(sToolName));
    oProcessBuilder = oExecutor.command(oExecutor.getClass(), oList );
    env = oProcessBuilder.environment();
    env.put('OSC_MESSENGER_LOG', sMessageFile);
    
    if( bUseMLDll )
        
        if atgcv_env_version_bits_get('MATLAB') == 64
            sDir = fullfile( matlabroot, 'bin','win64');
            sPath = char(env.get('Path'));
            env.put('Path', [sDir ,';',sPath]);
        end
        if atgcv_env_version_bits_get('MATLAB') == 32
            sDir = fullfile( matlabroot, 'bin','win32');
            sPath = char(env.get('Path'));
            env.put('Path', [sDir ,';',sPath]);
        end
    end
    
    oProcess = oProcessBuilder.start();
    oProcess.waitFor();
    
    
    
    if exist(sMessageFile, 'file')
        try
            atgcv_exec_transfer_msglog(stEnv, sMessageFile);
            delete(sMessageFile);
        catch exception
            delete(sMessageFile);
            rethrow(exception);
        end
    end
    
catch exception
    cd(sPwd);
    rethrow(exception);
end

cd(sPwd);
return


%**************************************************************************
% END OF FILE
%**************************************************************************