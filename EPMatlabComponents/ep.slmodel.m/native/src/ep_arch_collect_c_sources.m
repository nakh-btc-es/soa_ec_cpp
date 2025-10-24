function ep_arch_collect_c_sources(xEnv, sCodeModelFile, bIsCpp)
% Collect all c sources from the codemodel file inclusive the ML/TL sources into a specific managed tmp directory 
% and adapt the paths in the codemodel file to the new specific managed tmp directory.
%
% function ep_arch_collect_c_sources(xEnv, sTargetConfig, sCodeModelFile)
%
%   INPUT               DESCRIPTION
%   - xEnv                  (object)  Environment
%   - sCodeModelFile        (String)  Path to Code Model File
%   - bIsCpp                (bool)    True iff in C++ mode, false for C mode. 
%
%  Copyright (c)2023
%  BTC Embedded Systems AG, Oldenburg, Germany
%  All rights reserved
%%
    oException = [];
    bCppCompChanged = false;
    stPrevCompiler = [];

    sTargetConfigTempDir = xEnv.getTempDirectory();

    if bIsCpp
        [~, bCppCompChanged, stPrevCompiler] = ep_core_adapt_mex_compilers('setCppLikeC');
    end

    try
        sTargetConfigFile = fullfile(sTargetConfigTempDir, 'targetconf.xml');
        ep_arch_create_target_config(xEnv, sTargetConfigFile, bIsCpp);
        i_ep_arch_collect_c_sources(xEnv, sTargetConfigFile, sCodeModelFile);
    catch exception
        oException = MException('EP:CSOURCESCOLLECT', '%s', ['Collection of C sources failed: ', exception.message]);
    end

    % clean up
    if bCppCompChanged
        ep_core_adapt_mex_compilers('setCpp', stPrevCompiler);
    end

    xEnv.deleteDirectory(sTargetConfigTempDir);

    if ~isempty(oException)
        xEnv.throwException(oException);
    end

end

%% internal main function
function i_ep_arch_collect_c_sources(xEnv, sTargetConfig, sCResultFile)

    sTargetDir = fileparts(sCResultFile);
    mkdir(sTargetDir, 'csourcecollect-results');
    sCSourceCollectTargetDir = fullfile(sTargetDir, 'csourcecollect-results');
    
    sCompilerFile = fullfile(sCSourceCollectTargetDir, 'compilersetup.xml');
    ep_core_compiler_settings_get('XMLOutputFile', sCompilerFile);
    
    hCodeModel = mxx_xmltree('load', sCResultFile);
    xOnCleanupCloseDocCodeModel = onCleanup(@() mxx_xmltree('clear', hCodeModel));
    
    hCompiler = mxx_xmltree('load', sCompilerFile);
    xOnCleanupCloseDocCompiler = onCleanup(@() mxx_xmltree('clear', hCompiler));
    
    hCSourceCollectInput = mxx_xmltree('create', 'CSourceInfo');
    mxx_xmltree('set_attribute', hCSourceCollectInput, 'pch', 'true');
    xOnCleanupCloseDocCSourceCollectInput = onCleanup(@() mxx_xmltree('clear', hCSourceCollectInput));
    
    hTargetConfig = mxx_xmltree('load', sTargetConfig);
    xOnCleanupCloseDocTargetConfig = onCleanup(@() mxx_xmltree('clear', hTargetConfig));
    
    % create CSourceCollect nodes
    sCMode = i_getCDialekt(hTargetConfig);
    i_addExcludeCopyPaths(hCompiler, hCSourceCollectInput);
    i_addIncludePaths(hCodeModel, hCompiler, hCSourceCollectInput, sCMode);
    i_addSources(hCodeModel, hCSourceCollectInput);
    i_addDefines(hCodeModel, hCompiler, hCSourceCollectInput, sCMode);
    i_addOutputData(hCSourceCollectInput, sCSourceCollectTargetDir);
    i_adaptCodePaths(xEnv, hCodeModel, hCSourceCollectInput, hCompiler, sCSourceCollectTargetDir, sTargetConfig, sCMode);
    
    % save adapted code model xml
    mxx_xmltree('save', hCodeModel, sCResultFile);
    
end

