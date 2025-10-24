function ut_compiler_settings_get_for_msvc()
% Tests, if the compiler settings for MSVC can be extracted.
%
%  function ut_compiler_settings_get_for_msvc()
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

stComp = mex.getCompilerConfigurations('C', 'selected');
if ~strcmp(stComp.Manufacturer, 'Microsoft')
    MU_MESSAGE('Test only active for Microsoft compiler');
    return;
end


%% clean up first
ep_tu_cleanup();

%% predefined values
sPwd                = pwd;
sTestRoot           = fullfile(sPwd, 'ut_compiler_settings_get_for_msvc');

%% setup env for test
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end

%% test
try
    hRootNode = [];
    
    % Call SUT
    ep_core_compiler_settings_get('XMLOutputFile','compiler.xml');
    
    % Load result file
    hRootNode = mxx_xmltree('load', 'compiler.xml');
    
    hCompiler = mxx_xmltree('get_nodes', hRootNode, 'compiler');
    
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hCompiler, 'name')), ...
        'Compiler name is not set correctly.');
    
    MU_ASSERT_TRUE(~isempty(mxx_xmltree('get_attribute', hCompiler, 'additionalInfo')), ...
        'Additional Compiler information is not set correctly.');
    
    MU_ASSERT_EQUAL('cl', mxx_xmltree('get_attribute', hCompiler, 'executable'), ...
        'Compiler executeable is not set correctly.');
    
    MU_ASSERT_EQUAL('', mxx_xmltree('get_attribute', hCompiler, 'location'), ...
        'Compiler location is not set correctly.');
    
    if strcmp('mexw64', mexext)
        MU_ASSERT_EQUAL('64', mxx_xmltree('get_attribute', hCompiler, 'bitWidth'), ...
            'Bit width of the compiler is not set correctly.');
    else
        MU_ASSERT_EQUAL('32', mxx_xmltree('get_attribute', hCompiler, 'bitWidth'), ...
            'Bit width of the compiler is not set correctly.');
    end
    
    hOutputObjectFileOption = mxx_xmltree('get_nodes', hCompiler, './outputObjectFileOption');
    MU_ASSERT_EQUAL('/Fo', mxx_xmltree('get_attribute', hOutputObjectFileOption, 'option'), ...
        'Output object file option is not set correctly.');
    MU_ASSERT_EQUAL('false', mxx_xmltree('get_attribute', hOutputObjectFileOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');
    
    hObjectGenerationOption = mxx_xmltree('get_nodes', hCompiler, './objectGenerationOption');
    MU_ASSERT_EQUAL('/c', mxx_xmltree('get_attribute', hObjectGenerationOption, 'option'), ...
        'Object generation option is not set correctly.');
    MU_ASSERT_EQUAL('true', mxx_xmltree('get_attribute', hObjectGenerationOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');
    
    hDefaultIncludePathItems = mxx_xmltree('get_nodes', hCompiler, './defaultIncludePaths/item');
    MU_ASSERT_TRUE(~isempty(hDefaultIncludePathItems), 'No include path has been set.')
    
    hDefaultCFlagsItems = mxx_xmltree('get_nodes', hCompiler, './defaultCompilerFlags/item');
    MU_ASSERT_TRUE(~isempty(hDefaultCFlagsItems), 'No C-flag has been set.')
    
    % EPDEV-45032
    astCFlags = mxx_xmltree('get_attributes', hCompiler, './defaultCompilerFlags/item', 'value');
    MU_ASSERT_TRUE(all(cellfun('isempty', (strfind({astCFlags.value}, '/D')))), 'Compiler flags contain defines.')
    
    hDefaultDefines= mxx_xmltree('get_nodes', hCompiler, './defaultDefines/pair');
    MU_ASSERT_TRUE(~isempty(hDefaultDefines), 'No default define set.')
    
    % EPDEV-45107
    astDefines = mxx_xmltree('get_attributes', hCompiler, './defaultDefines/pair', 'key');
    MU_ASSERT_TRUE(all(cellfun('isempty', (strfind({astDefines.key}, 'MATLAB_MEX_FILE')))), ...
        'MATLAB_MEX_FILE define should not be included in the config.')
    
    hIncludeFolderOption = mxx_xmltree('get_nodes', hCompiler, './includeFolderOption');
    MU_ASSERT_EQUAL('-I', mxx_xmltree('get_attribute', hIncludeFolderOption, 'option'), ...
        'Include folder option is not set correctly.');
    MU_ASSERT_EQUAL('false', mxx_xmltree('get_attribute', hIncludeFolderOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');
    
    hMacroOption = mxx_xmltree('get_nodes', hCompiler, './macroDefineOption');
    MU_ASSERT_EQUAL('-D', mxx_xmltree('get_attribute', hMacroOption, 'option'), ...
        'Macro define option is not set correctly.');
    MU_ASSERT_EQUAL('false', mxx_xmltree('get_attribute', hMacroOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');
    
    hEnvironmentVariables= mxx_xmltree('get_nodes', hCompiler, './environmentVariables/pair');
    MU_ASSERT_TRUE(~isempty(hEnvironmentVariables), 'No environment variable set.');
    
    % Lib Tool
    hLibTool = mxx_xmltree('get_nodes', hRootNode, 'libtool');
    MU_ASSERT_EQUAL('lib', mxx_xmltree('get_attribute', hLibTool, 'executable'), ...
        'Lib Tool executeable is not correct.');
    
    MU_ASSERT_EQUAL('', mxx_xmltree('get_attribute', hLibTool, 'location'), ...
        'Lib Tool location is not correct.');
    
    hOutputFileOption = mxx_xmltree('get_nodes', hLibTool, './outputFileOption');
    MU_ASSERT_EQUAL('/out:', mxx_xmltree('get_attribute', hOutputFileOption, 'option'), ...
        'Output file option for Lib Tool is not set correctly.');
    MU_ASSERT_EQUAL('false', mxx_xmltree('get_attribute', hOutputFileOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');

    % linker
    hLinker = mxx_xmltree('get_nodes', hRootNode, 'linker');
    MU_ASSERT_EQUAL('link', mxx_xmltree('get_attribute', hLinker, 'executable'), ...
        'Linker executeable is not correct.');
    
    MU_ASSERT_EQUAL('', mxx_xmltree('get_attribute', hLinker, 'location'), ...
        'Linker location is not correct.');
    
    ahDllGenOptions= mxx_xmltree('get_nodes', hLinker, './defaultLinkerFlags/item');
    MU_ASSERT_TRUE(~isempty(ahDllGenOptions), 'No DLL generation option set.');
    
    for i = 1:length(ahDllGenOptions)
        sValue = mxx_xmltree('get_attribute', ahDllGenOptions(i), 'value');
        MU_ASSERT(~isempty(regexp(sValue, '^/', 'ONCE')), ...
            'Unexpected linker Flag, all flags should begin with "/".');
        % EP-1801
        MU_ASSERT_FALSE(strncmpi(sValue, '/LIBPATH:', 9), 'LIBPATH compiler flags has not been filtered');
    end
    
    hdllOption = mxx_xmltree('get_nodes', hLinker, './dllOption');
    MU_ASSERT_EQUAL('/dll', mxx_xmltree('get_attribute', hdllOption, 'option'), ...
        'DLL opiton for linker is not set correctly.');
    MU_ASSERT_EQUAL('true', mxx_xmltree('get_attribute', hdllOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');
    
    hOutputFileOption = mxx_xmltree('get_nodes', hLinker, './outputFileOption');
    MU_ASSERT_EQUAL('/out:', mxx_xmltree('get_attribute', hOutputFileOption, 'option'), ...
        'Output file option for linker is not set correctly.');
    MU_ASSERT_EQUAL('false', mxx_xmltree('get_attribute', hOutputFileOption, 'spaceKeyValue'), ...
        '''spaceKeyValue'' option is not set correctly.');
    
    mxx_xmltree('clear', hRootNode);
catch exception
    if ~isempty(hRootNode)
        mxx_xmltree('clear', hRootNode);
    end
    MU_FAIL(['Unexpected exception: ', getReport(exception)]);
end

%% clean
try
    cd(sPwd);
    ep_tu_cleanup();
    if (exist(sTestRoot, 'file') )
        ep_tu_rmdir(sTestRoot);
    end
catch exception %#ok
end