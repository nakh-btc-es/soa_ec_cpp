function ep_core_check_args(casArgNames, stArgs, varargin)
%  checking input arguments in API functions 
%
% function et_api_argcheck(casArgNames, stArgs, varargin)
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
%   REMARKS
%      !! internal function: no input checks !!!
%
%

%%
oErr = [];
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
    bIsUsed = false;
    if ~isstruct(stArgs)
        xArg = stArgs;
    elseif isfield(stArgs, sArgName)
        xArg = stArgs.(sArgName);
        bIsUsed = true;
    end
    
    for i = 1:length(caxProperties)
        xProperty = caxProperties{i};

        if iscell(xProperty) && ~isempty(xArg)
            switch xProperty{1}
                case 'class'
                    if ~isa(xArg, xProperty{2})
                        oErr = MException('EP:API:ARG_WRONG_CLASS', ...
                            'Argument "%s" is not of the expected class "%s".', ...
                            sArgName, xProperty{2} );
                    end
                case 'classes'
                    if ~any(cellfun(@isa, ...
                            xArg, ...
                            repmat(xProperty(2), 1, length(xArg))))
                        oErr = MException('EP:API:ARG_WRONG_CLASS', ...
                            'Argument "%s" is not of the expected class "%s".', ...
                            sArgName, xProperty{2} );
                    end
                case 'keyvalue'
                    if ( ~ischar(xArg) || ~any(strcmp(xArg, xProperty{2})) )
                        oErr = MException('EP:API:ILLEGAL_KEY_VALUE', ...
                            'Illegal value for key "%s": "%s".', ...
                            sArgName, xArg);
                    end
                case 'keyvalue_i'
                    if ( ~ischar(xArg) || ~any(strcmpi(xArg, xProperty{2})) )
                        oErr = MException('EP:API:ILLEGAL_KEY_VALUE', ...
                            'Illegal value for key "%s": "%s".', ...
                            sArgName, xArg);
                    end
                case 'strcmpi'
                    if ( ~ischar(xArg) || ~any(strcmpi(xArg, xProperty{2})) )
                        oErr = MException('EP:API:ARG_NOTMEMBER_SET', ...
                            'Value of argument "%s" is not in the allowed set.', ...
                            sArgName);
                    end
                case 'ismember'
                    if ~all(ismember(xArg, xProperty{2}))
                        oErr = MException('EP:API:ARG_NOTMEMBER_SET', ...
                            'Value of argument "%s" is not in the allowed set.', ...
                            sArgName);
                    end
                case 'date'
                    try
                        n = datenum(xArg, xProperty{2}); %#ok n not used
                    catch
                        oErr = MException( 'EP:API:ARG_WRONG_DATE_FORMAT', ...
                            'Argument "%s" has not the expected date format "%s".', ...
                            sArgName, xProperty{2} );
                    end
                case 'fileext'
                    [p, f, e] = fileparts(xArg);   %#ok p,f not used             
                    if ~strcmpi(e(2:end), xProperty{2})
                        oErr = MException( ...
                            'EP:API:ARG_WRONG_FILEEXT', ...
                            'Argument "%s" has an unexpected file extension "%s".', ...
                            sArgName, e(2:end) );
                    end
                case 'range'
                    xRange = xProperty{2};
                    if( xArg < xRange(1) || xArg > xRange(2) )
                        oErr = MException('EP:API:ARG_OUTOF_RANGE', ...
                            'Value "$argval$" for argument "$argname$" is out of the valid range [$lower$, $upper$].', ...
                            sArgName, num2str(xArg), num2str(xRange(1)), num2str(xRange(2)) );
                    end
                case 'dtdvalid'
                    bIsValid = true;
                    sDtdFull = xProperty{2};
                    [~, sName, sExt] = fileparts(sDtdFull);
                    sDtdFile = [sName, sExt];
                    hXml = mxx_xmltree('load', xArg);
                    try
                        bErr = mxx_xmltree('validate', hXml, sDtdFull);
                        if (bErr ~= 0)
                            bIsValid = false;
                        end
                    catch
                        bIsValid = false;
                    end
                    mxx_xmltree('clear', hXml);
                    if ~bIsValid
                        oErr = MException('EP:API:ARG_XML_INVALID', ...
                            'File "%s" does not validate against DTD "%s".', ...
                            xArg, sDtdFile);
                    end
                case 'regexp'
                    if ~any(regexp(xArg, xProperty{2}, 'once'))
                        oErr = MException('EP:API:ILLEGAL_KEY_VALUE', ...
                            'Illegal value for key "%s": "%s".', ...
                            sArgName, xArg);
                    end
                otherwise
                    error('EP:API:INTERNAL_ERROR', ...
                        'Unknown argument property name "%s" is ignored', xProperty{1});                
            end
        elseif ~iscell(xProperty)
            if isempty(xArg)
                if strcmp(xProperty, 'obligatory') && ~ischar(xArg)
                    oErr = MException('EP:API:KEY_OBLIGATORY', ...
                        'Parameter key "%s" is obligatory but not defined.', sArgName);
                end
                if strcmp(xProperty, 'not_empty')
                    oErr = MException('EP:API:ARG_EMPTY', 'Argument "%s" is empty.', sArgName);
                end
                if (strcmp(xProperty, 'not_empty_if_used') && bIsUsed)
                    oErr = MException('EP:API:ARG_EMPTY', 'Argument "%s" is empty.', sArgName);
                end
            else
                switch xProperty
                    case {'obligatory', 'not_empty'}
                        % Avoid exception; check is done earlier
                    case 'scalar'
                        if ~isscalar(xArg)
                            oErr = MException('EP:API:ARG_NOT_SCALAR', ...
                                'Argument "%s" is not a scalar value.', sArgName);
                        end
                    case 'numeric'
                        if ~isnumeric(xArg)
                            oErr = MException('EP:API:ARG_NOT_NUMERIC', ...
                                'Argument "%s" is not a numeric value.', sArgName);
                        end
                    case 'integer'
                        if round(xArg) ~= xArg || isnan(xArg) || isinf(xArg)
                            oErr = MException('EP:API:ARG_NOT_INTEGER', ...
                                'Argument "%s" is not an integer value.', sArgName);
                        end
                    case 'string'
                        if ~ischar(xArg)
                            oErr = MException('EP:API:ARG_NOT_STRING', ...
                                'Argument "%s" is not a string value.', ...
                                sArgName);
                        end
                    case 'string or empty'
                        if ~(ischar(xArg) || isempty(xArg))
                            oErr = MException('EP:API:ARG_NOT_STRING', ...
                                'Argument "%s" is neither a string nor empty.', ...
                                sArgName);
                        end
                    case 'filedir'
                        if ~ischar(xArg) || ~exist(xArg, 'file')
                            oErr = MException( ......
                                'EP:API:ARG_FILEDIR_INVALID', ...
                                'filename', xArg, ...
                                'argname', sArgName );
                        end
                    case 'file'
                        if (~ischar(xArg) || ~exist(xArg, 'file') || isdir(xArg))
                            oErr = MException('EP:API:ARG_FILE_INVALID', ...
                                'File "%s" not found. Argument "%s" is not a valid file.', ...
                                xArg, sArgName);
                        end
                    case 'dir'
                        if ~ischar(xArg) || ~isdir(xArg)
                            oErr = MException('EP:API:ARG_DIR_INVALID', ...
                                'Dir "%s" not found. Argument "%s" is not a valid directory.', ...
                                xArg, sArgName);
                        end
                    case 'not_empty_if_used'
                        if isempty(xArg)
                            oErr = MException('EP:API:ARG_EMPTY', ...
                                'Argument "%s" is empty.', sArgName);
                        end
                    otherwise
                        error('EP:API:INTERNAL_ERROR', 'Unknown arg property name "%s" is ignored', xProperty);                
                end
            end
        end % end if...else
        if ~isempty(oErr)
            throw(oErr);
        end
    end % end inner for-loop
end
end
