function ut_mex_mdf_locals_add()

astLogData = [];
sTestPath = ep_core_canonical_path(fullfile(ut_testdata_dir_get(), 'mex', 'mdflogdata1'));
sMatFile = fullfile(sTestPath, 'data.mat');
load(sMatFile, 'astLogData', 'nVecLength');

sMdfFile = 'my.mdf';
if exist(sMdfFile, 'file'), delete(sMdfFile); end

hFile = mxx_mdf('create', sMdfFile, {astLogData(:).sId}, {astLogData(:).sType});
mxx_mdf('append_logdata', hFile, astLogData, nVecLength);
mxx_mdf('close', hFile);

hFile = mxx_mdf('open', sMdfFile);
canValues = mxx_mdf('get_values', hFile);
mxx_mdf('close', hFile);

for i=1:17
    MU_ASSERT_TRUE_FATAL(~isempty(canValues{i, 9}), 'Empty cells are not expected when recording locals to MDF');
end

end