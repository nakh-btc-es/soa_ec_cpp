function bSuccess = ep_tu_create_stub_function(sFcnName, sMode, StubFcn)
%  Creates an M stub function in the current directory.
%
%  function bSuccess = ep_tu_create_stub_function(sFcnName, sMode, StubFcn)
%
%  INPUT             DESCRIPTION
%  - sFcnName          Name of the function to be stubbed.
%  - sMode             One of 'alter_inputs', 'replace'.
%                      'alter_inputs':
%                      The stub function gets the input parameters an can alter them and return the changed parameters.
%                      In this case, the original function is called with the altered parameters and the result is returned.
%                      'replace':
%                      The stub function completely replaces the original function.
%  - StubFcn           Either a function handle which is called with all input parameters and which should return the altered
%                      input parameters, or a piece of inline code which directly accesses and alters varargin.
%                      The signature of the function is "function caNewInArgs = <function-name>(varargin)" and the
%                      return value is a cell array of the altered input parameters.
%  OUTPUT             DESCRIPTION
%  - bSuccess          Success (1) or failure (0).
%
% Remark: After generatin the function in the current directory you should use "rehash" to let Matlab know about the
%   new function. To avoid warning for overwritten builtin functions you can switch the warnings off by using the
%   command "status = warning('off', 'MATLAB:dispatcher:nameConflict');" and "warning(status);" afterwards. If the
%   stub is no longer needed, delete the stub m-script and use "rehash" again.
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author$
%  $Date$
%  $Revision$
%%
    bSuccess = 0;

    % suppress warning for stubbed builtin functions
    status = warning('off', 'MATLAB:dispatcher:nameConflict');
    
    try %#ok
        switch sMode
            case 'alter_inputs'
                bSuccess = i_create_mode_alter_inputs(sFcnName, StubFcn);
            case 'replace'
                bSuccess = i_create_mode_replace(sFcnName, StubFcn);
        end
    end

    warning(status);
end


%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************


%**************************************************************************
%  ALTER INPUTS AND CALL ORIGINAL FUNCTION                              ***
%                                                                       ***
%   PARAMETER(S)    DESCRIPTION                                         ***
%   -  sFcnName     (string) function name                              ***
%   -  StubFcn      (object) stub function                              ***
%                                                                       ***
%   OUTPUT                                                              ***
%   - bSuccess      (boolean) True, indicates success                   ***
%**************************************************************************
function bSuccess = i_create_mode_alter_inputs(sFcnName, StubFcn)

    bSuccess = 0;
    
    %  check parameter StubFcn
    switch class(StubFcn)
        case 'function_handle'
            sStubFcn = func2str(StubFcn);
            sStubCode = ['caNewArgs = ', sStubFcn, '(varargin{:});'];
        case 'char'
            sStubCode = [StubFcn, 10, '    caNewArgs = varargin;'];
        otherwise
            return
    end
    
    %  print head
    fid = fopen([sFcnName, '.m'], 'w');
    if fid == -1
        return
    end
    
    fprintf(fid, [ ...
        'function varargout = ', sFcnName, '(varargin)', 10, ...
        10, ...
        '    nInArgs = nargin;', 10, ...
        10, ...
        '    %%  avoid recursion', 10, ...
        '    caStack = dbstack;', 10, ...
        '    if sum(strcmp({caStack.name}, ''', sFcnName, ''')) == 1', 10, ...
        '        varargin = i_alter_inputs(varargin{:});', 10, ...
        '        nInArgs = length(varargin);', 10, ...
        '    end', 10, ...
        10, ...
        '    caAllFunctions = which(''', sFcnName, ''', ''-all'');', 10, ...
        '    if length(caAllFunctions) >= 2', 10, ...
        '        sOriginalFunction = caAllFunctions{2};', 10, ...
        '        if strncmp(sOriginalFunction, ''built-in'', 8)', 10, ...
        '            fEvaluate = @builtin;', 10, ...
        '            fun = ''', sFcnName, ''';', 10, ...
        '        else', 10, ...
        '            fEvaluate = @feval;', 10, ...
        '            sPathToOriginalFunction = fileparts(sOriginalFunction);', 10, ...
        '            sCurDir = cd;', 10, ...
        '            try %%#ok', 10, ...
        '                cd(sPathToOriginalFunction);', 10, ...
        '                fun = @', sFcnName, ';', 10, ...
        '            end', 10, ...
        '            cd(sCurDir);', 10, ...
        '        end', 10, ...
        10, ...
        '        if ~isempty(fun)', 10, ...
        '            if nargout > 0', 10, ...
        '                varargout = cell(nargout, 1);', 10, ...
        '                if nInArgs > 0', 10, ...
        '                    [varargout{1:nargout}] = fEvaluate(fun, varargin{:});', 10, ...
        '                else', 10, ...
        '                    [varargout{1:nargout}] = fEvaluate(fun);', 10, ...
        '                end', 10, ...
        '            else', 10, ...
        '                if nInArgs > 0', 10, ...
        '                    fEvaluate(fun, varargin{:});', 10, ...
        '                else', 10, ...
        '                    fEvaluate(fun);', 10, ...
        '                end', 10, ...
        '                try; if ~isempty(ans), varargout{1} = ans; end; end; %%#ok', 10, ...
        '            end', 10, ...
        '        end', 10, ...
        '    end', 10, ...
        'end', 10, ...
        10, ...
        'function caNewArgs = i_alter_inputs(varargin)', 10, ...
        '    ', sStubCode, 10, ...
        'end', 10, ...
        ]);
    
    fclose(fid);
    bSuccess = 1;
end

%**************************************************************************
%  COMPLETELY REPLACE THE ORIGINAL FUNCTION                             ***
%                                                                       ***
%   PARAMETER(S)    DESCRIPTION                                         ***
%   -  sFcnName     (string) function name                              ***
%   -  StubFcn      (object) stub function                              ***
%                                                                       ***
%   OUTPUT                                                              ***
%   - bSuccess      (boolean) True, indicates success of the function   ***
%**************************************************************************
function bSuccess = i_create_mode_replace(sFcnName, StubFcn)
    
    bSuccess = 0;
    
    %  check parameter StubFcn
    switch class(StubFcn)
        case 'function_handle'
            sStubFcn = func2str(StubFcn);
            sStubCode = ['varargout = ', sStubFcn, '(varargin{:});'];
        case 'char'
            sStubCode = StubFcn;
        otherwise
            return
    end
    
    %  print head
    fid = fopen([sFcnName, '.m'], 'w');
    if fid == -1
        return
    end
    
    fprintf(fid, [ ...
        'function varargout = ', sFcnName, '(varargin)', 10, ...
        '    ', sStubCode, 10, ...
        'end', 10, ...
        ]);
    
    fclose(fid);
    bSuccess = 1;   
end
%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************