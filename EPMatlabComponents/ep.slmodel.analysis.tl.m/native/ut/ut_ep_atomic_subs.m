function ut_ep_atomic_subs
% Check handling of scopes/blocks that are considered as atomic subsystems
%
%


%% prepare test
ut_cleanup();

sPwd      = pwd();
sTestRoot = fullfile(sPwd, 'tmp_atomic_subsystems');
sDataDir  = fullfile(ut_local_testdata_dir_get(), 'AtomicSubsystems');

sTlModel      = 'atomicSubsystems';
sTlModelFile  = fullfile(sTestRoot, [sTlModel, '.mdl']);

%% setup env for test
[xOnCleanupDoCleanupEnv, xEnv] = ut_prepare_env(sDataDir, sTestRoot);

xOnCleanupCloseModelSL = ut_open_model(xEnv, sTlModelFile);
xOrderedCleanup = onCleanup(@() cellfun(@delete, {xOnCleanupCloseModelSL, xOnCleanupDoCleanupEnv}));

astSubsystems = ep_model_subsystems_get(...
    'ModelContext', 'atomicSubsystems/Subsystem/Subsystem/Subsystem', ...
    'Environment', xEnv, ...
    'SubsystemFilter', @i_wrapper);

MU_ASSERT_EQUAL(5, length(astSubsystems));
MU_ASSERT_EQUAL('atomicSubsystems/Subsystem/Subsystem/Subsystem', astSubsystems(1).sVirtualPath);
MU_ASSERT_EQUAL('atomicSubsystems/Subsystem/Subsystem/Subsystem/Atomic', astSubsystems(2).sVirtualPath);
MU_ASSERT_EQUAL('atomicSubsystems/Subsystem/Subsystem/Subsystem/Model', astSubsystems(3).sVirtualPath);
MU_ASSERT_EQUAL('atomicSubsystems/Subsystem/Subsystem/Subsystem/Model/SubInModelRef', astSubsystems(4).sVirtualPath);
MU_ASSERT_EQUAL('atomicSubsystems/Subsystem/Subsystem/Subsystem/Sub/ChartAtomic', astSubsystems(5).sVirtualPath);


end
function [bLookInside, bIgnoreEntity] = i_wrapper(hEntity) 
[bLookInside, bIgnoreEntity] = atgcv_m01_subsys_filter(hEntity, true);
end