function sDir = ut_get_testdata_dir
% Returns the full path to the location of the test data.
%

persistent p_sDir;

if isempty(p_sDir)
    sThisPath = fileparts(mfilename('fullpath')); % path to <...>/ut
    p_sDir = fullfile(fileparts(sThisPath), 'tst', 'testdata');
end
sDir = p_sDir;
end
