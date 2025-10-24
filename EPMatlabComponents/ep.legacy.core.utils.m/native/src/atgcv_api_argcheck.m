function atgcv_api_argcheck(stEnv, sArgName, xArg, varargin)
%  checking input arguments in API functions 
%
% function atgcv_api_argcheck(stEnv, sArgName, xArg, varargin)
%
%
%   INPUT               DESCRIPTION
%     stEnv                 (struct)       environment data needed by osc_messenger
%
%     sArgName              (string)       name of argument
%     xArg                  (x)            argument (arbitrary type)
%     caxProperties         (cell array x) properties that should be
%                                          checked (type: 'some_string' or 
%                                          {'key', value})
%
%   OUTPUT              DESCRIPTION
%      (none)                function throws exception if argument violates a
%                            property
%     
%   REMARKS
%      !! internal function: no input checks !!!
%
%
%   <et_copyright>

%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 148564 $
%   Last modified: $Date: 2013-07-25 11:26:51 +0200 (Do, 25 Jul 2013) $ 
%   $Author: qa_user $
%

stErr = [];
caxProperties = varargin;
for i = 1:length(caxProperties)
    xProperty = caxProperties{i};
    
    if iscell(xProperty)
        switch xProperty{1}
            case 'class'
                if ~isa(xArg, xProperty{2})
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_WRONG_CLASS', ...
                        'argname', sArgName, ...
                        'class', xProperty{2} );
                end
            case 'keyvalue'
                if ( ~ischar(xArg) || ~any(strcmp(xArg, xProperty{2})) )
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ILLEGAL_KEY_VALUE', ...
                        'key', sArgName, ...
                        'value', xArg);
                end
            case 'strcmpi'
                if ( ~ischar(xArg) || ~any(strcmpi(xArg, xProperty{2})) )
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_NOTMEMBER_SET', ...
                        'argname', sArgName);
                end
                
            case 'ismember'
                if ~ismember(xArg, xProperty{2})
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_NOTMEMBER_SET', ...
                        'argname', sArgName);
                end
                
            case 'date'
                try
                    n = datenum(xArg, xProperty{2}); %#ok n not used
                catch
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_WRONG_DATE_FORMAT', ...
                        'argname', sArgName, ...
                        'valid_format', xProperty{2} );
                end
                
            case 'fileext'
                [p, f, e] = fileparts(xArg);   %#ok p,f not used             
                if ~strcmpi(e(2:end), xProperty{2})
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_WRONG_FILEEXT', ...
                        'argname', sArgName, ...
                        'fileext', e(2:end) );
                end
                 
            case 'range'
                xRange = xProperty{2};
                if( xArg < xRange(1) || xArg > xRange(2) )
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_OUTOF_RANGE', ...
                        'argname', sArgName, ...
                        'argval',  num2str(xArg), ...
                        'lower',   num2str(xRange(1)), ... 
                        'upper',   num2str(xRange(2)) );
                end
                
            case 'dtdvalid'
                bIsValid = true;
                sDtdFile = xProperty{2};
                try
                    sDtdFull = fullfile(atgcv_env_dtd_path(), sDtdFile);
                    [nErr, sErrMsg] = atgcv_m_xmllint(stEnv, sDtdFull, xArg);
                    if (nErr ~= 0)
                        bIsValid = false;
                    end
                catch
                    bIsValid = false;
                end
                if ~bIsValid
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_XML_INVALID', ...
                        'argname', sArgName, ...
                        'dtd',     sDtdFile);
                end
                
            otherwise
                error('ATGCV:API:INTERNAL_ERROR', ...
                    'Unknown arg property name "%s" is ignored', xProperty{1});                
        end
    else
        switch xProperty
            case 'obligatory'
                if isempty(xArg)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:KEY_OBLIGATORY', ...
                        'key', sArgName);
                end
            case 'not_empty'
                if isempty(xArg)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:ARG_EMPTY', ...
                        'argname', sArgName);
                end
            case 'scalar'
                if isempty(xArg)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:ARG_EMPTY', ...
                        'argname', sArgName);
                elseif ~isscalar(xArg)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:ARG_NOT_SCALAR', ...
                        'argname', sArgName);
                end
                
            case 'atgcv_isvalid'
                if ~atgcv_object_isvalid(xArg)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:OBJECT_INVALID', ...
                        'objname', sArgName);
                end
                
            case 'atgcv_isactive'
                bJustCheckActive = true;
                if ~atgcv_object_isvalid(xArg, bJustCheckActive)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:OBJECT_INVALID', ...
                        'objname', sArgName);
                end
                
            case 'numeric'
                if ~isnumeric(xArg)
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:ARG_NOT_NUMERIC', ...
                        'argname', sArgName);
                end
                
            case 'filedir'
                if ~exist(xArg, 'file')
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:ARG_FILEDIR_INVALID', ...
                        'filename', xArg, ...
                        'argname', sArgName );
                end
                
            case 'file'
                if (~exist(xArg, 'file') || isdir(xArg))
                    stErr = osc_messenger_add(stEnv, ...
                        'ATGCV:API:ARG_FILE_INVALID', ...
                        'filename', xArg, ...
                        'argname', sArgName);
                end
                
            case 'dir'
                if ~isdir(xArg)
                    stErr = osc_messenger_add( stEnv, ...
                        'ATGCV:API:ARG_DIR_INVALID', ...
                        'filename', xArg, ...
                        'argname', sArgName);
                end
                
            otherwise
                error('ATGCV:API:INTERNAL_ERROR', ...
                    'Unknown arg property name "%s" is ignored', xProperty);                
        end
    end % end if...else
    if ~isempty(stErr)
        osc_throw(stErr);
    end
end % end for-loop
end
