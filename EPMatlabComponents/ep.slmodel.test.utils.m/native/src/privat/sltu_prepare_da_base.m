function [xCleanupTestEnv, stTestData] = sltu_prepare_da_base(sModelName, sSuite, sTestDataPath, sEnc)
[xCleanupTestEnv, stTestData] = sltu_prepare_simenv_base(sModelName, sSuite, sTestDataPath, '', false, sEnc);
end
