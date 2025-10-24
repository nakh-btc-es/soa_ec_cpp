function it_slmil_vs_variants()
% Tests the ep_sim_harness_create method

if verLessThan('matlab','23.2')
    [xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SimulinkVariantSubsystems',...
        'SL', 'variantSub_variant/ml2017b', 'top'); %#ok
else
    [xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('SimulinkVariantSubsystems',...
        'SL', 'variantSub_variant/ml2023b', 'top'); %#ok
end

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