%% adapt code file paths and include paths in code model xml
function i_adaptCodePaths(xEnv, hCodeModel, hCSourceCollectInput, hCompiler, sCSourceCollectTargetDir, sTargetConfig, sCMode)
    
    sCSourceCollectInputFile = fullfile(sCSourceCollectTargetDir, 'csourcecollect-input.xml');
    mxx_xmltree('save', hCSourceCollectInput, sCSourceCollectInputFile);
    
    sCSourceCollectOutputFile = fullfile(sCSourceCollectTargetDir, 'csourcecollect-output.xml');
    sTargetConfigDir = fileparts(sTargetConfig);
    
    % create predefined_macros.txt file for EDG based tool csourcescollect for gcc based compilers
    mkdir(sTargetConfigDir, 'lib');
    sPredefinedMacrosTxtPath = fullfile(sTargetConfigDir, 'lib', 'predefined_macros.txt');
    if isempty(sCMode)
        sCMode = 'C99';
    end
    
    if ~ep_arch_create_predefined_macros(xEnv, sPredefinedMacrosTxtPath, sCMode)
        % create an empty file
        fclose(fopen(sPredefinedMacrosTxtPath, 'w'));
    end

    % -----------------------------------------------------------------
    % remove this workaround for _Float128 support as long as code_extraction (1) does
    % does not yet support _Float128 (see MRDEVT-1104). code_extraction2 has support for it.
    if ~strcmpi('CPP', sCMode)
        fIdPredefinedMacrosTxt = fopen(sPredefinedMacrosTxtPath, 'a');
        sXPath = ['./compiler/defaultDefines', sCMode '/pair'];
        hdefaultDefines = mxx_xmltree('get_nodes', hCompiler, sXPath);
        if isempty(hdefaultDefines)
            hdefaultDefines = mxx_xmltree('get_nodes', hCompiler, './compiler/defaultDefines/pair');
        end
    
        for i = 1:length(hdefaultDefines)
            hDefine = hdefaultDefines(i);
            sDefineKey = mxx_xmltree('get_attribute', hDefine, 'key');
            sDefineValue = mxx_xmltree('get_attribute', hDefine, 'value');
    
            fprintf(fIdPredefinedMacrosTxt, ['all no  ', sDefineKey]);
            if ~isempty(sDefineValue)
                fprintf(fIdPredefinedMacrosTxt, [' ', sDefineValue]);
            end
            fprintf(fIdPredefinedMacrosTxt, newline);
        end
        fclose(fIdPredefinedMacrosTxt);
    end
    % -----------------------------------------------------------------

    sEnvArray = ["EDG_BASE", sTargetConfigDir];
    [exitValue, sError] = ep_core_toolcall('csourcescollect', sEnvArray, sTargetConfig, sCSourceCollectInputFile);
    % check result status of call to csourcescollect
    if exist(sCSourceCollectOutputFile, 'file')
        hCSourceCollectOutputFile = mxx_xmltree('load', sCSourceCollectOutputFile);
        xOnCleanupCloseDocCSourceCollectOutputFile = onCleanup(@() mxx_xmltree('clear', hCSourceCollectOutputFile));
    else
        hCSourceCollectOutputFile = [];
    end

    % pch memory allocation problem or E06/E09/E10/E11 error
    if  i_pchMemoryError(exitValue) || i_containsPchParseError(hCSourceCollectOutputFile)
        if ~isempty(hCSourceCollectOutputFile)
            mxx_xmltree('clear', hCSourceCollectOutputFile);
            delete(sCSourceCollectOutputFile);
        end

        % delete PCH files
        delete([sCSourceCollectTargetDir filesep '*.pch']);

        % call without pch option
        mxx_xmltree('set_attribute', hCSourceCollectInput, 'pch', 'false');
        mxx_xmltree('save', hCSourceCollectInput, sCSourceCollectInputFile);

        [exitValue, sError] = ep_core_toolcall('csourcescollect', sEnvArray, sTargetConfig, sCSourceCollectInputFile);
        if exist(sCSourceCollectOutputFile, 'file')
            hCSourceCollectOutputFile = mxx_xmltree('load', sCSourceCollectOutputFile);
        else
            hCSourceCollectOutputFile = [];
        end
    end
    
    if exitValue ~= 0 
        sErrorMessage = sError;
        if ~isempty(hCSourceCollectOutputFile)
            hErrorMessages = mxx_xmltree('get_nodes', hCSourceCollectOutputFile, '/SourceInfo/ErrorMessage');
            for i = 1 : length(hErrorMessages)
                hErrorMessage = hErrorMessages(i);
                sErrorCode = mxx_xmltree('get_attribute', hErrorMessage, 'errorCode');
                sInfo1 = mxx_xmltree('get_attribute', hErrorMessage, 'info1');
                sErrorMessage = sprintf('%s\n[%s] %s', sErrorMessage, sErrorCode, sInfo1);
            end
        end
        error(['Execution of csourcescollect failed:\n', sErrorMessage]);
    end
    
    % adapt file paths in C result xml
    i_adaptPaths(hCodeModel, hCSourceCollectOutputFile, sCSourceCollectTargetDir);
    
