function it_slmil_locals_trig_subs()
% Tests the ep_sim_harness_create method

if ep_core_version_compare('ml9.6') >= 0
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('ManyLocals', 'SL', 'locals_triggered_sub', 'trig', ...
    'testVectorML2019a.csv'); %#ok
else
    [xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('ManyLocals', 'SL', 'locals_triggered_sub', 'trig'); %#ok    
end

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
