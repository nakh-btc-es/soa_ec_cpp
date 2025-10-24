function varargout = sltu_validate_xml(sSchemaKind, sXmlFile)
% Checks is the provided XML follows the expected schema kind.
%
%  function varargout = sltu_validate_xml(sSchemaKind, sXmlFile)
%
%     INPUT                         DESCRIPTION
%     sSchemaKind        (char)      'TL' | 'SL' | 'MAPPING'
%     sXmlFile           (char)      path to XML file
% 
%

%%
sXmlFile = ep_core_canonical_path(sXmlFile);

jArchSpec = ep.architecture.spec.ArchitectureSpec();


switch upper(sSchemaKind)
    case 'TL'
        jValidationResult = jArchSpec.isValidArchTL(java.io.File(sXmlFile));
        
    case 'SL'
        jValidationResult = jArchSpec.isValidArchSL(java.io.File(sXmlFile));
        
    case 'CONSTRAINTS'
        jValidationResult = jArchSpec.isValidArchConstraints(java.io.File(sXmlFile));
        
    case 'MAPPING'
        jValidationResult = jArchSpec.isValidMapping(java.io.File(sXmlFile));
        
    case 'EC_AA'
        jValidationResult = jArchSpec.isValidAdaptiveAutosarComponent(java.io.File(sXmlFile));
        
    otherwise
        error('SLTU:VALIDATE_XML:ERROR', 'Unknown schema kind "%s".', sSchemaKind);
end

stResult = i_transformValidationResultIntoStruct(jValidationResult);
if (nargout > 0)
    varargout{1} = stResult;
else
    i_assertValidXml(sXmlFile, stResult);
end
end


%%
function i_assertValidXml(sXmlFile, stValResult)
SLTU_ASSERT_TRUE(stValResult.bIsValid, sprintf('XML file "%s" is invalid.', sXmlFile));
for i = 1:numel(stValResult.casMessages)
    SLTU_FAIL(stValResult.casMessages{i});
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
