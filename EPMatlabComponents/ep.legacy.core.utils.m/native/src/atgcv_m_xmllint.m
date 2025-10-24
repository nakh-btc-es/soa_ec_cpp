function [nErrorCode,sErrMsg] = atgcv_m_xmllint(stEnv, sDTDFile,sXMLFile)
% Validation of xml files.
%
% Remark:
% In this adjusted legacy function 'xml_tree' is used for the validation.
% 
%
% function [nErrorCode,sErrMsg] = atgcv_m_xmllint(stEnv,sDTDFile,sXMLFile)
%
%
%   PARAMETER(S)    DESCRIPTION
%   stEnv           (struct)  Environment structure with a component
%                                  ".hMessenger"
%   sDTDFile        (string) name of the DTD file
%   sXNLFile        (string) name of the XML file
%
%   OUTPUT
%   nErrorCode      (integer) error code:
% 				0    No error
% 				1    Unclassified
%(Obsolete)   	2    Error in DTD                      
% 				3    Validation error
%(Obsolete)   	4    Validation error
%(Obsolete)   	5    Error in schema compilation
%(Obsolete)   	6    Error writing output
%(Obsolete)   	7    Error in pattern (generated when [--pattern] option is used)
%(Obsolete)   	8    Error in Reader registration (generated when [--chkregister] option is used)
%(Obsolete)   	9    Out of memory error
%              10    File not found
%   sErrMsg         (string) error message 
%
% AUTHOR(S):
%   Hilger.Steenblock@osc-es.de
% $$$COPYRIGHT$$$-2005
%
%   $Revision: 76739 $ Last modified: $Date: 2010-11-02 09:06:47 +0100 (Di, 02 Nov 2010) $
%   $Author: hilger $ 


nErrorCode = 0;
sErrMsg  = '';

try
    if ~exist(sDTDFile,'file')
        nErrorCode = 10;
        sErrMsg    = sprintf('File not found %s',sDTDFile);
        return;
    end
    if ~exist(sXMLFile,'file')
        nErrorCode = 10;
        sErrMsg    = sprintf('File not found %s',sXMLFile);
        return;
    end

    %  check for suffix .html
    bIsHtml = false;
    [sPath, sFile, sSuffix] = fileparts(sXMLFile); %#ok
    if strcmp(sSuffix, '.html')
        bIsHtml = true;
    end

    %  call xml_tree for validation
    try
        hDoc = mxx_xmltree('load', sXMLFile);
        result =  mxx_xmltree('validate', hDoc, sDTDFile );
        mxx_xmltree('clear',hDoc);
    catch
        e = osc_lasterror;
        sErrMsg    = sprintf('%s\n%s',e.identifier, e.message);
        nErrorCode = 1;        
        return;
    end

    %  sometimes in HTML mode we get the error code 0 in case of errors
    if bIsHtml && ~isempty( result )
        sErrMsg = sprintf('File %s does validate against %s',sXMLFile , sDTDFile);
        nErrorCode = 1;
    end
    
    % Validation Error
    if ~result
        sErrMsg  = sprintf('File %s does validate against %s',sXMLFile , sDTDFile);
        nErrorCode = 3;
    end
    
catch
    nErrorCode = 1;
    stCurErr = osc_lasterror;
    sErrMsg    = stCurErr.message;
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************