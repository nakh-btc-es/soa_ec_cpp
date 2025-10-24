function sltu_create_debug_vector_file(stValues, sExtractionModelXml, nSteps, sDebugVectorFile, sVecName)
% Utility function to create a debug vector file

%% optional
if (nargin < 5)
    sVecName = 'dummy';
end


%%
xInitVector =  mxx_xmltree('create', 'TestVector');
xCalibrations = mxx_xmltree('add_node', xInitVector, 'Inputs');

mxx_xmltree('set_attribute', xInitVector, 'length', num2str(nSteps));
mxx_xmltree('set_attribute', xInitVector, 'name', sVecName);

xDocInit = mxx_xmltree('load', sExtractionModelXml);
xExtractionModel = mxx_xmltree('get_root', xDocInit);
xScopeList = mxx_xmltree('get_nodes',xExtractionModel, 'child::Scope');
xScope = xScopeList(1);

sSampleTime = mxx_xmltree('get_attribute', xScope, 'sampleTime');
mxx_xmltree('set_attribute', xInitVector, 'sampleTime', sSampleTime);

xNodeList = mxx_xmltree('get_nodes', xScope, './Calibration//ifName');
nCals = length(xNodeList);
for iCal = 1:nCals
    xNormalizedAccessPath = xNodeList(iCal);
    
    xCalibration = mxx_xmltree('add_node', xCalibrations, 'Calibration');
    
    sIfId = mxx_xmltree('get_attribute', xNormalizedAccessPath, 'ifid');    
    mxx_xmltree('set_attribute', xCalibration, 'ifid', sIfId);
    
    sIdentifier = mxx_xmltree('get_attribute', xNormalizedAccessPath, 'identifier');
    mxx_xmltree('set_attribute', xCalibration, 'identifier', sIdentifier);
        
    sSignalType = mxx_xmltree('get_attribute', mxx_xmltree('get_nodes', xNormalizedAccessPath, '..'), 'signalType'); 
    mxx_xmltree('set_attribute', xCalibration,'signalType', sSignalType);
    
    sInitValue = stValues.astCals(iCal).initValue;
    if isempty(sInitValue)
        sInitValue = '0';
    end
    mxx_xmltree('set_attribute', xCalibration, 'initValue', sInitValue);    
end

mxx_xmltree('save',  xInitVector, sDebugVectorFile);
mxx_xmltree('clear', xInitVector);
mxx_xmltree('clear', xDocInit);
end