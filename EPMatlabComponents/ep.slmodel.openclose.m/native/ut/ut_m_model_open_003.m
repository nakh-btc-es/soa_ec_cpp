function ut_m_model_open_003
% Test of atgcv_m_model_open when model is loaded but libs are not
%
% function ut_m_model_open
%
% #Further Descriptions#
%
%   PARAMETER(S)    DESCRIPTION
%   -
%
%   OUTPUT
%   -
%
% AUTHOR(S):
%  Frederik Berg
% $$$COPYRIGHT$$$
%%

if atgcv_version_compare('ML8.0') < 0
    MU_MESSAGE('Test skipped. Only for ML versions >= 2012b');
    return;
end

sTestRoot = fullfile(pwd, 'modelref_link');
sDataPath = '..\testdata\modelref_link';

copyfile(sDataPath, sTestRoot); 
bdclose all; dsdd('Close', 'Save', 'off');

sCD = cd(sTestRoot);
sModelName  = 'model_ref_liblink';
sLibName    = 'model_ref_lib';
sLib2Name   = 'lib2'; 
sModelFile  = fullfile(pwd, [sModelName, '.mdl']);

% upgrade the data dictionary if the target link version greater
% or equal TL3.4
try
    tu_test_model_adapt(sModelFile);
catch %#ok
    z = lasterror; %#ok
    cd(sCD);
    MU_FAIL_FATAL(z.message);
end

try
    stEnv.sTmpPath    = fullfile(pwd, 'tmp');
    stEnv.sResultPath = fullfile(pwd, 'res');
    stEnv.hMessenger  = 0;

    %Case1: Model is open and libraries closed
    
    % load TL model
    load_system(sModelName);
    
    % close referenced lib
    close_system(sLibName, 0);
    close_system(sLib2Name, 0);
    
    % Open model that is currently closed, unrelated DD should be closed
    stRes = atgcv_m_model_open(stEnv, sModelFile, {}, true);
            
    casOpenModels = find_system('type', 'block_diagram');
    bIsLibOpened = any(strcmpi(sLibName, casOpenModels));
    MU_ASSERT_TRUE(bIsLibOpened, ...
        'Referenced library ''model_ref_lib'' should be opened');
    
    bIsLibOpened = any(strcmpi(sLib2Name, casOpenModels));
    MU_ASSERT_TRUE(bIsLibOpened, ...
        'Referenced library ''lib2'' should be opened');
    
    % Close the model and check if the DDs are reloaded correctly
    atgcv_m_model_close(stEnv, stRes);
    
    casOpenModels = find_system('type', 'block_diagram');
    
    bIsLibOpened = any(strcmpi(sLibName, casOpenModels));
    MU_ASSERT_FALSE(bIsLibOpened, ...
        'Referenced library ''model_ref_lib'' should be closed');
    
    bIsLibOpened = any(strcmpi(sLib2Name, casOpenModels));
    MU_ASSERT_FALSE(bIsLibOpened, ...
        'Referenced library ''lib2'' should be closed');
    
    %Case2: Model is open and one library is open. Fixes EP-606
    
    % load TL model
    load_system(sModelName);
    % close referenced lib
    load_system(sLib2Name);
    
    % Open model that is currently closed, unrelated DD should be closed
    stRes = atgcv_m_model_open(stEnv, sModelFile, {}, true);
            
    casOpenModels = find_system('type', 'block_diagram');
    bIsLibOpened = any(strcmpi(sLibName, casOpenModels));
    MU_ASSERT_TRUE(bIsLibOpened, ...
        'Referenced library ''model_ref_lib'' should be opened');
    
    bIsLibOpened = any(strcmpi(sLib2Name, casOpenModels));
    MU_ASSERT_TRUE(bIsLibOpened, ...
        'Referenced library ''lib2'' should be opened');
    
    % Close the model and check if the DDs are reloaded correctly
    atgcv_m_model_close(stEnv, stRes);
    
    casOpenModels = find_system('type', 'block_diagram');
    
    bIsLibOpened = any(strcmpi(sLibName, casOpenModels));
    MU_ASSERT_FALSE(bIsLibOpened, ...
        'Referenced library ''model_ref_lib'' should be closed');
    
    bIsLibOpened = any(strcmpi(sLib2Name, casOpenModels));
    MU_ASSERT_TRUE(bIsLibOpened, ...
        'Referenced library ''lib2'' should be closed');
    
catch %#ok
    z = lasterror; %#ok
    MU_FAIL(z.message);
end

% cleanup
bdclose all; dsdd('Close', 'Save', 'off');
end