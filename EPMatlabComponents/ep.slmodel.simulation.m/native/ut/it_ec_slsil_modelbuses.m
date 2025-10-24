function it_ec_slsil_modelbuses()

stMLVerInfo = ver('matlab');
if strcmp(stMLVerInfo.Version, '9.8')
    MU_MESSAGE('Test skipped! Strange model behavior in ML2020a. Matlab bug?');
    return;
end

[xOnCleanUpCloseModel, stTestData] = sltu_prepare_simenv('modelbuses', 'EC', 'modelbuses', 'top'); %#ok

sOrgSimMode = 'SL SIL';
[stResult, oOnCleanUpCloseExtrModel] = sltu_sim_vector(stTestData, ...
    'OriginalSimulationMode', sOrgSimMode, ...
    'SutAsModelRef',          true); %#ok<ASGLU>

SLTU_ASSERT_SELF_CONTAINED_MODEL(stResult.sModelName, true);
SLTU_ASSERT_EQUAL_VECTORS(stTestData.sTestVectorFile, stResult.sSimulatedVector);
end