end

% check the exit value of CSourcesCollect regarding pch memory error
function pchMemoryError = i_pchMemoryError(exitValue)

    % different return codes in Win/Linux, in Linux 4711 is also returned by CSourceCollect, 
    % but cut by cast to UINT because in Linux only 8 bit are available for the exit value from a process  
    pchMemoryError = (ispc && exitValue == 4711) || (isunix && exitValue == 103);

end

function pchParseError = i_containsPchParseError(hCSourceCollectOutputFile)

    pchParseError = false;

    if ~isempty(hCSourceCollectOutputFile)
        hErrorMessages = mxx_xmltree('get_nodes', hCSourceCollectOutputFile, '/SourceInfo/ErrorMessage');
        for i = 1 : length(hErrorMessages)
            hErrorMessage = hErrorMessages(i);
            sErrorCode = mxx_xmltree('get_attribute', hErrorMessage, 'errorCode');
            switch sErrorCode
                case {'E06', 'E09', 'E10', 'E11'} 
                    pchParseError = true;
            end
        end
    end
end

%% read out file path mapping from result file of csourcescollect
function pathMap = i_readPathMapping(hCSourceCollectOutputFile, sTargetDir)
    
    pathMap = containers.Map('KeyType', 'char', 'ValueType', 'char');
    
    hFiles = mxx_xmltree('get_nodes', hCSourceCollectOutputFile, '/SourceInfo/Files/File');
    for i = 1:length(hFiles)
        hFile = hFiles(i);
        sOriginalLocation = mxx_xmltree('get_attribute', hFile, 'originalLocation');
        sOriginalLocation = char(java.io.File(sOriginalLocation).getCanonicalPath());
        [~, ~, sSuffix] = fileparts(sOriginalLocation);
        % pick out only C sources, ignore headers
        if endsWith(lower(sSuffix), {'.c', '.c++', '.cpp'})
            hCopiedLocations = mxx_xmltree('get_nodes', hFile, './CopiedLocations/CopiedLocation');
            if length(hCopiedLocations) ~= 1
                % we expect ecaxtly one copy of this source file
                error(['Collection of C sources failed: exactly one copy expected for source file ', ...
                    sOriginalLocation, '. Found: ', int2str(length(hCopiedLocations)), '.']);
            end
            hCopiedLocation = hCopiedLocations(1);
            sCopiedRelativeLocation = mxx_xmltree('get_attribute', hCopiedLocation, 'name');
            sCopiedLocation = [sTargetDir, filesep, sCopiedRelativeLocation];
            sCopiedLocation = char(java.io.File(sCopiedLocation).getCanonicalPath());
            % add path mapping to map
            pathMap(sOriginalLocation) = sCopiedLocation;
        end
    end
    
end

%% replace paths in cResults.xml by Dx paths from csourcecollect output xml
function i_adaptPaths(hCodeModel, hCSourceCollectOutputFile, sTargetDir)
    
    oPathMap = i_readPathMapping(hCSourceCollectOutputFile, sTargetDir);
    
    %  adapt paths to collected C source code files in the code model
    hFiles = mxx_xmltree('get_nodes', hCodeModel, '/CodeModel/Files/File');
    for i = 1 : length(hFiles)
        hFile = hFiles(i);
        sPath = mxx_xmltree('get_attribute', hFile, 'path');
        sName = mxx_xmltree('get_attribute', hFile, 'name');
        sOriginalFullPath = fullfile(sPath, sName);
        % get mapped actual path for this file
        if oPathMap.isKey(sOriginalFullPath)
            sCopiedFullPath = oPathMap(sOriginalFullPath);
            [sCopiedPath, sName, sSuffix] = fileparts(sCopiedFullPath);
            sCopiedName = [sName, sSuffix];
            mxx_xmltree('set_attribute', hFile, 'path', sCopiedPath);
            mxx_xmltree('set_attribute', hFile, 'name', sCopiedName);
        else
            error(['Source file ', sOriginalFullPath, ' not found within collected C code files.']);
        end
        
    end
    
    % adapt the include paths
    mxx_xmltree('delete_nodes', hCodeModel, '/CodeModel/IncludePaths/IncludePath');
    
    hIncludePaths = mxx_xmltree('get_nodes', hCodeModel, '/CodeModel/IncludePaths');
    hCopiedIncludePaths = mxx_xmltree('get_nodes', hCSourceCollectOutputFile, '/SourceInfo/CopiedIncludePaths/CopiedIncludePath');
    for i = 1 : length(hCopiedIncludePaths)
        hCopiedIncludePath = hCopiedIncludePaths(i);
        sName = mxx_xmltree('get_attribute', hCopiedIncludePath, 'name');
        sFullIncludePath = fullfile(sTargetDir, sName);
        hIncludePath = mxx_xmltree('add_node', hIncludePaths, 'IncludePath');
        mxx_xmltree('set_attribute', hIncludePath, 'path', sFullIncludePath);
    end
