function sDtdFile = ut_m01_get_spec_dtd(sDtdName)
% return full path to the provided DTD
%
% note: just a helper function for UnitTests   
%
%

%%
sThisPath = fileparts(mfilename('fullpath'));
sDtdFile = fullfile(fileparts(fileparts(sThisPath)), 'spec', 'dtd', sDtdName);
end

