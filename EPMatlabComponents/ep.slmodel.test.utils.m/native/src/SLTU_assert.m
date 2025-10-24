function SLTU_assert(sAssertFunc, bFail, sFailMsg)
% Internal wrapper function for all SLTU (MU extension) assert scripts.
%
% function SLTU_assert(sAssertFunc, bFail, sFailMsg)

%   PARAMETER(S)    DESCRIPTION
%   - sAssertFunc   Name of calling SLTU assert script.
%   - bFail         If true this assert marks a failing run.
%   - sFailMsg      Optionally: if failmsg is given, then it is reported instead of an empty string


%% default value for failmsg
if (nargin < 3)
    sFailMsg = '';
end


%% common result attributes
stFailed = struct();
stFailed.assert    = sAssertFunc;
stFailed.condition = [sAssertFunc, sFailMsg];
stFailed.fatal     = 0;
stFailed.ref       = '';


%% main
if bFail
    [stStack, stHighestSLTU] = i_getRelevantStack(dbstack);
    if ~isempty(stHighestSLTU)
        [~, sHighestAssert] = fileparts(stHighestSLTU.file);
        stFailed.condition = [sHighestAssert, sFailMsg];
    end
    stFailed.name      = stStack.file;
    stFailed.line      = num2str(stStack.line);
    stFailed.failed    = 1;
else
    stFailed.name      = '';
    stFailed.line      = '';
    stFailed.failed    = 0;
end
MU_registry_tunnel('ASSERT', stFailed);
end


%%
function [stStack, stHighestSLTU] = i_getRelevantStack(astStack)
iBaseLevel = 3;

iRelevantLevel = -1;
for i = iBaseLevel:numel(astStack)
    if (isempty(regexpi(astStack(i).file, '^SLTU_', 'once')) ...
            && isempty(regexpi(astStack(i).name, '^SLTU_', 'once')))
        iRelevantLevel = i;
        break;
    end
end

if (iRelevantLevel > 0)
    stStack = astStack(iRelevantLevel);
    stHighestSLTU = astStack(iRelevantLevel - 1);
else
    stStack = struct( ...
        'name', '<unknown>', ...
        'line', -1);
    stHighestSLTU = [];
end
end


%%
function MU_registry_tunnel(varargin)
sPwd = pwd;
xOnCleanupReturn = onCleanup(@() cd(sPwd));

sPath = fullfile(fileparts(which('MU_ASSERT')), 'private');
cd(sPath);
MU_registry(varargin{:});
end
