function ut_m_model_open_002
% Test of atgcv_m_model_open
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
%  Stefan Schulz
% $$$COPYRIGHT$$$
%%

if (atgcv_version_compare('TL3.3') < 0)
    MU_MESSAGE('Test skipped. Tested feature only for TL3.3 and higher.');
    % Multiple workspaces are only supported in TL3.3 and higher
    return;
end

dos('copy "..\testdata\sbc_TL33\*.*" "."');
bdclose all; dsdd('Close', 'Save', 'off');

sModelFile  = fullfile(pwd, 'simplebc_tl.mdl');
sInitScript = fullfile(pwd, 'simplebc_mdl.m');
sDDFile     = fullfile(pwd, 'simplebc.dd');
sAddDDFile  = fullfile(pwd, 'new_dd1.dd');

% upgrad the data dictionary if the target link version greater
% or equal TL3.4
try
    if atgcv_version_compare('TL3.4') >= 0
        tu_test_model_adapt(sModelFile, sInitScript);
        sBatchMode = ds_error_get('BatchMode');
        ds_error_set('BatchMode','on');
        dsdd('Close', 'Save', 'on');
        dsdd('Open', 'file', sAddDDFile, ...
            'Upgrade', 'off'); % prevent PopUp, upgrade will be done later
        dsdd('Upgrade');
        dsdd('Close', 'Save', 'on');
        dsdd_free;
        ds_error_set('BatchMode', sBatchMode);
        delete( fullfile(pwd,'untitled.dd'));
    else
        dsdd_upgrade(sAddDDFile, sAddDDFile);
    end
catch %#ok
    z = lasterror; %#ok
    MU_FAIL_FATAL(z.message);
end

try
    stEnv.sTmpPath    = pwd;
    stEnv.sResultPath = pwd;
    stEnv.hMessenger  = 0;
    
    % Create new DD
    [notNeeded, errorCode0] = dsdd('CreateDD', ...
        'name', 'new_dd', 'initialize', 'on', 'DDIdx', 4);
    
    MU_ASSERT_FATAL(errorCode0 == 0, 'Could not create additional DD.');
    
    % Open model that is currently closed, unrelated DD should be closed
    stRes1 = atgcv_m_model_open( ...
                stEnv, ...
                sModelFile, ...
                {sInitScript}, ...
                true, ...
                false, ...
                {pwd},...
                true);
    
    astDDInfo = dsdd('GetAllDDs');
    MU_ASSERT(length(astDDInfo) == 1, ...
        sprintf('Too many DDs still loaded (expected 1, found %d)', ...
        length(astDDInfo)));
    
    MU_ASSERT_STRING_EQUAL(astDDInfo(1).fileName, sDDFile, ...
        ['Found unexpected DD: ', astDDInfo(1).fileName]);
    
    % Create new DDs
    sDDName2 = 'new_dd2';
    nDDIdx1 = 6;
    nDDIdx2 = 4;
    
    % Existing DD has to be reloaded
    errorCode1 = dsdd('AutoLoad', ...
        'file', sAddDDFile, 'DDIdx', nDDIdx1);
    
    % New DD will not be reloaded
    [notNeeded, errorCode2] = dsdd('CreateDD', ...
        'name', sDDName2, 'initialize', 'on', 'DDIdx', nDDIdx2);
    
    MU_ASSERT_FATAL(errorCode1 == 0, 'Could not create additional DD1.');
    MU_ASSERT_FATAL(errorCode2 == 0, 'Could not create additional DD2.');
    
    % Open model that is already opened, unrelated DD 
    % should be closed here as well
    stRes2 = atgcv_m_model_open( ...
                stEnv, ...
                sModelFile, ...
                {sInitScript}, ...
                true, ...
                false, ...
                {pwd},...
                true);
    
    astDDInfo = dsdd('GetAllDDs');
    MU_ASSERT(length(astDDInfo) == 1, ...
        sprintf('Too many DDs still loaded (expected 1, found %d)', ...
        length(astDDInfo)));
    
    MU_ASSERT_STRING_EQUAL(astDDInfo(1).fileName, sDDFile, ...
        ['Found unexpected DD: ', astDDInfo(1).fileName]);
    
    % Close the model and check if the DDs are reloaded correctly
    atgcv_m_model_close(stEnv, stRes2);
    
    % Expecting 2 DDs, the dault one (DD0) and "new_dd1.dd" which has been
    % loaded previously. The default DD that has been created is expected 
    % not to be loaded because it does not exist as file yet.
    astDDInfo = dsdd('GetAllDDs');
    MU_ASSERT(length(astDDInfo) == 2, ...
        sprintf('Expected 2 DDs to be loaded, found %d', length(astDDInfo)));
    
    stDD = astDDInfo(ismember({astDDInfo.fileName}, sAddDDFile));
    MU_ASSERT(~isempty(stDD), 'Expected DD was not loaded.');
    if ~isempty(stDD)
        MU_ASSERT(stDD.treeIdx == nDDIdx1, ...
            'Expected DD was loaded ito the wrong workspace.');
    end
    
    % close model correctly and free resources
    atgcv_m_model_close(stEnv, stRes1);
    
catch %#ok
    z = lasterror; %#ok
    MU_FAIL(z.message);
end

% cleanup
bdclose all; dsdd('Close', 'Save', 'off');
end

