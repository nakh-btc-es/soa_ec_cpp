function stResult = sltu_create_debug_vectors(sTestVector, sExtractionModelFile, sDebugModelFile, casVecNames)
% Utility function to create debug vectors (XML and MDF)


%% optional inputs
if (nargin < 3)
    sDebugModelFile = fullfile(pwd, 'debug_root', 'debug_model.xml');
end
if (nargin < 4)
    casVecNames = {'MyTestCase'};
end


%%
stModel = sltu_eval_extraction_model(sExtractionModelFile);
[stValues, nSteps] = i_convert_cvs(sTestVector, stModel);

sDebugRootDir = fileparts(sDebugModelFile);
if ~exist(sDebugRootDir, 'dir')
    mkdir(sDebugRootDir);
end
sltu_create_debug_model_file(sExtractionModelFile, sDebugModelFile);

sVecsRootDir = fullfile(sDebugRootDir, 'vecs');
mkdir(sVecsRootDir);

nVecs = numel(casVecNames);
casDebugVectorFiles = cell(1, nVecs);
for i = 1:nVecs
    sVecName = casVecNames{i};
    
    sVecDir = fullfile(sVecsRootDir, sprintf('V%d', i));
    mkdir(sVecDir);
    
    sDebugVectorFile = fullfile(sVecDir, sprintf('debug_V%d.xml', i));
    sltu_create_debug_vector_file(stValues, sExtractionModelFile, nSteps, sDebugVectorFile, sVecName);
    
    casDebugVectorFiles{i} = sDebugVectorFile;
end

sInputsMDFFile = fullfile(sVecsRootDir, 'mil_i.mdf');
i_create_inputs_mdf(stValues, sInputsMDFFile);

sParamsMDFFile = fullfile(sVecsRootDir, 'mil_p.mdf');
i_create_param_mdf(sDebugVectorFile, sParamsMDFFile);

sOutputsMDFFile = fullfile(sVecsRootDir, 'mil_o.mdf');
i_create_outputs_mdf(stValues, sOutputsMDFFile);

astVecs = repmat(struct( ...
    'sDir',             '', ...
    'sDebugVectorFile', '', ...
    'sInputsMDFFile',   '', ...
    'sParamsMDFFile',   '', ...
    'sOutputsMDFFile',  ''), 1, nVecs);
for i = 1:nVecs
    sVecDir = fileparts(casDebugVectorFiles{i});
    copyfile(fullfile(sVecsRootDir, '*.mdf'), sVecDir);
    
    astVecs(i).sDir             = sVecDir;
    astVecs(i).sDebugVectorFile = casDebugVectorFiles{i};
    astVecs(i).sInputsMDFFile   = fullfile(sVecDir, 'mil_i.mdf');
    astVecs(i).sParamsMDFFile   = fullfile(sVecDir, 'mil_p.mdf');
    astVecs(i).sOutputsMDFFile  = fullfile(sVecDir, 'mil_o.mdf');
    
end
delete(sInputsMDFFile);
delete(sParamsMDFFile);
delete(sOutputsMDFFile);

stResult = struct( ...
    'stValues',        stValues, ...
    'sDebugModelFile', sDebugModelFile, ...
    'astVecs',         astVecs);
end


%%
function [stValues, nSteps] = i_convert_cvs(sTestVector, stModel)
if verLessThan('matlab' , '9.8')
    stTestVector = readtable(sTestVector, 'HeaderLines', 1, 'Delimiter', ';');
else
    stTestVector = readtable(sTestVector, 'HeaderLines', 1, 'Delimiter', ';', 'Format', 'auto');
end


stInputs = struct();
for i = 1:length(stModel.astInports)
    sIfid = stModel.astInports(i).ifid;
    stInputs.(sIfid) = struct('ModelInfo', stModel.astInports(i), 'adValues', {stTestVector.(sIfid)(4:end)});
end

