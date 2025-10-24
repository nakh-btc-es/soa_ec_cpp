function ahVars = atgcv_m01_global_vars_get(stEnv, hSubsys, sKind)
% get all specific global variables of provided subsystem
%
% function ahVars = atgcv_m01_global_vars_get(stEnv, hSubsys, sKind)
%
%   INPUT           DESCRIPTION
%     stEnv             (struct)       environment structure
%     hSubsys           (handle)       DD handle to a current subsystem (DD->Subsystems->"TopLevelName")
%     sKind             (string)       kind of variable:
%                                      'cal'       -- Calibration
%                                      'disp'      -- Display
%                                      'dsm_read'  -- DataStoreMemory Read
%                                      'dsm_write' -- DataStoreMemory Write
%
%   OUTPUT          DESCRIPTION
%       ahVars           (array)       DD variables of the specified kind
%


%% main
% first find all TargetLink top subsystems (including model references)
ahSubs = atgcv_m01_involved_subsystems_get(stEnv, hSubsys);

% create a whitelist of allowed SimFrameFiles (important for RTE (AUTOSAR) and/or Incremental/Reusable handling)
casAllowedSimFrameFiles = i_getAllValidSimFrameFiles(stEnv, ahSubs);

% now get the needed variables from these subsystems
ahVars = [];
for i = 1:length(ahSubs)
    hSub = ahSubs(i);
    
    ahDdModules = i_getRelevantModules(stEnv, hSub, casAllowedSimFrameFiles);    
    ahAddVars = i_getSubsystemGlobalVars(stEnv, hSub, sKind, ahDdModules);
    if ~isempty(ahAddVars)
        ahVars = [ahVars, ahAddVars]; %#ok<AGROW>
    end
end
end





%%
function ahVars = i_getSubsystemGlobalVars(stEnv, hSubsys, sKind, ahDdModules)
ahVars = i_getAllVarsOfKind(stEnv, hSubsys, sKind, ahDdModules);

% some vars are inactive due to data variants
% ! can only be done _before_ we filter out any variables at all; otherwise we would lose the needed info !
ahVars = i_removeInactiveDataVariantVars(stEnv, hSubsys, ahVars);

% remove variables with local scope
abSelect = false(size(ahVars));
for i = 1:length(ahVars)
    abSelect(i) = ~i_isLocalScope(stEnv, ahVars(i));
end
ahVars = ahVars(abSelect);
end


%%
function ahVars = i_getAllVarsOfKind(stEnv, hSubsys, sKind, ahDdModules)
ahVars = [];

switch lower(sKind)
    case 'cal'
        ahVarClasses = i_getClassesWithInfo(stEnv, hSubsys, {'readwrite', 'bypassing_readwrite'});
        stCalSettings = atgcv_cal_settings();
        sIgnoredClasses = stCalSettings.ET_CAL_ignore_variable_classes;
        if ~isempty(sIgnoredClasses)
            abReject = false(size(ahVarClasses));
            casIgnoredClasses = regexp(sIgnoredClasses, ';', 'split');
            for i = 1:length(ahVarClasses)
                hVarClass = ahVarClasses(i);
                sClassName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hVarClass, 'Name');
                if any(strcmp(sClassName, casIgnoredClasses))
                    abReject(i) = true;
                    i_addIgnoreNoteClass(stEnv, sClassName)
                end
            end
            ahVarClasses = ahVarClasses(~abReject);
        end
        
    case 'disp'
        ahVarClasses = i_getClassesWithInfo(stEnv, hSubsys, {'readonly', 'bypassing_readonly'});
        
    case 'dsm_read'
        ahVarClasses = i_getClassesWithProperty(stEnv, hSubsys, 'SimulationValueSource');
        
    case 'dsm_write'
        ahVarClasses = i_getClassesWithProperty(stEnv, hSubsys, 'SimulationValueDestination');
        
    otherwise
        error('ATGCV:INTERNAL:ERROR', 'unknown kind "%s"', sKind);
end
if (isempty(ahVarClasses) && any(strcmpi(sKind, {'cal', 'disp'})))
    % early return for CAL and DISP if no Classes found
    return;
end

aiVariantIds = i_getVariantIds();

