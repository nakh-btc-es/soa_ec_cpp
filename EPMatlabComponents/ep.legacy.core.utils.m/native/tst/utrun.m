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

sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');

addpath(sUtPath);


if ~isempty(varargin)
    MUNITTEST(varargin{:});
else
    %  run all unittests with coverage statistics
    MUNITTEST('-cov', sSrcPath)
end

end
%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************
