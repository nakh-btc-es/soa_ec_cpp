function utrun(varargin)
% Automatically run unit tests.
%
%  INPUT             DESCRIPTION
%
%  OUTPUT            DESCRIPTION
%
%
%  REMARKS
%
% $$$COPYRIGHT$$$

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%
sUtPath   = fullfile(fileparts(cd), 'ut');
sSrcPath  = fullfile(fileparts(cd), 'src');
sPrivPath = fullfile(fileparts(cd), 'src', 'privat');

addpath(sUtPath);
addpath(sSrcPath);
addpath(sPrivPath);

if ~isempty(varargin)
     MUNITTEST('-cov', sSrcPath, varargin{:});
else
     MUNITTEST('-cov', sSrcPath) 
end
%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************