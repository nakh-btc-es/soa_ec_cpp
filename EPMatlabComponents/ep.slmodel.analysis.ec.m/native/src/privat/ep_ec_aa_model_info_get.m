function stModelInfo = ep_ec_aa_model_info_get(sModelName, sInitScript)
% Analyses the structure of the AA C/S model and returns necessary info required to build a wrapper model
%
%  function ep_ec_aa_model_info_get(sModelName, sInitScript)
%
%  INPUT                        DESCRIPTION
%
%   - sModelName                The original model name
%   - sInitScript               The init script of the original model

%
%  OUTPUT                       DESCRIPTION
%    - stModelInfo
%         .sName                  (string) The original model name
%         .sPath                  (string)  Full path to the original model
%         .sInitScript            (string)  The init script of the original model
%         .casErrorMessages       (cell)    Cell containing warning/error messages.
%         .aoInports              (array)   Information about the in ports
%         .aoOutports             (array)   Information about the out ports
%         .aoRequiredMethods      (array)   Information about the required methods
%         .aoProvidedMethods      (array)   Information about the provided methods
%
%


%%
if (nargin < 2)
    sInitScript = '';
    if (nargin < 1)
        sModelName = bdroot(gcs);
    end
end

stModelInfo = struct( ...
    'sName',              sModelName, ...
    'sPath',              fileparts(get_param(sModelName, 'FileName')), ...
    'sInitScript',        sInitScript, ...
    'aoInports',          [], ...
    'aoOutports',         [], ...
    'aoProvidedMethods',  [], ...
    'aoRequiredMethods',  [], ...
    'bHasFieldsUpdate',   i_hasFieldsUpdate(sModelName), ...
    'casErrorMessages',   {{}});

try
    oRestoreModel = i_compileModel(sModelName); %#ok<NASGU> onCleanup object for restoring normal mode of model
catch oEx
    sCause = oEx.getReport('basic', 'hyperlinks', 'off');
    fprintf('[ERROR] Model "%s" cannot be initialized:\n\n%s', sModelName, sCause);
    stModelInfo.casErrorMessages{end + 1} = ...
        sprintf('Model "%s" cannot be initialized. For detailed messages see the Matlab console.', sModelName);
    return;
end

stPorts = ep_ec_aa_model_root_ports_get(sModelName);
stModelInfo.aoInports = stPorts.aoInports;
stModelInfo.aoOutports = stPorts.aoOutports;

aoReqMethods = ep_ec_aa_required_methods_get(sModelName);
stModelInfo.aoRequiredMethods = i_reorderMethodsAccordingToPortOrder(aoReqMethods, stModelInfo.aoInports);

aoProvMethods = ep_ec_aa_provided_methods_get(sModelName);
stModelInfo.aoProvidedMethods =  i_reorderMethodsAccordingToPortOrder(aoProvMethods, stModelInfo.aoOutports);
end


%%
function aoMethods = i_reorderMethodsAccordingToPortOrder(aoMethods, aoPorts)
mNameToIdx = i_mapNameToOrderIdxForClientServerPorts(aoPorts);

aiOrderedIdx = zeros(size(aoMethods));
for i = 1:numel(aoMethods)
    sFuncName = aoMethods(i).sFunctionName;

    if mNameToIdx.isKey(sFuncName)
        aiOrderedIdx(mNameToIdx(sFuncName)) = i;
    else
        error('EP:INTERNAL:ERROR', 'Unexpected: Function name of method not among the server-client ports.');
    end
end

aoMethods = aoMethods(aiOrderedIdx);
end


%%
function mNameToIdx = i_mapNameToOrderIdxForClientServerPorts(aoPorts)
mNameToIdx = containers.Map;
for i = 1:numel(aoPorts)
    oPort = aoPorts(i);

    if oPort.bIsClientServer
        sName = sprintf('%s.%s', oPort.sPortName, oPort.sElement);
        mNameToIdx(sName) = mNameToIdx.length + 1;
    end
end
end



%%
function oOnCleanupTerminateCompileMode = i_compileModel(sModelName)
eval([sModelName, '([], [], [], ''compile'');']);
oOnCleanupTerminateCompileMode = onCleanup(@() i_terminateModelRobustly(sModelName));
end


%%
function i_terminateModelRobustly(sModelName)
try
    feval(sModelName, [], [], [], 'term');
catch oEx %#ok<NASGU> 
    % be robust
end
end

%%
function bRes = i_hasFieldsUpdate(sModelName)
bRes = ~isempty(ep_find_system(get_param(sModelName, 'Handle'), ...
    'FindAll',             'on', ...
    'BlockType',           'TriggerPort', ...
    'TriggerType',         'message', ...
    'TriggerTime',         'on message available', ...
    'ScheduleAsAperiodic', 'on'));
end

