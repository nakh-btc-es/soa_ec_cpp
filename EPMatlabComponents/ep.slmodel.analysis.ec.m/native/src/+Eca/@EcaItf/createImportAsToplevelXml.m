function createImportAsToplevelXml(oEca, bForceToplevel)
% If this xml is generated, the EC Simulink architecture is imported as toplevel architecture
% to enable the simulation on the actual model file.
%
if nargin < 2
    bForceToplevel = false;
end

bReturn = false;
if ~strcmp(getenv('EC_IMPORT_AS_TOPLEVEL'), 'true')
    bReturn = true;
end
if bForceToplevel
    bReturn = false;
end

sXmlFile = fullfile(oEca.sTempDir, 'importAsToplevel.xml');
if (bReturn || isfile(sXmlFile))
    return;
end

hDocNode = mxx_xmltree('create', 'importAsToplevel');
oOnCleanupClear = onCleanup(@() mxx_xmltree('clear', hDocNode));
mxx_xmltree('save', hDocNode, sXmlFile);
end