% loop the VariableClasses and look for corresponding Variables
for i = 1:length(ahVarClasses)
    hClass = ahVarClasses(i);
    sClassName = atgcv_mxx_dsdd(stEnv, 'GetAttribute', hClass, 'Name');
    
    for j = 1:length(ahDdModules)
        hModule = ahDdModules(j);
        
        % 1) Variables with the specified VariableClass (without code variants!)
        %    ---> these ones can be found by _class_handle_
        ahFound = atgcv_mxx_dsdd(stEnv, ...
            'find',         hModule, ...
            'ObjectKind',   'Variable', ...
            'Property',     {'name', 'Class', 'value', hClass});
        ahVars = [ahVars, ahFound]; %#ok<AGROW>
        
        % ! Note: DD-inconsistency:
        % for variant-Variables VariableClass is a string and not a handle!
        %
        % 2) Variables with the specified VariableClass (with current code variants)
        %    ---> these ones can only be found by _class_name_string_
        for k = 1:length(aiVariantIds)
            iVariantId = aiVariantIds(k);
            
            % workaround for DD-inconsistency:
            % for variant-Variables you have to ask with the Name-String of VariableClass
            ahFound = atgcv_mxx_dsdd(stEnv, ...
                'find',         hModule, ...
                'ObjectKind',   'Variable', ...
                'Property',     {'name',    'Class', ...
                'value',        sClassName, ...
                'variant',      iVariantId});
            ahVars = [ahVars, ahFound]; %#ok<AGROW>
        end
    end
end

% for DSM look directly for special Variable attributes
if any(strcmpi(sKind, {'dsm_read', 'dsm_write'}))
    if strcmpi(sKind, 'dsm_read')
        if (atgcv_version_p_compare('TL3.5') >= 0)
            sProperty = 'SimulationValueSource';
        else
            sProperty = 'SimulinkSignalName';
        end
    else
        sProperty = 'SimulationValueDestination';
    end
    for j = 1:length(ahDdModules)
        hModule = ahDdModules(j);
        
        ahFound = atgcv_mxx_dsdd(stEnv, ...
            'find',         hModule, ...
            'ObjectKind',   'Variable', ...
            'Property',     {'name', sProperty});
        ahVars = [ahVars, ahFound]; %#ok<AGROW>
    end
end

% with the variants we can have the same variable handles multiple times in our array
% ---> make array unique and afterward sort them in reverse order 
% (because this is the order you get when callig GetChildren in DD)
ahVars = unique(ahVars);
ahVars = ahVars(end:-1:1);
end


%%
function i_addIgnoreNoteClass(stEnv, sClass)
osc_messenger_add(stEnv, 'ATGCV:MOD_ANA:IGNORE_CAL_BY_CLASS', 'varClass', sClass);
end


%%
function aiVariantIds = i_getVariantIds()
astVariants = dsdd('GetCodeVariants');
if isempty(astVariants)
    % if no variant is active, add the default variantID=0
    aiVariantIds = 0;
else
    aiVariantIds = [astVariants(:).variant];
end
end


%%
function ahClasses = i_getClassesWithInfo(stEnv, hDdSearchRoot, casAllowedInfoValues)
ahClasses = [];
for i = 1:numel(casAllowedInfoValues)
    sInfoValue = casAllowedInfoValues{i};
    
    ahClassesTmp = atgcv_mxx_dsdd(stEnv, ...
        'Find',       hDdSearchRoot, ...
        'ObjectKind', 'VariableClass', ...
        'Property',   {'name', 'Info', 'value', sInfoValue});    
    ahClasses = [ahClasses, reshape(ahClassesTmp, 1, [])]; %#ok<AGROW>
end
end


%%
function ahClasses = i_getClassesWithProperty(stEnv, hDdSearchRoot, sPropertyName)
ahClasses = atgcv_mxx_dsdd(stEnv, ...
    'Find',       hDdSearchRoot, ...
    'ObjectKind', 'VariableClass', ...
    'Property',   {'name', sPropertyName});
end


%%
function ahDdModules = i_getAllModules(stEnv, hSubsys)
ahDdModules = atgcv_mxx_dsdd(stEnv, 'GetChildren', hSubsys, 'objectKind', 'Module');
end


