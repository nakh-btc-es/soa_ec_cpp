function astVars = ep_rtesignal_vars_get(hSubsysDD)
% Get all RTE-Signal variables of provided subsystem.
%
% functionastVars = ep_rtesignal_vars_get(hSubsysDD)
%
%   INPUT           DESCRIPTION
%     hSubsysDD         (handle)       DD handle to a current subsystem (DD->Subsystems->"TopLevelName")
%
%   OUTPUT          DESCRIPTION
%     ahVars            (array)        DD variables of the specified kind
%
%   REMARKS
%
%     Note: function makes heavily use of "tl_collect_framegen_data.m"


%% 
astVars = i_getRteVars(hSubsysDD);
astVars = i_removeInvalidVars(hSubsysDD, astVars);
end


%%
function astVars = i_getRteVars(hDdSubsystem)
astRteSignalData = i_getRteSignalData(hDdSubsystem);
nVars = length(astRteSignalData);
astVars = repmat(struct( ...
    'hVar',       [], ...
    'signalName', ''), 1, nVars);
for i = 1:nVars
    astVars(i).hVar = astRteSignalData(i).hVariable;
    astVars(i).signalName = ...
        i_getCleanSignalName(astRteSignalData(i).simulinkSignalName);
end
end


%%
function sCleanName = i_getCleanSignalName(sName)
sCleanName = '';
if ~isempty(sName)
    % remove leading and trailing double-quotes
    sCleanName = strtrim(regexprep(sName, '"', ''));
end
end


%%
function astVars = i_removeInvalidVars(hSubsys, astVars)
if isempty(astVars)
    return;
end
ahOrigVars = [astVars(:).hVar];

% some vars are inactive due to data variants
% ! can only be done _before_ we filter out any variables at all; otherwise
%   we would lose the needed info !
ahVars = i_removeInactiveDataVariantVars(hSubsys, ahOrigVars);

% remove variables with local scope
abSelect = false(size(ahVars));
for i = 1:length(ahVars)
    abSelect(i) = ~i_isLocalScope(ahVars(i));
end
ahVars = ahVars(abSelect);

% remove the Variable structs that were not selected
[ahNotSelectedVars, aiNotSelectedIdx] = setdiff(ahOrigVars, ahVars); %#ok<ASGLU>
astVars(aiNotSelectedIdx) = [];
end


%%
function stOptions = i_getOptions(hSubsystemDD)
stOptions = struct();

stOptions.model                       = dsdd('GetSubsystemInfoModel', hSubsystemDD);
stOptions.application                 = 'Application';
stOptions.codeCoverageLevel           = 0;
stOptions.mode                        = 'base';
stOptions.simMode                     = 'TL_CODE_HOST';
stOptions.bIsStandalone               = 0;
stOptions.ddSubsystemObject           = i_getSubsystemAttributes(hSubsystemDD);
stOptions.bBaseMode                   = 1;
stOptions.bCodeCoverage               = 0;
stOptions.bUseOSEKEmulator            = 0;
stOptions.hTmpData                    = [];
stOptions.argumentsList               = [];
stOptions.globalSymbols               = [];
stOptions.externSymbols               = [];
stOptions.compiledRootOutportsData    = [];
stOptions.taskRefList                 = [];
stOptions.isrRefList                  = [];
stOptions.portInfoId                  = 1;
stOptions.tickDuration                = -1;
stOptions.hDDSimTimer                 = [];
stOptions.sampleTimes                 = [];
stOptions.bOsekCompliantRTOS          = 0;
stOptions.counterAlarmBlockList       = [];
stOptions.indexForActualParams        = 0;
stOptions.baseSampleTime              = -1; 
stOptions.defineLoopIndex             = 0;
stOptions.bPrintNotes                 = 0;
stOptions.bCheckInitValue             = 0;
stOptions.bFoundRootBuses             = 0;
stOptions.mvInportsStr                = [];
stOptions.mvOutportsStr               = [];
stOptions.bECPSupport                 = 0;
stOptions.bUseFrameActaulArguments    = 0;
stOptions.subsystemHierarchy          = [];
stOptions.targetTimeOut               = 1;
stOptions.writeAccessFcnInfoStructList = [];
stOptions.readAccessFcnInfoStructList  = [];
stOptions.bVEcuFrame                   = 0;
stOptions.bFmuFrame                    = 0;
stOptions.outputDirectory              = '';
stOptions.enumTypeList                 = []; 

stOptions.subsystemHierarchy = dsdd_manage_application('GetSubsystems', ...
    'Application',   stOptions.application, ...
    'SubsystemName', stOptions.ddSubsystemObject.name);
stOptions.subsystemID = dsdd('GetSubsystemInfoSubsystemID', deblank(stOptions.ddSubsystemObject.path));
end


%%
function astRteSignalData = i_getRteSignalData(hSubsystemDD)
stOptions = i_getOptions(hSubsystemDD);
[~, astSfcnData] = tl_collect_framegen_data(stOptions);

if ~isempty(astSfcnData)
    astRteSignalData = reshape(astSfcnData(1).rteSignalData, 1, []);
    for i = 2:numel(astSfcnData)
        astRteSignalData = [astRteSignalData, reshape(astSfcnData(i).rteSignalData, 1, [])]; %#ok<AGROW> 
    end
else
    astRteSignalData = [];
end
end


%%
function [stAttributes, bSuccess] = i_getSubsystemAttributes(hSubsystemDD)
[stAttributes, iErrorCode] = dsdd('GetAttributes', hSubsystemDD);
if (iErrorCode ~= 0 || ~strcmpi(stAttributes.objectKind, 'Subsystem'))
    bSuccess = false;
    stAttributes = [];
else
    bSuccess = true;
    stAttributes.path = dsdd('GetAttribute', hSubsystemDD, 'path');
end
end


%%
function ahReducedVars = i_removeInactiveDataVariantVars(hSubsys, ahVars)
% shortcut if no DataVariant is active
stConfig = ep_variant_config_get();
if ~isfield(stConfig, 'astDataVariants')
    ahReducedVars = ahVars;
    return;
end

% set_A: all our vars ahVars

% set_B: all DV vars 
ahDvVars = dsdd('Find', hSubsys, ...
    'objectKind', 'Variable', ...
    'Property', {'name', 'DataVariantName'});

% all active DV vars (set_C)
ahActiveDvVars = ep_active_dv_vars_get(hSubsys);

% set_D = intersect(set_A, set_B): all our vars which are dependent on DV
ahDvVarsPart = intersect(ahVars, ahDvVars); 

% set_E = set_D - set_C: all inactive vars in our original set_A
ahInactiveDvVarsPart = setdiff(ahDvVarsPart, ahActiveDvVars);

% set_D = set_A - set_E:  return value == all vars minus the inactive ones
ahReducedVars = setdiff(ahVars, ahInactiveDvVarsPart);
end


%%
function bIsLocal = i_isLocalScope(hVar)
stInfo = ep_variable_class_get(hVar);
bIsLocal = isempty(stInfo.hClass) || strcmpi(stInfo.sScope, 'local');
end