end

%%
function sCanonicalPath = i_canonicalPath(sPath)
    try
        oFile = java.io.File(sPath);
        sCanonicalPath = char(oFile.getCanonicalPath());
        if isunix 
            sCanonicalPath = strrep(sCanonicalPath, '\', '/');
        else
            sCanonicalPath = strrep(sCanonicalPath, '/', '\');
        end
    catch
        sCanonicalPath = sPath;
    end
end

%%
function i_addExcludeCopyPaths(hCompiler, hCSourceCollectInput)

    hdefaultIncludePaths = mxx_xmltree('get_nodes', hCompiler, './compiler/defaultIncludePaths/item');
    hExcludeCopyPaths = mxx_xmltree('add_node', hCSourceCollectInput, 'ExcludeCopyPaths');
    for i = 1:length(hdefaultIncludePaths)
        hIncludePath = hdefaultIncludePaths(i);
        sIncludePath = mxx_xmltree('get_attribute', hIncludePath, 'value');
        sCanonicalIncludePath = i_canonicalPath(sIncludePath);
        hExcludeCopyPath = mxx_xmltree('add_node', hExcludeCopyPaths, 'ExcludeCopyPath');
        mxx_xmltree('set_attribute', hExcludeCopyPath, 'name', sCanonicalIncludePath);
    end
end

%%
function i_addIncludePaths(hCodeModel, hCompiler, hCSourceCollectInput, sCMode)

    hIncludePaths = mxx_xmltree('get_nodes', hCodeModel, './IncludePaths/IncludePath');
    hCSourceCollectIncludePaths = mxx_xmltree('add_node', hCSourceCollectInput, 'IncludePaths');
    if isunix
        mxx_xmltree('set_attribute', hCSourceCollectIncludePaths, 'searchStrategy', 'replace_restore');
    else
        mxx_xmltree('set_attribute', hCSourceCollectIncludePaths, 'searchStrategy', 'stack');
    end

    for i = 1:length(hIncludePaths)
        hIncludePath = hIncludePaths(i);
        sIncludePath = mxx_xmltree('get_attribute', hIncludePath, 'path');
        hIncludePath = mxx_xmltree('add_node', hCSourceCollectIncludePaths, 'IncludePath');
        sCanonicalIncludePath = i_canonicalPath(sIncludePath);
        mxx_xmltree('set_attribute', hIncludePath, 'name', sCanonicalIncludePath);
    end

    includePathCMode = '';
    if strcmpi('CPP', sCMode)
        includePathCMode = 'CPP';
    end
    hdefaultIncludePaths = mxx_xmltree('get_nodes', hCompiler, ['./compiler/defaultIncludePaths', includePathCMode, '/item']);
    if isempty(hdefaultIncludePaths)
        hdefaultIncludePaths = mxx_xmltree('get_nodes', hCompiler, './compiler/defaultIncludePaths/item');
    end
    for i = 1:length(hdefaultIncludePaths)
        hIncludePath = hdefaultIncludePaths(i);
        sIncludePath = mxx_xmltree('get_attribute', hIncludePath, 'value');
        hIncludePath = mxx_xmltree('add_node', hCSourceCollectIncludePaths, 'IncludePath');
        sCanonicalIncludePath = i_canonicalPath(sIncludePath);
        mxx_xmltree('set_attribute', hIncludePath, 'name', sCanonicalIncludePath);
    end    
end

%%
function i_addSources(hCodeModel, hCSourceCollectInput)

    hFiles = mxx_xmltree('get_nodes', hCodeModel, './Files/File');
    hSources = mxx_xmltree('add_node', hCSourceCollectInput, 'Sources');
    for i = 1:length(hFiles)
        hFile = hFiles(i);
        sPath = mxx_xmltree('get_attribute', hFile, 'path');
        sName = mxx_xmltree('get_attribute', hFile, 'name');
        sFile = fullfile(sPath, sName);
        
        hSource = mxx_xmltree('add_node', hSources, 'Source');
        mxx_xmltree('set_attribute', hSource, 'name', sFile);
    end
    
end

%%
function sCMode = i_getCDialekt(hTargetConfig)
    
    sErrorMessage = 'Target configuration file does not contain informatin about C mode (C90, C99, C++).';
    
    % get C mode from the target confoguration
    hExtendedInfos = mxx_xmltree('get_nodes', hTargetConfig, '/tc:TargetConfiguration/tc:ExtendedInfo');
    if length(hExtendedInfos) ~= 1
        error(sErrorMessage);
    end
    hExtendedInfo = hExtendedInfos(1);
    sValue = mxx_xmltree('get_attribute', hExtendedInfo, 'is_c_plus_plus');
    if strcmp('true', sValue) == 1
        sCMode = 'CPP';
    else
        sValue = mxx_xmltree('get_attribute', hExtendedInfo, 'c_version');
        switch lower(sValue)
            case 'c90'
                sCMode = 'C90';
            case 'c99'
                sCMode = 'C99';
            otherwise
                sCMode = '';
        end
    end
end


%%
function i_addDefines(hCodeModel, hCompiler, hCSourceCollectInput, sCMode)

    hDefines = mxx_xmltree('get_nodes', hCodeModel, './Defines/Define');
    hCSourceCollectDefines = mxx_xmltree('add_node', hCSourceCollectInput, 'Defines');
    for i = 1:length(hDefines)
        hDefine = hDefines(i);
        sDefineKey = mxx_xmltree('get_attribute', hDefine, 'name');
        sDefineValue = mxx_xmltree('get_attribute', hDefine, 'value');
        
        hDefine = mxx_xmltree('add_node', hCSourceCollectDefines, 'Define');
        mxx_xmltree('set_attribute', hDefine, 'name', sDefineKey);
        if ~isempty(sDefineValue)
            mxx_xmltree('set_attribute', hDefine, 'value', sDefineValue);
        end
    end
    
    hDefine = mxx_xmltree('add_node', hCSourceCollectDefines, 'Define');
    mxx_xmltree('set_attribute', hDefine, 'name', '__far');
    mxx_xmltree('set_attribute', hDefine, 'value', ' ');
    hDefine = mxx_xmltree('add_node', hCSourceCollectDefines, 'Define');
    mxx_xmltree('set_attribute', hDefine, 'name', '__near');
    mxx_xmltree('set_attribute', hDefine, 'value', ' ');
    
    sXPath = ['./compiler/defaultDefines', sCMode '/pair'];
    % check specific mode settings
    hdefaultDefines = mxx_xmltree('get_nodes', hCompiler, sXPath);
    if isempty(hdefaultDefines)
       hdefaultDefines = mxx_xmltree('get_nodes', hCompiler, './compiler/defaultDefines/pair');
    end
        
    for i = 1:length(hdefaultDefines)
        hDefine = hdefaultDefines(i);
        sDefineKey = mxx_xmltree('get_attribute', hDefine, 'key');
        sDefineValue = mxx_xmltree('get_attribute', hDefine, 'value');
        
        hDefine = mxx_xmltree('add_node', hCSourceCollectDefines, 'Define');
        mxx_xmltree('set_attribute', hDefine, 'name', sDefineKey);
        if ~isempty(sDefineValue)
            mxx_xmltree('set_attribute', hDefine, 'value', sDefineValue);
        end
    end
end

%%
function i_addOutputData(hCSourceCollectInput, sTargetDir)

    hOutputData = mxx_xmltree('add_node', hCSourceCollectInput, 'OutputData');
    mxx_xmltree('set_attribute', hOutputData, 'outputDirectory', sTargetDir);
    mxx_xmltree('set_attribute', hOutputData, 'outputSourceInfo', fullfile(sTargetDir, 'csourcecollect-output.xml'));

end

