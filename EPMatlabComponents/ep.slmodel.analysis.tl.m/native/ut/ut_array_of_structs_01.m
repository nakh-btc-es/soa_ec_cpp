function ut_array_of_structs_01
% Check limitation for TL4.4: Currently the handling of "ArrayOfStructs" in C-Code is not supported.
%
%  REMARKS
%       Limitation: When accessing elements of arrays of structs in C-code TL is using "pseudo variables", which
%                   do not represent any real variable but only "accessor macros". Such macros currently cannot
%                   be handled correctly inside the model analysis.
%
%       --> Cosequence of Limitation: If "pseudo variables" are used as interfaces inside of a scope, this particular
%           scope needs to be rejected as SUT.
%


%% check pre-req
if (ep_core_version_compare('TL4.4') < 0)
    MU_MESSAGE('TEST SKIPPED: Test model using array of structs only for TL4.4 and higher.');
    return;
end


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'array_of_structs_01');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'tl44', 'my_bus_cc');

sTlModel      = 'bus_cc_tl';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.slx']);
sTlInitScript = fullfile(sTestRoot, 'start.m');
sDdFile       = fullfile(sTestRoot, 'bus_cc.dd');


%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv, sResultDir] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelTL = ut_open_model(xEnv, sTlModelFile, sTlInitScript);

xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelTL, xOnCleanupDoCleanupEnv}));


%% execute test
stOpt = struct( ...
    'sDdPath',       sDdFile, ...
    'sTlModel',      sTlModel, ...
    'xEnv',          xEnv);

stOpt = ut_prepare_options(stOpt, sResultDir);

[sErrFile, oEx] = ut_ep_model_analyse(stOpt);


%% check test results
MU_ASSERT_TRUE(~isempty(oEx) && strcmp(oEx.identifier, 'ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED'), ...
    'Expecting exception for unsupported interface of toplevel subsystem.');

astMsg = ut_read_error_file(sErrFile);
if ~isempty(astMsg)
    casMsgIds = {astMsg(:).id}; 
    MU_ASSERT_TRUE(sum(strcmp('ATGCV:MOD_ANA:WARNING_INTERFACE_READOUT', casMsgIds)) == 7, ...
        'Expecting 7 warnings for inconsistent interface readout: 3x Inputs & 3x Outputs and 1x Subsystem.');
    
    MU_ASSERT_TRUE(sum(strcmp('ATGCV:MOD_ANA:TOPLEVEL_INVALID_NOT_RECOVERED', casMsgIds)) == 1, ...
        'Expecting 1 error for unrecovered support for toplevel subsystem.');
else
    MU_FAIL('Expecting messages for inconsistent readout and invalid toplevel subsystem.');
end
end


