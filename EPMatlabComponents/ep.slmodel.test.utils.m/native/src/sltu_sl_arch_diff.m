function varargout = sltu_sl_arch_diff(sExpectedSlArchFile, sTestSlArchFile)
% Asserts that the SL architecture XML file is equal to the expected XML file.
%

%%
sExpectedSlArchFile = ep_core_canonical_path(sExpectedSlArchFile);
sTestSlArchFile = ep_core_canonical_path(sTestSlArchFile);

jExpectedSlArchFile = java.io.File(sExpectedSlArchFile);
jTestSlArchFile = java.io.File(sTestSlArchFile);


jResult = ep.architecture.spec.test.utils.arch.ArchitectureComparison.compareFiles(...
    jExpectedSlArchFile, ...
    jTestSlArchFile);

jDiffList = jResult.asFlatList();
casDiffs = cell(jDiffList.toArray());

if (nargout < 1)
    fprintf('\n\nFound %d differences.\n', numel(casDiffs));
    for i = 1:numel(casDiffs)
        fprintf('  (%03d) %s\n', i, casDiffs{i});
    end
    fprintf('\n');
else
    varargout{1} = casDiffs;
end
end
