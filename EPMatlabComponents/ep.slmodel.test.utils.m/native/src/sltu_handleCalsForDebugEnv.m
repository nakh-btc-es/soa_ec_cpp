function sltu_handleCalsForDebugEnv(stValues, sInitFile)
%making sure that the extracted model compiles when preparing the debug env
for i=1:numel(stValues.astCals)
    assignin('base', ['i_', stValues.astCals(i).ifid], [0 str2double(stValues.astCals(i).initValue)]);
end
assignin('base', 'btc_vector_length', length(stValues.adTimeValues));


sPath= fullfile(fileparts(sInitFile), 'mdebug_vector.mat');
evalin('base', sprintf('save(''%s'')', sPath));
movefile('mdebug_vector.mat', fullfile(fileparts(sInitFile), 'mdebug_vector'))
sContent = fileread(sInitFile);
sContent = [sprintf('load(''%s'');', sPath), char(10), sContent];
hFid = fopen(sInitFile, 'w');
if hFid == -1, error('Cannot open file %s', sInitFile); end
fwrite(hFid, sContent, 'char');
fclose(hFid);
end