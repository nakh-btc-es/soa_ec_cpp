function [sDefineDDEnumInWSScript, sClearDDEnumInWSScript] = ep_simenv_callbacks_gen(xEnv, sSrcMdl, sTrgMdl)
% Generates callbacks for PreLoadFn and CloseFcn
%
% function ep_simenv_callbacks_gen(stEnv, sModelName, sDestMdl)
%
%   INPUT                       DESCRIPTION
%     stEnv                      environment
%     sSrcMdl                    name of the source model
%     sTrgMdl                    name of the target model
%   OUTPUT                      DESCRIPTION
%     sDefineDDEnumInWSScript    script to define the Enums in the workspace


%%
sDefineDDEnumInWSScript = '';
sClearDDEnumInWSScript = '';

sResultPath = pwd();

sMatDD          = [sTrgMdl, '_design_data.mat'];
sMatDDFile      = fullfile(sResultPath, sMatDD);

sMatDDTemp      = [sTrgMdl, '_design_data_temp.mat'];
sExportFile     = fullfile(sResultPath, sMatDDTemp);

astAllEnumTypes = [];
jKnownEnums = java.util.HashSet;
bExportedStuffFromSLDD = false;

casRefMdls = ep_find_mdlrefs(sSrcMdl);
casSLDDToUse = i_getAllSLDDsToUse(casRefMdls);
for i = 1:numel(casSLDDToUse)
    oDictionaryObj = Simulink.data.dictionary.open(casSLDDToUse{i});
    if (oDictionaryObj.NumberOfEntries <= 0)
        continue;
    end
    
    oDataSectObj = getSection(oDictionaryObj, 'Design Data');
    astEnumTypes = i_findEnumTypes(oDataSectObj);
    abDoKeep = false((numel(astEnumTypes)), 1);
    for j = 1:length(astEnumTypes)
        if ~jKnownEnums.contains(astEnumTypes(j).Name)
            jKnownEnums.add(astEnumTypes(j).Name);
            abDoKeep(j) = true;
        end
    end
    
    astAllEnumTypes = [astAllEnumTypes; astEnumTypes(abDoKeep)];%#ok
    if isempty(astEnumTypes)
        casEnumTypeNames = {};
    else
        casEnumTypeNames = {astEnumTypes.Name};
    end
    
    oConfigSectObj = getSection(oDictionaryObj, 'Configurations');
    i_exportBothDDSectionsWithoutEnums(sExportFile, oDataSectObj, oConfigSectObj, casEnumTypeNames, sMatDDFile);
    
    bExportedStuffFromSLDD = true;
end

if bExportedStuffFromSLDD
    if exist(fullfile(sResultPath, sMatDDTemp), 'file')
        delete(fullfile(sResultPath, sMatDDTemp));
    end
    stEnv = ep_core_legacy_env_get(xEnv, true);
    sModelPreloadScriptName = sprintf('%s_mdl_pre_load_fcn', sTrgMdl);
    sModelPreloadScript     = fullfile(sResultPath, [sModelPreloadScriptName, '.m']);
    sModelCloseScriptName   = sprintf('%s_mdl_close_fcn', sTrgMdl);
    sModelCloseScript       = fullfile(sResultPath, [sModelCloseScriptName, '.m']);
    sMatSnapshot            = [sTrgMdl, '_preload_state.mat'];

    [sDefineDDEnumInWSScript, sClearDDEnumInWSScript] = i_writeCallbacksForTransferringDDSection( ...
        stEnv, sModelPreloadScript, sModelCloseScript, sMatSnapshot, sMatDD, astAllEnumTypes);

    i_prependCallback(sTrgMdl, 'PreLoadFcn', sModelPreloadScriptName);
    i_prependCallback(sTrgMdl, 'CloseFcn', sModelCloseScriptName);
end
end


%%
% returns the SLDD of the main model and just the SLDDs that are not referenced by it
function casRes = i_getAllSLDDsToUse(casRefMdls)
casRes = {};
casBlackListSLDD = {};
% flip so that the main model is first and not last
casRefMdls(end:-1:1) = casRefMdls(:);
sMainDD = get_param(casRefMdls{1}, 'DataDictionary');
if ~isempty(sMainDD)
    casAlreadyKnownDDs = [];
    casBlackListSLDD = i_getAllReferencedDDs(sMainDD, casAlreadyKnownDDs);
end
for i = 1:numel(casRefMdls)
    sSLDD = get_param(casRefMdls{i}, 'DataDictionary');
    if isempty(sSLDD)
        continue;
    end
    if any(strcmp(casBlackListSLDD, sSLDD))
        continue;
    end
    casRes(end+1) = {sSLDD}; %#ok
