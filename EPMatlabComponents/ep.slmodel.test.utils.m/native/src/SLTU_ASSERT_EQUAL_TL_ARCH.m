function SLTU_ASSERT_EQUAL_TL_ARCH(sExpectedTlArchFile, sTestTlArchFile)
% Asserts that the TL architecture XML file is equal to the expected XML file.
%

%%
sExpectedTlArchFile = ep_core_canonical_path(sExpectedTlArchFile);
sTestTlArchFile = ep_core_canonical_path(sTestTlArchFile);


if ~exist(sExpectedTlArchFile, 'file')
    if SLTU_update_testdata_mode()
        MU_MESSAGE('Creating expected version of the TL Arch XML. No equality checks performed!');
        sltu_copyfile(sTestTlArchFile, sExpectedTlArchFile);
    else
        SLTU_FAIL('No expected values found. Cannot perform any checking.');
    end
else
    casDiff = sltu_tl_arch_diff(sExpectedTlArchFile, sTestTlArchFile);
    if isempty(casDiff)
        MU_PASS(); % just for statistics reported in MUNIT report
    else
        if SLTU_update_testdata_mode()
            MU_MESSAGE('Differences found. Updating expected values in the TL Arch XML. No equality checks performed!');
            sltu_copyfile(sTestTlArchFile, sExpectedTlArchFile);
        else
            for i = 1:numel(casDiff)
                SLTU_FAIL(casDiff{i});
            end
        end
    end
end
end