function sltu_prepare_simulation_vectors(sTestVector, sInitVector, sResultVector, sExtractionModelFile,...
    sParamsMDFFile, sInputsMDFFile, sHarnessModelIn, sHarnessModeOut)
% Utility function to prepare vectors for simulation.

stModel = sltu_eval_extraction_model(sExtractionModelFile, sHarnessModelIn, sHarnessModeOut);

[stValues, nSteps] = i_convertCvs(sTestVector, stModel);

sltu_create_init_vector(stValues.stParams, nSteps, sInitVector);
sltu_create_result_vector(stModel, nSteps, sResultVector);

i_createSignalMdf(stValues.stInputs, sInputsMDFFile);
i_createSignalMdf(stValues.stParams, sParamsMDFFile, 1)
end


%%
function [stValues, nSteps] = i_convertCvs(sTestVector, stModel)
if verLessThan('matlab' , '9.8')
    stTestVector = readtable(sTestVector, 'HeaderLines', 1, 'Delimiter', ';');
else
    stTestVector = readtable(sTestVector, 'HeaderLines', 1, 'Delimiter', ';', 'Format', 'auto');
end

stInputs = struct();
for i = 1:length(stModel.astInports)
    sIfid = stModel.astInports(i).ifid;
    stInputs.(sIfid) = struct( ...
        'stModelInfo', stModel.astInports(i), ...
        'casValues',   {stTestVector.(sIfid)(4:end)});
end

for i = 1:length(stModel.astDSReads)
    sIfid = stModel.astDSReads(i).ifid;
    stInputs.(sIfid) = struct( ...
        'stModelInfo', stModel.astDSReads(i), ...
        'casValues',   {stTestVector.(sIfid)(4:end)});
end

stParams = struct();
for i = 1:length(stModel.astCals)
    sIfid = stModel.astCals(i).ifid;
    stParams.(sIfid) = struct( ...
        'stModelInfo', stModel.astCals(i), ...
        'casValues',   {stTestVector.(sIfid)(4:end)});
end

stValues = struct( ...
    'casTimeValues', {stTestVector.ifid(4:end)}, ...
    'stInputs',      stInputs, ...
    'stParams',      stParams);
nSteps = length(stValues.casTimeValues);
end


%%
function i_createSignalMdf(stSignals, sMDFFile, nMaxSteps)
casIfids = fieldnames(stSignals);
if isempty(casIfids)
    hFile = i_createMdfFile(sMDFFile, {}, {});
    mxx_mdf('close', hFile);
    return;
end

nSigs = numel(casIfids);
casIdentifiers = cell(1, nSigs);
casSignalTypes = cell(1, nSigs);
for i = 1:nSigs
    casIdentifiers{i} = stSignals.(casIfids{i}).stModelInfo.identifier;
    casSignalTypes{i} = i_getMdfType(stSignals.(casIfids{i}).stModelInfo.signalType, false);    
end

hFile = i_createMdfFile(sMDFFile, casIdentifiers, casSignalTypes);
xOnCleanup = onCleanup(@() mxx_mdf('close', hFile));

nSteps = numel(stSignals.(casIfids{1}).casValues); % assuming that each signal has the same number of values
if (nargin > 2)
    nSteps = min(nSteps, nMaxSteps);
end
for iStepIdx = 1:nSteps    
    
    caxValues = cell(1, nSigs);
    for iSigIdx = 1:nSigs
        caxValues{iSigIdx} = i_getMdfValue(stSignals.(casIfids{iSigIdx}).casValues{iStepIdx}, casSignalTypes{iSigIdx});
    end
    
    mxx_mdf('append_values', hFile, caxValues);
end
end


%%
function xMdfValue = i_getMdfValue(sValue, sMdfType)
if strncmp(sMdfType, 'fixdt', 5)
    dVal = eval(sprintf('double(%s)', sValue)); % TODO: problem here for FXP values that cannot be tranformed into double
    oFxpType = eval(sMdfType);
    oFxpVal = embedded.fi(dVal, oFxpType);
    xMdfValue = oFxpVal.int;
else
    xMdfValue = eval(sprintf('%s(%s)', sMdfType, sValue));
end
end


%%
function hMdfFile = i_createMdfFile(sFileName, casIdentifiers, casTypes)
sMDFDialect = 'EP2.9';
hMdfFile = mxx_mdf('create', sFileName, casIdentifiers, casTypes, '', '', '', sMDFDialect);
end


%%
function sMdfType = i_getMdfType(sType, bTransformFxpToDouble)
stInfo = ep_sl_type_info_get(sType);
if stInfo.bIsFxp
    if bTransformFxpToDouble
        sMdfType = 'double';
    else
        sMdfType = stInfo.sEvalType;
    end
else
    sMdfType = stInfo.sBaseType;
end
end
