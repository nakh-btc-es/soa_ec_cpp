function ut_modelana_consistency_check(~, sModelAna)
% checking consistency of ModelAnalysis.xml
%
%
%   PARAMETER(S)    DESCRIPTION
%
%   OUTPUT
%

%%
% AUTHOR(S):
%   Alexander.Hornstein@btc-es.de
% $$$COPYRIGHT$$$
%
%   $Revision: 220330 $ 
%   Last modified: $Date: 2017-05-05 17:04:59 +0200 (Fr, 05 Mai 2017) $ 
%   $Author: frederikb $


%% validity
if ~i_isValidXML(sModelAna)
    return;
end

%% consistency
hDoc = mxx_xmltree('load', sModelAna);
xOnCleanupClearDoc = onCleanup(@() mxx_xmltree('clear', hDoc));
try
    % Interface
    i_checkInportConsistency(hDoc);
    i_checkCalibrationConsistency(hDoc);
    
    i_checkOutportConsistency(hDoc);
    i_checkDisplayConsistency(hDoc);
    
    i_checkSignalConsistency(hDoc);
    
    i_checkParameterConsistency(hDoc);
    
catch oEx
    MU_FAIL(sprintf('Unexpected exception.\n%s', oEx.message));
end
end


%%
function i_checkSignalConsistency(hDoc)
ahSigInterfaces = mxx_xmltree('get_nodes', hDoc, ...
    '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/*/*[self::ma:Port or self::ma:Display]');
for i = 1:length(ahSigInterfaces)
    i_checkSignalVariableConsistency(ahSigInterfaces(i));
end
end


%%
% hParentOfVar --> ma:Port, ma:Display
function i_checkSignalVariableConsistency(hParentOfVar)
xSigGroups = containers.Map;
astSigs = mxx_xmltree('get_attributes', hParentOfVar, './ma:Variable/ma:ifName[@signalDim]', ...
    'ifid', 'signalDim', 'signalName', 'index1', 'index2');
for i = 1:length(astSigs)
    stSig = astSigs(i);
    if isempty(stSig.signalName)
        stSig.signalName = '';
    end
    
    if xSigGroups.isKey(stSig.signalName)
        xSigGroups(stSig.signalName) = [xSigGroups(stSig.signalName), stSig];
    else
        xSigGroups(stSig.signalName) = stSig;
    end
end

casSignalNames = xSigGroups.keys;
for i = 1:length(casSignalNames)
    sSignalName = casSignalNames{i};
    
    astGroupSigs = xSigGroups(sSignalName);
    i_checkSignalGroupConsistency(astGroupSigs);
end
end


%%
function i_checkSignalGroupConsistency(astSigs)
% assert same dimension for signal group
casDims = {astSigs(:).signalDim};
MU_ASSERT_TRUE(length(unique(casDims)) == 1, ...
    sprintf('Signals in Group "%s" have not the same signal dimension.', i_getSigGroupID(astSigs)));

% assert the number of signals is consistent to signal dimension
aiDim = eval(casDims{1});
nExpectedSigs = prod(aiDim(2:end));
nFoundSigs = length(astSigs);
MU_ASSERT_TRUE(nExpectedSigs == nFoundSigs, ...
    sprintf('There should be %d signals in Group "%s" instead of %d.', ...
    nExpectedSigs, i_getSigGroupID(astSigs), nFoundSigs));
end


%%
function sGroupID = i_getSigGroupID(astSigs)
casIfids = {astSigs(:).ifid};
sGroupID = sprintf('%s ', casIfids{:});
sGroupID(end) = [];
end


%%
function bIsValid = i_isValidXML(sModelAna)
bIsValid = false;

% existence
if ~exist(sModelAna, 'file')
    MU_FAIL(sprintf('ModelAna file "%s" not found.', sModelAna));
    return;
end

% XML validity
sMaDtdFile = ut_m01_get_ma_dtd();
[nErr, sErr] = atgcv_m_xmllint(0, sMaDtdFile, sModelAna);
MU_ASSERT_TRUE(nErr == 0, sprintf('Invalid ModelAnalysis XML output:\n%s', sErr));

