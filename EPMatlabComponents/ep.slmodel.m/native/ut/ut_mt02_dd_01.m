function ut_mt02_dd_01
%
% Problem: Checking fix for BTS/36088. Wrong reconstruction of the DD after
%          during breaking liks to Include DDs.
%


%%
MU_MESSAGE('TEST SKIPPED. The DD Upgrade mechanism is broken and currently leads to blocking upgrade dialogs. TODO: Fix me!');
return;


%% prepare data
% assuming that we are in .../m/tst/tempdir
sPwd           = pwd();
sDataPath      = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'tst', 'testdata', 'bug_36088');
sRootDir       = fullfile(sPwd, 'm02_dd_01');
sDdFile        = fullfile(sRootDir, 'main.dd');


%% cleanup hook
i_reboot();
xOnCleanup = onCleanup(@() i_cleanup(sPwd, sRootDir));


%% prepare env
try
    if exist(sRootDir, 'dir')
        rmdir(sRootDir, 's');
    end
    copyfile(sDataPath, sRootDir);
    
catch oEx
    MU_FAIL_FATAL(sprintf('Unexpected exception: %s.', oEx.message));
end


%% get expected values
try
    stExpected = i_upgradeAndReadExpectedValues(sDdFile);

catch oEx
    MU_FAIL_FATAL(sprintf('Unexpected exception: %s.', oEx.message));
end


%% test
try
    sCheckDD = fullfile(sPwd, 'check.dd');
    if exist(sCheckDD, 'file')
        delete(sCheckDD);
    end
    
    % !Note: important to _not_ be in the same directory as the DD file!
    dsdd('Open', sDdFile);
    ep_adapt_current_dd(0);
    
    stValues1 = i_readValues();
    
    dsdd('Save', '//DD0', 'File', sCheckDD);
    dsdd('Close', 'Save', 'off');
    dsdd_free();
    
    stValues2 = i_readValues(sCheckDD);
        
    MU_ASSERT_TRUE(isequal(stExpected, stValues1), ...
        'Adapted DD seems to differ from the original one.');
    MU_ASSERT_TRUE(isequal(stExpected, stValues2), ...
        'Adapted and re-loaded DD seems to differ from the original one.');
catch oEx
    MU_FAIL(sprintf('Unexpected exception: %s.', oEx.message));
end
end


%% 
function i_reboot()
bdclose all;
dsdd('Close', 'Save', 'off');
dsdd_free();
end


%%
function i_cleanup(sPwd, sTestDir)
try
    i_reboot();
catch oEx 
    warning(oEx.identifier, '%s', oEx.message);
end
if exist(sPwd, 'dir')
    cd(sPwd);
end
if exist(sTestDir, 'dir')
    try 
        rmdir(sTestDir, 's'); 
    catch oEx 
        warning(oEx.identifier, '%s', oEx.message);
    end
end
end


%%
function stExpected = i_upgradeAndReadExpectedValues(sDDFile)
sPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sPwd));

% !Note: important to go into the folder where the main DD resides!
sDDPath = fileparts(sDDFile);
cd(sDDPath);

xOnCleanupClose = i_loadDD(sDDFile); %#ok<NASGU> onCleanup Object
i_upgradeDD();
dsdd('Save');

stExpected = i_readValues();
end


%%
function xOnCleanupClose = i_loadDD(sDDFile)
dsdd_free();
dsdd('Open', 'File', sDDFile, 'Upgrade', 'off');

xOnCleanupClose = onCleanup(@() dsdd_free);
end


%%
function i_upgradeDD()
if (atgcv_version_p_compare('TL3.4') < 0)
    dsdd_upgrade();
else
    dsdd('Upgrade');
end
end


%%
function stValues = i_readValues(sDDFile)
if (nargin > 0)
    xOnCleanupClose = i_loadDD(sDDFile); %#ok<NASGU> onCleanup Object
end

stValues = struct();
ahVars = dsdd('Find', '/Pool/Variables', 'ObjectKind', 'Variable');
for i = 1:length(ahVars)
    hVar = ahVars(i);
    
    sName = dsdd('GetAttribute', hVar, 'Name');
    stValues.(sName) = i_getVarAttributes(hVar);
end
end


%%
function stAtt = i_getVarAttributes(hVar)
stAtt = struct( ...
    'Type',  dsdd('GetType',  hVar), ...
    'Value', dsdd('GetValue', hVar), ...
    'Min',   dsdd('GetMin',   hVar), ...
    'Max',   dsdd('GetMax',   hVar));   
end


