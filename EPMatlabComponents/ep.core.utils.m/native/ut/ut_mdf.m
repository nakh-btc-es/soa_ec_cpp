% Tests for the ep_core_mdf script.
%
%  function ut_mdf()
%
% $$$COPYRIGHT$$$-2023
function ut_mdf()

    sPreferrefDialect = ep_core_mdf('GetPreferredDialect');
    MU_ASSERT_STRING_EQUAL('EP2.9', sPreferrefDialect);

    bEnabled = ep_core_mdf('GetFixedPointBaseValueEnabled');
    MU_ASSERT_TRUE(bEnabled);
    
end