function ep_simenv_eval_logged_values(xEnv, simlabel, sLoggingFile, sDerivedVecName)
% Evaluate the TL_SIL logging data
%
% function ep_simenv_eval_logged_values(xEnv, simlabel, sLoggingFile, sDerivedVecName)
%
%   INPUT               DESCRIPTION
%
%   OUTPUT              DESCRIPTION
%
%


%%
xLoggingInfo = mxx_xmltree('load', sLoggingFile);
xOnCleanupCloseDoc = onCleanup(@() mxx_xmltree('clear', xLoggingInfo));


xLoggingAnalysis = mxx_xmltree('get_root', xLoggingInfo);
ahLogging = mxx_xmltree('get_nodes', xLoggingAnalysis, '//Logging');

nLengthLogs = length(ahLogging);
if (nLengthLogs > 0)
    bSuccess = true;
    
    i_simHandle('reset');
    for i = 1:nLengthLogs
        hLogging = ahLogging(i);
        
        sKind = mxx_xmltree('get_attribute', hLogging, 'kind');
        
        ahAccess = mxx_xmltree('get_nodes', hLogging, './/Access');
        for j = 1:length(ahAccess)
            hAccess = ahAccess(j);
            
            [bIfSuccess] = i_evalData(xEnv, simlabel, hLogging, hAccess, sKind);
            
            if ~bIfSuccess
                bSuccess = false;
                sDisplayName = mxx_xmltree('get_attribute', hAccess, 'displayName');
                xEnv.addMessage('ATGCV:SLAPI:LOGGING_WARNING', 'name', sDisplayName );
            end
        end
    end
    if ~bSuccess
        xEnv.throwException(xEnv.addMessage('ATGCV:SLAPI:LOGGING_NO_VECTOR', 'name', sDerivedVecName));
    end
else
    % TODO: replace with its own message!!!!
    xEnv.throwException(xEnv.addMessage('ATGCV:SIM:TL_LOGGING_LIMITATION'));
end
end


%%
function [simHandle, msgStruct] = i_simHandle(sCmd)
persistent p_simHandle;
persistent p_msgStruct;

switch sCmd
    case 'reset'
        [p_simHandle, p_msgStruct] = i_getSimHandle();
        simHandle = p_simHandle;
        msgStruct = p_msgStruct;
    case 'get'
        if (isempty(p_simHandle) && isempty(p_msgStruct))
            [simHandle, msgStruct] = i_simHandle('reset');
        else
            simHandle = p_simHandle;
            msgStruct = p_msgStruct;
        end
    otherwise
        error('ATGCV:INTERNAL:ERROR', 'Unknown command "%s".', sCmd);
end
end


%%
function [simHandle, msgStruct] = i_getSimHandle()
bTL40 = atgcv_version_compare('TL4.0') >= 0;
boardName = 'HostPC';
if( bTL40 )
    [simHandle, msgStruct] = tlSimInterface('ConnectToSimPlatform', 'BoardName', boardName);
else
    [simHandle, msgStruct] = tl_sim_interface('ConnectToSimPlatform', 'BoardName', boardName);
end
end

%%
function [bSuccess, adData, adTimes] = i_eval_cal_block_data(sTLBlock, sTLBlockVariable, sIndex1, sIndex2)
bSuccess = false;
adData = [];
adTimes = 0;
[simHandle, msgStruct] = i_simHandle('get');
if ~isempty(msgStruct)
    return;
end
bTL40 = atgcv_version_compare('TL4.0') >= 0;

if( ~isempty( simHandle ) )
    if( bTL40  )
        [varInfo, msgStruct] = tlSimInterface('GetBlockVarAddr', ...
            simHandle, 'TLBlock', sTLBlock, 'TLBlockVariable', sTLBlockVariable);
    else
        [varInfo, msgStruct] = tl_sim_interface('GetBlockVarAddr', ...
            simHandle, 'TLBlock', sTLBlock, 'TLBlockVariable', sTLBlockVariable);
    end
    if ~isempty(msgStruct)
        return;
    end
    if( ~isempty( varInfo ) )
        if( bTL40 )
            [adValues, msgStruct] = tlSimInterface('Read', simHandle, 'VarInfos', varInfo);
        else
            [adValues, msgStruct] = tl_sim_interface('Read', simHandle, 'VarInfos', varInfo);
        end
        if isempty(msgStruct)
            if( ~isempty(sIndex1) )
                if( ~isempty(sIndex2) )
                    adData = adValues(str2double(sIndex1),str2double(sIndex2));
                else
                    adData = adValues(str2double(sIndex1));
                end
            else
                adData = adValues;
            end
            bSuccess = true;
            return;
        end
    end
