function sLocation = ut_testdata_dir_get()
% Returns the location of the local testdata.
%
% function sDir = ut_testdata_dir_get()
%


%%
sThisPath = fileparts(mfilename('fullpath'));
sLocation = fullfile(fileparts(sThisPath), 'tst', 'data');

if ~exist(sLocation, 'dir')
    error('UT:INTERNAL:ERROR', 'Expected testdata location for local testdata "%s" not found.', sLocation);
end
end
