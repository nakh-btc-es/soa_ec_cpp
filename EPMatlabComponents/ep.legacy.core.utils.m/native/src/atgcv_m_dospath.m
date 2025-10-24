function sDosPath = atgcv_m_dospath(sWindowsPath)

%  Returns the DOS path of a given windows path.
%
%  function sDosPath = atgcv_m_dospath(sWindowsPath)
%
%   INPUT               DESCRIPTION
%     sWindowsPath        (string)    The Windows Path (may contain spaces).
%
%   OUTPUT              DESCRIPTION
%     sDosPath            (string)    The DOS path, or an empty string, if transformation failed.
%
%   AUTHOR(S):
%     Rainer Koopmann
% $$$COPYRIGHT$$$-2005


sDosPath = i_getDosPath(sWindowsPath);
if ~exist(sDosPath, 'dir')
    % sometimes DOS 8.3 path is not correctly constructed
    % see BTS/28856 --> use Workaround function
    sDosPath = i_getDosPathWorkaround(sWindowsPath);
end
end


%%
function sDosPath = i_getDosPath(sPath)
cmd = sprintf('for %%g in ("%s") do echo.%%~fsg', sPath);
[s, w] = dos(cmd);
dil = sprintf('\n');
[t, r] = strtok(w, dil);
sDosPath = strtok(r, dil);
end

%%
function sDosPath = i_getDosPathWorkaround(sWindowsPath)
[sDosPath, sPathRemain] = strtok(sWindowsPath, filesep);
while ~isempty(sPathRemain)
    [sPathPart, sPathRemain] = strtok(sPathRemain, filesep);
    sDosPath = i_getDosPath(fullfile(sDosPath, sPathPart));
end
end