bIsValid = (nErr == 0);
end


%%
function i_checkParameterConsistency(hDoc)
astParams = mxx_xmltree('get_attributes', hDoc, '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/ma:Parameter', ...
    'paramNr', ...
    'expression', ...
    'declaration', ...
    'module');

for i = 1:length(astParams)
    stParam = astParams(i);
    
    i_checkParamDeclaredOrInModule(stParam);
end  
end


%%
% RULE: Parameter needs to have a declaration or be declared inside a module
%       --> either attribute needs to be there
function i_checkParamDeclaredOrInModule(stParam)
if (isempty(stParam.declaration) && isempty(stParam.module))
    FAIL(sprintf('Found parameter %s[%s] without declaration and module.', stRes.expression, stRes.paramNr));
end
end


%%
function i_checkInportConsistency(hDoc)
astIf = mxx_xmltree('get_attributes', hDoc, ...
    '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/ma:Input/ma:Port/*/ma:ifName', ...
    'ifid', ...
    'signalDim', ...
    'index1', ...
    'index2');
for i = 1:length(astIf)
    stIf = astIf(i);
    
    i_checkMatrixIndex(stIf);
end
end


%%
function i_checkCalibrationConsistency(~)
% nothing yet
end


%%
function i_checkOutportConsistency(hDoc)
astIf = mxx_xmltree('get_attributes', hDoc, ...
    '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/ma:Output/ma:Port/*/ma:ifName', ...
    'ifid', ...
    'signalDim', ...
    'index1', ...
    'index2');
for i = 1:length(astIf)
    stIf = astIf(i);
    
    i_checkMatrixIndex(stIf);
end
end


%%
function i_checkDisplayConsistency(hDoc)
astIf = mxx_xmltree('get_attributes', hDoc, ...
    '/ma:ModelAnalysis/ma:Subsystem/ma:Interface/ma:Output/ma:Display/*/ma:ifName', ...
    'ifid', ...
    'signalDim', ...
    'index1', ...
    'index2');
for i = 1:length(astIf)
    stIf = astIf(i);
    
    i_checkMatrixIndex(stIf);
end
end


%%
% RULE: Signals with matrix-dimension need to have an index1 and index2
function i_checkMatrixIndex(stIf)
if isempty(stIf.signalDim)
    return;
end
aiDim = eval(stIf.signalDim);

[nWidth1, nWidth2] = i_getWidths(aiDim);
bShallHaveIndex1 = ~isempty(nWidth1);
bShallHaveIndex2 = ~isempty(nWidth2);
if bShallHaveIndex1
    MU_ASSERT_FALSE(isempty(stIf.index1), sprintf( ...
        'Signal "%s" shall have an index1 but does not have one.', stIf.ifid));
else
    MU_ASSERT_TRUE(isempty(stIf.index1), sprintf( ...
        'Signal "%s" shall not have an index1 but has one.', stIf.ifid));
end
if bShallHaveIndex2
    MU_ASSERT_FALSE(isempty(stIf.index2), sprintf( ...
        'Signal "%s" shall have an index2 but does not have one.', stIf.ifid));
else
    MU_ASSERT_TRUE(isempty(stIf.index2), sprintf( ...
        'Signal "%s" shall not have an index2 but has one.', stIf.ifid));
end
end


%%
function [nWidth1, nWidth2] = i_getWidths(aiDim)
nDim = aiDim(1);
if (nDim < 2)
    nWidth1 = aiDim(2);
    if (nWidth1 < 2)
        nWidth1 = [];
    end
    nWidth2 = [];
else
    nWidth1 = aiDim(2);
    nWidth2 = aiDim(3);
    if ((nWidth1 < 2) || (nWidth2 < 2))
        nMax = max(nWidth1, nWidth2);
        if (nMax < 2)
            nWidth1 = [];
        else
            nWidth1 = nMax;
        end
        nWidth2 = [];
    end
end
end









