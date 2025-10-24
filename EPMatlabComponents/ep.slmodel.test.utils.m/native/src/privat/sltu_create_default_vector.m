function sltu_create_default_vector(sDefaultVectorProperties, sTestVectorFile, sExtractionModelFile, sHarnessModelIn,...
    sHarnessModelOut)
% Creates a default test case based on the properties given by the defautlVector.csv

if ~exist(sDefaultVectorProperties, 'file')
    error('Default vector properties not found.');
end
if ~exist(sExtractionModelFile, 'file')
    error('Extraction model file not found.');
end

stDefaultVectorProperties = readtable(sDefaultVectorProperties, 'HeaderLines', 0, 'Delimiter', ';');
stModel = sltu_eval_extraction_model(sExtractionModelFile, sHarnessModelIn, sHarnessModelOut);
stValues = sltu_create_input_values(stModel, ...
    stDefaultVectorProperties.nSteps, ...
    stDefaultVectorProperties.dVal,...
    stDefaultVectorProperties.dDiffTime, ...
    stDefaultVectorProperties.dDiffSig);
sltu_create_test_case_vector(stModel, stValues, sTestVectorFile);
end