function bResult = ds_isa(varargin)
% stubbed version to ensure that this function is not used (see BTS/35339)

sStackTrace = i_getStackTrace(dbstack());
if i_isIllegalCall(sStackTrace)
    if i_isInUnitTestContext(sStackTrace)
        MU_FAIL(sprintf('TL function "ds_isa()" was illegaly used from\n%s', sStackTrace));
    else
        error('STUB:TEST:ERROR', 'TL function "ds_isa()" was illegaly used from\n%s', sStackTrace);
    end
end
bResult = i_callOrig(varargin{:});
end


%%
function bResult = i_callOrig(varargin)
a = which('ds_isa', '-all');
sPath = fileparts(a{2});

sPwd = pwd();
xOnCleanupReturn = onCleanup(@() cd(sPwd));

cd(sPath);
bResult = ds_isa(varargin{:});
end


%%
function bIsIllegal = i_isIllegalCall(sStackTrace)
bIsIllegal = true; % per default every call is illegal

% use a whitelist for exceptions
casWhiteList = {'load_system', 'close_system', 'tu_test_model_adapt', 'tlDsInitFastRestart'};
for i = 1:length(casWhiteList)
    if ~isempty(regexp(sStackTrace, ['\n', casWhiteList{i}], 'once'))
        bIsIllegal = false;
        return;
    end
end
end


%%
function bIsInUT = i_isInUnitTestContext(sStackTrace)
bIsInUT = ~isempty(regexp(sStackTrace, '\nMU_registry', 'once'));
end


%%
function sStackTrace = i_getStackTrace(astDbStack)
nMax = 20;
nStack = length(astDbStack);

sStackTrace = '';
for i = 2:min(nMax, nStack)
    sStackTrace = [sStackTrace, sprintf('%s (%d)\n', astDbStack(i).name, astDbStack(i).line)];
end
end
