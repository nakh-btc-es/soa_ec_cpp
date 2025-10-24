function utrun(varargin)
% Automatically run unit tests.
%
% function utrun
%

%  run all unittests with coverage statistics
sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');

addpath(sUtPath);
addpath(sSrcPath);

if ~isempty(varargin)
     MUNITTEST(varargin{:});
else
     MUNITTEST('-cov', sSrcPath) 
end
end
