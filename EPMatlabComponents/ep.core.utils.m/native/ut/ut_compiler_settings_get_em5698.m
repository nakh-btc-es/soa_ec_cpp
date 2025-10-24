function ut_compiler_settings_get_em5698()
% Tests, if the compiler settings can be extracted correctly if the path to
% the compiler contains the delimiter character
%
%  function ut_compiler_settings_get_em5698()
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

%% clean up first
ep_tu_cleanup();

%% predefined values
sPwd                = pwd;
sTestRoot           = fullfile(sPwd, 'ut_compiler_settings_get_em5698');
sFakeMlRoot         = fullfile(sTestRoot, 'ml with spaces');
sOrigMlRoot         = matlabroot();

%% setup env for test
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
    
    % Create symbolic link to matlab root
    % Note: This link needs to be removed with this command only:
    %   "dos(sprintf('rmdir "%s"', sFakeMlRoot));"
    % Other command could corrupt (or delete) the Matlab directory!
    dos(sprintf('mklink /D /J "%s" "%s"', sFakeMlRoot, sOrigMlRoot))
    
    % Fake the matlabroot
    fid = fopen(fullfile(sTestRoot, 'matlabroot.m'), 'wt');
    fprintf(fid, 'function sDir = matlabroot()\n');
    fprintf(fid, 'sDir = ''%s'';', sFakeMlRoot);
    fclose(fid);
    
    rehash();
catch exception
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end

%% test
try
    % Call SUT 
    ep_core_compiler_settings_get('XMLOutputFile','compiler.xml');

    % Load result file
    hRootNode = mxx_xmltree('load', 'compiler.xml');
    xmlCleanup = onCleanup(@() mxx_xmltree('clear', hRootNode));
    ahAdditionalSourceFiles = mxx_xmltree('get_nodes', hRootNode, './additionalSourceFiles/item');

    for i = 1:length(ahAdditionalSourceFiles)
        sFile = mxx_xmltree('get_attribute', ahDllGenOptions(i), 'value');
        sFile = regexprep(sFile, '^-I', '');
        MU_ASSERT(exist(sFile, 'file'), sprintf( ...
            'Additional Source File "%s" does not exist', sFile));
    end
    
    % remove the link to avoid corruption of the matlab directory
    dos(sprintf('rmdir "%s"', sFakeMlRoot));
catch exception
    % remove the link to avoid corruption of the matlab directory
    dos(sprintf('rmdir "%s"', sFakeMlRoot));
    MU_FAIL(['Unexpected exception: ', getReport(exception)]);
end

%% clean
try
    cd(sPwd);
    ep_tu_cleanup();
    if (exist(sTestRoot, 'file') )
        ep_tu_rmdir(sTestRoot);
    end
    rehash();
catch exception %#ok
end
