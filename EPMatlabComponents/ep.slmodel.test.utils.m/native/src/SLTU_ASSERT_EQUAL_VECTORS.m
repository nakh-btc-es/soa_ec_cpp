function SLTU_ASSERT_EQUAL_VECTORS(sTestVector, sSimulatedVector, bIgnoreLocals, bLocalTypeDouble)
% Compares the outputs of the test vector and the simulated vector

if (nargin < 3)
    bIgnoreLocals = false;
end
if (nargin < 4)
    bLocalTypeDouble = false;
end


% Get expected interface
if ep_core_version_compare('ML9.8') >= 0
    stExpectedValues = readtable(sTestVector, 'HeaderLines', 1, 'Delimiter', ';', 'Format', 'auto');
else
    stExpectedValues = readtable(sTestVector, 'HeaderLines', 1, 'Delimiter', ';');
end
casFieldNames = stExpectedValues.Properties.VariableNames;
sInputsMDF  = fullfile(fileparts(sSimulatedVector), 'v_i.mdf');
sParamsMDF  = fullfile(fileparts(sSimulatedVector), 'v_p.mdf');
sOutputsMDF = fullfile(fileparts(sSimulatedVector), 'v_o.mdf');
sLocalsMDF  = fullfile(fileparts(sSimulatedVector), 'v_l.mdf');

% Check existence of MDF files
MU_ASSERT_TRUE(exist(sInputsMDF,  'file'), 'Input MDF file is missing');
MU_ASSERT_TRUE(exist(sParamsMDF,  'file'), 'Parameter MDF file is missing');
MU_ASSERT_TRUE(exist(sOutputsMDF, 'file'), 'Output MDF file is missing');
if ~bIgnoreLocals
    MU_ASSERT_TRUE(exist(sLocalsMDF,  'file'), 'Local MDF file is missing');
end

% Get interface and values for inputs
[casInputsSigNames, casInputsTypes, caxInputsValues] = i_getValuesFromMdf(sInputsMDF);

% Get interface and values for inputs
[casParamsSigNames, casParamsTypes, caxParamsValues] = i_getValuesFromMdf(sParamsMDF);

% Get interface and values for outputs
[casOutputsSigNames, casOutputsTypes, caxOutputsValues] = i_getValuesFromMdf(sOutputsMDF);

if ~bIgnoreLocals
    % Get interface and values for locals
    [casLocalsSigNames, casLocalsTypes, caxLocalsValues] = i_getValuesFromMdf(sLocalsMDF);
end

bOutputsAvailable = false;
bAnyOutputCompared = false;
for i = 1:length(casFieldNames)
    sField = casFieldNames{i};
    
    sKind = stExpectedValues.(sField){3};
    sExpectedType = stExpectedValues.(sField){1};
    sExpectedId = stExpectedValues.(sField){2};
    
    sKind = lower(sKind);
    if any(strcmp(sKind, {'input', 'parameter', 'output', 'local'}))
        
        if bIgnoreLocals && strcmp(sKind, 'local')
            continue;
        end
        
        if bLocalTypeDouble && strcmp(sKind, 'local')
            sExpectedType = 'double';
        end
        
        casExpectedValues = i_getExpectedValues(stExpectedValues, sField);
        nLastStep = numel(casExpectedValues);
        
        switch sKind
            case 'input'
                casSigNames = casInputsSigNames;
                casTypes    = casInputsTypes;
                caxValues   = caxInputsValues;
                
            case 'parameter'
                casSigNames = casParamsSigNames;
                casTypes    = casParamsTypes;
                caxValues   = caxParamsValues;
                nLastStep = 1; % for params just check the first step
                
            case 'output'
                casSigNames = casOutputsSigNames;
                casTypes    = casOutputsTypes;
                caxValues   = caxOutputsValues;
                bOutputsAvailable = true;
                
            case 'local'
                casSigNames = casLocalsSigNames;
                casTypes    = casLocalsTypes;
                caxValues   = caxLocalsValues;
                bOutputsAvailable = true;
                
            otherwise
                error('UT:ERROR', 'Unknown kind "%s".', sKind);
        end
        [caxActSimulatedValues, sActType] = ...
            i_getSimulatedValuesForSig(sExpectedId, casSigNames, casTypes, caxValues);
        
        nSimLength = numel(caxActSimulatedValues);
        if (nSimLength < nLastStep)
            for k = (nSimLength + 1):nLastStep
                caxActSimulatedValues{k} = [];
            end
            if isempty(sActType)
                sActType = sExpectedType;
                if strcmp('boolean', sActType)
                    sActType = 'int8';
                end
            end
        end
        
        i_checkType(sExpectedId, sExpectedType, sActType);
        
        bValueChecked = false;
        for j = 1:nLastStep
            sExpValue = casExpectedValues{j};
            xValue    = caxActSimulatedValues{j};
            
            switch sKind
                case 'input'
                    i_checkValue(j, sExpectedId, sExpValue, xValue);
                    
                case 'parameter'
                    MU_ASSERT_EQUAL(1, numel(caxActSimulatedValues));
                    i_checkValue(j, sExpectedId, sExpValue, xValue);
                    
                case 'output'
                    bValueChecked = i_checkValue(j, sExpectedId, sExpValue, xValue);
                    
                case 'local'
                    bValueChecked = i_checkValue(j, sExpectedId, sExpValue, xValue);
                    
                otherwise
                    error('UT:ERROR', 'Unknown kind "%s".', sKind);
            end
            bAnyOutputCompared = bAnyOutputCompared || bValueChecked;
        end
    end
end

if bOutputsAvailable
    if ~bAnyOutputCompared
        MU_FAIL('Not any of the expected output values has been compared during check.');
    end
