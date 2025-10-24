function utrun(varargin)
% Automatically run unit tests.
%
% function utrun
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%
% AUTHOR(S):
%   Rainer.Lochmann@osc-es.de
% $$$COPYRIGHT$$$

%  run all unittests with coverage statistics
sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');

addpath(sUtPath);
addpath(sSrcPath);

if( length(varargin) > 0 )
     MUNITTEST(varargin{:});
else
     MUNITTEST('-cov', sSrcPath) 
end

%  open web browser
%[a,b] = dos('index.html');

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
