function ut_storage
% Tests if internal storage is working as expected.
%
%  function ut_storage
%
%
% $$$COPYRIGHT$$$-2017


%% prepare
xOnCleanupRemoveStorage = onCleanup(@() ep_core_storage('clear'));


%% test main use case
try
    ep_core_storage('clear');
    
    % -- add ---
    dSomeNum = 7.23;
    xKey = ep_core_storage('add', dSomeNum);
    caxStoredKeys = ep_core_storage('keys');
    
    MU_ASSERT_TRUE(length(caxStoredKeys) == 1, ...
        'AFTER ADD: Storage with one data element shall have exactly one key.');
    MU_ASSERT_TRUE(ismember(xKey, caxStoredKeys), ...
        'AFTER ADD: Returned key shall be amongst the stored keys.');
    MU_ASSERT_TRUE(isequal(ep_core_storage('get', xKey), dSomeNum), ...
        'AFTER ADD: Returned data shall be equal to original one.');
    
    % -- add ---
    stSomeStruct = struct('fieldA', 'hallo', 'fieldB', [1 2 3]);
    xSecondKey = ep_core_storage('add', stSomeStruct);
    caxStoredKeys = ep_core_storage('keys');
    
    MU_ASSERT_TRUE(length(caxStoredKeys) == 2, ...
        'AFTER SECOND ADD: Storage with two data elements shall have exactly two keys.');
    MU_ASSERT_TRUE(ismember(xSecondKey, caxStoredKeys), ...
        'AFTER SECOND ADD: Returned key shall be amongst the stored keys.');
    MU_ASSERT_TRUE(isequal(ep_core_storage('get', xSecondKey), stSomeStruct), ...
        'AFTER SECOND ADD: Returned data shall be equal to original one.');
    
    % -- remove ---
    ep_core_storage('remove', xKey);
    caxStoredKeys = ep_core_storage('keys');
        
    MU_ASSERT_TRUE(length(caxStoredKeys) == 1, ...
        'AFTER REMOVE: Storage with one data elements shall have exactly one key.');
    MU_ASSERT_TRUE(ismember(xSecondKey, caxStoredKeys), ...
        'AFTER REMOVE: Key of the remaining data element shall be amongst the stored keys.');
    MU_ASSERT_TRUE(isequal(ep_core_storage('get', xSecondKey), stSomeStruct), ...
        'AFTER REMOVE: Returned data shall be equal to original one.');

    % -- remove ---
    ep_core_storage('remove', xSecondKey);
    caxStoredKeys = ep_core_storage('keys');
    
    MU_ASSERT_TRUE(isempty(caxStoredKeys), ...
        'AFTER SECOND REMOVE: The storage shall be empty (without any keys).');
           
catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end


%% test clearing specifically
try
    ep_core_storage('clear');
    caxStoredKeys = ep_core_storage('keys');
    MU_ASSERT_TRUE(isempty(caxStoredKeys), 'Cleared storage shall have no keys.');
    
    % multiple clears without issues
    ep_core_storage('clear');
    ep_core_storage('clear');
    caxStoredKeys = ep_core_storage('keys');
    MU_ASSERT_TRUE(isempty(caxStoredKeys), 'Multiple cleared storage shall have no keys.');
    
    ep_core_storage('add', 'someData');
    ep_core_storage('add', 'someOtherData');
    caxStoredKeys = ep_core_storage('keys');
    MU_ASSERT_TRUE(~isempty(caxStoredKeys), 'Storage shall contain elements with keys.');
    
    ep_core_storage('clear');
    caxStoredKeys = ep_core_storage('keys');
    MU_ASSERT_TRUE(isempty(caxStoredKeys), 'Cleared storage shall have no keys.');

catch oEx
    MU_FAIL(sprintf('Unexpected error:\n%s', oEx.message));
end



%% robustness
try
    ep_core_storage();
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end


%% robustness
try
    ep_core_storage([]);
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end


%% robustness
try
    ep_core_storage(7.2);
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end

%% robustness
try
    ep_core_storage('some_command');
    MU_FAIL('Missing exception for WRONG_USAGE.');

catch oEx
    MU_PASS(sprintf('Expected error:\n%s', oEx.message));
end
end



%%
function i_createHookFcn(sHookDir,  sHookName)
sHookFile = fullfile(sHookDir, [sHookName, '.m']);
i_writeFile(sHookFile, { ...
    sprintf('function varargout = %s(varargin)', sHookName), ...
    'nArgs = nargin;', ...
    'varargout = cell(1, nArgs);', ...
    'for i = 1:nArgs', ...
    '  varargout{i} = varargin{i};', ...
    'end', ...
    'end'})
end


%%
function xOnCleanupRemoveStub = i_createStubHookDirGet(sTmpHookDir)
if exist(sTmpHookDir, 'dir')
    rmdir(sTmpHookDir, 's');
end
mkdir(sTmpHookDir);

sStubFile = fullfile(pwd, 'ep_core_path_get.m');
i_writeFile(sStubFile, { ...
    'function sPath = ep_core_path_get(varargin)', ...
    sprintf('sPath = ''%s'';', sTmpHookDir), ...
    'end'});
xOnCleanupRemoveStub = onCleanup(@() i_removeStubAndDir(sStubFile, sTmpHookDir));
end


%%
function i_writeFile(sFile, casLines)
hFid = fopen(sFile, 'wt');
if (hFid)
    xOnCleanupClose = onCleanup(@() fclose(hFid));
    
    for i = 1:length(casLines)
        fprintf(hFid, '%s\n', casLines{i});
    end
end
end


%%
function i_removeStubAndDir(sStubFile, sDir)
[~, sCmd] = fileparts(sStubFile);
clear(sCmd);
try
    delete(sStubFile);
    rehash;
catch oEx
    MU_FAIL(sprintf('Stub file was not removed correctly.\nError:\n%s', oEx.message));
end
try
    rmdir(sDir, 's');
catch oEx
    MU_FAIL(sprintf('Directory was not removed correctly.\nError:\n%s', oEx.message));
end
end

