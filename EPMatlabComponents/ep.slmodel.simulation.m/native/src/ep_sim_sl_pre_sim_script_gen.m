function ep_sim_sl_pre_sim_script_gen(stEnv, sDestMdlName, xSubsystem, nUsage, iModelRefMode, oProgress )
% Generates the pre-simulation script for SL
%
% function ep_sim_sl_pre_sim_script_gen(stEnv, sDestMdl, xSubsystem, nUsage, iModelRefMode, oProgress )
%
% INPUTS:
%     ...          (...)     ...
%
% OUTPUTS:
%
%

%% internal
% AUTHOR(S):
%   Remmer.Wilts@btc-es.de
%   Kristof.Woll@btc-es.de
% $$$COPYRIGHT$$$-2006
%
%%

ahCalibration = mxx_xmltree('get_nodes', xSubsystem, './Calibration');
if isempty(ahCalibration)
    % without Calibrations nothing to do --> early return
    return;
end

sResultPath = pwd();
if isstruct(stEnv)
    sResultPath = stEnv.sResultPath;
end


% make name unique to avoid problems of "shadowing" in Matlab
sPreSimScriptName = sprintf('%s_pre_sim', sDestMdlName);
sPreSimScriptFile = fullfile(sResultPath, [sPreSimScriptName, '.m']);

% open file
hFid = fopen(sPreSimScriptFile, 'wt');
xOnCleanupFile = onCleanup(@() fclose(hFid));

i_createInitScriptHeader(hFid, sPreSimScriptName);
i_initCalWSVars(hFid, ahCalibration);
i_setExternCal(stEnv, hFid, xSubsystem, nUsage, iModelRefMode, sDestMdlName, oProgress);
end


%%
function i_initCalWSVars(fid, ahCalibration)

fprintf(fid, '%% Initialization of WS variables in order to make model compilable.\n');
for i=1:length(ahCalibration)
   ahIfNames = mxx_xmltree('get_nodes', ahCalibration(i),  './Variable/ifName');
   for j=1:length(ahIfNames)
       sIfid = mxx_xmltree('get_attribute', ahIfNames(j), 'ifid');
       sInitValue = mxx_xmltree('get_attribute', ahIfNames(j), 'initValue');
       sVarName = sprintf('i_%s', sIfid);
       sLine = sprintf('if ~exist(''%s'', ''var''), evalin(''base'', ''%s = [0, %s];''); end', sVarName, sVarName, sInitValue);
       fprintf(fid, '%s\n', sLine);
   end
end
end


%%
function i_createInitScriptHeader(fid, sInitScriptName)
ep_simenv_print_script_header(fid, sInitScriptName, 'This file contains the initialization of the MIL simulation.');
end


%%
function i_setExternCal(stEnv, fid, xSubsystem, nUsage, iModelRefMode, sDestMdlName, oProgress)
bLegacyML = verLessThan('matlab', '9.5');

bBreakModelRefs = iModelRefMode == ep_sl.Constants.BREAK_REFS;

bUseTl = isequal(nUsage, 1);
if bUseTl
    bIsWithVariants = ~isempty(dsdd('GetDataVariants')) || ~isempty(dsdd('GetCodeVariants'));
else
    bIsWithVariants = false; % not really needed for bUseTL=false, but anyhow
end

astSatSwitchInfo = repmat(struct( ...
    'sBlockName',     '', ...
    'xCalibration',   '', ...
    'bModelRef',      false,...
    'sBlockVariable', '',...
    'sUsage',         '', ...
    'sType',          '', ...
    'sValue',         ''), 0, 0);

