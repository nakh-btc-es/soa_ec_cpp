function ep_simenv_cals2ws_init(sVectorMetaInfoFile, sMdfFile)
% Transform a vector file into WS variables.
%
% function ep_simenv_cals2ws_init(sVectorMetaInfoFile, sMdfFile)
%
%   INPUT                       DESCRIPTION
%   sVectorMetaInfoFile          (string)    XML file containing parameter identifiers, Ifids, ...
%   sMdfFile                     (string)    MDF file containing parameter identifiers and values
%
%   OUTPUT                      DESCRIPTION
%   ---
%

%%
hVecDoc = mxx_xmltree('load', sVectorMetaInfoFile);
oOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hVecDoc));

hVecRoot = mxx_xmltree('get_root', hVecDoc);

ahCalNodes = mxx_xmltree('get_nodes', hVecRoot, '/TestVector/Inputs/Calibration');
if isempty(ahCalNodes)
    return;
end

if (nargin < 2)
    i_legacyCreateValuesInBaseWorkspace(ahCalNodes);
else
    astSignals = ep_sim_mdf2struct(sMdfFile);
    mIdToValue = i_getValueMap(astSignals);
    i_createValuesInBaseWorkspace(ahCalNodes, mIdToValue);
end
end


%%
function i_legacyCreateValuesInBaseWorkspace(ahCalNodes)
nInputs = length(ahCalNodes);
for iInput = 1:nInputs
    hInput = ahCalNodes(iInput);
    
    sIfid  = mxx_xmltree('get_attribute', hInput, 'ifid');
    sValue = mxx_xmltree('get_attribute', hInput, 'initValue');
    
    if ~isempty(sValue)
        dValue = str2double(sValue);
        anVec(1, 1) = 0;
        anVec(1, 2) = dValue;
        
        % create input variable in base workspace
        sInputId = ['i_', sIfid];
        assignin('base', sInputId, anVec );
    end
end 
end


%%
function i_createValuesInBaseWorkspace(ahCalNodes, mIdToValue)
nInputs = length(ahCalNodes);
for iInput = 1:nInputs
    hInput = ahCalNodes(iInput);
    
    sID = mxx_xmltree('get_attribute', hInput, 'identifier');
    if mIdToValue.isKey(sID)
        xValue = mIdToValue(sID);
    else
        % TODO: should NEVER happen to be here in the else-case, but as a temporary fallback maybe useful
        xValue = str2double(mxx_xmltree('get_attribute', hInput, 'initValue'));

    end
    sIfid = mxx_xmltree('get_attribute', hInput, 'ifid');
    
    if ~isempty(xValue)
        axTimeValue = [0, xValue];
        
        % create input variable in base workspace
        sParamValVariable = ['i_', sIfid];
        assignin('base', sParamValVariable, axTimeValue);
    end
end 
end


%%
function mIdToValue = i_getValueMap(astSignals)
mIdToValue = containers.Map('KeyType', 'char', 'ValueType', 'any');
for i = 1:numel(astSignals)
    xValue = astSignals(i).xValue;
    if ~isscalar(xValue)
        xValue = xValue(1); % only first value relevant for parameters during simulation
    end
    mIdToValue(astSignals(i).sID) = xValue;
end
end
