function utrun_nocov(varargin)
% Automatically run unit tests.
%

%% add the source paths
sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');
sPrivPath = fullfile(fileparts(cd), 'src', 'privat');

addpath(sUtPath);
addpath(sSrcPath);
addpath(sPrivPath);


%% caching
% activate for local usage
ut_use_caching(true);


%% run
if ~isempty(varargin)
    MUNITTEST(varargin{:});
else
    MUNITTEST();
end
end
