function utrun(varargin)
% Automatically run unit tests.
%

%% add the source paths
sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');
sPrivPath = fullfile(fileparts(cd), 'src', 'privat');

addpath(sUtPath);
addpath(sSrcPath);
addpath(sPrivPath);


%% activate for local usage
sltu_use_caching(true);


%% run
if ~isempty(varargin)
    MUNITTEST('-cov', sSrcPath, varargin{:});
else
    MUNITTEST('-cov', sSrcPath);
end
end
