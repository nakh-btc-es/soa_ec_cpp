function sltu_create_test_case_vector(stModel, stValues, sTestVectorFile)
% Creates a test case vector file (csv).

nSteps = length(stValues.adTimeValues);
casTestVector = [{'ifid'}, {'baseType'}, {'identifier'}, {'kind'}, num2cell(stValues.adTimeValues)];
casTestVector = casTestVector';
for i=1:length(stModel.astInports)
    sColumn = [stModel.astInports(i).ifid, stModel.astInports(i).baseType, stModel.astInports(i).identifier, ...
        stModel.astInports(i).kind, num2cell(stValues.stInputs.(stModel.astInports(i).ifid))];
    casTestVector = [casTestVector, sColumn']; %#ok
end

for i=1:length(stModel.astDSReads)
    sColumn = [stModel.astDSReads(i).ifid, stModel.astDSReads(i).baseType, stModel.astDSReads(i).identifier, ...
        stModel.astDSReads(i).kind, num2cell(stValues.stInputs.(stModel.astDSReads(i).ifid))];
    casTestVector = [casTestVector, sColumn']; %#ok
end

for i=1:length(stModel.astCals)
    sColumn = [stModel.astCals(i).ifid, stModel.astCals(i).baseType, stModel.astCals(i).identifier, ...
        stModel.astCals(i).kind, num2cell(repmat(str2double(stModel.astCals(i).initValue), 1, nSteps))];
    casTestVector = [casTestVector, sColumn']; %#ok
end

for i=1:length(stModel.astDisplays)
    sColumn = [stModel.astDisplays(i).ifid, stModel.astDisplays(i).baseType, stModel.astDisplays(i).identifier, ...
        stModel.astDisplays(i).kind, num2cell(repmat('*', 1, nSteps))];
    casTestVector = [casTestVector, sColumn']; %#ok
end

for i=1:length(stModel.astOutports)
    sColumn = [stModel.astOutports(i).ifid, stModel.astOutports(i).baseType, stModel.astOutports(i).identifier, ...
        stModel.astOutports(i).kind, num2cell(repmat('*', 1, nSteps))];
    casTestVector = [casTestVector, sColumn']; %#ok
end

for i=1:length(stModel.astDSWrites)
    sColumn = [stModel.astDSWrites(i).ifid, stModel.astDSWrites(i).baseType, stModel.astDSWrites(i).identifier, ...
        stModel.astDSWrites(i).kind, num2cell(repmat('*', 1, nSteps))];
    casTestVector = [casTestVector, sColumn']; %#ok
end

hFid = fopen(sTestVectorFile,'w');
oOnCleanupCloseFHandle = onCleanup(@() fclose(hFid));

fprintf(hFid, ['scope;', stModel.sPath , '\n']);

for i = 1:size(casTestVector)
    casLine = casTestVector(i,:);
    sLine = [];
    for j=1:length(casLine)
        if ischar(casLine{j})
            sLine = [sLine, casLine{j}]; %#ok
        else
            sLine = [sLine, num2str(casLine{j})]; %#ok
        end
        if (j < length(casLine))
            sLine = [sLine, ';']; %#ok
        end
    end
    fprintf(hFid, [sLine,  '\n']);
end
end