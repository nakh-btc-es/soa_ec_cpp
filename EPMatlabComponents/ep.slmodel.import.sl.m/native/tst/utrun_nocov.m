function utrun_nocov(varargin)
% Automatically run unit tests.
%

sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');
sPrivPath = fullfile(fileparts(cd), 'src', 'privat');

addpath(sUtPath);
addpath(sSrcPath);
addpath(sPrivPath);

if ~isempty(varargin)
     MUNITTEST(varargin{:});
else
     MUNITTEST() 
end
end
