function [bIsValid, oEx] = sltu_validate_xml_by_xsd(sXsdFile, sXmlFile)
% Checks if the provided XML follows the provided schema file.
%
%  function varargout = sltu_validate_xml_by_xsd(sXsdFile, sXmlFile)
%
%     INPUT                         DESCRIPTION
%     sXsdFile           (char)      path to XSD Schema file
%     sXmlFile           (char)      path to XML file
% 
%


%%
jValidator = i_createValidator(sXsdFile);
jStreamSource = i_createStreamSource(sXmlFile);

bIsValid = true;
oEx = [];
try
    jValidator.validate(jStreamSource);
    fprintf('\nValidation SUCCEEDED.\n\n');

catch oEx
    bIsValid = false;

    sShortMsg = regexprep(oEx.getReport, 'at org\.apache\.xerces.+', ''); % remove trailing stack
    sShortMsg = regexprep(sShortMsg, '.+Java exception occurred:', '');   % remove leading error context
    sShortMsg = strtrim(sShortMsg);
    fprintf('\nValidation FAILED:\n%s\n\n', sShortMsg);
end
end


%%
function jValidator = i_createValidator(sXsdFile)
jFactory = javax.xml.validation.SchemaFactory.newInstance('http://www.w3.org/2001/XMLSchema');
jSchemaLocation = java.io.File(sXsdFile);
jSchema = jFactory.newSchema(jSchemaLocation);
jValidator = jSchema.newValidator();
end


%%
function jStreamSource = i_createStreamSource(sXmlFile)
jXmlFile = java.io.File(sXmlFile);
sXmlFile = char(jXmlFile.toURI().toURL());
jStreamSource = javax.xml.transform.stream.StreamSource(sXmlFile);
end

