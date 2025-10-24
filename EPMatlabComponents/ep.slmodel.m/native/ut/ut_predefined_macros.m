%
%  UT for script ep_arch_create_predefined_macros
%
function ut_predefined_macros

    xEnv = EPEnvironment;
    sCMode = 'C90';
    
    sOutputPredefinedMacrosPath = ['predefined_macros_', sCMode, '.txt'];
    MU_ASSERT_FALSE(exist(sOutputPredefinedMacrosPath, 'file'));
    
    bIsGcc = i_isGcc(sCMode);

    % script should always succeed
    bSuccess = ep_arch_create_predefined_macros(xEnv, sOutputPredefinedMacrosPath, sCMode);
    MU_ASSERT_EQUAL(bIsGcc, bSuccess);
    
    % we expect a predefined macros file only for gcc/g++
    if bIsGcc
        MU_ASSERT_TRUE(exist(sOutputPredefinedMacrosPath, 'file'));
    else
       % no predefined macros file expected 
        MU_ASSERT_FALSE(exist(sOutputPredefinedMacrosPath, 'file'));
    end
    
end

%% Check if current mex compiler (for the given C mode) is GNU gcc compiler
function bIsGcc = i_isGcc(sCMode)

    caCompilerConfigurations = mex.getCompilerConfigurations;
    
    sExecutable = '';
    for k=1:length(caCompilerConfigurations)
        if strcmp(sCMode, 'CPP')
            if strcmp('C++', caCompilerConfigurations(k).Language)
                sExecutable = caCompilerConfigurations(k).Details.CompilerExecutable;
                break;
            end
        else
            if strcmp('C', caCompilerConfigurations(k).Language)
                sExecutable = caCompilerConfigurations(k).Details.CompilerExecutable;
                break;
            end
        end    
    end
    MU_ASSERT_FALSE(isempty(sExecutable), ['mex compiler not found for C mode ', sCMode, '.']);

    len = length(sExecutable);
    bIsGcc = false;
    if len >= 3
        bIsGcc = strcmpi(sExecutable(len-2:len), 'g++') || strcmpi(sExecutable(len-2:len), 'gcc');
    end
end