ahCalibrations = mxx_xmltree('get_nodes', xSubsystem, './Calibration');
if ~isempty(ahCalibrations)
    % use some unusual name for temporary var
    sTmpNamePrefix = 'btc_tmp_calxxx';
    
    %check if we need to tune model workspace parameters
    ahModelWsNodes = mxx_xmltree('get_nodes', xSubsystem, './Calibration/Source[@kind=''ModelWorkspace'']');
    bModelWorkspaceUsed = ~isempty(ahModelWsNodes);
        
    if bModelWorkspaceUsed
        switch (iModelRefMode)
            case ep_sl.Constants.BREAK_REFS
                i_initModelWs(fid, sDestMdlName);
                
            otherwise
                %find distinct model workspaces being used
                casModelWS = i_listDistinctModelWS(ahModelWsNodes);
                for i=1:length(casModelWS)
                    i_initModelWs(fid, casModelWS{i});
                end
        end
    end
            
    nCalLength = length(ahCalibrations);
    atgcv_progress_set(oProgress, 'current', 0, 'total', nCalLength);
    for i = 1:nCalLength
        hCalibration = ahCalibrations(i);
        atgcv_progress_set(oProgress, 'current', i);
        
        sValue = atgcv_m13_cal_value_get(hCalibration);
        sCalVarNameIntoSimModel = atgcv_m13_object_block_get(hCalibration, bBreakModelRefs);
        
        sUsage = mxx_xmltree('get_attribute', hCalibration, 'origin');
        if ~strcmp(sUsage, 'explicit_param')
            % UseCase: Limited Blockset Calibration
            
            ahModelContextNodes = mxx_xmltree('get_nodes', hCalibration, './CalibrationUsage');
            
            for j = 1:length(ahModelContextNodes)
                hModelContextNode = ahModelContextNodes(j);
                
                [sCalVarNameIntoSimModel, sModelRef] = atgcv_m13_object_block_get(hModelContextNode, bBreakModelRefs);
                bModelRef = false;
                if ~isempty(sModelRef)
                    bModelRef = true;
                end
                
                if any(strcmp(sUsage, {'sf_const', 'sf_param'}))
                    atgcv_m13_sf_calibrate_set(stEnv, fid, ...
                        hCalibration, hModelContextNode,...
                        sCalVarNameIntoSimModel, bModelRef);
                elseif bUseTl && strcmp(sUsage,'switch_threshold')
                    nCriteria = tl_get(sCalVarNameIntoSimModel, 'threshold.criteria');
                    
                    % if criteria to passing the first input is not equal 'u2~=0'
                    % the block should be not calibrated.
                    if (nCriteria~=3)
                        sBlockValue = get_param( sCalVarNameIntoSimModel, 'threshold' );
                        sType = i_evaluateExpressionType(sBlockValue);
                        sBlockName= atgcv_var2str(sCalVarNameIntoSimModel);
                        i_fprintfSetBlockParameter(fid, sType, sBlockName, sValue, 'threshold', bModelRef);
                        sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'threshold.variable');
                        i_setValueInDD(fid, sDDPath, sValue, bIsWithVariants);
                    end
                    
                    % in this case, the block is a target link saturation block
                elseif( ~bUseTl && any(strcmp(sUsage, {'sat_lower','sat_upper'})) ||...
                        any(strcmp(sUsage, {'sat_lower','sat_upper'})) )
                    [sSettingParameter,sBlockVariable] = atgcv_m13_cal_parameter_get(sUsage);
                    astSatSwitchInfo(end + 1).sBlockName = ...
                        atgcv_var2str(sCalVarNameIntoSimModel); %#ok<AGROW>
                    astSatSwitchInfo(end).xCalibration =  hCalibration;
                    astSatSwitchInfo(end).bModelRef = bModelRef;
                    if strcmp(sUsage,'sat_lower')
                        sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter );
                        sType = i_evaluateExpressionType(sBlockValue);
                        sTypeValue = sprintf('%s(%s)', sType, sValue);
                        astSatSwitchInfo(end).sUsage = 'LowerLimit';
                        astSatSwitchInfo(end).sType = sType;
                        astSatSwitchInfo(end).sValue = sTypeValue;
                        astSatSwitchInfo(end).sBlockVariable = sBlockVariable;
                        astSatSwitchInfo(end).sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'lowerlimit.variable');
                    elseif strcmp(sUsage,'sat_upper')
                        sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter );
                        sType = i_evaluateExpressionType(sBlockValue);
                        sTypeValue = sprintf('%s(%s)', sType, sValue);
                        astSatSwitchInfo(end).sUsage = 'UpperLimit';
                        astSatSwitchInfo(end).sType = sType;
                        astSatSwitchInfo(end).sValue = sTypeValue;
                        astSatSwitchInfo(end).sBlockVariable = sBlockVariable;
                        astSatSwitchInfo(end).sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'upperlimit.variable');
                    end
                    
                    % In this case the block might be a simulink or target link Relay block.
                    % The OnSwitchValue and OffSwitchValue parameters must be
                    % calibrated at the same time.
                elseif any(strcmp(sUsage,{'relay_switch_on','relay_switch_off'}))
                    [sSettingParameter,sBlockVariable] = atgcv_m13_cal_parameter_get(sUsage);
                    astSatSwitchInfo(end + 1).sBlockName = ...
                        atgcv_var2str(sCalVarNameIntoSimModel); %#ok<AGROW>
                    astSatSwitchInfo(end).xCalibration =  hCalibration;
                    astSatSwitchInfo(end).bModelRef = bModelRef;
                    if strcmp(sUsage,'relay_switch_on')
                        sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter );
                        sType = i_evaluateExpressionType(sBlockValue);
                        sTypeValue = sprintf('%s(%s)', sType, sValue);
                        astSatSwitchInfo(end).sUsage = sSettingParameter;
                        astSatSwitchInfo(end).sType = sType;
                        astSatSwitchInfo(end).sValue = sTypeValue;
                        astSatSwitchInfo(end).sBlockVariable = sBlockVariable;
                        astSatSwitchInfo(end).sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'onswitch.variable');
                    elseif strcmp(sUsage,'relay_switch_off')
                        sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter);
                        sType = i_evaluateExpressionType(sBlockValue);
                        sTypeValue = sprintf('%s(%s)', sType, sValue);
                        astSatSwitchInfo(end).sUsage = sSettingParameter;
                        astSatSwitchInfo(end).sType = sType;
                        astSatSwitchInfo(end).sValue = sTypeValue;
                        astSatSwitchInfo(end).sBlockVariable = sBlockVariable;
                        astSatSwitchInfo(end).sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'offswitch.variable');
                    end
                elseif any(strcmp(sUsage,{'relay_out_on', 'relay_out_off'}))
                    [sSettingParameter,sBlockVariable] = atgcv_m13_cal_parameter_get(sUsage);
                    astSatSwitchInfo(end + 1).sBlockName = ...
                        atgcv_var2str(sCalVarNameIntoSimModel); %#ok<AGROW>
                    astSatSwitchInfo(end).xCalibration =  hCalibration;
                    astSatSwitchInfo(end).bModelRef = bModelRef;
                    if strcmp(sUsage,'relay_out_on')
                        sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter);
                        sType = i_evaluateExpressionType(sBlockValue);
                        sTypeValue = sprintf('%s(%s)', sType, sValue);
                        astSatSwitchInfo(end).sUsage = sSettingParameter;
                        astSatSwitchInfo(end).sType = sType;
                        astSatSwitchInfo(end).sValue = sTypeValue;
                        astSatSwitchInfo(end).sBlockVariable = sBlockVariable;
                        astSatSwitchInfo(end).sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'onoutput.variable');
                    elseif strcmp(sUsage,'relay_out_off')
                        sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter);
                        sType = i_evaluateExpressionType(sBlockValue);
                        sTypeValue = sprintf('%s(%s)', sType, sValue);
                        astSatSwitchInfo(end).sUsage = sSettingParameter;
                        astSatSwitchInfo(end).sType = sType;
                        astSatSwitchInfo(end).sValue = sTypeValue;
                        astSatSwitchInfo(end).sBlockVariable = sBlockVariable;
                        astSatSwitchInfo(end).sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'offoutput.variable');
                    end
                elseif strcmp(sUsage,'gain')
                    [sSettingParameter, ~] = atgcv_m13_cal_parameter_get(sUsage);
                    sBlockName = atgcv_var2str(sCalVarNameIntoSimModel);
                    sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter );
                    sType = i_evaluateExpressionType(sBlockValue);
                    i_fprintfSetBlockParameter(fid, sType, sBlockName, ...
                        sValue, sSettingParameter, bModelRef);
                    sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'gain.variable');
                    i_setValueInDD(fid, sDDPath,sValue, bIsWithVariants);
                    
                else
                    % get the adequate parameter to set.
                    [sSettingParameter, ~] = atgcv_m13_cal_parameter_get(sUsage);
                    sBlockValue = get_param( sCalVarNameIntoSimModel, sSettingParameter );
                    sType = i_evaluateExpressionType(sBlockValue);
                    sBlockName = atgcv_var2str(sCalVarNameIntoSimModel);
                    i_fprintfSetBlockParameter(fid, sType, sBlockName, ...
                        sValue, sSettingParameter, bModelRef);
                    sDDPath = i_getDdVarPath(sCalVarNameIntoSimModel, 'output.variable');
                    i_setValueInDD(fid, sDDPath, sValue, bIsWithVariants);
                end
            end
            
        else
            % UseCase: Explicit Parameter Calibration
            
            sVarName = mxx_xmltree('get_attribute', hCalibration, 'name');
            sStartIdx = mxx_xmltree('get_attribute', hCalibration, 'startIdx');
            hSourceNode = mxx_xmltree('get_nodes', hCalibration, './Source');
            
            if ~isempty(hSourceNode)
                sKind = mxx_xmltree('get_attribute', hSourceNode, 'kind');
            else
                sKind = '';
            end
            
            if strcmp(sKind, 'ModelWorkspace') %new special handling for model workspace parameters
                sModelName = mxx_xmltree('get_attribute', hSourceNode, 'file');
                switch (iModelRefMode)
                    case ep_sl.Constants.BREAK_REFS
                        stTypeResult = ep_sim_check_model_ws_param(sVarName, sDestMdlName);
                    otherwise
                        stTypeResult = ep_sim_check_model_ws_param(sVarName, sModelName);
                end
                
                ahIfNames = mxx_xmltree('get_nodes', hCalibration, './Variable/ifName');

                for j = 1:length(ahIfNames)
                    hIfName = ahIfNames(j);
                    sIfName_Id = mxx_xmltree('get_attribute', hIfName, 'ifid');
                    % handling embedded.fi objects
                    if stTypeResult.bEmbeddedFi || (~isempty(stTypeResult.stTypeInfo) && stTypeResult.stTypeInfo.bIsFxp)
                        sValueAssign = sprintf('fi(i_%s(1,2),%s)', sIfName_Id, stTypeResult.stTypeInfo.sEvalType);
                    else
                        VarNode_id = mxx_xmltree('get_nodes', hCalibration, './Variable');
                        bIsSignalTypeEnum = strcmp('yes', mxx_xmltree('get_attribute', VarNode_id, 'isSignalTypeEnum'));
                        if bIsSignalTypeEnum
                            stTypeResult.sVarType =  mxx_xmltree('get_attribute', VarNode_id, 'signalType');
                        end
                        sValueAssign = sprintf('%s(i_%s(1,2))', stTypeResult.sVarType, sIfName_Id);
                    end
                    sIndex1 = mxx_xmltree('get_attribute', hIfName, 'index1');
                    sIndex2 = mxx_xmltree('get_attribute', hIfName, 'index2');
                    sIndexAccess = i_getIndexAccess(sStartIdx, sIndex1, sIndex2);
                    fprintf(fid,'\n%s''%s''\n', '%', ...
                        strrep(sCalVarNameIntoSimModel, char(10), ' '));%#ok
                    switch (iModelRefMode)
                        case ep_sl.Constants.BREAK_REFS
                            sNameWS = ['handleWS_' sDestMdlName];
                        otherwise
                            sNameWS = ['handleWS_' sModelName];
                    end
                    if ~stTypeResult.bIsParamType && ~contains(stTypeResult.sVarAccess, '.Breakpoints.Value')...
                            && ~contains(stTypeResult.sVarAccess, '.Table.Value')
                        fprintf(fid, '%s.assignin(''%s%s'',%s);\n',...
                        sNameWS, stTypeResult.sVarAccess, sIndexAccess, sValueAssign);
                    else
                        if bLegacyML
                            %set value directly in individual model workspace
                            fprintf(fid, '%s.evalin(''%s%s = evalin(''''base'''', ''''%s'''');'');\n',...
                                sNameWS, stTypeResult.sVarAccess, sIndexAccess, sValueAssign);
                        else
                            %set value directly in individual model workspace
                            fprintf(fid, '%s.setVariablePart(''%s%s'',%s);\n',...
                                sNameWS, stTypeResult.sVarAccess, sIndexAccess, sValueAssign);
                        end
                    end
                end
        
            else
                % check if name exists as Workspace variable; write to workspace
                % only if the name is a varname and the  var exists
                % ! do not accept struct-names e.g. 'a.b'
                stExpressionResult = atgcv_m13_expression_info_get(sVarName);
                if ~stExpressionResult.bIsLValue
                    sVarName = '';
                end

                stTypeInfo = [];
                if isempty(sVarName)
                    bWriteToWorkspace = false;
                    sVarName = [sTmpNamePrefix, int2str(i)];
                    sVarType = 'double';
                    bIsSimParam = false;
                    bEmbeddedFi = false;
                    sVarAccess = sVarName;
                else
                    bWriteToWorkspace = true;
                    [sVarType, bIsSimParam, ~, bEmbeddedFi, sVarAccess, stTypeInfo] = ....
                        atgcv_m13_evalinbase_vartype(sVarName);
                end

                % if in TL context AND if we have a DD_path AND DD_path is valid
                % --> write also to DD
                sDdPath = '';
                if bUseTl
                    sDdPath = mxx_xmltree('get_attribute', hCalibration, 'ddPath');
                end
                bWriteToDd = ~isempty(sDdPath) && dsdd('Exist', sDdPath);

                % if no writing to be done at all, take a shortcut here
                if ~bWriteToWorkspace && ~bWriteToDd
                    continue;
                end

                fprintf(fid,'\n%s''%s''\n', '%', ...
                    strrep(sCalVarNameIntoSimModel, newline, ' '));
                % variables of type Simulation.Parameter have to be treated
                % differently
                if bIsSimParam                    
                    sCondition = 'isempty';
                    sParamMin = '[]';
                    sParamMax = '[]';
                    
                    if contains(sVarAccess, '.Breakpoints.Value')
                        sEvalCmd = sprintf( ...
                            'if ~%s(%s.Breakpoints.Min), %s.Breakpoints.Min = %s; end', ...
                            sCondition, sVarName, sVarName, sParamMin);
                        fprintf(fid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                        sEvalCmd = sprintf( ...
                            'if ~%s(%s.Breakpoints.Max), %s.Breakpoints.Max = %s; end', ...
                            sCondition, sVarName, sVarName, sParamMax);
                        fprintf(fid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                    elseif contains(sVarAccess, '.Table.Value')
                        sEvalCmd = sprintf( ...
                            'if ~%s(%s.Table.Min), %s.Table.Min = %s; end', ...
                            sCondition, sVarName, sVarName, sParamMin);
                        fprintf(fid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                        sEvalCmd = sprintf( ...
                            'if ~%s(%s.Table.Max), %s.Table.Max = %s; end', ...
                            sCondition, sVarName, sVarName, sParamMax);
                        fprintf(fid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                    else
                        sEvalCmd = sprintf( ...
                            'if ~%s(%s.Min), %s.Min = %s; end', ...
                            sCondition, sVarName, sVarName, sParamMin);
                        fprintf(fid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                        sEvalCmd = sprintf( ...
                            'if ~%s(%s.Max), %s.Max = %s; end', ...
                            sCondition, sVarName, sVarName, sParamMax);
                        fprintf(fid, 'evalin(''base'', ''%s'');\n', sEvalCmd);
                    end
                end

                % note: even for the case bWriteToWorkspace==false we have
                % to create at least a temporary variable (cleanup later)


                ahIfNames = mxx_xmltree('get_nodes', hCalibration, './Variable/ifName');
                for j = 1:length(ahIfNames)
                    hIfName = ahIfNames(j);
                    sIfName_Id = mxx_xmltree('get_attribute', hIfName, 'ifid');
                    % handling embedded.fi objects
                    if bEmbeddedFi || (~isempty(stTypeInfo) && stTypeInfo.bIsFxp)
                        sValueAssign = sprintf('fi(i_%s(1,2),%s)', sIfName_Id, stTypeInfo.sEvalType);
                    else
                        VarNode_id = mxx_xmltree('get_nodes', hCalibration, './Variable');
                        bIsSignalTypeEnum = strcmp('yes', mxx_xmltree('get_attribute', VarNode_id, 'isSignalTypeEnum'));
                        if bIsSignalTypeEnum
                            sVarType =  mxx_xmltree('get_attribute', VarNode_id, 'signalType');
                        end
                        sValueAssign = sprintf('%s(i_%s(1,2))', sVarType, sIfName_Id);
                    end
                    sIndex1 = mxx_xmltree('get_attribute', hIfName, 'index1');
                    sIndex2 = mxx_xmltree('get_attribute', hIfName, 'index2');
                    sIndexAccess = i_getIndexAccess(sStartIdx, sIndex1, sIndex2);
                    fprintf(fid, 'evalin(''base'', ''%s%s = %s;'');\n', sVarAccess, sIndexAccess, sValueAssign);
                end

                if bWriteToDd
                    if ~bWriteToWorkspace
                        i_setValueInDD(fid, sDdPath, sValue, bIsWithVariants)
                    else
                        % if write to DD and WS, we have to make sure, that the values are identical
                        i_setValueInDD(fid, sDdPath, sValue, bIsWithVariants, sVarType)
                    end
                end

                % if we shouldn't have written to workspace in the first place,
                % now is a good time to cleanup our mess
                if ~bWriteToWorkspace
                    fprintf(fid, 'evalin(''base'', ''clear(''''%s'''');'');\n', sVarName);
                end
            end
        end
    end
    
    if ~isempty(bModelWorkspaceUsed)
        fprintf(fid, 'clear handleWS_*;\n');
    end
    
end
% different strategy because the parameters for SaturationBlock and RelayBlock
% have to be set simultaneously
if isempty(astSatSwitchInfo)
    return;
end
casBlockNames = {astSatSwitchInfo(:).sBlockName};
bAlreadyUsed = false(1, length(astSatSwitchInfo));
for i = 1:length(astSatSwitchInfo)
    if bAlreadyUsed(i)
        continue;
    end
    sBlockName = astSatSwitchInfo(i).sBlockName;
    aiFound = find(strcmp(sBlockName, casBlockNames));
    if (length(aiFound) == 2) || (length(aiFound) == 4)
        i_1 = aiFound(1);
        i_2 = aiFound(2);
        sTypeFir = astSatSwitchInfo(i_1).sType;
        sValueFir = astSatSwitchInfo(i_1).sValue;
        sDDPathFir =  astSatSwitchInfo(i_1).sDDPath;
        
        bModelRef = astSatSwitchInfo(i_1).bModelRef;
        sTypeSec = astSatSwitchInfo(i_2).sType;
        sValueSec = astSatSwitchInfo(i_2).sValue;
        sDDPathSec =  astSatSwitchInfo(i_2).sDDPath;
        
        if (length(aiFound) == 4)
            i_3 = aiFound(3);
            i_4 = aiFound(4);
            
            sTypeThird = astSatSwitchInfo(i_3).sType;
            sValueThird = astSatSwitchInfo(i_3).sValue;
            sDDPathThird =  astSatSwitchInfo(i_3).sDDPath;
            
            sTypeFourth = astSatSwitchInfo(i_4).sType;
            sValueFourth = astSatSwitchInfo(i_4).sValue;
            sDDPathFourth =  astSatSwitchInfo(i_4).sDDPath;
        end
        
        if (length(aiFound) == 2)
            fprintf(fid,'\n%s''%s''\n', '%', astSatSwitchInfo(i_1).sBlockName);
            fprintf(fid,'sValueOp1 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeFir, sValueFir);
            fprintf(fid,'sValueOp2 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeSec, sValueSec);
            if( ~bModelRef )
                fprintf(fid,'set_param(%s,''%s'',sValueOp1,''%s'',sValueOp2);\n\n',...
                    sBlockName, astSatSwitchInfo(i_1).sUsage, astSatSwitchInfo(i_2).sUsage );
            end
            i_setValueInDD(fid, sDDPathFir, sValueFir, bIsWithVariants);
            i_setValueInDD(fid, sDDPathSec, sValueSec, bIsWithVariants);
            bAlreadyUsed(i_1) = true;
            bAlreadyUsed(i_2) = true;
        else
            fprintf(fid,'\n%s''%s''\n', '%', astSatSwitchInfo(i_1).sBlockName);
            fprintf(fid,'sValueOp1 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeFir, sValueFir);
            fprintf(fid,'sValueOp2 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeSec, sValueSec);
            fprintf(fid,'sValueOp3 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeThird, sValueThird);
            fprintf(fid,'sValueOp4 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeFourth, sValueFourth);
            
            if( ~bModelRef )
                fprintf(fid,'set_param(%s,''%s'',sValueOp1,''%s'',sValueOp2,''%s'',sValueOp3,''%s'',sValueOp4);\n\n',...
                    sBlockName,  astSatSwitchInfo(i_1).sUsage, astSatSwitchInfo(i_2).sUsage , ...
                    astSatSwitchInfo(i_3).sUsage, astSatSwitchInfo(i_4).sUsage );
            end
            
            i_setValueInDD(fid, sDDPathFir, sValueFir, bIsWithVariants);
            i_setValueInDD(fid, sDDPathSec, sValueSec, bIsWithVariants);
            i_setValueInDD(fid, sDDPathThird, sValueThird, bIsWithVariants);
            i_setValueInDD(fid, sDDPathFourth, sValueFourth, bIsWithVariants);
            bAlreadyUsed(i_1) = true;
            bAlreadyUsed(i_2) = true;
            bAlreadyUsed(i_3) = true;
            bAlreadyUsed(i_4) = true;
        end
    elseif (length(aiFound) == 1)
        i_1 = aiFound(1);
        sTypeFir = astSatSwitchInfo(i_1).sType;
        sValueFir = astSatSwitchInfo(i_1).sValue;
        sDDPathFir =  astSatSwitchInfo(i_1).sDDPath;
        
        bModelRef = astSatSwitchInfo(i_1).bModelRef;
        
        
        fprintf(fid,'\n%s''%s''\n', '%', astSatSwitchInfo(i_1).sBlockName);
        fprintf(fid,'sValueOp1 = [''%s('',evalin(''base'',''mat2str(%s, 20)''),'')''];\n', sTypeFir, sValueFir);
        if( ~bModelRef )
            fprintf(fid, 'set_param(%s,''%s'',sValueOp1);\n', sBlockName, astSatSwitchInfo(i_1).sUsage);
        end
        i_setValueInDD(fid, sDDPathFir, sValueFir, bIsWithVariants);
        
        bAlreadyUsed(i_1) = true;
    else
        % should never happen!
        error('ATGCV:INTERNAL:ERROR', 'Unexpected number of CAL objects found for block "%s".', sBlockName);
    end
end
end


%%
function aiDataVariantIds = i_getDataVariantIDs(sDdPath)
hDataVariant = dsdd('GetDataVariant', sDdPath);
if isempty(hDataVariant)
    aiDataVariantIds = [];
else
    aiDataVariantIds = dsdd('GetDataVariantIDs', hDataVariant);
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
function [sType, bIsSimParam, bIsSimSignal] = i_evaluateExpressionType(xExpression)
bIsSimParam  = false;
bIsSimSignal = false;

if ischar(xExpression)
    try
        xExpression = evalin('base', xExpression);
    catch
        sType = 'double';
        return;
    end
end

try
    if isa(xExpression, 'Simulink.Parameter')
        bIsSimParam = true;
        sType = xExpression.DataType;
        
    elseif isa(xExpression, 'Simulink.Signal')
        bIsSimSignal = true;
        sType = xExpression.DataType;
        
    else
        sType = class(xExpression);
        
    end
    sType = i_evaluateType(sType);
catch
    % now is default double
    sType = 'double';
end
end

%%
function i_fprintfSetBlockParameter(fid, sType, sBlockName, sValue, sParamName, bModelRef)
sTypeValue = sprintf('%s(%s)', sType, sValue);
fprintf(fid,'\n%s%s\n', '%', sBlockName);
if( ~bModelRef )
    fprintf(fid,'set_param(%s,''%s'',''%s'');\n', sBlockName, sParamName, sTypeValue);
end

end

%%
function sEvalType = i_evaluateType(sType)
sEvalType = sType;
if ~i_isBuiltInSignalType(sEvalType)
    try
        stInfo = ep_sl_type_info_get(sEvalType);
        sEvalType = stInfo.sBaseType;
    catch
        sEvalType = 'double';
    end
end
end

%%
function bIsBuiltIn = i_isBuiltInSignalType(sCheckType)
persistent casTypes;

if isempty(casTypes)
    casTypes = {  ...
        'double', ...
        'single', ...
        'int8',   ...
        'uint8',  ...
        'int16',  ...
        'uint16', ...
        'int32',  ...
        'uint32', ...
        'boolean', ...
        'logical'};
end
bIsBuiltIn = any(strcmpi(sCheckType, casTypes));
end


%%
function sDDVarPath = i_getDdVarPath(sBlock, sAccess)
sDDVarPath = [];
hBlock = get_param( sBlock, 'Handle' );
if ~isempty(hBlock)
    sDDVarPath = tl_get( hBlock, sAccess );
    if ~isempty(sDDVarPath)
        sDDVarPath = ['//DD0/Pool/Variables/', sDDVarPath];
    end
end
end


%%
function i_setValueInDD(fid, sDdPath, sValue, bIsWithVariants, sVarType)
if nargin < 5 || ~i_isOnWhiteList(sVarType)
    sVarType = "double";
end

if (isempty(sDdPath) || isempty(sValue))
    return;
end

fprintf(fid, 'xValue = evalin(''base'', ''%s'');\n', sValue);

if bIsWithVariants
    %we got data variants, handle it in the right way
    if dsdd('ValueIsDataVarianted', sDdPath)
        % now take care of the active variant index for variable
        aiVariantIDs = i_getDataVariantIDs(sDdPath);

        if ~isempty(aiVariantIDs)
            % just to be sure set for all variables corresponding to the available data variants
            for i = 1:numel(aiVariantIDs)
                fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', %s(xValue), %i);\n', sDdPath, sVarType,...
                    aiVariantIDs(i));
                atgcv_m13_dsdd_error_handling(fid);
            end
        end
        fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', %s(xValue));\n', sDdPath, sVarType);
    %we got code variants, different handling    
    elseif dsdd('ValueIsCodeVarianted', sDdPath)
        aoVarVal = dsdd('GetVariantedValues', sDdPath);
        if numel(aoVarVal) == 1
            iActiveInd = aoVarVal.variant;
        else
            aoCodeVar = dsdd('GetCodeVariants');
            iActiveInd = 0;
            for i = 1:numel(aoVarVal)                
                for j = 1:numel(aoCodeVar)
                    if (aoVarVal(i).variant == aoCodeVar(j).variant)
                        iActiveInd = aoCodeVar(j).variant;
                        break;
                    end
                end
                if (iActiveInd ~= 0)
                    break;
                end
            end
        end
        fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', %s(xValue), %i);\n', sDdPath, sVarType, iActiveInd);
    %when there are Variants in the model but not for this variable also set value
    else
        fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', %s(xValue));\n', sDdPath, sVarType);
    end
%also set value in case of no variants    
else
    fprintf(fid, 'nErrorCode = dsdd(''SetValue'', ''%s'', %s(xValue));\n', sDdPath, sVarType);
end

atgcv_m13_dsdd_error_handling(fid);

end


%%
function bIsOnWhiteList = i_isOnWhiteList(sVarType)
casTypeWhiteList = {
    'double', ...
    'single', ...
    'int8', ...
    'int16', ...
    'int32', ...
    'int64', ...
    'uint8', ...
    'uint16', ...
    'uint64'};

bIsOnWhiteList = any(ismember(casTypeWhiteList, sVarType));
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
function i_initModelWs(fid, sModel)
sNameWS = ['handleWS_' sModel];
fprintf(fid, '%s = get_param(''%s'', ''ModelWorkspace'');\n', sNameWS, sModel);
end

