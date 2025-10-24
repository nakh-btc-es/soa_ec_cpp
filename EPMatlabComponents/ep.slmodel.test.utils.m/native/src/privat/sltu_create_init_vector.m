function sltu_create_init_vector(stParameters, nLength, sInitVector)
% Utility function to create an init vector as preparation for a simulation run.
%

%%
hRoot = mxx_xmltree('create', 'TestVector');
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));

mxx_xmltree('set_attribute', hRoot, 'name', 'dummy');
mxx_xmltree('set_attribute', hRoot, 'length', sprintf('%d', nLength));

hInputs = mxx_xmltree('add_node', hRoot, 'Inputs');
casIfids = fieldnames(stParameters);
for i = 1:length(casIfids)
    sIfid = casIfids{i};
    stParam = stParameters.(sIfid);
    i_addCal(hInputs, stParam);
end

mxx_xmltree('save', hRoot, sInitVector);
end


%%
function i_addCal(hInputs, stParam)
hCal = mxx_xmltree('add_node', hInputs, 'Calibration');

mxx_xmltree('set_attribute', hCal, 'ifid',       stParam.stModelInfo.ifid);
mxx_xmltree('set_attribute', hCal, 'initValue',  stParam.casValues{1});
mxx_xmltree('set_attribute', hCal, 'identifier', stParam.stModelInfo.identifier);
mxx_xmltree('set_attribute', hCal, 'signalType', stParam.stModelInfo.signalType);
end
