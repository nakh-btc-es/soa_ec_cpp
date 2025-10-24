function ep_sim_argcheck(casArgNames, stArgs, varargin)
%  checking input arguments in API functions
%
% function ep_sim_argcheck(casArgNames, stArgs, varargin)
%
%
%   INPUT               DESCRIPTION
%     casArgNames           (cell)         argument names
%                                          note: if just one ArgName, it may be
%                                          provided as a simple string
%     stArgs                (struct)       arguments in a structure
%                                          (casArgName is used to access
%                                          the fields) or a single argument
%     caxProperties         (cell array x) properties that should be
%                                          checked (type: 'some_string' or
%                                          {'key', value})
%
%   OUTPUT              DESCRIPTION
%      (none)                function throws exception if argument violates a
%                            property
%
%
% $$$COPYRIGHT$$$-2015

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $
%%

caxProperties = varargin;
% in case that just one argument was provided as char
if ischar(casArgNames)
    casArgNames = {casArgNames};
end

for j = 1:length(casArgNames)
    % First check: do we have a structure, does it contain the expected
    %              field?
    sArgName = casArgNames{j};
    xArg = [];
    if ~isstruct(stArgs)
        xArg = stArgs;
    elseif isfield(stArgs, sArgName)
        xArg = stArgs.(sArgName);
    end
    
    for i = 1:length(caxProperties)
        xProperty = caxProperties{i};
        
        if iscell(xProperty) && ~isempty(xArg)
            switch xProperty{1}
                case 'class'
                    if ~isa(xArg, xProperty{2})
                        %                         stErr = osc_messenger_add( xEnv, ...
                        %                             'ATGCV:API:ARG_WRONG_CLASS', ...
                        %                             'argname', sArgName, ...
                        %                             'class', xProperty{2} );
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined.', sArgName);
                    end
                case 'keyvalue'
                    if ( ~ischar(xArg) || ~any(strcmp(xArg, xProperty{2})) )
                        %                         stErr = osc_messenger_add( xEnv, ...
                        %                             'ATGCV:API:ILLEGAL_KEY_VALUE', ...
                        %                             'key', sArgName, ...
                        %                             'value', xArg);
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined.', sArgName);
                    end
                case 'keyvalue_i'
                    if ( ~ischar(xArg) || ~any(strcmpi(xArg, xProperty{2})) )
                        %                         stErr = osc_messenger_add( xEnv, ...
                        %                             'ATGCV:API:ILLEGAL_KEY_VALUE', ...
                        %                             'key', sArgName, ...
                        %                             'value', xArg);
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined.', sArgName);
                    end
                case 'strcmpi'
                    if ( ~ischar(xArg) || ~any(strcmpi(xArg, xProperty{2})) )
                        %                         stErr = osc_messenger_add( xEnv, ...
                        %                             'ATGCV:API:ARG_NOTMEMBER_SET', ...
                        %                             'argname', sArgName);
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined.', sArgName);
                    end
                case 'xsdvalid'
                    bIsValid = true;
                    sDtdFile = xProperty{2};
                    sMessage = '';
                    try
                        sXmlFile = xArg;
                        if(~exist(sDtdFile, 'file'))
                            sXsdFull = fullfile(atgcv_env_dtd_local_path(), sDtdFile);
                        else
                            sXsdFull = sDtdFile;
                        end
                        if( exist(sXmlFile,'file') == 2) % file exists
                            i_validateSchema(sXmlFile, sXsdFull);
                        end
                    catch
                        bIsValid = false;
                        e = lasterror; %#ok;
                        sMessage = e.message;
                    end
                    if ~bIsValid
                        %                         stErr = osc_messenger_add( xEnv, ...
                        %                             'ATGCV:API:ARG_XML_INVALID', ...
                        %                             'argname', sArgName, ...
                        %                             'dtd',     sDtdFile);
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined: %s', sArgName, sMessage);
                    end
                otherwise
                    error('EP:STD:INTERNAL_ERROR', ...
                        'Unknown arg property name "%s" is ignored', xProperty{1});
            end
        elseif ~iscell(xProperty)
            switch xProperty
                case {'obligatory', 'not_empty'}
                    % Avoid exception; check is done earlier
                case 'file'
                    if (~exist(xArg, 'file') || isdir(xArg))
                        %                             stErr = osc_messenger_add(xEnv, ...
                        %                                 'ATGCV:API:ARG_FILE_INVALID', ...
                        %                                 'filename', xArg, ...
                        %                                 'argname', sArgName);
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined.', sArgName);
                    end
                    
                case 'dir'
                    if ~isdir(xArg)
                        %                             stErr = osc_messenger_add( xEnv, ...
                        %                                 'ATGCV:API:ARG_DIR_INVALID', ...
                        %                                 'filename', xArg, ...
                        %                                 'argname', sArgName);
                        error( 'EP:STD:ARGUMENT_EXCEPTION', ...
                            'Argument %s is not valid or fully defined.', sArgName);
                    end
                    
                otherwise
                    error('EP:STD:INTERNAL_ERROR', ...
                        'Unknown arg property name "%s" is ignored', xProperty);
            end
            
        end 
    end 
end
end

function i_validateSchema(sXmlFile, sSchemaFile)
% Use Schema validation for the XML file
import java.io.*;
import javax.xml.transform.Source;
import javax.xml.transform.stream.StreamSource;
import javax.xml.validation.*;

try
    jXmlFile = File(sXmlFile);
    sXmlFile = char(jXmlFile.toURI().toURL());
catch
end

jFactory = SchemaFactory.newInstance('http://www.w3.org/2001/XMLSchema');
jSchemaLocation = File(sSchemaFile);
jSchema = jFactory.newSchema(jSchemaLocation);
jValidator = jSchema.newValidator();
jSource = StreamSource(sXmlFile);
jValidator.validate(jSource);
end
