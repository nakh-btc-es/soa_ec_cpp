function stMEXCompilerSettings = ep_core_compiler_msvc_get(stMEXConfig, sCompilerName)
% Evaluates the compiler settings of a MSVC and MSSDK
%
% function stMEXCompilerSettings = ep_core_compiler_msvc_get(stMEXConfig, sCompilerName)
%
%   INPUT
%       - stMEXConfig                   (struct)            The 'mex.getCompilerConfigurations()'
%       - sCompilerName                 (string)            Name of the compiler
%   OUTPUT
%       - stMEXCompilerSettings         (struct)            Settings of the MEX compiler and linker
%                                                           Null, if no supported compiler setting can be
%                                                           found.
%           .stCompiler                 (struct)            Settings of the MEX compiler
%           .sName                      (string)            Name of the compiler
%           .sAdditionalInfo            (string)            Additional information about the compiler
%           .sExecutable                (string)            Name of the compiler executable
%           .sLocation                  (string)            Location to the compiler executable
%           .sBitWidth                   (string)           Bit width of the compiler (32 Bit or 64 Bit)
%           .casCompilerFlags           (cell array)        List of default compiler flags
%           .hDefaultDefines            (HashMap)           Map of default compiler defines
%                                                           (The key describes the compiler define itself. The map value,
%                                                           the value of the compiler define.)
%           .hOutputObjectFileOption    (HashMap            Object output file option
%                                                           (The key describes the option itself. The value if a space 
%                                                           after the option is required for the compiler call.)
%           .hObjectGenerationOption    (HashMap)           Object generation option
%                                                           (The key describes the option itself. The value if a space 
%                                                           after the option is required for the compiler call.)
%           .casDefaultIncludePaths     (cell array)        List of default include paths
%           .hIncludeFolderOption       (HashMap)           Include folder option
%                                                           (The key describes the option itself. The value if a space 
%                                                           after the option is required for the compiler call.)
%           .hMacroDefineOption         (HashMap)           Macro define option
%                                                           (The key describes the option itself. The value if a space 
%                                                           after the option is required for the compiler call.)
%           .hEnvironmentVariables      (HashMap)           Map of environment variables
%                                                           (The key describes the variable itself. The map value,
%                                                           the value of the variable.)
%           .castRegistrySettings       (cell array)        Registry entries
%         .stLibTool                    (struct)            Setting of the Lib Tool
%           .sExecutable                (string)            Name of the Lib Tool executable
%           .sLocation                  (string)            Location of the Lib Tool executable
%           .hOutputFileOption          (HashMap)           Output file option for Lib Tool
%                                                           (The key describes the option itself. The value if a space
%                                                           after the option is required for the Lib Tool call.)
%         .stLinker                     (struct)            Setting of the MEX linker
%           .sExecutable                (string)            Name of the linker executable
%           .sLocation                  (string)            Location of the linker executable
%           .hDllOptionForLinker        (HashMap)           Dll option for linker
%                                                           (The key describes the option itself. The value if a space 
%                                                           after the option is required for the linker call.)
%           .casLinkerFlags             (string)            List of default linker flags
%           .hOutputFileOption          (HashMap)           Output file option for linker
%                                                           (The key describes the option itself. The value if a space 
%                                                           after the option is required for the linker call.)
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%
    
stMEXCompilerSettings = struct('stCompiler' ,  [] , 'stLibTool'   ,  [] , 'stLinker'   ,  []);
    
% Set stCompiler
stMEXCompilerSettings.stCompiler = i_create_compiler_info(stMEXConfig, sCompilerName);

% Set stLibTool
stMEXCompilerSettings.stLibTool = i_create_libtool_info();
    
% Set stLinker
stMEXCompilerSettings.stLinker = i_create_linker_info(stMEXConfig);
end

%***********************************************************************************************************************
% Create compiler settings of the active mex compiler
%
% function stCompiler = i_create_compiler_info(stMEXConfig)
%
%   INPUT
%   - stMEXConfig            (struct) The 'mex.getCompilerConfigurations()'
%   - sCompilerName          (string) Name of the compiler
%   OUTPUT
%   - stCompiler             (struct) Information of the compiler
%
%***********************************************************************************************************************
function stCompiler = i_create_compiler_info(stMEXConfig, sCompilerName)

% Compiler struct
stCompiler = struct('sName', [], ...
    'sAdditionalInfo', [], ...
    'sExecutable', [], ...
    'sLocation', [], ...
    'casCompilerFlags', {{}}, ...
    'sBitWidth', [], ...
    'hDefaultDefines', java.util.HashMap, ...
    'hOutputObjectFileOption', java.util.HashMap, ...
    'hObjectGenerationOption', java.util.HashMap, ...
    'casDefaultIncludePaths', {{}}, ...
    'hIncludeFolderOption', java.util.HashMap, ...
    'hMacroDefineOption', java.util.HashMap, ...
    'hEnvironmentVariables', java.util.HashMap, ...
    'castRegistrySettings', []);

% Compiler Name
stCompiler.sName = sCompilerName;

% Compiler Additional Info
stCompiler.sAdditionalInfo = [stMEXConfig.Name , ' (' , stMEXConfig.Version, ')'];

% Compiler Executable
stCompiler.sExecutable = stMEXConfig.Details.CompilerExecutable;

% Compiler Location
% Compiler path is set by the environment variable PATH
% TODO: The absolute path extraction would be a better solution.
stCompiler.sLocation = '';

% Default Compiler Flags
casCFlags = ep_core_mexopt_read(stMEXConfig, 'COMPFLAGS', '/');
if strcmpi(stMEXConfig.Language, 'C++')
    casCFlags{end + 1} = 'TP';
    casCFlags{end + 1} = 'std:c++14';
end 
for i=1:length(casCFlags)
    [sCFlag, casImplicitInclPaths, jImplicitDefinesMap] = ...
        i_split_implicit_include_paths(casCFlags{i});
    for k = 1:length(casImplicitInclPaths)
        sPath = casImplicitInclPaths{k};
        if exist(sPath, 'dir')
            stCompiler.casDefaultIncludePaths{end+1} = sPath;
        end
    end
    stCompiler.hDefaultDefines.putAll(jImplicitDefinesMap);
    
    % Filter not needed flags
    if ~i_is_cflag_excluded(sCFlag)
        sDelimCFlag = ['/', sCFlag];
        % See PROM-8162. It is needded, because some DLLs could not be loaded dynamically
        if strcmp(sDelimCFlag, '/MD')
            sDelimCFlag = '/MT';
        end
        if ~any(strcmp(sDelimCFlag, stCompiler.casCompilerFlags))
            stCompiler.casCompilerFlags{end + 1} = sDelimCFlag;
        end
    end
end

%Filter defines
casDefineBlacklist = i_getDefineBlacklist();
for i = 1:length(casDefineBlacklist)
    stCompiler.hDefaultDefines.remove(casDefineBlacklist{i});
end

%Default defines
if strcmp('mexw64', mexext)
    stCompiler.hDefaultDefines.put('__MSC__', ' ');
    stCompiler.sBitWidth = '64';
else
    stCompiler.hDefaultDefines.put('__MSC__', ' ');
    stCompiler.sBitWidth = '32';
end

% OutputObjectFileOption
stCompiler.hOutputObjectFileOption.put('/Fo', 'false');

% ObjectGenerationOption
stCompiler.hObjectGenerationOption.put('/c', 'true');

% DefaultIncludePaths
casIncludePaths = ep_core_mexopt_read(stMEXConfig, 'INCLUDE', ';');
for i=1:length(casIncludePaths)
    sPath = casIncludePaths{i};
    if exist(sPath, 'dir')
        if ~any(strcmp(sPath, stCompiler.casDefaultIncludePaths))
            stCompiler.casDefaultIncludePaths{end+1} = sPath;
        end
    end
end

% IncludeFolderOption
stCompiler.hIncludeFolderOption.put('-I', 'false');

% MacroDefineOption
stCompiler.hMacroDefineOption.put('-D', 'false');

% EnvironmentVariables
stCompiler.hEnvironmentVariables.put('PATH', ep_core_mexopt_read(stMEXConfig, 'PATH', []));
stCompiler.hEnvironmentVariables.put('LIB', ep_core_mexopt_read(stMEXConfig, 'LIB', []));

% RegistrySettings
% TODO: Currently not needed
stCompiler.castRegistrySettings = [];
end




%***********************************************************************************************************************
% Workaround for MSVC COMPFLAGS. Include path are provided with a different
% Delimiter -I"C:\a\b\c".
%
% [sFlag, casImplicitInclPaths] = i_split_implicit_include_paths(sFlag)
%
%   OUTPUT
%   - sFlag                (string) original valid flag
%   - casImplicitInclPaths (cell)   splitted include Paths (if available)
%
%***********************************************************************************************************************
function [sFlag, casImplicitInclPaths, jImplicitDefines] = i_split_implicit_include_paths(sFlag)
casImplicitInclPaths = {};
jImplicitDefines = java.util.HashMap();
iFound = regexp(sFlag, ' -I\"', 'once');
if ~isempty(iFound)
    casPaths = regexp(sFlag(iFound:end), ' -I\"([^"]+)', 'tokens');
    casImplicitInclPaths = [casPaths{:}];
    sFlag = sFlag(1:iFound-1);
end
iFound = regexp(sFlag, '^D', 'once');
if ~isempty(iFound)
    casDefines = regexp(sFlag(iFound + 1:end), '^([^ ]+)', 'tokens');
    for i = 1:length(casDefines)
        sDefine = casDefines{i}{1};
        nEqualsIndex = strfind(sDefine, '=');
        if ~isempty(nEqualsIndex)
            sValue = sDefine(min(nEqualsIndex + 1, length(sDefine)):end);
            sDefine = sDefine(1:nEqualsIndex-1);
        else
            sValue = '';
        end
        jImplicitDefines.put(sDefine, sValue);
    end
    sFlag = sFlag(1:iFound-1);
end
end


%***********************************************************************************************************************
% Add lib tool settings of the active mex compiler
%
% function stLibTool = i_create_libtool_info(stMEXConfig)
%
%   OUTPUT
%   - stLibTool               (struct) Information of the lib tool
%
%***********************************************************************************************************************
function stLibTool = i_create_libtool_info()

% Lib Tool struct
stLibTool = struct('sExecutable', [], ...
    'sLocation', [], ...
    'hOutputFileOption', java.util.HashMap);

% Lib Tool Executable
stLibTool.sExecutable = 'lib';

% Lib Tool Location
% Location is set by the PATH variable
% TODO: The absolute path extraction would be a better solution.
stLibTool.sLocation = '';

% output file option
stLibTool.hOutputFileOption.put('/out:', 'false');

end

%***********************************************************************************************************************
% Add linker settings of the active mex compiler
%
% function stLinker = i_create_linker_info(stMEXConfig)
%
%   INPUT
%   - stMEXConfig            (struct) The 'mex.getCompilerConfigurations()'
%   OUTPUT
%   - stLinker               (struct) Information of the linker
%
%***********************************************************************************************************************
function stLinker = i_create_linker_info(stMEXConfig)

% Linker struct
stLinker = struct('sExecutable', [], ...
    'sLocation', [], ...
    'casLinkerFlags', [], ...
    'hDllOptionForLinker', java.util.HashMap,  ...
    'hOutputFileOption', java.util.HashMap, ....
    'casAdditionalSourceFiles', []);

% Linker Executable
stLinker.sExecutable = stMEXConfig.Details.LinkerExecutable;

% Compiler Location
% Location is set by the PATH variable
% TODO: The absolute path extraction would be a better solution.
stLinker.sLocation = '';

% Linker flags
casLinkerFlags = ep_core_mexopt_read(stMEXConfig, 'LINKFLAGS', '/');
for i=1:length(casLinkerFlags)
    if i_is_linker_flag_excluded(casLinkerFlags{i})
        continue;
    end
    if isempty(stLinker.casLinkerFlags)
        stLinker.casLinkerFlags = {['/', casLinkerFlags{i}]};
    else
        stLinker.casLinkerFlags{end+1} = ['/', casLinkerFlags{i}];
    end
end

stLinker.hDllOptionForLinker.put('/dll', 'true');

% output file option
stLinker.hOutputFileOption.put('/out:', 'false');
end

%***********************************************************************************************************************
% Determines if the given sCFlag must be excluded.
%
% function [bOmit] = i_is_cflag_excluded(sCFlag)
%
%   INPUT
%   - sCFlag            (string)  The C-flag to investigate
%   OUTPUT
%   - bOmit             (boolean) True, if the sCFlag must be excluded. Otherwise, false.
%
%***********************************************************************************************************************
function [bOmit] = i_is_cflag_excluded(sCFlag)
    bOmit = false;
    if isempty(sCFlag) || strcmpi(strrep(sCFlag, ' ', ''), 'c')
        bOmit = true;
    end
end

%***********************************************************************************************************************
% Determines if the given sLinkerFlag must be excluded.
%
% function [bOmit] = i_is_linker_flag_excluded(sLinkerFlag)
%
%   INPUT
%   - sCFlag            (string)  The Linker-Flag to investigate
%   OUTPUT
%   - bOmit             (boolean) True, if the sLinkerFlag must be excluded. Otherwise, false.
%
%***********************************************************************************************************************
function [bOmit] = i_is_linker_flag_excluded(sLinkerFlag)
    bOmit = false;
    if ~isempty(regexpi(sLinkerFlag, '^dll'))
        bOmit = true;
        return;
    end
    if ~isempty(regexpi(sLinkerFlag, '^export'))
        bOmit = true;
        return;
    end
    sMlLibPath = ['LIBPATH:"', matlabroot()];
    if strncmpi(sLinkerFlag, sMlLibPath, length(sMlLibPath))
        bOmit = true;
        return;
    end
end

%***********************************************************************************************************************
% Returns a blacklist for defines. Values of this list never should be added to the compiler settings.
%
% function casDefineBlacklist = i_getDefineBlacklist()
%
%   INPUT
%   - 
%   OUTPUT
%   - casDefineBlacklist (cell) List of blacklisted defines
%
%***********************************************************************************************************************
function casDefineBlacklist = i_getDefineBlacklist()
    casDefineBlacklist = {'MATLAB_MEX_FILE'};
end