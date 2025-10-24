function bSuccess = ep_arch_create_predefined_macros(xEnv, sOutputPredefinedMacrosPath, sCMode)
% Create predefined macros file for gcc compilers.
%
% function ep_arch_create_target_config(xEnv, sOutputTargetFile, bIsCpp)
%
%   INPUT               DESCRIPTION
%   - xEnv                  (object)  Environment
%   - sOutputTargetFile     (String)  Path to output targetl file path.
%   - bIsCpp                (bool)    C mode (C90, C99, CPP, ...)
%
%   OUTPUT
%   - bSuccess              (bool)    True if compiler is gcc/g++.
%
%   If the compiler is gcc/g++ and the file could not be generated,
%   an exception is thrown.
%
%  Copyright (c)2024
%  BTC Embedded Systems AG, Oldenburg, Germany
%  All rights reserved
%%
    bSuccess = false;
    try
        % get corresponding mex configuration
        oMexConfiguration = i_getMexConfiguration(xEnv, sCMode);
        if i_isGcc(oMexConfiguration)
            bSuccess = i_createGccPredefinedMacros(oMexConfiguration, sCMode, sOutputPredefinedMacrosPath);
        end
    catch exception
        oException = MException('EP:PREDEFINED_MACROS', '%s', ['Collection of C sources failed: ', exception.message]);
        xEnv.throwException(oException);
    end

end

%% Get corresponding C/C++ compiler configuration
function oMexConfiguration = i_getMexConfiguration(xEnv, sCMode)

    switch sCMode
        case 'CPP'
            sSearchLanguage = 'C++';
        otherwise
            sSearchLanguage = 'C';
    end
        
    aMexConfigurations = mex.getCompilerConfigurations();
    saLanguages = {aMexConfigurations.Language};
    index = find(strcmp(saLanguages, sSearchLanguage));
    
    if isempty(index)
        oException = MException('EP:PREDEFINED_MACROS', 'Failed to get selected mex C/C++ compiler for mode %s.', sCMode);
        xEnv.throwException(oException);
    else
        oMexConfiguration = aMexConfigurations(index);
    end
end

%% Check for GNU gcc/g++ compiler
function bIsGcc = i_isGcc(oMexConfiguration)
    sCompilerExecutable = oMexConfiguration.Details.CompilerExecutable;
    bIsGcc = false;
    if length(sCompilerExecutable) >= 3
        sCompiler = sCompilerExecutable(end-2:end);
        bIsGcc = strcmp('g++', sCompiler) || strcmp('gcc', sCompiler);
    end
end

%% Execute gcc/g++ to retreive the predefined macros
function bSuccess = i_createGccPredefinedMacros(oMexConfiguration, sCMode, sOutputPredefinedMacrosPath)

    bSuccess = false;

    sExecutable = oMexConfiguration.Details.CompilerExecutable;
    sCompileOptions = oMexConfiguration.Details.CompilerFlags;
    switch sCMode
        case 'C90'
            sCompileOptions = [sCompileOptions, ' -std=gnu90 -x c'];
        case 'C99'
            sCompileOptions = [sCompileOptions, ' -std=gnu99 -x c'];
        case 'CPP'
            sCompileOptions = [sCompileOptions, ' -std=gnu++11 -x c++'];
    end
    % add options to retrieve predefined macros
    sCompileOptions = [sCompileOptions, ' -E -dM'];
    
    if isunix
        sCommandDelimiter = ';';
        sDevNull = '/dev/null';
    else
        sCommandDelimiter = '&';
        sDevNull = 'NUL';
    end
    
    % compose command string and execute
    sSetEnv = oMexConfiguration.Details.SetEnv;
    casSetEnv = splitlines(sSetEnv);
    casSetEnv = strip(casSetEnv); % normalize (remove leading and trailing whitespaces)
    casSetEnv = casSetEnv(~cellfun('isempty', casSetEnv)); %  remove empty cells
    casSetEnv = join(casSetEnv, sCommandDelimiter);
    sSetEnvCommands = casSetEnv{1};
     
    % execute gcc/g++ to retrieve preprocessed macros
    sCommand = [sSetEnvCommands, sCommandDelimiter, sExecutable, ' ', sCompileOptions, ' - < ', sDevNull];
    [iResult, sResult] = system(sCommand);
    
    if iResult == 0
        % convert result into expected format
        fOutputPredefinedMacros = fopen(sOutputPredefinedMacrosPath, 'w');

        % causes redefinition error messages. Reason unclear!
        caBlackList = {'__VERSION__', '__STDC_VERSION__', '__cpp_', '__cplusplus', '__has_include'};
        
        csLines = splitlines(sResult);
        
        for iLine=1:length(csLines)
            sLine = csLines{iLine};
            bInclude = true;
            for iBlackList=1:length(caBlackList)
                sPattern = caBlackList{iBlackList};
                aFound = strfind(sLine, sPattern);
                if ~isempty(aFound) %#ok
                    bInclude = false;
                    break;
                end
            end
            if bInclude
               sPredefinedMacrosContent  = strrep(sLine, '#define', 'all no');
               fprintf(fOutputPredefinedMacros, '%s\n', sPredefinedMacrosContent);
            end
        end
        
        fclose(fOutputPredefinedMacros);
        bSuccess = true;
    end
end


