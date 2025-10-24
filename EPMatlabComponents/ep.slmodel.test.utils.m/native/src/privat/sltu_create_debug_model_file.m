function sltu_create_debug_model_file(sExtractionModelXml, sDebugModelFile)
% Utility function to create an initial result vector as preparation for debug simulation
%

%%
xDebugModel =  mxx_xmltree('create','DebugModel');

xOutputs = mxx_xmltree('add_node', xDebugModel, 'Outputs');
xDocInit = mxx_xmltree('load', sExtractionModelXml);

xExtractionModel = mxx_xmltree('get_root', xDocInit);
xScopeList = mxx_xmltree('get_nodes', xExtractionModel, 'child::Scope');
sSampleTime = mxx_xmltree('get_attribute', xScopeList(1), 'sampleTime');
mxx_xmltree('set_attribute', xDebugModel, 'sampleTime', sSampleTime);
sScopeName = mxx_xmltree('get_attribute', xScopeList(1), 'name');

xNodeList = mxx_xmltree('get_nodes', xExtractionModel, ...
    ['/ExtractionModel/Scope[@name=''', sScopeName,''']/OutPort//ifName']);
nOutputs = length(xNodeList);
for i = 1:nOutputs
    xNormalizedAccessPath = xNodeList(i);
    
    sIfId = mxx_xmltree('get_attribute', xNormalizedAccessPath, 'ifid');
    sDisplayName = mxx_xmltree('get_attribute', xNormalizedAccessPath, 'displayName');
    
    xOutport = mxx_xmltree('add_node', xOutputs, 'Outport');
    mxx_xmltree('set_attribute', xOutport, 'ifid', sIfId);
    if isempty(sDisplayName)
        sDisplayName = 'n.a.';
    end
    mxx_xmltree('set_attribute', xOutport, 'displayName', sDisplayName);  
end

mxx_xmltree('save', xDebugModel, sDebugModelFile);

mxx_xmltree('clear', xDebugModel);
mxx_xmltree('clear', xDocInit);
end

