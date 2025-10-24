function stErr = ep_ma_validate_xml(sSchemaKind, sXmlFile)
sXmlFile = ep_core_canonical_path(sXmlFile);

jArchSpec = ep.architecture.spec.ArchitectureSpec();

sXmlFile = ep_core_canonical_path(sXmlFile);
switch upper(sSchemaKind)
    case 'TL'
        jValidationResult = jArchSpec.isValidArchTL(java.io.File(sXmlFile));
        
    case 'SL'
        jValidationResult = jArchSpec.isValidArchSL(java.io.File(sXmlFile));
        
    otherwise
        error('UT:ERROR', 'Unknown schema kind "%s".', sSchemaKind);
end

stErr = i_transformValidationResultIntoStruct(jValidationResult);
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
