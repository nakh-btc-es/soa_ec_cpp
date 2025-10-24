function ut_value_compare_checks
% checking functionality of Value class
%



%% empty
oValA = ep_sl.Value('');
oValB = ep_sl.Value('');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == 0, 'Unexpected compare for empty Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 0, 'Unexpected compare for empty Values.');

oValA = ep_sl.Value([]);
oValB = ep_sl.Value('');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == 0, 'Unexpected compare for empty Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 0, 'Unexpected compare for empty Values.');

oValA = ep_sl.Value([]);
oValB = ep_sl.Value('NaN');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == 0, 'Unexpected compare for empty Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 0, 'Unexpected compare for empty Values.');


%% bool
oValA = ep_sl.Value('true');
oValB = ep_sl.Value(true);
MU_ASSERT_TRUE(oValA.compareTo(oValB) == 0, 'Unexpected compare for bool Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 0, 'Unexpected compare for bool Values.');

oValA = ep_sl.Value('false');
oValB = ep_sl.Value(true);
MU_ASSERT_TRUE(oValA.compareTo(oValB) == -1, 'Unexpected compare for bool Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 1,  'Unexpected compare for bool Values.');

oValA = ep_sl.Value(true);
oValB = ep_sl.Value('false');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == 1,  'Unexpected compare for bool Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == -1, 'Unexpected compare for bool Values.');


%% 64bit
oValA = ep_sl.Value('36028797018963981');
oValB = ep_sl.Value('36028797018963982');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == -1, 'Unexpected compare for 64bit Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 1,  'Unexpected compare for 64bit Values.');

oValA = ep_sl.Value(int64(36028797018963981));
oValB = ep_sl.Value('36028797018963982');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == -1, 'Unexpected compare for 64bit Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 1,  'Unexpected compare for 64bit Values.');

oValA = ep_sl.Value('36028797018963981');
oValB = ep_sl.Value(int64(36028797018963982));
MU_ASSERT_TRUE(oValA.compareTo(oValB) == -1, 'Unexpected compare for 64bit Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 1,  'Unexpected compare for 64bit Values.');

oValA = ep_sl.Value(uint64(18446744073709551614));
oValB = ep_sl.Value(uint64(18446744073709551615));
MU_ASSERT_TRUE(oValA.compareTo(oValB) == -1, 'Unexpected compare for 64bit Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 1,  'Unexpected compare for 64bit Values.');

%% misc
oValA = ep_sl.Value('36028797018963981.005');
oValB = ep_sl.Value('36028797018963981.01');
MU_ASSERT_TRUE(oValA.compareTo(oValB) == -1, 'Unexpected compare for 64bit Values.');
MU_ASSERT_TRUE(oValB.compareTo(oValA) == 1,  'Unexpected compare for 64bit Values.');
end

