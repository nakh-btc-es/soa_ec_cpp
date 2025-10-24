function it_ep_1300()
% Tests the ep_sim_harness_create method

sltu_clear_classes;
[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('variantSubs', 'UT_MIL_SL', 'variantSubs');

sOrgSimMode = 'SL MIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, 'OriginalSimulationMode', sOrgSimMode);
xCleanupTestEnv = onCleanup(@() cellfun(@delete, {xOnCleanUpCloseModel, oOnCleanUpCloseExtrModel}));

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);

% since the extraction model is still open, we can check it now
[~, sName] = fileparts(stResult.stExtractInfo.ExtractionModel);
hModeRef1 = get_param([sName, '/top_level/Variant Subsystem/modelRef1'], 'handle');
hModeRef2 = get_param([sName, '/top_level/Variant Subsystem/modelRef2'], 'handle');
if verLessThan('Matlab', '9.3')
    MU_ASSERT_TRUE(strcmp(get(hModeRef1, 'BlockType'), 'SubSystem'), 'Wrong BlockType');
else
   MU_ASSERT_TRUE(strcmp(get(hModeRef1, 'BlockType'), 'ModelReference'), 'Wrong BlockType');
end
MU_ASSERT_TRUE(strcmp(get(hModeRef2, 'BlockType'), 'ModelReference'), 'Wrong BlockType');
hVariantSub = get_param([sName, '/top_level/Variant Subsystem'], 'handle');
if ep_core_version_compare('ML9.6') >= 0
    MU_ASSERT_TRUE(strcmp(get(hVariantSub, 'CompiledActiveChoiceBlock'), [sName, '/top_level/Variant Subsystem/modelRef1']), ...
        'Wrong subsystem is the active variant');
else
    MU_ASSERT_TRUE(strcmp(get(hVariantSub, 'ActiveVariantBlock'), [sName, '/top_level/Variant Subsystem/modelRef1']), ...
        'Wrong subsystem is the active variant');
end
end