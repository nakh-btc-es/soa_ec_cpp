function stMock = sltu_create_mock(sFuncName, sContent, sOutputExpression)
% 
%

%%
if isempty(sFuncName)
    error('SLTU:USAGE:ERROR', 'Empty function name not allowed.');
end
if (nargin < 3)
    sOutputExpression = '';
end
if (nargin < 2)
    sContent = '';
end

sTempDir = i_createTempDir();
sMockFile = fullfile(sTempDir, [sFuncName, '.m']);

i_createMockWithContent(sMockFile, sFuncName, sContent, sOutputExpression);

addpath(sTempDir);
rehash;

stMock = struct( ...
    'sMockFile',        sMockFile, ...
    'oOnCleanupDelete', onCleanup(@() i_deleteMockDir(sTempDir)));
end


%%
function sTmpDir = i_createTempDir()
sTmpDir = tempname;
if ~exist(sTmpDir, 'dir')
    mkdir(sTmpDir);
end
end


%%
function i_deleteMockDir(sTempDir)
rmpath(sTempDir);
try
    try
        rmdir(sTempDir, 's');
    catch
        cd(tempdir());
        rmdir(sTempDir, 's');
    end
catch oEx
    fprintf('[SLTU:ERROR] Directory %s containing the mock could not be removed:\n%s', sTempDir, oEx.getReport());
end
rehash;
end


%%
function i_createMockWithContent(sMockFile, sFuncName, sContent, sOutputExpression)
hFid = fopen(sMockFile, 'w');
oOnCleanup = onCleanup(@() fclose(hFid));

if isempty(sOutputExpression)
    fprintf(hFid, 'function %s(varargin)\n', sFuncName);
else
    fprintf(hFid, 'function %s = %s(varargin)\n', sOutputExpression, sFuncName);
end

fprintf(hFid, '%% MOCK created for testing\n\n');
if ~isempty(sContent)
    fprintf(hFid, '%s\n', sContent);
end

fprintf(hFid, 'end\n');
end