end
end


%%
function [bSuccess, adData, adTimes] = i_eval_cal_ddvar_data( sDDVarPath, nDDVarIndex, sIndex1, sIndex2 )
bSuccess = false;
adData = [];
adTimes = 0;
[simHandle, msgStruct] = i_simHandle('get');
if ~isempty(msgStruct)
    return;
end
bTL40 = atgcv_version_compare('TL4.0') >= 0;
if ~isempty(simHandle)
    iRenameIdx = [];
    aiIdx = dsdd('GetAutoRenamePropertyIndices', sDDVarPath, 'VariantVariableRef');
    if ~isempty(aiIdx)
        if (nDDVarIndex > 0) && (numel(aiIdx) >= nDDVarIndex)
            iRenameIdx = aiIdx(nDDVarIndex);
        else
            iRenameIdx = aiIdx(1);
        end
    end
    
    if ~isempty(iRenameIdx)
        hDDVar = dsdd('GetVariantVariableRef', sDDVarPath, iRenameIdx);
        if ~isempty(hDDVar)
            if bTL40
                [varInfo, msgStruct] = tlSimInterface('GetDDVarAddr', simHandle, 'DDVariables', hDDVar);
            else
                [varInfo, msgStruct] = tl_sim_interface('GetDDVarAddr', simHandle, 'DDVariables', hDDVar);
            end
        else
            return;
        end
    else
        if( bTL40 )
            [varInfo, msgStruct] = tlSimInterface('GetDDVarAddr', simHandle, 'DDVariables', sDDVarPath);
        else
            [varInfo, msgStruct] = tl_sim_interface('GetDDVarAddr', simHandle, 'DDVariables', sDDVarPath);
        end
    end
    if ~isempty(msgStruct)
        return;
    end
    if ~isempty(varInfo)
        if bTL40
            [adValues, msgStruct] = tlSimInterface('Read', simHandle, 'VarInfos', varInfo);
        else
            [adValues, msgStruct] = tl_sim_interface('Read', simHandle, 'VarInfos', varInfo);
        end
        if isempty(msgStruct)            
            if ~isempty(sIndex1)
                if ~isempty(sIndex2)
                    adData = adValues(str2double(sIndex1), str2double(sIndex2));
                else
                    adData = adValues(str2double(sIndex1));
                end
            else
                adData = adValues;
            end
            
            bSuccess = true;
            return;
        end
    end
end
end


%%
function [bSuccess, adData, adTimes] = i_eval_logdata(simlabel, sBlock, sSignalName, sIndex1, sIndex2)
bSuccess = false;
adData = [];
adTimes = 0;
signallogdata = [];
if ~isempty(simlabel)
    signallogdata = ep_simenv_tlds_get_logged_signal(simlabel, sBlock, sSignalName);
end
if (length(signallogdata) == 1)
    bSuccess = true;
    
    stData = signallogdata.signal;
    adTimes = stData.t;
    adValues = stData.y;
    
    if ~isempty(sIndex1)
        if ~isempty(sIndex2)
            adData = adValues(str2double(sIndex1), str2double(sIndex2), :);
        else
            adData = adValues(str2double(sIndex1), :);
        end
    else
        adData = adValues;
    end
end
end


%%
function [bSuccess] = i_evalData(xEnv, simlabel, hLogging, hAccess, sKind)

