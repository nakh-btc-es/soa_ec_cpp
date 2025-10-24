function stDataMdf = sltu_mdf_to_struct(sMdfFile)
hMdf = mxx_mdf('open', sMdfFile);
xOnCleanupCloseMdf = onCleanup(@() mxx_mdf('close', hMdf));

stDataMdf = struct( ...
    'casIds',    {mxx_mdf('get_signal_names', hMdf)'}, ...
    'casTypes',  {mxx_mdf('get_signal_types', hMdf)'}, ...
    'caxValues', {mxx_mdf('get_values',       hMdf)});
end

