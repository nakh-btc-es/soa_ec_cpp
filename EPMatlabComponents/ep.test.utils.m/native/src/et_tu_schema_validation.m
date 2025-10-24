function [bSuccess, sErrorMessage] = et_tu_schema_validation(xmlFile, schemaFile)
    % Validate XML against XSD schema.
    %
    % function [bSuccess, sErrorMessage] = et_tu_schema_validation(xmlFile, schemaFile)
    %
    %   INPUT               DESCRIPTION
    %     xmlFile              (string)  full path to XML file
    %     schemaFile           (string)  full path to XSD file
    %
    %   OUTPUT              DESCRIPTION
    %     bSuccess             (boolean) True, iff validation is successful.
    %     sErrorMessage        (string)  Validation error message if not successful.
    %
    %  REMARKS
    %
    %  Copyright (c) 2015,
    %  BTC Embedded Systems AG, Oldenburg, Germany
    %  All rights reserved
    
    %%  internal
    %  $Author$
    %  $Date$
    %  $Revision$
    %%
    import java.io.*;
    import javax.xml.transform.Source;
    import javax.xml.transform.stream.StreamSource;
    import javax.xml.validation.*;
    
    factory = SchemaFactory.newInstance('http://www.w3.org/2001/XMLSchema');
    schemaLocation = File(schemaFile);
    schema = factory.newSchema(schemaLocation);
    validator = schema.newValidator();
    source = StreamSource(xmlFile);
    
    try
        validator.validate(source);
        bSuccess = true;
        sErrorMessage = '';
    catch exception
        bSuccess = false;
        sErrorMessage = exception.message;
    end
end
