function sLocation = ut_testdata_dir_get(varargin)
% Returns the location of the local testdata.
%
% function sDir = ut_testdata_dir_get(varargin)
%


%%
sThisPath = fileparts(mfilename('fullpath'));
sLocation = fullfile(fileparts(sThisPath), 'tst', 'testdata');

if ~exist(sLocation, 'dir')
    MU_FAIL_FATAL(sprintf('Expected testdata location for local testdata "%s" not found.', sLocation));
end
end
