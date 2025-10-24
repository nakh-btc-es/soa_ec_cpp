function ut_path_get()
% Tests, if the hook of ep_core_path_get works.
%
%  function ut_path_get()
%
% $$$COPYRIGHT$$$-2021

oPrefDir = javaObject('java.io.File', tempname);
oPrefDir.mkdir();
oPrefDir.deleteOnExit();
oHookDir = javaObject('java.io.File', oPrefDir, '.\hooks');
oHookDir.mkdir();
oHookDir.deleteOnExit();
sHookDir = ep_core_canonical_path(char(oHookDir.getPath()));
oConfigDir = javaObject('java.io.File', oPrefDir, '.\ec_configs');
oConfigDir.mkdir();
oConfigDir.deleteOnExit();
sConfigDir = ep_core_canonical_path(char(oConfigDir.getPath()));
oPrefFile = javaObject('java.io.File', oPrefDir, 'EPPreference.xml');
oPrefFile.deleteOnExit();
sPrefFile = char(oPrefFile.getPath());
setenv('EP_PREFERENCE_LOCATION', sPrefFile);

try 
    
% prepare unit test for a relative hook path and EC config path next to preference file works
i_writePreferenceFile(sPrefFile, '.\hooks', '.\ec_configs');
    
% unit test check that a relative hook path next to preference file works
% correctly for EP_HOOKS
sAbsoluteResourcePath = ep_core_path_get('EP_HOOKS');
MU_ASSERT_STRING_EQUAL(sHookDir, sAbsoluteResourcePath, 'relative hook path next to preference file does not work');

% unit test check that a relative hook path next to preference file works
% correctly for TL_HOOKS
sAbsoluteResourcePath = ep_core_path_get('TL_HOOKS');
MU_ASSERT_STRING_EQUAL(fullfile(sHookDir, 'tl_hooks'), sAbsoluteResourcePath, 'relative TL hook path next to preference file does not work');

% unit test check that a relative EC config path next to preference file works
% correctly for EC_CONFIGS
sAbsoluteResourcePath = ep_core_path_get('EC_CONFIGS');
MU_ASSERT_STRING_EQUAL(sConfigDir, sAbsoluteResourcePath, 'relative EC config path next to preference file does not work');


% prepare unit test for an absolute hook path and EC config path works correctly
i_writePreferenceFile(sPrefFile, sHookDir, sConfigDir)

% unit test check that an absolute hook path works correctly for EP_HOOKS
sAbsoluteResourcePath = ep_core_path_get('EP_HOOKS');
MU_ASSERT_STRING_EQUAL(sHookDir, sAbsoluteResourcePath, 'absolute hook path does not work');

% unit test check that an absolute hook path works correctly for TL_HOOKS
sAbsoluteResourcePath = ep_core_path_get('TL_HOOKS');
MU_ASSERT_STRING_EQUAL(fullfile(sHookDir, 'tl_hooks'), sAbsoluteResourcePath, 'absolute TL hook path does not work');

% unit test check that an absolute EC config path works correctly for EC_CONFIGS
sAbsoluteResourcePath = ep_core_path_get('EC_CONFIGS');
MU_ASSERT_STRING_EQUAL(sConfigDir, sAbsoluteResourcePath, 'absolute EC config path does not work');


% prepare unit test for a relative hook path next to installation path works correctly
%% TODO it seems it is not possible to execute the following UT because we
%% have not an installed product on jenkins, there the UT is disabled
% i_writePreferenceFile(sPrefFile, '')

% sAbsoluteMatlabPath = ep_core_internal_resource_get('scripts/m');

% unit test check that a relative hook path next to installation path works correctly for EP_HOOKS
% sAbsoluteResourcePath = ep_core_path_get('EP_HOOKS');
% MU_ASSERT_STRING_EQUAL(fullfile(sAbsoluteMatlabPath, 'hooks'), sAbsoluteResourcePath, 'relative hook path next to installation path does not work');

% unit test check that a relative hook path next to installation path works correctly for TL_HOOKS
% sAbsoluteResourcePath = ep_core_path_get('TL_HOOKS');
% MU_ASSERT_STRING_EQUAL(fullfile(sAbsoluteMatlabPath, 'hooks', 'tl_hooks'), sAbsoluteResourcePath, 'relative TL hook path next to installation path does not work');

setenv('EP_PREFERENCE_LOCATION');

catch oEx
    setenv('EP_PREFERENCE_LOCATION');
    rethrow(oEx)
end

end

%%
function i_writePreferenceFile(sFile, sHookDir, sConfigDir)
    hFid = fopen(sFile, 'wt');
    fprintf(hFid, '<?xml version="1.0" encoding="UTF-8"?>\n');
    fprintf(hFid, '<preferences>\n');
    fprintf(hFid, '<preference name="GENERAL_MATLAB_HOOKS_DIRECTORY" description="no" type="String" global="true" value="%s" />\n', sHookDir);
    fprintf(hFid, '<preference name="ARCHITECTURE_EC_DEFAULT_CONFIGURATION_FOLDER" description="no" type="String" global="true" value="%s" />\n', sConfigDir);
    fprintf(hFid, '</preferences>\n');
    fclose(hFid);
end
