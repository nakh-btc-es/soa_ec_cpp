function createConstantsXml(oEca)
% EC Use Case: Generates XML-File for the constants
%
% function createConstantsXml(oEca)
%
%   INPUT               DESCRIPTION
%       -                      -
%
%   OUTPUT              DESCRIPTION
%       -                      -
%

%% internal
%
%   AUTHOR(S):
%     Kristof Woll
% $$$COPYRIGHT$$$
%%

if oEca.bDiagMode
    fprintf('\n## Generation of constants XML file ...\n');
end

%% main
if isempty(oEca.sConstantsFile)
    return;
end

astConstants = oEca.astConstants;

hDoc = mxx_xmltree('create', 'Constants');
xOnCleanupClearMappingDoc = onCleanup(@() mxx_xmltree('clear', hDoc));

for i = 1:length(astConstants)
    hConstNode = mxx_xmltree('add_node', hDoc, 'Constant');
    mxx_xmltree('set_attribute', hConstNode, 'name', astConstants(i).sName);
    mxx_xmltree('set_attribute', hConstNode, 'value', num2str(astConstants(i).xValue));
end

mxx_xmltree('save', hDoc, oEca.sConstantsFile);
end