end
end


%%
function casRes = i_getAllReferencedDDs(sMainDD, casAlreadyKnownDDs)
casRes = [];
casAlreadyKnownDDs{end+1} = sMainDD;
oDictionaryObj = Simulink.data.dictionary.open(sMainDD);
caoDataSources = oDictionaryObj.DataSources;
for i=1:numel(caoDataSources)
    if ~any(strcmp(casAlreadyKnownDDs, caoDataSources{i}))
        casRes{end+1} = caoDataSources{i};%#ok
        casRes = [casRes i_getAllReferencedDDs(caoDataSources{i}, casAlreadyKnownDDs)];%#ok
    end
end
end


%%
function [sDefineDDEnumInWSScript, sClearDDEnumInWSScript] = i_writeCallbacksForTransferringDDSection( ...
    stEnv, sModelPreloadScript, sModelCloseScript, sMatSnapshot, sMatDD, astEnumTypes)
% preload fcn
[hFidPreload, xOnCleanupClosePreloadFile] = i_createAndOpenCallbackFcnFile(sModelPreloadScript); %#ok
i_addSaveBaseWorkspace(hFidPreload, sMatSnapshot);
sDefineDDEnumInWSScript = '';
if ~isempty(astEnumTypes)
    i_addClearAllWithoutWarnings(hFidPreload);
    sDefineDDEnumInWSScript = i_createAndUseDDEnumDefScript(stEnv, hFidPreload, astEnumTypes, 'btc_define_enums');
end
i_addLoadMatFile(hFidPreload, sMatDD);
i_addLoadMatFile(hFidPreload, sMatSnapshot);
% close fcn
[hFidClose, xOnCleanupCloseCloseFile] = i_createAndOpenCallbackFcnFile(sModelCloseScript); %#ok
i_addClearAllWithoutWarnings(hFidClose);
sClearDDEnumInWSScript = '';
if ~isempty(astEnumTypes)
    sClearDDEnumInWSScript = i_createClearEnumScript(astEnumTypes, fileparts(sModelCloseScript), 'btc_clear_enums');
end
i_addLoadMatFile(hFidClose, sMatSnapshot);
end


%%
function i_exportBothDDSectionsWithoutEnums(sExportFile, oDataSectObj, oConfigSectObj, casEnumTypeNames, sMatDD)
% Efficiently export both Design Data and Configuration sections in one operation
sExportFile1 = [sExportFile(1:end-4), '_data.mat'];
sExportFile2 = [sExportFile(1:end-4), '_config.mat'];

% Export both sections to temporary files
oDataSectObj.exportToFile(sExportFile1);
oConfigSectObj.exportToFile(sExportFile2);

% Load both exported data
stDataSection = load(sExportFile1);
stConfigSection = load(sExportFile2);

% Remove enum types from data section if needed
if ~isempty(casEnumTypeNames)
    casEnumTypeNames = casEnumTypeNames(cellfun(@(sEnumType) isfield(stDataSection, sEnumType), casEnumTypeNames));
    if ~isempty(casEnumTypeNames)
        stDataSection = rmfield(stDataSection, casEnumTypeNames);
    end
end

% Merge both sections into one structure
stCombinedData = i_mergeStructs(stDataSection, stConfigSection);

% Save merged data to export file and append to final mat file
save(sExportFile, '-struct', 'stCombinedData');
i_appendDataToMatFile(sMatDD, stCombinedData);

