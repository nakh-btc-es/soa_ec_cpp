function varargout = tu_tmp_env(varargin)
% Setting/getting the current temporary test data directory
%
% function varargout = sltu_tmp_env(varargin)
%
%   PARAMETER(S)    DESCRIPTION
%
%  ----------------------- (1) read ---------------------------
%      sTmpDir = sltu_tmp_env()     --> Gets the test data directory
%
%  ----------------------- (2) write ---------------------------
%      sltu_tmp_env(sTmpDir)        --> Sets the test data directory
%


%% read
if (nargin < 1)
    varargout{1} = getenv('TU_TMP_TEST_DIR');
    if isempty(varargout{1})
        setenv('TU_TMP_TEST_DIR', i_getTempDir);
        varargout{1} = getenv('TU_TMP_TEST_DIR');
    end
    return;
end

%% write
if ((nargin > 0) && (nargout < 1))
    setenv('TU_TMP_TEST_DIR', varargin{1});
    return;
end

%% error
error('TU:TMP_ENV:WRONG_USAGE', 'Wrong usage. Plese read the docu.');
end

%%
function sTmpDir = i_getTempDir()
sPath = fullfile(tempdir(), ['ut', datestr(now, 30), '_', sprintf('%d', feature('getpid'))]);

% note: normalize path; otherwise, on some machines we get regressions in context of 8.3 DOS-path notation
jFile = java.io.File(sPath);
sTmpDir = char(jFile.getCanonicalPath());
end