%%
function casSimFrameFiles = i_getAllValidSimFrameFiles(stEnv, ahAllSubs)
ahDdModules = [];
for i = 1:numel(ahAllSubs)
    hSub = ahAllSubs(i);
    if ~i_isReusableIncremental(hSub)
        ahSubDdModules = atgcv_mxx_dsdd(stEnv, 'GetChildren', hSub, 'objectKind', 'Module');
        abIsSimFrameFile = arrayfun(@(h) strcmp('SimulationFrameFile', i_getFileType(stEnv, h)), ahSubDdModules);
        ahDdModules = [ahDdModules, ahSubDdModules(abIsSimFrameFile)]; %#ok<AGROW>
    end
end
casSimFrameFiles = arrayfun(@(h) dsdd('GetAttribute', h, 'Name'), ahDdModules, 'UniformOutput', false);
end


%%
function bIsReusableIncremental = i_isReusableIncremental(hSub)
ahSubInfos = dsdd('Find', hSub, ...
    'objectKind', 'SubsystemInfo', ...
    'property', {'name', 'Reusable',    'value', 'on'}, ...
    'property', {'name', 'Incremental', 'value', 'on'});
bIsReusableIncremental = ~isempty(ahSubInfos);
end


%%
% return only files that "belong" to the SUT, i.e. filter out System files or similar
function ahDdModules = i_getRelevantModules(stEnv, hSubsys, casAllowedSimFrameFiles)
ahDdModules = i_getAllModules(stEnv, hSubsys);

nMod = length(ahDdModules);
abSelect = false(1, nMod);    % per default: no module is selected
for idx = 1:nMod
    hModule = ahDdModules(idx);
    sFileType = i_getFileType(stEnv, hModule);
    
    % if file has accepted FileType, mark it for selection
    abSelect(idx) = any(strcmpi(sFileType, ...
        {'GeneratedFile', ...
        'ImportedFile', ...
        'StubFile', ...
        'UserFile'}));
    
    % special treatment for SimulationFrameFiles on whitelist
    if (~abSelect(idx) && strcmpi(sFileType, 'SimulationFrameFile'))
        abSelect(idx) = any(strcmp(casAllowedSimFrameFiles, dsdd('GetAttribute', hModule, 'Name')));
    end
end
ahDdModules = ahDdModules(abSelect);
end


%%
function sFileType = i_getFileType(stEnv, hModule)
sFileType = 'unknown';

hModuleInfo = atgcv_mxx_dsdd(stEnv, 'GetModuleInfo', hModule);
ahFiles = atgcv_mxx_dsdd(stEnv, 'GetChildren', hModuleInfo, 'objectKind', 'FileInfo');

% possible Filetypes:
% unspec, GeneratedFile, TLSystemFile, SystemFile, UserFile, ImportedFile, SimulationFrameFile, StubFile

% use the first file entry to check the filetype <-- Assumption: all equal
if ~isempty(ahFiles)
    sFileType = atgcv_mxx_dsdd(stEnv, 'GetFileType', ahFiles(1));
end
end


%%
function ahReducedVars = i_removeInactiveDataVariantVars(stEnv, hSubsys, ahVars)
ahReducedVars = ahVars;

% Shortcut 1 if no variables are provided
if isempty(ahVars)
    return;
end

% Shortcut 2 if no DataVariant is active
stConfig = atgcv_m01_variant_config_get(stEnv);
if ~isfield(stConfig, 'astDataVariants')
    return;
end

% set_A: all our vars ahVars (external input to this function)

% set_B: all DV vars
ahDvVars = atgcv_mxx_dsdd(stEnv, 'Find', hSubsys, ...
    'objectKind', 'Variable', ...
    'Property',   {'name', 'DataVariantName'});

% all active DV vars (set_C)
ahActiveDvVars = atgcv_m01_active_dv_vars_get(stEnv, hSubsys);

% set_D = intersect(set_A, set_B): all our vars which are dependent on DV
ahDvVarsPart = intersect(ahVars, ahDvVars);

% set_E = set_D - set_C: all inactive vars in our original set_A
ahInactiveDvVarsPart = setdiff(ahDvVarsPart, ahActiveDvVars);

% set_D = set_A - set_E:  return value == all vars minus the inactive ones
ahReducedVars = setdiff(ahVars, ahInactiveDvVarsPart);
end


%%
function bIsLocal = i_isLocalScope(stEnv, hVar)
stInfo = atgcv_m01_variable_class_get(stEnv, hVar);
bIsLocal = isempty(stInfo.hClass) || strcmpi(stInfo.sScope, 'local');
end

