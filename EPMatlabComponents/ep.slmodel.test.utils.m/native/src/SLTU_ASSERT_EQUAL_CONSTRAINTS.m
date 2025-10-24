function SLTU_ASSERT_EQUAL_CONSTRAINTS(sExpectedConstrFile, sTestConstrFile)
% Asserts that the Constraints XML file is equal to the expected XML file.
%

%%
if ~exist(sExpectedConstrFile, 'file')
    if SLTU_update_testdata_mode()
        MU_MESSAGE('Creating expected version of the Constraints XML. No equality checks performed!');
        sltu_copyfile(sTestConstrFile, sExpectedConstrFile);
    else
        SLTU_FAIL('No expected values found. Cannot perform any checking.');
    end
else
    [hExpRoot,  oOnCleanupCloseExpDoc]  = i_openXml(sExpectedConstrFile); %#ok<ASGLU> onCleanup object
    [hTestRoot, oOnCleanupCloseTestDoc] = i_openXml(sTestConstrFile);     %#ok<ASGLU> onCleanup object
    
    oExpectedMap = i_getScopeConstraintsMap(hExpRoot);
    oTestMap = i_getScopeConstraintsMap(hTestRoot);
    
    % for updating we are not interested in the report but just in the diff result
    % --> don't report and in case of found differences replace the expected XML by the new one
    bDontReport = SLTU_update_testdata_mode();
    bDiffsFound = i_compareConstraintsMaps(oExpectedMap, oTestMap, bDontReport);
    if (bDiffsFound && bDontReport)
        MU_MESSAGE('Updating expectation values in Constraints XML. No equality checks performed!');
        sltu_copyfile(sTestConstrFile, sExpectedConstrFile);
    end
end
end


%%
function bDiffsFound = i_compareConstraintsMaps(oExpectedMap, oTestMap, bDontReport)
bDiffsFound = false;

casScopes = union(oExpectedMap.keys, oTestMap.keys);
for i = 1:numel(casScopes)
    sScope = casScopes{i};
    
    casExpectedAssums = i_getVal(oExpectedMap, sScope, {});
    casTestAssums = i_getVal(oTestMap, sScope, {});
    
    casMissing = setdiff(casExpectedAssums, casTestAssums);
    casUnexpected = setdiff(casTestAssums, casExpectedAssums);
    
    bDiffsFound = bDiffsFound || ~isempty(casMissing) || ~isempty(casUnexpected);
    if (bDiffsFound && bDontReport)
        return; % since we are not reporting anyway, the very first time a diff is found, we can immediately return
    end
    i_reportResults(casMissing, casUnexpected, sScope);
end
end


%%
function i_reportResults(casMissing, casUnexpected, sScope)
if (isempty(casMissing) && isempty(casUnexpected))
    MU_PASS(); % just for statistics reported in MUNIT report
else
    for i = 1:length(casMissing)
        SLTU_FAIL('Scope "%s": Expected assumption "%s" not found.', sScope, casMissing{i});
    end
    for i = 1:length(casUnexpected)
        SLTU_FAIL('Scope "%s": Unexpected assumption "%s" found.', sScope, casUnexpected{i});
    end
end
end


%%
function xVal = i_getVal(oMap, sKey, xDefaultVal)
if oMap.isKey(sKey)
    xVal = oMap(sKey);
else
    xVal = xDefaultVal;
end
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end


%%
function oScopeConstraintsMap = i_getScopeConstraintsMap(hDoc)
oScopeConstraintsMap = containers.Map;

ahScopes = mxx_xmltree('get_nodes', hDoc, '/architectureConstraints/scope');
for i = 1:numel(ahScopes)
    hScope = ahScopes(i);
    
    ccasAssums = arrayfun(@(hAss) i_readAssumptions(hAss), ...
        mxx_xmltree('get_nodes', hScope, './assumptions'), 'UniformOutput', false);
    oScopeConstraintsMap(mxx_xmltree('get_attribute', hScope, 'path')) = vertcat(ccasAssums{:});
end
end


%%
function casAssumptions = i_readAssumptions(hAss)
sOrigin = mxx_xmltree('get_attribute', hAss, 'origin');
casSigSigs = arrayfun(@(h) i_readSigSigAssumption(h, sOrigin), ...
    mxx_xmltree('get_nodes', hAss, './signalSignal'), 'UniformOutput', false);
casSigVals = arrayfun(@(h) i_readSigValAssumption(h, sOrigin), ...
    mxx_xmltree('get_nodes', hAss, './signalValue'), 'UniformOutput', false);

casAssumptions = [casSigSigs, casSigVals];
end


%%
function sSigSig = i_readSigSigAssumption(hSigSig, sOrigin)
stAtt = mxx_xmltree('get_attributes', hSigSig, '.', 'signal1', 'relation', 'signal2');
sSigSig = sprintf('%s [%s <%s> %s]', sOrigin, stAtt.signal1, stAtt.relation, stAtt.signal2);
end


%%
function sSigSig = i_readSigValAssumption(hSigVal, sOrigin)
stAtt = mxx_xmltree('get_attributes', hSigVal, '.', 'signal', 'relation', 'value');
sSigSig = sprintf('%s [%s <%s> "%s"]', sOrigin, stAtt.signal, stAtt.relation, stAtt.value);
end
