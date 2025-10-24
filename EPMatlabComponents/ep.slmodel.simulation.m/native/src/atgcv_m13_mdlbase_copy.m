function atgcv_m13_mdlbase_copy(hSrcMdl, hDestMdl)
% Copying the model workspace content from source model into destination model.
%


%%
oDestMdlWs = get_param(hDestMdl, 'modelworkspace');
oDestMdlWs.DataSource = 'Model File';

% Note: all kind of DataSource is copied to the MDL-File
aoSrcMdlWs = get_param(hSrcMdl, 'modelworkspace');
for j = 1:numel(aoSrcMdlWs)
    astData = aoSrcMdlWs(j).data;

    for i = 1:numel(astData)
        stData = astData(i);
        oDestMdlWs.assignin(stData.Name, stData.Value);
    end
end
end
