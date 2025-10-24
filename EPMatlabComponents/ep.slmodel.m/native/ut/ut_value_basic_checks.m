function ut_value_basic_checks
% checking functionality of Value class
%



%% corner cases
oVal = ep_sl.Value('');
i_checkVal('Empty String', oVal, true, false, true, '');

oVal = ep_sl.Value([]);
i_checkVal('Empty Array', oVal, true, false, true, '');

oVal = ep_sl.Value('NaN');
i_checkVal('NaN String', oVal, false, false, true, 'NaN');

oVal = ep_sl.Value(NaN);
i_checkVal('NaN Value', oVal, false, false, true, 'NaN');

oVal = ep_sl.Value(java.lang.Double('NaN'));
i_checkVal('NaN Java object', oVal, false, false, true, 'NaN');

oVal = ep_sl.Value('Inf');
i_checkVal('Inf String', oVal, false, false, false, 'Infinity');

oVal = ep_sl.Value('Infinity');
i_checkVal('Infinity String', oVal, false, false, false, 'Infinity');

oVal = ep_sl.Value('  +Infinity  ');
i_checkVal('Infinity with whitespaces and plus String', oVal, false, false, false, 'Infinity');

oVal = ep_sl.Value(java.lang.Double('Infinity'));
i_checkVal('Infinity Java object', oVal, false, false, false, 'Infinity');

oVal = ep_sl.Value(Inf);
i_checkVal('Inf Value', oVal, false, false, false, 'Infinity');

oVal = ep_sl.Value('-Inf');
i_checkVal('-Inf String', oVal, false, false, false, '-Infinity');

oVal = ep_sl.Value('-Infinity');
i_checkVal('-Infinity String', oVal, false, false, false, '-Infinity');

oVal = ep_sl.Value(-Inf);
i_checkVal('-Inf Value', oVal, false, false, false, '-Infinity');



%% 64bit
oVal = ep_sl.Value('36028797018963981');
i_checkVal('Int64 String', oVal, false, true, false, '36028797018963981');

oVal = ep_sl.Value(int64(36028797018963981));
i_checkVal('Int64 value', oVal, false, true, false, '36028797018963981');

oVal = ep_sl.Value(int64(36028797018963981));
i_checkVal('Int64 value', oVal, false, true, false, '36028797018963981');

oVal = ep_sl.Value(int64(-9223372036854775808));
i_checkVal('Int64 value', oVal, false, true, false, '-9223372036854775808');

oVal = ep_sl.Value('-9223372036854775808');
i_checkVal('Int64 String', oVal, false, true, false, '-9223372036854775808');

oVal = ep_sl.Value(int64(9223372036854775807));
i_checkVal('Int64 value', oVal, false, true, false, '9223372036854775807');

oVal = ep_sl.Value('9223372036854775807');
i_checkVal('Int64 String', oVal, false, true, false, '9223372036854775807');

oVal = ep_sl.Value(uint64(18446744073709551615));
i_checkVal('UInt64 value', oVal, false, true, false, '18446744073709551615');

oVal = ep_sl.Value('18446744073709551615');
i_checkVal('UInt64 value', oVal, false, true, false, '18446744073709551615');

end



%%
function i_checkVal(sContext, oVal, bIsEmpty, bIsFinite, bIsNan, sStringVal)
MU_ASSERT_TRUE(oVal.isempty() == bIsEmpty, ...
    sprintf('%s: Unexpected isempty() result.', sContext));

MU_ASSERT_TRUE(oVal.isfinite() == bIsFinite, ...
    sprintf('%s: Unexpected isfinite() result.', sContext));

MU_ASSERT_TRUE(oVal.isnan() == bIsNan, ...
    sprintf('%s: Unexpected isnan() result.', sContext));

sFoundString = oVal.toString();
MU_ASSERT_TRUE(strcmp(sStringVal, oVal.toString()), ...
    sprintf('%s: Expected method toString to yield "%s" instead of "%s".', sContext, sStringVal, sFoundString));
end
