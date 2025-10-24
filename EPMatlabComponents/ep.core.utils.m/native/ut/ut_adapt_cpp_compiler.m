%%
%  Test of function ep_core_adapt_mex_compilers.
%%
function ut_adapt_cpp_compiler

    aInstalledCCompilers = mex.getCompilerConfigurations('C', 'Installed');
    if length(aInstalledCCompilers) == 1
        sName = aInstalledCCompilers(1).Name;
        MU_MESSAGE_FATAL(['Just one C compiler (', sName, ') installed. Skipping test.']);
    end

    aInstalledCppCompilers = mex.getCompilerConfigurations('C++', 'Installed');
    if length(aInstalledCppCompilers) == 1
        sName = aInstalledCppCompilers(1).Name;
        MU_MESSAGE_FATAL(['Just one CPP compiler (', sName, ') installed. Skipping test.']);
    end

    stSelectedCCompiler = mex.getCompilerConfigurations('C', 'Selected');
    if isempty(stSelectedCCompiler)
        MU_MESSAGE_FATAL('No selected C compiler found. Omiting this test.')
    end
    stSelectedCCompiler = i_getInstalled(stSelectedCCompiler);

    stSelectedCppCompiler = mex.getCompilerConfigurations('C++', 'Selected');
    if isempty(stSelectedCppCompiler)
        MU_MESSAGE_FATAL('No selected C++ compiler found. Omiting this test.')
    end
    stSelectedCppCompiler = i_getInstalled(stSelectedCppCompiler);
    
    try
        i_ut_adapt_cpp_compiler(aInstalledCCompilers, aInstalledCppCompilers, ...
            stSelectedCCompiler, stSelectedCppCompiler);
    catch exception
        MU_FAIL(exception.message);
    end

    % restore the selected C++ compiler
    i_set_cpp_compiler(stSelectedCppCompiler);
end