for i = 1:length(stModel.astDSReads)
    sIfid = stModel.astDSReads(i).ifid;
    stInputs.(sIfid) = struct('ModelInfo', stModel.astDSReads(i), 'adValues', {stTestVector.(sIfid)(4:end)});
end

stOutputs = struct();
for i = 1:length(stModel.astOutports)
    sIfid = stModel.astOutports(i).ifid;
    stOutputs.(sIfid) = struct('ModelInfo', stModel.astOutports(i), 'adValues', {stTestVector.(sIfid)(4:end)});
end

for i = 1:length(stModel.astDSWrites)
    sIfid = stModel.astDSWrites(i).ifid;
    stOutputs.(sIfid) = struct('ModelInfo', stModel.astDSWrites(i), 'adValues', {stTestVector.(sIfid)(4:end)});
end

astCals = stModel.astCals;
for i = 1:length(stModel.astCals)
    sIfid = stModel.astCals(i).ifid;
    astCals(i).initValue = stTestVector.(sIfid){4};
end

stValues = struct( ...
    'adTimeValues', {stTestVector.ifid(4:end)}, ...
    'stInputs',     stInputs, ...
    'stOutputs',    stOutputs, ...
    'astCals',      astCals);
nSteps = length(stValues.adTimeValues);
end


%%
function i_create_mdf(stInterfaces, adTimeValues, sFile)
nLengthValues = length(adTimeValues);
if isempty(stInterfaces)
    casIfids = {};
else
    casIfids = fieldnames(stInterfaces);
end
casIndentifier = cell(1, length(casIfids));
casSignalTypes = cell(1, length(casIfids));
for i = 1:length(casIfids)
    casIndentifier{i} = stInterfaces.(casIfids{i}).ModelInfo.identifier;
    casSignalTypes{i} = i_get_mdf_type(stInterfaces.(casIfids{i}).ModelInfo.signalType);
end

hFile = mxx_mdf('create', sFile, casIndentifier, casSignalTypes);
xOnCleanup = onCleanup(@() mxx_mdf('close', hFile));

if ~isempty(casIfids)
    for i = 1:nLengthValues
        casValues = cell(1, length(casIfids));
        for j = 1:length(casIfids)
            casValues{j} = str2double(stInterfaces.(casIfids{j}).adValues(i));
        end
        mxx_mdf('append_values', hFile, casValues);
    end
end
end


%%
function i_create_inputs_mdf(stValues, sInputsMDFFile)
i_create_mdf(stValues.stInputs, stValues.adTimeValues, sInputsMDFFile);
end


%%
function i_create_outputs_mdf(stValues, sOutputsMDFFile)
i_create_mdf(stValues.stOutputs, stValues.adTimeValues, sOutputsMDFFile)
end


%%
function i_create_param_mdf(sDebugVector, sParamsMDFFile)
hVec = mxx_xmltree('load', sDebugVector);
xOnCleanupCloseVectorFile = onCleanup(@() mxx_xmltree('clear', hVec));
astValues = mxx_xmltree('get_attributes', hVec, '/TestVector/Inputs/Calibration', 'identifier', 'initValue', 'signalType');
for i = 1:length(astValues)
    astValues(i).initValue = str2double(astValues(i).initValue);
end
if isempty(astValues)
    hFile = mxx_mdf('create', sParamsMDFFile, {}, {});
    xOnCleanup = onCleanup(@() mxx_mdf('close', hFile));
else
    casMDFTypes = cellfun(@i_get_mdf_type, {astValues(:).signalType}, 'UniformOutput', false);
    hFile = mxx_mdf('create', sParamsMDFFile, {astValues(:).identifier}, casMDFTypes);
    xOnCleanup = onCleanup(@() mxx_mdf('close', hFile));
    mxx_mdf('append_values', hFile, {astValues(:).initValue});
end
end


%%
function sMdfType = i_get_mdf_type(sType)
stInfo = ep_sl_type_info_get(sType);
if stInfo.bIsFxp
    sMdfType = 'double';
else
    sMdfType = stInfo.sBaseType;
end
end