function ut_helper_hook_mock(sMockFile, sObserverFile, casLinesBeforeSave, casLinesAfterSave)
% Helper for creating mock hook functions.

%%
if (nargin < 3)
    casLinesBeforeSave = {};
end
if (nargin < 4)
    casLinesAfterSave = {};
end

[sHookDir, sHookName] = fileparts(sMockFile);
if ~exist(sHookDir, 'dir')
    mdkir(sHookDir);
end

hFid = fopen(sMockFile, 'w');
oOnCleanupClose = onCleanup(@() fclose(hFid));

fprintf(hFid, 'function stSettings = %s(stSettings, stAdditionalInfo)\n', sHookName);
fprintf(hFid, 'persistent nCalls;\n');
fprintf(hFid, '[p, f, e] = fileparts(''%s'');\n', sObserverFile);
fprintf(hFid, 'if isempty (nCalls)\n');
fprintf(hFid, '    nCalls = 1;\n');
fprintf(hFid, '    sSaveFile = fullfile(p, [f, e]);\n');
fprintf(hFid, 'else\n');
fprintf(hFid, '    nCalls = nCalls + 1;\n');
fprintf(hFid, '    sSaveFile = fullfile(p, [f, num2str(nCalls), e]);\n');
fprintf(hFid, 'end\n');
for i = 1:numel(casLinesBeforeSave)
    fprintf(hFid, '%s\n', casLinesBeforeSave{i});
end
fprintf(hFid, 'save(sSaveFile);\n');
for i = 1:numel(casLinesAfterSave)
    fprintf(hFid, '%s\n', casLinesAfterSave{i});
end
fprintf(hFid, 'end\n');
end