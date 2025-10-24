function stMEXCompilerSettings = ep_core_compiler_gcc_get(stMEXConfig, sCompilerName)
% Evaluates the compiler settings of a GCC compiler
%
% function stMEXCompilerSettings = ep_core_compiler_gcc_get(stMEXConfig, sCompilerName)
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
%           .sBitWidth                  (string)            Bit width of the compiler (32 Bit or 64 Bit)
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
% $$$COPYRIGHT$$$-2022

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

stMEXCompilerSettings = struct(...
    'stCompiler', i_create_compiler_info(stMEXConfig, sCompilerName), ...
    'stLibTool', i_create_libtool_info(), ...
    'stLinker', i_create_linker_info(stMEXConfig));
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
stCompiler = struct('sName', upper(sCompilerName), ...
    'sAdditionalInfo', [stMEXConfig.Name , ' (' , stMEXConfig.Version, ')'], ...
    'sExecutable', stMEXConfig.Details.CompilerExecutable, ...
    'sLocation', '', ...
    'casCompilerFlags', [], ...
    'sBitWidth', [], ...
    'hDefaultDefines', java.util.HashMap, ...
    'hOutputObjectFileOption', java.util.HashMap, ...
    'hObjectGenerationOption', java.util.HashMap, ...
    'casDefaultIncludePaths', [], ...
    'hIncludeFolderOption', java.util.HashMap, ...
    'hMacroDefineOption', java.util.HashMap, ...
    'hEnvironmentVariables', java.util.HashMap, ...
    'castRegistrySettings', []);

% Default Compiler Flags
casCFlags = ep_core_mexopt_read(stMEXConfig, 'CFLAGS', ' -');
casCFlags = unique(regexprep(casCFlags, '^-', ''), 'stable');

if strcmpi(stMEXConfig.Language, 'C++')
    casCFlags{end + 1} = 'std=gnu++14';
    casCFlags{end + 1} = 'x c++';
else
    if stMEXConfig.bUseC99
        casCFlags{end + 1} = 'std=gnu99';
    else
        casCFlags{end + 1} = 'std=gnu90';
    end

    stCompiler.hDefaultDefines.put('_Float32', 'float');
    stCompiler.hDefaultDefines.put('_Float32x', 'double');
    stCompiler.hDefaultDefines.put('_Float64', 'double');
    stCompiler.hDefaultDefines.put('_Float64x', 'long double');
    stCompiler.hDefaultDefines.put('_Float128', 'long double');
end 
casCFlags{end + 1} = 'fwrapv';


casIncludePaths = {};
for i=1:length(casCFlags)
    if (i_is_cflag_excluded(casCFlags{i}))
        continue;
    end
    % Extract include paths and add to default include paths
    if (~isempty(regexp(casCFlags{i}, '^I.+', 'Once')) && ...
            exist(fullfile(strrep(casCFlags{i}(2:end), '"', '')), 'dir') == 7)
        if isempty(casIncludePaths)
            casIncludePaths = {strrep(casCFlags{i}(2:end), '"', '')};
        else
            casIncludePaths{end+1} = strrep(casCFlags{i}(2:end), '"', ''); %#ok
        end
    end
    % Add compiler flags
    if isempty(stCompiler.casCompilerFlags)
        stCompiler.casCompilerFlags = {['-', casCFlags{i}]};
    else
        stCompiler.casCompilerFlags{end+1} = ['-', casCFlags{i}];
    end
end

%Default defines
if strcmp('mexw64', mexext) || strcmp('mexa64', mexext)
    stCompiler.sBitWidth = '64';
else
    stCompiler.sBitWidth = '32';
end

% OutputObjectFileOption
stCompiler.hOutputObjectFileOption.put('-o', 'true');

% ObjectGenerationOption
stCompiler.hObjectGenerationOption.put('-c', 'true');

% DefaultIncludePaths
casIncludePaths = horzcat(casIncludePaths , ep_core_mexopt_read(stMEXConfig, 'INCLUDE', ';'));

if strcmpi(stMEXConfig.Language, 'C++')
    casIncludePaths{end + 1} = fullfile('/usr/include/c++/', stMEXConfig.Version);
    casIncludePaths{end + 1} = fullfile('/usr/include/x86_64-linux-gnu/c++/', stMEXConfig.Version);
end
casIncludePaths{end + 1} = fullfile(['/usr/lib/gcc/x86_64-linux-gnu/', stMEXConfig.Version, '/include']);
casIncludePaths{end + 1} = fullfile('/usr/local/include');
casIncludePaths{end + 1} = fullfile('/usr/include/x86_64-linux-gnu');
casIncludePaths{end + 1} = fullfile('/usr/include');

for i=1:length(casIncludePaths)
    if exist(casIncludePaths{i}, 'dir')
        if isempty(stCompiler.casDefaultIncludePaths)
            stCompiler.casDefaultIncludePaths = casIncludePaths(i);
        else
            stCompiler.casDefaultIncludePaths{end+1} = casIncludePaths{i};
        end
    end
end

% IncludeFolderOption
stCompiler.hIncludeFolderOption.put('-I', 'false');

