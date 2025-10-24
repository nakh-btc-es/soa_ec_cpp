function ep_sim_sl_top_pre_sim_script_gen(stEnv, sDestMdlName, xSubsystem, oProgress)
% Generates the pre-simulation script for SL-TOP
%
% function ep_sim_sl_top_pre_sim_script_gen(stEnv, sDestMdl, xSubsystem, oProgress)
%

%%
bBreakModelRefs = false; % for SL-Toplevel model references are never broken

ahCalibration = mxx_xmltree('get_nodes', xSubsystem, './Calibration');
if isempty(ahCalibration)
    % without Calibrations nothing to do --> early return
    return;
end

sResultPath = pwd();
if isstruct(stEnv)
    sResultPath = stEnv.sResultPath;
end

sPreSimScriptName = sprintf('%s_pre_sim', sDestMdlName);
sPreSimScriptFile = fullfile(sResultPath, [sPreSimScriptName, '.m']);

% open file
hFid = fopen(sPreSimScriptFile, 'wt');
xOnCleanupFile = onCleanup(@() fclose(hFid));
hDestMdl = get_param(sDestMdlName, 'Handle');

i_createPreLoadScriptHeader(hFid, sPreSimScriptName);
i_initCalWSVars(hFid, ahCalibration);
i_setExternCal(hFid, xSubsystem, hDestMdl, bBreakModelRefs, oProgress);
end


%%
function i_initCalWSVars(fid, ahCalibration)
fprintf(fid, '%% Pre-simulation init of WS variables in order to make model compilable.\n');
for i = 1:length(ahCalibration)
    ahIfNames = mxx_xmltree('get_nodes', ahCalibration(i),  './Variable/ifName');
    for j = 1:length(ahIfNames)
        sIfid = mxx_xmltree('get_attribute', ahIfNames(j), 'ifid');
        sInitValue = mxx_xmltree('get_attribute', ahIfNames(j), 'initValue');
        sVarName = sprintf('i_%s', sIfid);
        sLine = sprintf('if ~exist(''%s'', ''var''), evalin(''base'', ''%s = [0, %s];''); end', sVarName, sVarName, sInitValue);
        fprintf(fid, '%s\n', sLine);
    end
end
end


%%
function i_createPreLoadScriptHeader(fid, sPreLoadScriptName)
ep_simenv_print_script_header(fid, sPreLoadScriptName, 'This file contains the initialization of the MIL simulation.');
end


%%
function i_setExternCal(hFid, hSubsystemNode, hModel, bBreakModelRefs, oProgress)
ahCalibrations = mxx_xmltree('get_nodes', hSubsystemNode, './Calibration');

% state marker if check for variants in TLDD was performed
bCheckedForTlVariants = false;

% set if TL variants are actually used
bUsesTlVariants = false;