%%
function i_ut_adapt_cpp_compiler(aInstalledCCompilers, aInstalledCppCompilers, ...
        stSelectedCCompiler, stSelectedCppCompiler)

    iCCompilerIndex = 0;
    for i=1:length(aInstalledCCompilers)
        stInstalledCompiler = aInstalledCCompilers(i);
        if i_compilers_equals(stSelectedCCompiler, stInstalledCompiler)
            iCCompilerIndex = i;
            break
        end
    end
    MU_ASSERT_NOT_EQUAL_FATAL(iCCompilerIndex, 0);

    iCppCompilerIndex = 0;
    for i=1:length(aInstalledCppCompilers)
        stInstalledCompiler = aInstalledCppCompilers(i);
        if i_compilers_equals(stSelectedCppCompiler, stInstalledCompiler)
            iCppCompilerIndex = i;
            break
        end
    end
    MU_ASSERT_NOT_EQUAL_FATAL(iCppCompilerIndex, 0);

    bCompilersMatch = strcmp(stSelectedCCompiler.Location, stSelectedCppCompiler.Location);

    % set cpp to not mathing compiler first
    if bCompilersMatch
        iCppNotMatching = mod(iCppCompilerIndex, length(aInstalledCppCompilers)) + 1;
        iCppMatching = iCppCompilerIndex;
        i_set_cpp_compiler(aInstalledCppCompilers(iCppNotMatching));
    else
        iCppNotMatching = iCppCompilerIndex;
        for i=1:length(aInstalledCppCompilers)
            stInstalledCompiler = aInstalledCppCompilers(i);
            if strcmp(stSelectedCCompiler.Location, stInstalledCompiler.Location)
                iCppMatching = i;
                break
            end
        end
    end

    % call SUT (this call should set the CPP compiler to the matching one
    [bCAndCppCompilersMatch, bCppCompilerWasSwitched, stPreviousCppCompiler] ...
        = ep_core_adapt_mex_compilers('setCppLikeC');
    % we expect that the compiler now match
    MU_ASSERT_TRUE(bCAndCppCompilersMatch);
    % we expect that the compiler has been switched
    MU_ASSERT_TRUE(bCppCompilerWasSwitched);
    % we expect that we get the correct previous unmatching CPP for later restore
    MU_ASSERT_TRUE(i_compilers_equals(stPreviousCppCompiler, aInstalledCppCompilers(iCppNotMatching)));
    stCurrentCppCompiler = mex.getCompilerConfigurations('C++', 'Selected');
    MU_ASSERT_STRING_EQUAL_FATAL(stSelectedCCompiler.Location, stCurrentCppCompiler.Location);

    % reset cpp compiler and call again
    ep_core_adapt_mex_compilers('setCpp', stPreviousCppCompiler);
    stCurrentCppCompiler = mex.getCompilerConfigurations('C++', 'Selected');
    MU_ASSERT_STRING_EQUAL_FATAL(stPreviousCppCompiler.Location, stCurrentCppCompiler.Location);
    [bCAndCppCompilersMatch, bCppCompilerWasSwitched, stPreviousCppCompiler] ...
        = ep_core_adapt_mex_compilers('setCppLikeC');
    % we expect that the compiler now match
    MU_ASSERT_TRUE(bCAndCppCompilersMatch);
    % we expect that the compiler has been switched
    MU_ASSERT_TRUE(bCppCompilerWasSwitched);
    % we expect that we get the correct previous unmatching CPP for later restore
    MU_ASSERT_TRUE(i_compilers_equals(stPreviousCppCompiler, aInstalledCppCompilers(iCppNotMatching)));
    stCurrentCppCompiler = mex.getCompilerConfigurations('C++', 'Selected');
    MU_ASSERT_STRING_EQUAL_FATAL(stSelectedCCompiler.Location, stCurrentCppCompiler.Location);

    % call again, this time the compilers are already matching
    [bCAndCppCompilersMatch, bCppCompilerWasSwitched, stPreviousCppCompiler] ...
        = ep_core_adapt_mex_compilers('setCppLikeC');
    % we expect that the compiler now match
    MU_ASSERT_TRUE(bCAndCppCompilersMatch);
    % we expect that the compiler has not been switched
    MU_ASSERT_FALSE(bCppCompilerWasSwitched);
    % we expect that we get the correct previous matching CPP
    MU_ASSERT_TRUE(i_compilers_equals(stPreviousCppCompiler, aInstalledCppCompilers(iCppMatching)));
    stCurrentCppCompiler = mex.getCompilerConfigurations('C++', 'Selected');
    MU_ASSERT_STRING_EQUAL_FATAL(stSelectedCCompiler.Location, stCurrentCppCompiler.Location);

end

%% get installed compiler for a selected compiler (their MexOpt may differ)
function stCompiler = i_getInstalled(stCompiler)
    
    aInstalledCompilers = mex.getCompilerConfigurations(stCompiler.Language, 'Installed');
    for i=1:length(aInstalledCompilers)
        stInstalledCompiler = aInstalledCompilers(i);
        if i_compilers_equals(stCompiler, stInstalledCompiler)
            stCompiler = stInstalledCompiler;
            return
        end
    end

    MU_FAIL_FATAL('No compiler installation found.');
end

%% compare two compilers
function bIsEquals = i_compilers_equals(stComp1, stComp2)
    bIsEquals = ...
        strcmp(stComp1.Name, stComp2.Name) && ...
        strcmp(stComp1.Language, stComp2.Language) && ...
        strcmp(stComp1.Version, stComp2.Version) && ...
        strcmp(stComp1.Location, stComp2.Location);
end    

%% set mex cpp compiler
function i_set_cpp_compiler(stCompiler)
    sCmd = ['mex(''-setup:', stCompiler.MexOpt, ''',''C++'')'];
    try
        result = evalin('base', sCmd);
        MU_ASSERT_EQUAL(result, 0);
    catch exception
        MU_FAIL(['Error occurent: can not set mex cpp compiler: ', exception.message]);
    end
end