% MacroDefineOption
stCompiler.hMacroDefineOption.put('-D', 'false');

% EnvironmentVariables
stCompiler.hEnvironmentVariables.put('PATH', ep_core_mexopt_read(stMEXConfig, 'PATH', []));
stCompiler.hEnvironmentVariables.put('LIB', ['/lib/gcc/x86_64-linux-gnu/', stMEXConfig.Version]);

% RegistrySettings
% TODO: Currently not needed
stCompiler.castRegistrySettings = [];
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

% Lib Tool Location
% Location is set by the PATH variable
% TODO: The absolute path extraction would be a better solution.
stLibTool = struct('sExecutable', 'gcc', ...
    'sLocation', '', ...
    'hOutputFileOption', java.util.HashMap);

% output file option
stLibTool.hOutputFileOption.put('-o', 'true');

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
    'sLocation', '', ...
    'casLinkerFlags', '', ...
    'hDllOptionForLinker', java.util.HashMap,  ...
    'hOutputFileOption', java.util.HashMap, ....
    'casAdditionalSourceFiles', []);

% Linker Executable
stLinker.sExecutable = stMEXConfig.Details.LinkerExecutable;
if isempty(stLinker.sExecutable)
    stLinker.sExecutable = 'gcc';
end

% Linker flags
casLinkerFlags = ep_core_mexopt_read(stMEXConfig, 'LDFLAGS', ' -');
casLinkerFlags = unique(regexprep(casLinkerFlags, '^-', ''), 'stable');
casLinkerFlags(~cellfun('isempty', regexp(casLinkerFlags, 'Wl,.*mexFunction.def"?', 'ONCE'))) = [];
casLinkerFlags(~cellfun('isempty', regexp(casLinkerFlags, 'Wl,.*mexFunction.map"?', 'ONCE'))) = [];
casLinkerFlags(ismember(casLinkerFlags, 'shared')) = [];
sPrelinkCommand = ep_core_mexopt_read(stMEXConfig, 'PRELINK_CMDS1', []);

for i=1:length(casLinkerFlags)
    % Ensure that the obj files of the PRELINK_CMDS1'
    % The prelink files are handled by the additional sources below
    if (~isempty(regexpi(casLinkerFlags{i}, '(.+\.o"?)$')))
        sLinkerFlagsWithoutObjectFiles = [];
        casRemaining = textscan(casLinkerFlags{i}, '%s','delimiter',' ');
        if ~isempty(casRemaining)
            casRemaining = casRemaining{1};
            for j=1:length(casRemaining)
                sLinkerFlag = casRemaining{j};
                if isempty(regexpi(sLinkerFlag, '(.+\.o"?)$')) || ...
                        (isempty(sPrelinkCommand) || ...
                        isempty(strfind(sPrelinkCommand{1}, sLinkerFlag)))
                    sLinkerFlagsWithoutObjectFiles = [sLinkerFlagsWithoutObjectFiles, sLinkerFlag, ' ']; %#ok
                end
            end
        end
        casLinkerFlags{i} = sLinkerFlagsWithoutObjectFiles;
    end
    
    % Filter DLL flag
    if i_is_linker_flag_excluded(casLinkerFlags{i})
        continue;
    end
    if isempty(stLinker.casLinkerFlags)
        stLinker.casLinkerFlags = {['-', casLinkerFlags{i}]};
    else
        stLinker.casLinkerFlags{end+1} = ['-', casLinkerFlags{i}];
    end
end

% Add post link flags
casLinkFlagsPost = ep_core_mexopt_read(stMEXConfig, 'LINKFLAGSPOST', []);
if ~isempty(casLinkFlagsPost)
    stLinker.casLinkerFlags{end+1} = casLinkFlagsPost{1};
end

% Dll gen option
stLinker.hDllOptionForLinker.put('-shared', 'true');

% output file option
stLinker.hOutputFileOption.put('-o', 'true');

% additional sources for the linker
casAdditionalFiles = ep_core_mexopt_read(stMEXConfig, 'PRELINK_CMDS1', ' ');

for i=1:length(casAdditionalFiles)
    if ~isempty(regexp(casAdditionalFiles{i}, '[^-](.)+\.c"?', 'Once'))
        stLinker.casAdditionalSourceFiles{end+1} = strrep(casAdditionalFiles{i}, '"', '');
    end
end
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
    if strcmpi(strrep(sCFlag, ' ', ''), 'c')
        bOmit = true;
    end
    if strcmpi(sCFlag, 'DMATLAB_MEX_FILE')
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
    if ~isempty(regexpi(sLinkerFlag, '^so'))
        bOmit = true;
        return;
    end
    if ismember(sLinkerFlag, {'llibmx', 'llibmex', 'llibmat', 'llibmwlapack', 'llibmwblas', 'lmx', 'lmex', 'lmat', 'lstdc++'})
        bOmit = true;
        return;
    end
    sMlLibPath = ['L"', matlabroot()];
    if strncmpi(sLinkerFlag, sMlLibPath, length(sMlLibPath))
        bOmit = true;
        return;
    end
end
