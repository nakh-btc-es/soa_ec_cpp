function SLTU_ASSERT_EQUAL_SL_ARCH(sExpectedSlArchFile, sTestSlArchFile)
% Asserts that the SL architecture XML file is equal to the expected XML file.
%

%%
sExpectedSlArchFile = ep_core_canonical_path(sExpectedSlArchFile);
sTestSlArchFile = ep_core_canonical_path(sTestSlArchFile);

if ~exist(sExpectedSlArchFile, 'file')
    if SLTU_update_testdata_mode()
        MU_MESSAGE('Creating expected version of the SL Arch XML. No equality checks performed!');
        sltu_copyfile(sTestSlArchFile, sExpectedSlArchFile);
    else
        SLTU_FAIL('No expected values found. Cannot perform any checking.');
    end
else
    casDiff = sltu_sl_arch_diff(sExpectedSlArchFile, sTestSlArchFile);
    if isempty(casDiff)
        MU_PASS(); % just for statistics reported in MUNIT report
    else
        if SLTU_update_testdata_mode()
            MU_MESSAGE('Differences found. Updating expected values in the SL Arch XML. No equality checks performed!');
            sltu_copyfile(sTestSlArchFile, sExpectedSlArchFile);
        else
            for i = 1:numel(casDiff)
                SLTU_FAIL(casDiff{i});
            end
        end
    end
end
end

