% Returns the directory for 64 bit executables (.exe files)
%
% function sPath = atgcv_env_bin64_path()
%
%   AUTHOR(S):
%       Rainer.Lochmann@btc-es.de
% $$$COPYRIGHT$$$-2012
%

function path = atgcv_env_bin64_path()
path = char(ct.nativeaccess.ResourceServiceFactory.getInstance().getResourceAsFile([], 'x64').getAbsolutePath());
end
