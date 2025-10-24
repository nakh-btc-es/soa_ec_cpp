function xOut = atgcv_mxx_dsdd(stEnv, varargin)
% wrapper for the most frequent dsdd call(s) with error handling
%
%  version1: nErr = dsdd(varargin{:})
%  version2: [xOut, nErr] = dsdd(varargin{:})
%
%  For nErr ~= 0 an error is inserted into the messenger.
%



%% handle one or two outputs
try
    if (nargout < 1)
        nErr = dsdd(varargin{:});
    else
        [xOut, nErr] = dsdd(varargin{:});
    end
catch
    stErr = lasterror();
    astStack = dbstack;    
    sMsg = i_getMessage(astStack, varargin, stErr.message);
    
    stOscErr = osc_messenger_add(stEnv,...
        'ATGCV:TLAPI:DSDD_ERROR', ...
        'number',  stErr.identifier,...
        'message', sMsg);
    osc_throw(stOscErr);
end
   

%% error handling
if (nErr ~= 0)
    stErr = dsdd('GetLastMessage');
    astStack = dbstack;
    
    sMsg = i_getMessage(astStack, varargin, stErr.msg);    
    stOscErr = osc_messenger_add(stEnv,...
        'ATGCV:TLAPI:DSDD_ERROR', ...
        'number',  sprintf('%d', nErr),...
        'message', sMsg );
    osc_throw(stOscErr);
end
end % main



%% i_getMessage
function sMsg = i_getMessage(astStack, caxCallArgs, sErrMsg)

nArgs = length(caxCallArgs);
if (nArgs < 1)
    sCmd = 'dsdd()';
else
    sCmd = sprintf('dsdd(%s', i_getString(caxCallArgs{1}));
    for i = 2:nArgs
        sCmd = sprintf('%s, %s', sCmd, i_getString(caxCallArgs{i}));
    end
    sCmd = sprintf('%s)', sCmd);
end
    
nStack = length(astStack);
if (nStack > 1)
    sCalledFrom = sprintf('%s(%i)', astStack(2).name, astStack(2).line);
else
    sCalledFrom = 'Command Window';
end
sStackTrace = sCalledFrom;
for i = 3:min(nStack, 5)
    sStackTrace = sprintf('%s(%i)//%s', astStack(i).name, ...
        astStack(i).line, sStackTrace);
end

sMsg = sprintf('\ncalled from: %s\ncmd: %s\nerror: %s', ...
    sStackTrace, sCmd, sErrMsg);
end


%% i_getString
function s = i_getString(x)
if ischar(x)
    s = sprintf('''%s''', x);
elseif iscell(x)
    s = '{';
    if ~isempty(x)
        x_elem = x{1};
        s_elem = i_getString(x_elem);
        s      = [s, s_elem];
        
        for i = 2:length(x)
            x_elem = x{i};
            s_elem = i_getString(x_elem);
            s = [s, ', ', s_elem];
        end
    end
    s = [s, '}'];   
else
    if isempty(x)
        s = '[]';
    else
        s = num2str(x);
    end
end
end