% Load into base workspace
evalin('base', ['load(''', sExportFile, ''')']);

% Clean up temporary files
if exist(sExportFile1, 'file')
    delete(sExportFile1);
end
if exist(sExportFile2, 'file')
    delete(sExportFile2);
end
end


%%
function i_exportDDSectionWithoutEnums(sExportFile, oDataSection, casEnumTypeNames, sMatDD)
oDataSection.exportToFile(sExportFile);
if ~isempty(casEnumTypeNames)
    stData = load(sExportFile);
    
    casEnumTypeNames = casEnumTypeNames(cellfun(@(sEnumType) isfield(stData, sEnumType), casEnumTypeNames));
    stData = rmfield(stData, casEnumTypeNames); %used as string in following command
    
    save(sExportFile, '-struct', 'stData');
    i_appendDataToMatFile(sMatDD, stData);
else
    % store the parameters from DD
    stData = load(sExportFile);
    i_appendDataToMatFile(sMatDD, stData);
end

evalin('base', ['load(''', sExportFile, ''')']);
end


%%
function i_appendDataToMatFile(sMatDD, stData)
stDataToSave = stData; % used as string in following command
if ~exist(sMatDD, 'file')
    save(sMatDD, '-struct', 'stDataToSave');
else
    % Load existing data, merge with new data, and save all at once
    % This is much faster than individual field assignments or append
    stExisting = load(sMatDD);
    stMerged = i_mergeStructs(stExisting, stDataToSave);
    save(sMatDD, '-struct', 'stMerged');
end
end


%%
function stMerged = i_mergeStructs(stExisting, stNew)
% Fast structure merging - new fields overwrite existing ones
stMerged = stExisting;
fieldNames = fieldnames(stNew);
for i = 1:numel(fieldNames)
    stMerged.(fieldNames{i}) = stNew.(fieldNames{i});
end
end


%%
function [hFid, xOnCleanupClose] = i_createAndOpenCallbackFcnFile(sCallbackFile)
[~, sFuncName]  = fileparts(sCallbackFile);

hFid = fopen(sCallbackFile, 'wt');
xOnCleanupClose = onCleanup(@() i_closeCallbackFcn(hFid));

fprintf(hFid, 'function %s()\n', sFuncName);
end


%%
function i_closeCallbackFcn(hFid)
fprintf(hFid, 'end\n');
fclose(hFid);
end


%%
function sDefineDDEnumScriptFile = i_createAndUseDDEnumDefScript(stEnv, hFidPreload, astEnumTypes, sDefineDDEnumScriptName)
sDefineDDEnumSciptPath = fileparts(fopen(hFidPreload));
sDefineDDEnumScriptFile = fullfile(sDefineDDEnumSciptPath, [sDefineDDEnumScriptName, '.m']);
[hFid, xOnCleanupClose] = i_createAndOpenCallbackFcnFile(sDefineDDEnumScriptFile); %#ok
i_addEnumHandlingPreload(stEnv, hFid, astEnumTypes);

fprintf(hFidPreload, 'stWarningMode = warning(''QUERY'', ''BACKTRACE'');\n');
fprintf(hFidPreload, 'if strcmp(''on'', stWarningMode.state), warning off backtrace, end\n');
fprintf(hFidPreload, 'warning(''EP:MIL:ALL_MODELS_CLOSED'', ''All open models and Simulink DataDictionaries are closed to enable MIL simulation'');\n');
fprintf(hFidPreload, 'if strcmp(''on'', stWarningMode.state), warning on backtrace, end\n');
fprintf(hFidPreload, 'try\n');
fprintf(hFidPreload, '  bdclose all;\n');
fprintf(hFidPreload, 'end\n');
fprintf(hFidPreload, '%s;\n', sDefineDDEnumScriptName);
end


%%
function i_addEnumHandlingPreload(stEnv, hFid, astEnumTypes)
fprintf(hFid, 'evalin(''base'', ''clear all'');\n');
fprintf(hFid, 'Simulink.data.dictionary.closeAll(''-discard'');\n\n');

for i = 1:length(astEnumTypes)
    stEnumType = astEnumTypes(i);
    if verLessThan('matlab', '9.5')
        fprintf(hFid, 'clear %s;\n', stEnumType.Name);
    else
        fprintf(hFid, 'if ~isempty(Simulink.findIntEnumType(''%s''))\n', stEnumType.Name);
        fprintf(hFid, '  Simulink.clearIntEnumType(''%s'');\n', stEnumType.Name);
        fprintf(hFid, 'end\n');
    end
    i_addEnumDefinition(hFid, stEnumType);
end
fprintf(hFid, '\n');
osc_messenger_add(stEnv, 'ATGCV:MIL_GEN:ALL_MODELS_CLOSED');
end


%%
function i_addEnumDefinition(hFid, stEnumType)
sEnumName = stEnumType.Name;
sEnumLiterals = i_concatStringsAsStrings({stEnumType.astElems(:).Name});
sEnumValues = i_concatStrings({stEnumType.astElems(:).Value});
sEnumDataScope = stEnumType.sDataScope;
sEnumHeaderFile = stEnumType.sHeaderFile;

sEnumStorageType = stEnumType.sStorageType;

if isempty(sEnumHeaderFile)
    if ~isempty(sEnumStorageType)
        fprintf(hFid, 'Simulink.defineIntEnumType(''%s'', {%s}, [%s], ''DataScope'', ''%s'', ''StorageType'', ''%s'');\n', ...
            sEnumName, sEnumLiterals, sEnumValues, sEnumDataScope, sEnumStorageType);
    else
        fprintf(hFid, 'Simulink.defineIntEnumType(''%s'', {%s}, [%s], ''DataScope'', ''%s'');\n', ...
            sEnumName, sEnumLiterals, sEnumValues, sEnumDataScope);
    end
else
    if ~isempty(sEnumStorageType)
        fprintf(hFid, 'Simulink.defineIntEnumType(''%s'', {%s}, [%s], ''DataScope'', ''%s'', ''StorageType'', ''%s'', ''HeaderFile'', ''%s'');\n', ...
        sEnumName, sEnumLiterals, sEnumValues, sEnumDataScope, sEnumStorageType, sEnumHeaderFile);
    else
        fprintf(hFid, 'Simulink.defineIntEnumType(''%s'', {%s}, [%s], ''DataScope'', ''%s'', ''HeaderFile'', ''%s'');\n', ...
        sEnumName, sEnumLiterals, sEnumValues, sEnumDataScope,sEnumHeaderFile);
    end
end
end


%%
function sString = i_concatStrings(casStrings)
if isempty(casStrings)
    sString = '';
    return;
else
    sString = sprintf('%s, ', casStrings{:});
    sString(end-1:end) = [];
end
end


%%
function sString = i_concatStringsAsStrings(casStrings)
if isempty(casStrings)
    sString = '';
    return;
else
    sString = sprintf('''%s'', ', casStrings{:});
    sString(end-1:end) = [];
end
end


%%
function sClearEnumScript = i_createClearEnumScript(astEnumTypes, sClearEnumScriptPath, sClearEnumScriptName)
sClearEnumScript = fullfile(sClearEnumScriptPath, [sClearEnumScriptName, '.m']);
[hFid, xOnCleanupClose] = i_createAndOpenCallbackFcnFile(sClearEnumScript); %#ok
i_addEnumHandlingClose(hFid, astEnumTypes);
end


%%
function i_addEnumHandlingClose(hFid, astEnumTypes)
for i = 1:length(astEnumTypes)
    stEnumType = astEnumTypes(i);
    if verLessThan('matlab', '9.5')
        fprintf(hFid, 'clear %s;\n', stEnumType.Name);
    end
end

fprintf(hFid, 'Simulink.data.dictionary.closeAll(''-discard'');\n\n');
fprintf(hFid, 'Simulink.clearIntEnumType;\n');
end


%%
function i_addSaveBaseWorkspace(hFid, sMatFile)
fprintf(hFid, 'try\n');
fprintf(hFid, '  evalin(''base'', ''save(''''%s'''', ''''-regexp'''', ''''^(?!i_if_\\d+$).*'''')'');\n', sMatFile);
fprintf(hFid, 'end\n\n');
end


%%
function i_addClearAllWithoutWarnings(hFid)
fprintf(hFid, 'st = warning(''off'', ''all'');\n');
if exist('btc_clear_all_pre_hook', 'file')
    fprintf(hFid, 'btc_clear_all_pre_hook()\n');
    fprintf(hFid, 'evalin(''base'', ''clear all;'')\n');
    fprintf(hFid, 'btc_clear_all_post_hook()\n');
else
    fprintf(hFid, 'evalin(''base'', ''clear all;'')\n');
end
fprintf(hFid, 'warning(st);\n\n');
end


%%
function i_addLoadMatFile(hFid, sMatFile)
fprintf(hFid, 'if exist(''%s'', ''file'')\n', sMatFile);
warning('off', 'MATLAB:class:EnumerationValueChanged');
fprintf(hFid, '  evalin(''base'', ''load(''''%s'''');'');\n', sMatFile);
warning('on', 'MATLAB:class:EnumerationValueChanged');
fprintf(hFid, 'end\n\n');
end


%%
function astEnumTypes = i_findEnumTypes(oDDSection)
aoEnumEntries = oDDSection.find('-value', '-class', 'Simulink.data.dictionary.EnumTypeDefinition');
astEnumTypes = arrayfun(@i_createEnumInfo, aoEnumEntries);
end


%%
function stEnumInfo = i_createEnumInfo(oEnumEntry)
stEnumInfo = struct( ...
    'Name',         oEnumEntry.Name, ...
    'astElems',     oEnumEntry.getValue.Enumerals, ...
    'sDataScope',   oEnumEntry.getValue.DataScope, ...
    'sStorageType', oEnumEntry.getValue.StorageType,...
    'sHeaderFile',  oEnumEntry.getValue.HeaderFile);
end


%%
function i_prependCallback(sModel, sCallbackName, sExpression)
if isempty(sExpression)
    return;
end
sCurrentContent = get_param(sModel, sCallbackName);
if isempty(sCurrentContent)
    sContent = sExpression;
else
    sContent = sprintf('%s;%s', sExpression, sCurrentContent);
end
set_param(sModel, sCallbackName, sContent);
end
