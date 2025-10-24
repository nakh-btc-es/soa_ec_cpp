function ep_arch_create_target_config(xEnv, sOutputTargetFile, bIsCpp)
% Create target configuration file.
%
% function ep_arch_create_target_config(xEnv, sOutputTargetFile, bIsCpp)
%
%   INPUT               DESCRIPTION
%   - xEnv                  (object)  Environment
%   - sOutputTargetFile     (String)  Path to output targetl file path.
%   - bIsCpp                (bool)    True iff in C++ mode, false for C mode. 
%
%  Copyright (c)2023
%  BTC Embedded Systems AG, Oldenburg, Germany
%  All rights reserved
%%
    xException = [];

    % create working directory
    sWorkDir = xEnv.getTempDirectory();
    try
        % copy target configuration files to the working directory
        oResourceService = ct.nativeaccess.ResourceServiceFactory().getInstance();
        oTargetConfDir = oResourceService.getResourceAsFile([], 'targetconfiguration');
        sTargetConfDir = char(oTargetConfDir.getCanonicalFile().getAbsolutePath());
        copyfile(sTargetConfDir, sWorkDir, 'f');
        
        % add mex DLL entry point
        sOption = '';
        sMexMainFileName = 'mexmain.cpp';
        
        if ~bIsCpp
            sCompilerMode = ep_core_get_pref_value('GENERAL_COMPILER_MODE');
            bIsC90 = ~isempty(sCompilerMode) && strcmpi('c90', sCompilerMode);
            if bIsC90
                sCCompiler = mex.getCompilerConfigurations('C');
                if ~isempty(sCCompiler)
                    sCompilerExe = sCCompiler.Details.CompilerExecutable;
                	bIsGcc = length(sCCompiler) > 2 && ...
                        strcmpi('gcc', sCompilerExe(length(sCompilerExe)-2:end));
                    if bIsGcc
                        sOption = '-g CFLAGS="$CFLAGS -std=c99"';
                    end
                end
            end
            
            sMexMainFileName = 'mexmain.c';
        end

        sMexMainPath = fullfile(sWorkDir, sMexMainFileName);
        i_createMexFunctionCode(sMexMainPath);
        i_compile(sWorkDir, sOption, sMexMainFileName);
        sTargetConfigFile = fullfile(sWorkDir, 'targetconf.xml');        
        copyfile(sTargetConfigFile, sOutputTargetFile, 'f');

    catch exception
        xException = MException('EP:TARGETCONF', '%s', ['Creating the target configuration failed: ', exception.message]);
    end
    
    xEnv.deleteDirectory(sWorkDir);

    if ~isempty(xException)
        throw(xException);
    end
end

%%
function i_compile(sWorkDir, sOption, sMexMainFileName)

    sCurDir = cd();
    exception = [];

    try
        cd(sWorkDir);
        evalin('base', ['mex ', sOption, ' ', sMexMainFileName]);
        evalin('base', 'mexmain');
    catch catchedException
        exception = catchedException;
    end

    cd(sCurDir);

    % rethrow exception if one occurred
    if ~isempty(exception)
        rethrow(exception);
    end

end

%%
function i_createMexFunctionCode(sPath)

    sContent = [ ...
        '#include <mex.h>', newline, ...
        newline, ...
        '#define TC_MAIN targetConfigMain', newline, ...
        '#define TC_MAIN_WITH_VOID_ARGS 1', newline, ...
        newline, ...
        '#include "targetconf.c"', newline, ...
        newline, ...
        'void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {', newline, ...
        '    targetConfigMain();', newline, ...
        '}', newline];

    fId = fopen(sPath, 'w');
    fwrite(fId, sContent);
    fclose(fId);
end
