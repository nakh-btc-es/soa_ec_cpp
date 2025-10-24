function sltu_create_result_vector(stModel, nLength, sFile)
% Utility function to create an initial result vector as preparation for a simulation run.
%


%%
hRoot = mxx_xmltree('create', 'TestVector');
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));

mxx_xmltree('set_attribute', hRoot, 'name', 'dummy');
mxx_xmltree('set_attribute', hRoot, 'length', sprintf('%d', nLength));
mxx_xmltree('set_attribute', hRoot, 'startStep', '0');

hInputs = mxx_xmltree('add_node', hRoot, 'Inputs');
for i = 1:length(stModel.astInports)
    i_addObject(hInputs, stModel.astInports(i).ifid, stModel.astInports(i).identifier, stModel.astInports(i).signalType);
end

hOutputs = mxx_xmltree('add_node', hRoot, 'Outputs');
for i = 1:length(stModel.astOutports)
    i_addObject(hOutputs, stModel.astOutports(i).ifid, stModel.astOutports(i).identifier, stModel.astOutports(i).signalType);
end
for i = 1:length(stModel.astDisplays)
    i_addObject(hOutputs, stModel.astDisplays(i).ifid,stModel.astDisplays(i).identifier, stModel.astDisplays(i).signalType);
end
for i = 1:length(stModel.astDSWrites)
    i_addObject(hOutputs, stModel.astDSWrites(i).ifid, stModel.astDSWrites(i).identifier, stModel.astDSWrites(i).signalType);
end
mxx_xmltree('save', hRoot, sFile);
end



%%
function hObject = i_addObject(hParentNode, sIfid, sIdentifier, sSignalType)
hObject = mxx_xmltree('add_node', hParentNode, 'Object');
mxx_xmltree('set_attribute', hObject, 'ifid', sIfid);
mxx_xmltree('set_attribute', hObject, 'identifier', sIdentifier);
mxx_xmltree('set_attribute', hObject, 'signalType', sSignalType);
end