if ~isempty(ahCalibrations)
    sSlddName = get_param(hModel, 'DataDictionary');
    
    %check if we need to tune model workspace parameters
    ahModelWsNodes = mxx_xmltree('get_nodes', hSubsystemNode, './Calibration/Source[@kind=''ModelWorkspace'']');
    bModelWorkspaceUsed = ~isempty(ahModelWsNodes);
    
    % define empty cell array to keep track on model workspaces in use
    casModelWS = {};    
    if bModelWorkspaceUsed
        %find distinct model workspaces being used
        casModelWS = i_listDistinctModelWS(ahModelWsNodes);
        for i = 1:length(casModelWS)
            i_backupModelWs(hFid, casModelWS{i});
        end
    end
    
    if ~isempty(sSlddName)
        hDictionary = Simulink.data.dictionary.open(sSlddName);
        
        %include SLDD access in init script
        fprintf(hFid, 'hDictionary = Simulink.data.dictionary.open(''%s'');\n', sSlddName);
        fprintf(hFid, 'hSection = getSection(hDictionary, ''Design Data'');\n');
        
        casParamsFromDD = {};
        nCountDDParams = 0;
    else
        hDictionary = [];
    end
    
    nCalLength = length(ahCalibrations);
    atgcv_progress_set(oProgress, 'current', 0, 'total', nCalLength);
    for i = 1:nCalLength
        hCalibration = ahCalibrations(i);
        atgcv_progress_set(oProgress, 'current', i);
        
        %reinit marker if TLDD values are used
        bUsesTLDD = false;
        
        %reinit marker if ModelWorkspace is the source
        bModelWSKind = false;
        
        %reinit TlMetaInfo structure
        stTlMetaInfo = [];
        
        %find out if CalibrationNode originates from TLDD
        hSourceNode = mxx_xmltree('get_nodes', hCalibration,  './Source');
        
        if ~isempty(hSourceNode)
            sKind = mxx_xmltree('get_attribute', hSourceNode, 'kind');
            if strcmp(sKind, 'TL-DataDictionary')
                bUsesTLDD = true;
                if ~bCheckedForTlVariants
                    %set marker that check has been performed
                    bCheckedForTlVariants = true;
                    bUsesTlVariants = i_checkTlVariantState;
                end
                stTlMetaInfo = struct(...
                    'sFile',            mxx_xmltree('get_attribute', hSourceNode, 'file'),...
                    'sAccessPath',      mxx_xmltree('get_attribute', hSourceNode, 'access'),...
                    'sCalValueSource',  atgcv_m13_cal_value_get(hCalibration));

            elseif strcmp(sKind, 'ModelWorkspace')
                bModelWSKind = true;
            end
        end
        
        sCalVarNameIntoSimModel = atgcv_m13_object_block_get(hCalibration, bBreakModelRefs);
        
        % UseCase: Explicit Parameter Calibration
        
        sVarName = mxx_xmltree('get_attribute', hCalibration, 'name');
        sStartIdx = mxx_xmltree('get_attribute', hCalibration, 'startIdx');
        
        if bModelWSKind
            ahIfNames = mxx_xmltree('get_nodes', hCalibration, './Variable/ifName');
            
            sModelName = mxx_xmltree('get_attribute', hSourceNode, 'file');
            stTypeResult = ep_sim_check_model_ws_param(sVarName, sModelName);
            
            for j = 1:length(ahIfNames)
                hIfName = ahIfNames(j);
                sIfName_Id = mxx_xmltree('get_attribute', hIfName, 'ifid');
                % handling embedded.fi objects
                if stTypeResult.bEmbeddedFi || (~isempty(stTypeResult.stTypeInfo) && stTypeResult.stTypeInfo.bIsFxp)
                    sValueAssign = sprintf('fi(i_%s(1, 2), %s)', sIfName_Id, stTypeResult.stTypeInfo.sEvalType);
                else
                    hVarNode = mxx_xmltree('get_nodes', hCalibration, './Variable');
                    bIsSignalTypeEnum = strcmp('yes', mxx_xmltree('get_attribute', hVarNode, 'isSignalTypeEnum'));
                    if bIsSignalTypeEnum
                        stTypeResult.sVarType =  mxx_xmltree('get_attribute', hVarNode, 'signalType');
                    end
                    sValueAssign = sprintf('%s(i_%s(1, 2))', stTypeResult.sVarType, sIfName_Id);
                end
                sIndex1 = mxx_xmltree('get_attribute', hIfName, 'index1');
                sIndex2 = mxx_xmltree('get_attribute', hIfName, 'index2');
                sIndexAccess = i_getIndexAccess(sStartIdx, sIndex1, sIndex2);
                sNameWS = ['h' sModelName 'WS'];
                % set value directly in individual model workspace
                fprintf(hFid, '%s.setVariablePart(''%s%s'', %s);\n', ...
                    sNameWS, stTypeResult.sVarAccess, sIndexAccess, sValueAssign);
            end
            stTypeResult.bCachedInWs = false;

        elseif ~bUsesTLDD
            % check if Parameter exists within the given SLDD, query additional information
            stTypeResult = ep_sim_check_dictionary_param(sVarName, hDictionary);

        else
            % don't generate base workspace/SLDD assignment instructions
            stTypeResult.bCachedInWs = false;
        end
        
        if stTypeResult.bCachedInWs && ~stTypeResult.bFromSLDD
            stExpressionResult = atgcv_m13_expression_info_get(sVarName);
            if ~stExpressionResult.bIsLValue
                sVarName = '';
            end
            stTypeResult = i_prepare_info_struct;
            [stTypeResult.sVarType, ~, ~, stTypeResult.bEmbeddedFi, ...
                stTypeResult.sVarAccess, stTypeResult.stTypeInfo] = atgcv_m13_evalinbase_vartype(sVarName);
            stTypeResult.bCachedInWs = true;
        end
        
        if isempty(sVarName) && ~bModelWSKind
            stTypeResult = i_prepare_info_struct;
            sTmpNamePrefix = 'btc_tmp_calxxx';
            sVarName = [sTmpNamePrefix, int2str(i)];
            stTypeResult.sVarType = 'double';
            stTypeResult.bEmbeddedFi = false;
            stTypeResult.sVarAccess = sVarName;
        end
        
        if(stTypeResult.bCachedInWs) && ~bModelWSKind
            fprintf(hFid,'\n%s''%s''\n', '%', strrep(sCalVarNameIntoSimModel, char(10), ' '));%#ok

            % variables of type Simulation.Parameter have to be treated differently
            % generate command to get the handle for the right entry if the variable originates from SLDD
            if stTypeResult.bFromSLDD
                nCountDDParams = nCountDDParams + 1;
                casParamsFromDD{nCountDDParams} = sVarName; %#ok<AGROW>
                fprintf(hFid, 'hEntry = getEntry(hSection, ''%s'');\n', sVarName);
                fprintf(hFid, '%s = getValue(hEntry);\n', sVarName);
                %use temporary name for object handle
                sNameVal = sVarName;
            else
                sNameVal = sVarName;
            end
            
            sCondition = 'isempty';
            sParamMin = '[]';
            sParamMax = '[]';
            
            if ~isempty(strfind(stTypeResult.sVarAccess, '.Breakpoints.Value'))
                sEvalCmd = sprintf( ...
                    'if ~%s(%s.Breakpoints.Min), %s.Breakpoints.Min = %s; end', ...
                    sCondition, sNameVal, sNameVal, sParamMin);
                fprintf(hFid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                sEvalCmd = sprintf( ...
                    'if ~%s(%s.Breakpoints.Max), %s.Breakpoints.Max = %s; end', ...
                    sCondition, sNameVal, sNameVal, sParamMax);
                fprintf(hFid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
            elseif ~isempty(strfind(stTypeResult.sVarAccess, '.Table.Value'))
                sEvalCmd = sprintf( ...
                    'if ~%s(%s.Table.Min), %s.Table.Min = %s; end', ...
                    sCondition, sNameVal, sNameVal, sParamMin);
                fprintf(hFid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                sEvalCmd = sprintf( ...
                    'if ~%s(%s.Table.Max), %s.Table.Max = %s; end', ...
                    sCondition, sNameVal, sNameVal, sParamMax);
                fprintf(hFid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
            elseif stTypeResult.bIsParamType %do this only for Simulink.Parameter, never for variables
                sEvalCmd = sprintf( ...
                    'if ~%s(%s.Min), %s.Min = %s; end', ...
                    sCondition, sNameVal, sNameVal, sParamMin);
                fprintf(hFid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                sEvalCmd = sprintf( ...
                    'if ~%s(%s.Max), %s.Max = %s; end', ...
                    sCondition, sNameVal, sNameVal, sParamMax);
                fprintf(hFid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
            end
            
            ahIfName = mxx_xmltree('get_nodes', hCalibration, './Variable/ifName');
            for j = 1:length(ahIfName)
                hIfName = ahIfName(j);
                sIfName_Id = mxx_xmltree('get_attribute', hIfName, 'ifid');
                % handling embedded.fi objects
                if stTypeResult.bEmbeddedFi || (~isempty(stTypeResult.stTypeInfo) && stTypeResult.stTypeInfo.bIsFxp)
                    sValueAssign = sprintf('fi(i_%s(1, 2), %s)', sIfName_Id, stTypeResult.stTypeInfo.sEvalType);
                else
                    hVarNode = mxx_xmltree('get_nodes', hCalibration, './Variable');
                    bIsSignalTypeEnum = strcmp('yes', mxx_xmltree('get_attribute', hVarNode, 'isSignalTypeEnum'));
                    if bIsSignalTypeEnum
                        stTypeResult.sVarType =  mxx_xmltree('get_attribute', hVarNode, 'signalType');
                    end
                    sValueAssign = sprintf('%s(i_%s(1, 2))', stTypeResult.sVarType, sIfName_Id);
                end
                sIndex1 = mxx_xmltree('get_attribute', hIfName, 'index1');
                sIndex2 = mxx_xmltree('get_attribute', hIfName, 'index2');
                sIndexAccess = i_getIndexAccess(sStartIdx, sIndex1, sIndex2);
                
                fprintf(hFid, 'evalin(''base'', ''%s%s = %s;'');\n', stTypeResult.sVarAccess, sIndexAccess, sValueAssign);
            end
            
            %remove this if MathWorks will provide bugfix for importFromBaseWorkspace
            if stTypeResult.bFromSLDD
                if verLessThan('matlab','9.9')
                    if ~isempty(strfind(stTypeResult.sVarAccess, '.Breakpoints.Value')) % special handling for Breakpoint
                        casParamsFromDD(end) = [];
                        nCountDDParams = nCountDDParams - 1; % erase last entry, avoid bulk writing of Breakpoints
                        fprintf(hFid, 'setValue(hEntry, %s);\n', sNameVal);
                        fprintf(hFid, 'clear %s;\n', sNameVal); % clear handle to avoid ambiguities
                    end
                end
            end
        end
        
        if bUsesTLDD
            i_setValueInDD(hFid, stTlMetaInfo.sAccessPath, stTlMetaInfo.sCalValueSource, bUsesTlVariants)
        end
        
    end
    clear ep_sl_type_info_get;

    if ~isempty(sSlddName)
        
        %loop to create an array containing all changed SLDD params/vars
        for i = 1:numel(casParamsFromDD)
            fprintf(hFid, 'casParamsFromDD{%i}=''%s'';\n', i, casParamsFromDD{i});
        end
        %significantly improved simulation init perfomance by bulk-writing updated values to SLDD
        if ~isempty(casParamsFromDD)
            fprintf(hFid, 'importFromBaseWorkspace(hDictionary, ''varList'', ...\n');
            fprintf(hFid, '\tcasParamsFromDD, ''existingVarsAction'', ''overwrite'', ...\n');
            fprintf(hFid, '\t''clearWorkspaceVars'', true);\n');
        end
        
        %clean up the messy base WS after completion
        fprintf(hFid, 'clear hDictionary;\n');
        fprintf(hFid, 'clear hSection;\n');
        fprintf(hFid, 'clear hEntry;\n');
        fprintf(hFid, 'clear i_if_*;\n');
        fprintf(hFid, 'clear casParamsFromDD;\n');
    end
    
    %     if bModelWorkspaceUsed
    %         %find distinct model workspaces being used
    %         for i=1:length(casModelWS)
    %             i_restore_model_ws(fid, casModelWS{i});
    %         end
    %     end
    
end
end


%%
function sIdx = i_addIndexOffset(sIdx, sStartIdx)
if ~isempty(sStartIdx)
    iStartIdx = str2double(sStartIdx);
    if (iStartIdx ~= 1)
        sIdx = int2str(str2double(sIdx) - iStartIdx + 1);
    end
end
end


%%
function sIndexAccess = i_getIndexAccess(sStartIdx, sIndex1, sIndex2)
if isempty(sIndex1)
    sIndexAccess = '';
else
    sIndex1 = i_addIndexOffset(sIndex1, sStartIdx);
    if isempty(sIndex2)
        sIndexAccess = sprintf('(%s)', sIndex1);
    else
        sIndex2 = i_addIndexOffset(sIndex2, sStartIdx);
        sIndexAccess = sprintf('(%s,%s)', sIndex1, sIndex2);
    end
end
end


%%
function stVarInfo = i_prepare_info_struct
% default output
stVarInfo = struct( ...
    'bCachedInWs',   false,...
    'bFromSLDD',     false,...
    'sVarType',      '',...
    'sVarAccess',    '',...
    'bIsParamType',  false,...
    'bEmbeddedFi',   false,...
    'stTypeInfo',    []);
end


%%
function i_setValueInDD(fid, sDdPath, sValue, bIsWithVariants)
if (isempty(sDdPath) || isempty(sValue))
    return;
end

fprintf(fid, 'xValue = evalin(''base'', ''%s'');\n', sValue);

% now take care of the active variant index for variable
aiVariantIDs = [];
if bIsWithVariants
    aiVariantIDs = i_getActiveVariantIDs(sDdPath);
end
if ~isempty(aiVariantIDs)
    % just to be sure set for all variables corresponding to the available data variants
    for i = 1:numel(aiVariantIDs)
        fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', double(xValue), %i);\n', sDdPath, aiVariantIDs(i));
        atgcv_m13_dsdd_error_handling(fid);
    end
end
fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', double(xValue));\n', sDdPath);
atgcv_m13_dsdd_error_handling(fid);
end


%%
function aiActiveVariantIds = i_getActiveVariantIDs(sDdPath)
hDataVariant = dsdd('GetDataVariant', sDdPath);
if isempty(hDataVariant)
    aiActiveVariantIds = [];
else
    aiActiveVariantIds = dsdd('GetDataVariantIDs', hDataVariant);
end
end


%%
function bUsesVariants = i_checkTlVariantState
%checks if variants are used
bUsesVariants = ~isempty(dsdd('GetDataVariants'));
end


%%
function casListModelWS = i_listDistinctModelWS(ahSourceNodes)
jNameSet = java.util.HashSet;
casListModelWS = {};
for i=1:length(ahSourceNodes)
    sModelName = mxx_xmltree('get_attribute', ahSourceNodes(i), 'file');
    %we make use of this add guard since it is more efficient than on-board ML methods
    if ~jNameSet.contains(sModelName)
        jNameSet.add(sModelName);
        %create the list itself
        casListModelWS{end+1} = sModelName; %#ok<AGROW>
    end
end
end


%%
function i_backupModelWs(fid, sModel)
sNameWS = ['handleWS_' sModel];
sMatFileName = [sModel 'WSBackup.mat'];
fprintf(fid, '%s = get_param(''%s'', ''ModelWorkspace'');\n', sNameWS, sModel);
fprintf(fid, '%s.DataSource=''MAT-File'';\n', sNameWS);
fprintf(fid, '%s.FileName=''%s'';\n', sNameWS, sMatFileName);
fprintf(fid, '%s.saveToSource;\n', sNameWS);
end

% %%
% function i_restore_model_ws(fid, sModel)
% sNameWS = ['handleWS_' sModel];
% sMatFileName = [sModel 'WSBackup.mat'];
% fprintf(fid, '%s.reload;\n', sNameWS);
% fprintf(fid, '%s.DataSource=''Model File'';\n', sNameWS);
% fprintf(fid, 'clear %s;\n', sNameWS);
% fprintf(fid, 'delete %s;\n', sMatFileName);
% end