function varargout = sltu_tl_arch_diff(sExpectedTlArchFile, sTestTlArchFile)
% Asserts that the TL architecture XML file is equal to the expected XML file.
%

%%
sExpectedTlArchFile = ep_core_canonical_path(sExpectedTlArchFile);
sTestTlArchFile = ep_core_canonical_path(sTestTlArchFile);

jExpectedSlArchFile = java.io.File(sExpectedTlArchFile);
jTestSlArchFile = java.io.File(sTestTlArchFile);


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
