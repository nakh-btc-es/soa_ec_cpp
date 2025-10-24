function ut_tl_arch_consistency_check(sTlResultFile)
% applying check for general consistency rules for the TL Architecture result file.
%

%%
hTlResultFile = mxx_xmltree('load', sTlResultFile);
xOnCleanupCloseDocTl = onCleanup(@() mxx_xmltree('clear', hTlResultFile));

% EP-842 ports shall not have "initValue" for the MIL view
i_assertPortsMilWithoutInitValue(hTlResultFile);
end


%%
function i_assertPortsMilWithoutInitValue(hDoc)
sXPath = '/tl:TargetLinkArchitecture/model/subsystem/inport/miltype';
astRes = mxx_xmltree('get_attributes', hDoc, sXPath, 'initValue');
if ~isempty(astRes)
    bAllEmpty = all(cellfun(@isempty, {astRes.initValue}));
    MU_ASSERT_TRUE(bAllEmpty, 'Unexpected: Found Inports with non-empty MIL init value.');
else
    MU_FAIL('Unexpected: No Inport MIL types found.');
end
sXPath = '/tl:TargetLinkArchitecture/model/subsystem/outport/miltype';
astRes = mxx_xmltree('get_attributes', hDoc, sXPath, 'initValue');
if ~isempty(astRes)
    bAllEmpty = all(cellfun(@isempty, {astRes.initValue}));
    MU_ASSERT_TRUE(bAllEmpty, 'Unexpected: Found Outports with non-empty MIL init value.');
else
    MU_FAIL('Unexpected: No Outport MIL types found.');
end
end