try
    sIndex1 = mxx_xmltree('get_attribute', hAccess, 'index1');
    sIndex2 = mxx_xmltree('get_attribute', hAccess, 'index2');
    sIfId = mxx_xmltree('get_attribute', hAccess, 'ifid');
    if strcmpi(sKind, 'Parameter')
        % Calibration
        bSuccess = false;
        sTLBlockVariable = mxx_xmltree('get_attribute', hLogging, 'blockUsage');
        if ~isempty(sTLBlockVariable)
            sTLBlock = mxx_xmltree('get_attribute', hLogging, 'block');
            [bSuccess, adData, adTimes] = i_eval_cal_block_data(sTLBlock, sTLBlockVariable, sIndex1, sIndex2);
        else
            sStateflowVar = mxx_xmltree('get_attribute', hLogging, 'stateflowVariable');
            if ~isempty(sStateflowVar)
                sChart = mxx_xmltree('get_attribute', hLogging, 'chart');
                sModule =  mxx_xmltree('get_attribute', hLogging, 'module');
                
                
                hDDVar = i_findStateflowVar(sModule, sChart, sStateflowVar);
                if ~isempty(hDDVar)
                    nDDVarIndex = 0;
                    sDDVarPath = dsdd('GetAttribute', hDDVar, 'path');
                    [bSuccess, adData, adTimes] = i_eval_cal_ddvar_data(sDDVarPath, nDDVarIndex, sIndex1, sIndex2);
                end
            end
        end
        
        if ~bSuccess
            sDDPath = mxx_xmltree('get_attribute', hLogging, 'ddPath');
            sDDVarPath = mxx_xmltree('get_attribute', hLogging, 'ddVarPath');
            if ~isempty(sDDVarPath) && dsdd('Exist', sDDVarPath)
                nDDVarIndex = 0;
                if ~isempty(sDDPath)
                    nDDVarIndex = i_getActiveVariantIndexForReferencesWithAutorename(sDDPath);
                end
                [bSuccess, adData, adTimes] = i_eval_cal_ddvar_data(sDDVarPath, nDDVarIndex, sIndex1, sIndex2);
            end
        end
    else
        sBlock      = mxx_xmltree('get_attribute', hLogging, 'block');
        sSignalName = mxx_xmltree('get_attribute', hLogging, 'signalName');
        [bSuccess, adData, adTimes] = i_eval_logdata(simlabel, sBlock, sSignalName, sIndex1, sIndex2);
    end
    
    
    if bSuccess
        if isequal(length(adTimes), length(adData))
            sMatFile = mxx_xmltree('get_attribute', hAccess, 'matFile');
                       
            if isobject(adData)
                adData = cast(adData, 'double');
            end
            xValue(1,:) = adTimes;
            xValue(2,:) = adData;
            if (ep_core_version_compare('ML7.13') >= 0 && false) % TODO: why de-activated?????????
                content = matfile(sMatFile, 'Writable', true);
                setfield(content, sIfId, xValue);%#ok
            else
                assignin('base', sIfId, xValue);
                evalin('base', sprintf('save(''%s'', ''%s'')', sMatFile, sIfId));
                evalin('base', sprintf('clear ''%s'';', sIfId));
            end
            clear xValue; % necessary because of the loop of outputs
        else
            % warning will be issued in calling function
            bSuccess = false;
        end
    end
    if (~bSuccess)
        disp('stop');
    end
catch oEx
    bSuccess = false;
    xEnv.addMessage(...
        'ATGCV:MIL_GEN:INTERNAL_ERROR', ...
        'script', mfilename(), ...
        'text', [oEx.identifier, ' ', oEx.message]);
end
end


%%
function iActiveIdx = i_getActiveVariantIndexForReferencesWithAutorename(sDdPath)
iActiveIdx = 0; % default index=0 if no active idx found

hDataVariant = dsdd('GetDataVariant', sDdPath);
if isempty(hDataVariant)
    return;
end

% NOTE: currently it's not possible to determine the correct instance of the VariantVariableRef
% pointing to exactly the CAL variant instance that was used by the code
% --> for now it's OK to use the first found one (because the Harness of EP is setting *all* instances
% to the same calibration value)
iActiveIdx = 1;
end


%%
function hDDVar = i_findStateflowVar(sModule, sChart, sStateflowVar)
hDDVar = [];
sDDRoot = ['//DD0/Subsystems/', sModule];
[bExist, hDDRoot] = dsdd('Exist', sDDRoot);
if bExist
    hDDChart = dsdd('Find', hDDRoot, ...
        'property', {'Name', 'BlockType', 'Value' 'Stateflow'}, ...
        'property', {'Name', 'BlockName', 'Value', sChart});
    
    if ~isempty(hDDChart)
        hDDBlockVar = i_findBlockVarInChart(hDDChart, sStateflowVar);
        if ~isempty(hDDBlockVar)
            hDDVar = dsdd('GetVariableRef', hDDBlockVar);
        end
    end
end
end


%%
function hDDBlockVar = i_findBlockVarInChart(hDDChart, sVar)
hDDBlockVar = [];

hDDSfNodes = dsdd('GetStateflowNodes', hDDChart);
if ~isempty(hDDSfNodes)
    casNodes = {'Input', 'Output', 'BlockVariable'};
    for i = 1:length(casNodes)
        sCmd = ['Get', casNodes{i}, 'RefTarget'];
        hDDBlockVar = dsdd(sCmd, hDDSfNodes, sVar);
        if ~isempty(hDDBlockVar)
            return;
        end        
    end
end
end

