function varargout = ut_validate_xml(sSchemaKind, sXmlFile)
sXmlFile = ep_core_canonical_path(sXmlFile);

jArchSpec = ep.architecture.spec.ArchitectureSpec();


switch upper(sSchemaKind)
    case 'TL'
        jValidationResult = jArchSpec.isValidArchTL(java.io.File(sXmlFile));
        
    case 'SL'
        jValidationResult = jArchSpec.isValidArchSL(java.io.File(sXmlFile));
        
    otherwise
        error('UT:ERROR', 'Unknown schema kind "%s".', sSchemaKind);
end

stErr = i_transformValidationResultIntoStruct(jValidationResult);
if (nargout > 0)
    varargout{1} = stErr;
else
    i_assertValidXml(sXmlFile, stErr);
end
end


%%
function i_assertValidXml(sXmlFile, stValResult)
MU_ASSERT_TRUE(stValResult.bIsValid, sprintf('XML file "%s" is invalid.', sXmlFile));
for i = 1:numel(stValResult.casMessages)
    MU_FAIL(stValResult.casMessages{i});
end
end


%%
function stValResult = i_transformValidationResultIntoStruct(jValidationResult)
casAllMsgs = [i_transformToCell(jValidationResult.getErrors()), i_transformToCell(jValidationResult.getWarnings())];
stValResult = struct( ...
    'bIsValid',    jValidationResult.isValid(), ...
    'casMessages', {casAllMsgs});
end


%%
function casStrings = i_transformToCell(jList)
if (jList.isEmpty())
    casStrings = {};
else
    nElems = jList.size();
    casStrings = cell(1, nElems);
    for i = 1:nElems
        casStrings{i} = jList.get(i - 1);
    end
end
end
