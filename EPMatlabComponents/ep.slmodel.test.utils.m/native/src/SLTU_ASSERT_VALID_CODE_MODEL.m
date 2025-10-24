function SLTU_ASSERT_VALID_CODE_MODEL(sCodeModelFile, bAssertCompilable)
% Asserts that the code model XML exists and is valid.
%

if (nargin < 2)
    bAssertCompilable = false;
end

%%
SLTU_ASSERT_TRUE(exist(sCodeModelFile, 'file'), 'Code model XML file is missing.');

%% DTD validation
% NOTE: currently no validation done!
% TODO ...

%% special asserts
[hExpRoot, oOnCleanupCloseExpDoc] = i_openXml(sCodeModelFile); %#ok<ASGLU> onCleanup object

% check that all context functions if mentioned are not empty
casContextFuncs = { ...
    'name', ...
    'initFunc', ...
    'pointerInitFunc', ...
    'postInitFunc', ...
    'proxyFunc', ...
    'preStepFunc'};
sltu_assert_nonempty_attributes(hExpRoot, '/CodeModel/Functions/Function', casContextFuncs);

if bAssertCompilable
    [bIsCompilable, sError] = sltu_assert_compilable(sCodeModelFile);
    SLTU_ASSERT_TRUE(bIsCompilable, 'CodeModel is not valid: \n%s', sError);
end
end


%%
% asserts that the attributes described by the XPath and the attribute names are non-empty
% note: if an attribute is not set at all, the check is automatically successful
function sltu_assert_nonempty_attributes(hContextNode, sXPath, casAttribs)
if isempty(casAttribs)
    return;
end
astVals = mxx_xmltree('get_attributes', hContextNode, sXPath, casAttribs{:});
for i = 1:numel(astVals)
    for k = 1:numel(casAttribs)
        sAttrib = casAttribs{k};
        sVal = astVals(i).(sAttrib);
        
        % note: in the following line using the fact that a non-existing attribute is yieding an empty array "[]" which
        % is a non-char type
        bAttribExists = ischar(sVal);
        if bAttribExists
            SLTU_ASSERT_FALSE(isempty(sVal), 'Found an unexpected empty value for attribute "%s".', sAttrib);
        end
    end
end
end


%%
function [hRoot, oOnCleanupCloseDoc] = i_openXml(sXml)
hRoot = mxx_xmltree('load', sXml);
oOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', hRoot));
end
