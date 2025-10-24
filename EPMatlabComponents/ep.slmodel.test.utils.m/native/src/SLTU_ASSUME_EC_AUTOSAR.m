function bIsAssumptionTrue = SLTU_ASSUME_EC_AUTOSAR
% assumption for the EmbeddedCoder AUTOSAR AddOn
%


%%
bIsAssumptionTrue = sltu_ec_autosar_addon_available;
if ~bIsAssumptionTrue
    MU_MESSAGE('TEST SKIPPED: Test requires EC AUTOSAR AddOn to be installed.');
    return;
end

%%
% for ML versions lower ML2019a a special license is not required --> take a shortcut if possible
if verLessThan('matlab', '9.6')
    return;
end

bIsAssumptionTrue = (license('test', 'autosar_blockset') ~= 0);
if ~bIsAssumptionTrue
    MU_MESSAGE('TEST SKIPPED: For ML >= 2019a test requires EC AUTOSAR blockset license to be available.');
    return;
end
end