else
    MU_MESSAGE('WARNING: Test is too weak! Expected output values have not been defined.')
end
end


%%
function bValueChecked = i_checkValue(iStepNumber, sIdentifier, sExpValue, xActValue)
bValueChecked = false;
if strcmp(sExpValue, '*')
    return;
end
bValueChecked = true;

if isempty(sExpValue)
    MU_ASSERT_TRUE(isempty(xActValue),...
        sprintf('Unexpected simulation result for %s in step %d. Expected value is empty. Actual value is %s', ...
        sIdentifier, iStepNumber, num2str(xActValue)));
else
    if isempty(xActValue)
        MU_FAIL(sprintf('Unexpected simulation result for %s in step %d. Expected value is %s. Actual value is empty.', ...
            sIdentifier, iStepNumber, sExpValue));
    else
        i_MU_ASSERT_EQUAL_EPS(str2double(sExpValue), double(xActValue), 0.0000001, ...
            sprintf('Unexpected simulation result for %s in step %d. Expected value is %s. Actual value is %s', ...
            sIdentifier, iStepNumber, sExpValue, num2str(xActValue)));
    end
end
end


%%
function i_MU_ASSERT_EQUAL_EPS(dExpValue, dActValue, dEpsilon, sMsg)
if (abs(dExpValue - dActValue) > dEpsilon)
    MU_FAIL(sMsg);
end
end


%%
function stType = i_getTypeAttributes(sType)
bIsSigned = false;
dLSB = 1.0;
dOffset = 0.0;
bIsFloat = false;

if strcmp('boolean', sType)
    nWordLength = 1;
    
elseif strncmp('int', sType, 3)
    nWordLength = str2double(sType(4:end));
    bIsSigned = true;
    
elseif strncmp('uint', sType, 3)
    nWordLength = str2double(sType(5:end));
    
elseif strncmp('fixdt', sType, 5)
    oType = evalin('base', sType);
    nWordLength = oType.WordLength;
    bIsSigned = strcmp('Signed', oType.Signedness);
    dLSB = oType.Slope;
    dOffset = oType.Bias;
    
elseif strcmp('double', sType)
    bIsFloat = true;
    nWordLength = 64;
    bIsSigned = true;
    
elseif strcmp('single', sType)
    bIsFloat = true;
    nWordLength = 32;
    bIsSigned = true;
    
else
    MU_FAIL_FATAL(['Unexpected type ', sType, '.']);
end

stType = struct( ...
    'Float', bIsFloat, ...
    'WordLength', nWordLength, ...
    'Signed', bIsSigned, ...
    'LSB', dLSB, ...
    'Offset', dOffset);
end


%%
function bResult = i_typeContainsType(oType1, oType2)
if ~oType1.Float && ~oType2.Float
    % for fxp types with bits different from 8,16,32,64
    % the word length of the actual type is rounded up
    bResult = ...
        oType1.LSB == oType2.LSB && ...
        oType1.Offset == oType2.Offset && ...
        ( ...
        ... % 16 bit signed int contains 8 bit signed int
        (oType1.WordLength >= oType2.WordLength && oType1.Signed == oType2.Signed) || ...
        ... % 16 bit signed int contains 8 bit unsigned int
        (oType1.WordLength > oType2.WordLength && oType1.Signed && ~oType2.Signed) ...
        );
else
    bResult = isequal(oType1, oType2);
end
end


%%
function i_checkType(sFieldName, sExpectedType, sActualType)
oExpectedType = i_getTypeAttributes(sExpectedType);
oActualType = i_getTypeAttributes(sActualType);

if ~i_typeContainsType(oActualType, oExpectedType)
    MU_FAIL(sprintf('Unexpected type information for %s. Expected type is %s. Actual type is %s', ...
        sFieldName, sExpectedType, sActualType))
end
end


%%
function [caxSimulatedValues, sType, bFound] = i_getSimulatedValuesForSig(sSigName, casMDFSigNames, casTypes, caxMDFValues)
iIndex = find(strcmp(sSigName, casMDFSigNames));
if isempty(iIndex)
    % sometimes the signame inside the CSV will contain \n, \t, etc --> evaluate them and compare with MDF identifiers
    iIndex = find(strcmp(sprintf(sSigName), casMDFSigNames));
    if isempty(iIndex)
        % as a last fallback: replace all whitespace chars \n, \t, etc. with a simple whitespace for the MDF identifiers
        casMDFSigNames = regexprep(casMDFSigNames, '\s', ' '); 
        iIndex = find(strcmp(sSigName, casMDFSigNames));
    end
end

if isempty(iIndex)
    caxSimulatedValues = {};
    sType = '';
    bFound = false;
else
    caxSimulatedValues = caxMDFValues(:, iIndex);
    sType = casTypes{iIndex};
    bFound = true;
end
end


%%
function casExpectedValues = i_getExpectedValues(stExpectedValues, sFieldName)
casExpectedValues = stExpectedValues.(sFieldName);
casExpectedValues = casExpectedValues(4:end);
end


%%
function [casSigNames, casTypes, caxValues] = i_getValuesFromMdf(sMDFFile)
casSigNames = {};
casTypes    = {};
caxValues   = {};
if exist(sMDFFile, 'file') ~= 0
    hMDF = mxx_mdf('open', sMDFFile);
    xOnCleanup = onCleanup(@() mxx_mdf('close', hMDF));
    
    casSigNames = mxx_mdf('get_signal_names', hMDF);
    casTypes    = mxx_mdf('get_signal_types', hMDF);
    caxValues   = mxx_mdf('get_values',       hMDF);
end
end