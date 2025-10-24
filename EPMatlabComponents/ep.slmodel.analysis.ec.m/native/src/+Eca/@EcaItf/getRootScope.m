function oRootScope = getRootScope(oEca)
% Search for the root scope

oRootScope = [];
stCfgAnalysis = oEca.stActiveConfig;
oScope = Eca.MetaScope;

%Get subsystem or modelblock
sRootScopePath = oEca.searchTopLevelSubsystemsAndModelblocks();
if ~isempty(sRootScopePath)
    oScope.bIsRootScope = true;
    
    sType = get_param(sRootScopePath, 'Type');
    if strcmp(sType, 'block_diagram')
        oScope.bScopeIsModel = true;
    else
        oScope.bScopeIsSubsystem  = strcmp(get_param(sRootScopePath, 'BlockType'), 'SubSystem');
        oScope.bScopeIsModelBlock = ~oScope.bScopeIsSubsystem;
    end
    
    %Subsystem info
    oScope.sSubSystemName = get_param(sRootScopePath, 'Name');
    oScope.sSubSystemFullName = sRootScopePath;
    if oScope.bScopeIsModelBlock
        oScope.sSubSystemAccess = get_param(sRootScopePath, 'ModelName');
        oScope.sSubSystemModelRef = sRootScopePath;
    else
        oScope.sSubSystemAccess = sRootScopePath;
    end
    oScope.nHandle = get_param(sRootScopePath, 'handle');
    oScope.nSampleTime = oEca.dModelSampleTime;
    oScope.sCodegenPath = oEca.sCodegenPath;
    
    % transfer codegen data from main object to root (TODO: check if this can be avoided)
    oScope.astCodegenSourcesFiles = oEca.astCodegenSourcesFiles;
    oScope.casCodegenHeaderFiles  = oEca.casCodegenHeaderFiles;
    oScope.casCodegenIncludePaths = oEca.casCodegenIncludePaths;
    oScope.astDefines = oEca.astDefines;
    
    
    % C-Function information
    stFuncInfo = [];

    % Use Code Descriptor
    oEca.oCodeDescSubInfoMap = i_getCodeDescSubInfoMap(oEca.sModelName, fileparts(oEca.sCodegenPath));
    
    [bIsExpFun, sFuncName] = i_isExportedFunc(oEca, oScope);
    if bIsExpFun
        stFuncInfo = oEca.getCodeInfoExportFunc(oScope, sFuncName);
        
    elseif (oScope.bScopeIsModel || stCfgAnalysis.ScopeCfg.RootScope.ForceUseOfModelStepFunc)
        stFuncInfo = oEca.getCodeInfoModel();
        if (stFuncInfo.bHasFuncArgs)
            stInfo = ep_core_feval('ep_ec_scope_code_info_get', oEca.sModelName);
            if stInfo.bIsValid
                oScope.mPort2Var = stInfo.mPort2Var;
            end
        end
        
    else
        if oScope.bScopeIsSubsystem
            stFuncInfo = oEca.getCodeInfoSubsystem(oScope);
            
        elseif oScope.bScopeIsModelBlock
            stFuncInfo = oEca.getCodeInfoModelRef(oScope);
            
        end
    end
    
    if ~isempty(stFuncInfo)
        % Prestep function
        sPreStepFunc = oEca.sPreStepCFunctionName;
        if ~isempty(sPreStepFunc)
            stFuncInfo.sPreStepCFunctionName = sPreStepFunc;
        end
        
        casAttributes = fieldnames(stFuncInfo);
        for m = 1:numel(casAttributes)
            sAttribute = casAttributes{m};
            oScope.(sAttribute) = stFuncInfo.(sAttribute);
        end
    end
    
    if oEca.bDiagMode
        sLink = sprintf('<a href = "matlab:open_system(''%s'');hilite_system(''%s'')">%s</a>',...
            oEca.sModelName, oScope.sSubSystemFullName, oScope.sSubSystemFullName);
        fprintf('\n## Root Scope %s has been detected \n',sLink);
    end
    
    
    
    % Interfaces
    oScope = oEca.getInterfaces(oScope);
    
    % Children scopes (note: not for the WRAPPER analysis mode)
    if ~oEca.isWrapperMode()
        oScope.oaChildrenScopes = oEca.getChildrenScopes(oScope);
    end
    oRootScope = oScope;
end
end


%%
function oCodeDescSubInfoMap = i_getCodeDescSubInfoMap(sModelName, sCodegenPath)
sPwd = pwd;
bSwitchBack = false;
if ~strcmp(pwd, sCodegenPath)
    cd(sCodegenPath);
    bSwitchBack = true;
end

% Get Code Descriptor information
oCodeDescSubInfoMap = ep_core_feval('ep_ec_code_desc_subs_info_get', sModelName);

if bSwitchBack
    cd(sPwd);
end
end


%%
function [bTrue, sFunName] = i_isExportedFunc(oEca, oScope)
bTrue = false;
sFunName = '';
if oScope.bScopeIsModel
    return;
end

bHasMatchGraphicalInterface = oEca.oCodeDescSubInfoMap.isKey(oScope.sSubSystemAccess);
if bHasMatchGraphicalInterface
    return;
end

stSubSysPh = get(oScope.nHandle, 'PortHandles');
if ~isempty(stSubSysPh.Trigger)
    stTrigPortProps = get(stSubSysPh.Trigger);
    bIsFunctionTrigger = strcmp(stTrigPortProps.CompiledPortDataType, 'fcn_call');
    if bIsFunctionTrigger
        %Search for connected "Inport" block on root level
        hSrcBlk = i_find_src_inport_block(stTrigPortProps.Line, oEca.sModelName);
        bTrue = ~isempty(hSrcBlk);
        if bTrue
            sFunName = get(hSrcBlk, 'Name');
        end
    end
end
end


%%
function hSrcBlk = i_find_src_inport_block(lh, sModelName)
%Find the connected Inport block which is sending a Function-call signal.
%Recursive search from bottom-up
hSrcBlk = get(lh, 'SrcBlockHandle');
if ~isempty(hSrcBlk)
    if strcmp(get(hSrcBlk, 'BlockType'), 'Inport')
        if ~strcmp(get(hSrcBlk, 'OutputFunctionCall'), 'on')
            par = get(hSrcBlk, 'Parent');
            if strcmp(par, sModelName)
                hSrcBlk = [];
            else
                pn = str2double(get(hSrcBlk, 'Port'));
                phs = get(get_param(par, 'handle'), 'PortHandles');
                inph = phs.Inport(pn);
                lh = get(inph, 'Line');
                hSrcBlk  = i_find_src_inport_block(lh, sModelName);
            end
        end
    else
        hSrcBlk = [];
    end
end
end