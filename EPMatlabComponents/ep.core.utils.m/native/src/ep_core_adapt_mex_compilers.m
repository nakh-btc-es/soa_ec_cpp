%%
%  This function set the mex CPP compiler to the corresponding C compiler.
%
%  [bCAndCppCompilersMatch, bCppCompilerWasSwitched, stPreviousCppCompiler] ...
%     = ep_core_adapt_mex_compilers('setCppLikeC')
%
%  INPUT               DESCRIPTION
%  'setCppLikeC'       Command mode of this function.
%
%  OUTPUT              DESCRIPTION
%  bCAndCppCompilersMatch  True iff C and C++ compilers match after the call.
%  bCppCompilerWasSwitched True iff the C++ compiler was switched,
%  stPreviousCppCompiler Previously set C++ compiler.
%                      This value can be used to reset the C++ compiler by calling
%                      ep_core_adapt_mex_compilers('setCpp', stPreviousCppCompiler).
%                      Can be empty if no compiler was set.
%
%  bSuccess = ep_core_adapt_mex_compilers('setCpp', stCompiler)
%
%  INPUT               DESCRIPTION
%  'setCpp'            Command mode of this function.
%  stCompiler          C++ compiler to be set.
%
%  OUTPUT              DESCRIPTION
%  bSuccess            True iff the compiler was switched successfully.
%%
function varargout = ep_core_adapt_mex_compilers(sCmd, varargin)

switch sCmd
    case 'setCppLikeC'
        [varargout{1:nargout}] = i_setCppLikeC();
    case 'setCpp'
        stCompiler = varargin{1};
        [varargout{1:nargout}] = i_setCpp(stCompiler);
    otherwise
        error(["Unknown command ", sCmd, "."]);
end

end

%%
%  This function sets a mex C++ compiler.
%
%  bSuccess = i_setCpp(stCompiler)
%
%  INPUT               DESCRIPTION
%  stCompiler          C++ compiler to be set.
%
%  OUTPUT              DESCRIPTION
%  bSuccess            True iff the compiler was switched successfully.
%%
function bSuccess = i_setCpp(stCompiler)

if isempty(stCompiler)
    bSuccess = false;
else
    try
        sMexOpt = stCompiler.MexOpt;
        sMexCmd = ['mex(''-setup:', sMexOpt, ''',''C++'')'];
        iResult = evalin('base', sMexCmd);
        bSuccess = iResult == 0;
    catch
        bSuccess = false;
    end
end
end


%%
%  This function set the mex CPP compiler to the corresponding C compiler.
%
%  function currentCppCompiler = i_setCppLikeC()
%
%  INPUT               DESCRIPTION
%
%  OUTPUT              DESCRIPTION
%  bCAndCppCompilersMatch True if C and C++ compilers match after the call.
%  bCppCompilerWasSwitched True iff the C++ compiler was switched,
%  stPreviousCppCompiler Previously set C++ compiler.
%                      This value can be used to reset the C++ compiler by calling
%                      ep_core_adapt_mex_compilers('setCpp', stPreviousCppCompiler).
%                      Can be empty if no compiler was set.
%%
function [bCAndCppCompilersMatch, bCppCompilerWasSwitched, stPreviousCppCompiler] = i_setCppLikeC()

    bCAndCppCompilersMatch = false;
    bCppCompilerWasSwitched = false;

    currentCCompiler = mex.getCompilerConfigurations('C', 'Selected');
    if isempty(currentCCompiler)
        % no C compiler has been set at all
        return
    end

    % check the currently set C++ compiler
    stPreviousCppCompiler = mex.getCompilerConfigurations('C++', 'Selected');
    if ~isempty(stPreviousCppCompiler) && strcmp(currentCCompiler.Location, stPreviousCppCompiler.Location)
        bCAndCppCompilersMatch = true;
        return
    end

    % get all installed C++ compilers
    aInstalledCppCompilers = mex.getCompilerConfigurations('C++', 'Installed');
    sCCompilerLocation = currentCCompiler.Location;
    for i=1:length(aInstalledCppCompilers)
        stInstalledCppCompiler = aInstalledCppCompilers(i);
        sCppCompilerLocation = stInstalledCppCompiler.Location;
        if strcmp(sCCompilerLocation, sCppCompilerLocation)
            % corresponding C++ compiler has been found, try to set
            bSuccess = i_setCpp(stInstalledCppCompiler);
            if bSuccess
                % setting the C++ compiler was successful
                bCAndCppCompilersMatch = true;
                bCppCompilerWasSwitched = true;
                stPreviousCppCompiler = i_get_installed_compiler(stPreviousCppCompiler);
            end
            return
        end
    end
end

%%
%  Re-read compiler from the installed ones to update the field MexOpt.
%%
function stCompiler = i_get_installed_compiler(stCompiler)

    aInstalledCppCompilers = mex.getCompilerConfigurations('C++', 'Installed');

    if ~isempty(stCompiler)
        % replace by installed compiler for which the attribute MexOpt refers to
        % an original compiler configuration file in the Matlab installation.
        % In the selected C++ configuration the MexOpt refers to a temporary file.
        for i=1:length(aInstalledCppCompilers)
            if ...
                    strcmp(stCompiler.Name, aInstalledCppCompilers(i).Name) && ...
                    strcmp(stCompiler.Language, aInstalledCppCompilers(i).Language) && ...
                    strcmp(stCompiler.Version, aInstalledCppCompilers(i).Version) && ...
                    strcmp(stCompiler.Location, aInstalledCppCompilers(i).Location)
                % installed compiler found
                stCompiler = aInstalledCppCompilers(i);
                break
            end
        end
    end
end