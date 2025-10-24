function it_ep_ep_675()
% Tests the ep_simenv_values2mat() method to ensure that the mat file is saved using -v6
%
%  it_ep_ep_675()
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
%% prepare test
ep_tu_cleanup();
sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'it_ep_ep_675');
try
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
    
    ep_tu_mkdir(sTestRoot);
    cd(sTestRoot);
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env setup: "%s".', exception.message));
end
%% Test Case
try
    xEnv = EPEnvironment();
    sTempDir = xEnv.getTempDirectory();
    sIfId = 'dummyVar';
    iNumber = 13000;
    adTimes = zeros(1,iNumber);
    adValues = ones(1,iNumber);
    dTime = 0.0;
    for i=1:iNumber
        adTimes(i) = dTime;
        dTime = dTime + 0.2;
    end
    % Set the preference to 7.3 to force the issue
    sOldSaveFormat = com.mathworks.services.Prefs.getStringPref('MatfileSaveFormat');
    com.mathworks.services.Prefs.setStringPref('MatfileSaveFormat', 'v7.3');
    
    % call the method to test
    ep_simenv_values2mat(sTempDir, sIfId, adTimes, adValues);
    
    com.mathworks.services.Prefs.setStringPref('MatfileSaveFormat', sOldSaveFormat);
    
    % check if the file can be imported
    sMatName = sprintf('%s.mat',sIfId);
    sMatFile = fullfile(sTempDir,sMatName);
    sType = evalc(['type(''', sMatFile, ''')']);
    MU_ASSERT_TRUE(strcmp(sType(2:20), 'MATLAB 5.0 MAT-file'), ...
        'MAT-File is not stored in MATLAB 5 format');
    delete(sMatFile);
catch exception
    if ~isempty(sOldSaveFormat)
        com.mathworks.services.Prefs.setStringPref('MatfileSaveFormat', sOldSaveFormat);
    end
    MU_FAIL(sprintf('Unexpected exception: "%s".', exception.message));
end
%% clean up test dir
try
    cd(sPwd);
    if exist(sTestRoot, 'dir')
        ep_tu_rmdir(sTestRoot);
    end
catch exception
    MU_FAIL_FATAL(sprintf('Unexpected exception during test env clean up: "%s".', exception.message));
end
end

