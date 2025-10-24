function [hSub, sOrigSubsysPath, sNewSubsysPath, mModelRefCopyMap, bIsScopeIntegrated] = atgcv_m13_subsys_add(stEnv, ...
    hDestBlock, xSubsystem, bTlModel, iModelRefMode, casPreserveLibLinks, bSubsystemIsOrigModel)
% Entry function to create the MIL extraction model.
%
% Parameters:
%   stEnv           (struct)    Environment structure
%  	hDestBlock      (handle)    Handle of the current extraction block.
%   xSubsystem      (handle)    Subsystem of the model analysis.
%                               (see ModelAnalysis.dtd)
%   bTlModel        (boolean)   true, when model is a TargetLink model
%                               otherwise false.
%   iModelRefMode   (int)       Model Reference Mode (0- Keep refs | 1- Copy refs | 2- Break refs)
%                              
%   casPreserveLibLinks
%                    (cell-array) Defines a list of library names for which the links must not be broken.
%                                 For some libraries it is possible that a link break leads to an invalid
%                                 extraction model. E.g (SimScape). Hence no Simulation is possible.
%                                 Only active if 'BreakLinks' is true
%   bSubsystemIsOrigModel (boolean)  true when the sut is the model level
% Output:
%   hSub            (handle)    Handle to the created(copied) subsystem.
%   sOrigSubsysPath (string)    full model path to the source Subsystem X inside the original model
%   sNewSubsysPath  (string)    full model path to the extracted Subsystem X inside the extraction model
%


%%
% Check if the selected object is a subsystem or a state flow
sKind = ep_em_entity_attribute_get(xSubsystem, 'kind');
bIsScopeIntegrated = true; % default == the original subsystem/model becomes part of the new extraction model
sTmpMdl = 'btc_temp_mdl';

try
    bIsModel = atgcv_m13_is_model(xSubsystem);
    
    hTmpModel = ep_new_model_create(sTmpMdl);
    xOnCleanupCloseTmpMdl = onCleanup(@() close_system(sTmpMdl, 0));
    sDestBlock = getfullname(hTmpModel);
    bIsTopLevel = atgcv_m13_is_toplevel(xSubsystem);
    sOrigSubsysPath = atgcv_m13_path_get(xSubsystem);
    if (bTlModel && bIsTopLevel)
        [sOrigSubsysPath, sMilSimPath] = i_getTLSimFramePath(sOrigSubsysPath);
    end
    
    bIsStateflow = strcmp(sKind, 'STATEFLOW');
    if bIsStateflow
        hSubTmp = i_addSubsystemSF(sDestBlock, sOrigSubsysPath);
        
        stArgs = struct(...
            'stEnv',           stEnv, ...
            'hSub',            hSubTmp, ...
            'iModelRefMode',   iModelRefMode, ...
            'mKnownModelRefs', containers.Map, ...
            'sPostFix',        ['_' getfullname(bdroot(hDestBlock))], ...
            'sTargetDir',      pwd);
        if isempty(casPreserveLibLinks)
            stArgs.casPreserveLibLinks = [];
        else
            stArgs.casPreserveLibLinks = casPreserveLibLinks;
        end
        
        mModelRefCopyMap = ep_model_subsystems_resolve(stArgs);
        
        if (iModelRefMode ~= ep_sl.Constants.KEEP_REFS)
            atgcv_m13_copyfcn_remove(hSubTmp);
        end
    else
        
        if bIsModel
            [hSubTmp, bIsModelRefReplaced] = i_addModelBlockSub( ...
                stEnv, ...
                sDestBlock, ...
                xSubsystem, ...
                iModelRefMode, ...
                casPreserveLibLinks, ...
                bSubsystemIsOrigModel);
            % if the model reference was replaced, the model content has become part of the extraction model;
            % otherwise it's still separate and referenced by the extraction model
            bIsScopeIntegrated = bIsModelRefReplaced;
        else
            hSubTmp = i_addSubsystemSub(stEnv, sDestBlock, sOrigSubsysPath, iModelRefMode, casPreserveLibLinks);
        end
        
        
        stArgs = struct(...
            'stEnv', stEnv, ...
            'hSub', hSubTmp, ...
            'iModelRefMode', iModelRefMode, ...
            'mKnownModelRefs', containers.Map, ...
            'sPostFix', ['_' getfullname(bdroot(hDestBlock))], ...
            'sTargetDir', pwd);
        if isempty(casPreserveLibLinks)
            stArgs.casPreserveLibLinks = [];
        else
            stArgs.casPreserveLibLinks = casPreserveLibLinks;
        end
        
        [mModelRefCopyMap, hSubTmp] = ep_model_subsystems_resolve(stArgs);
        
        if (iModelRefMode ~= ep_sl.Constants.KEEP_REFS)
            atgcv_m13_copyfcn_remove( hSubTmp );
        end
        if (bTlModel && bIsTopLevel)
            
            sTmpMilSimBlock = [sDestBlock, sMilSimPath];
            hMilSimBlock = get_param(sTmpMilSimBlock, 'Handle');
            atgcv_m13_copyfcn_remove(hMilSimBlock);
        end
        atgcv_m13_prepare_subsys(hSubTmp);
    end
    
    if ~(bTlModel && atgcv_m13_is_toplevel(xSubsystem))
        set(hSubTmp, 'Tag', '');
    end
    sDestBlock = getfullname(hDestBlock);
    sSub = getfullname(hSubTmp);
    sSrcName = get(hSubTmp, 'Name');
    hSub = atgcv_m13_add_block(sSub, sDestBlock, sSrcName);
    
    % note: the temporary model has accumulated all model workspaces of the referenced models that have been resolved
    %       --> copy this accumulated workspace into the destination model
    atgcv_m13_mdlbase_copy(hTmpModel, bdroot(hDestBlock));

    % transfer SF data from the tmp model into the destination model
    % do this only for versions <ML2022a because model data structure has changed
    if verLessThan('matlab', '9.12')
        stEmptyEnv = []; % no entering of messages
        bOverwrite = false;
        atgcv_m13_sfdata_transfer(stEmptyEnv, hTmpModel, bdroot(hDestBlock), bOverwrite);
    end
    
    if bTlModel
        % sometimes the CopyFcn of some inner block still puts "Enable" blocks
        % into the copied Subsystem --> WORKAROUND: remove it manually (again)
        atgcv_m13_prepare_subsys( hSub);
    end
    i_unmarkStateflowCharts(sTmpMdl);
    
    % close temporary model
    clear xOnCleanupCloseTmpMdl;
    
    
    if bIsStateflow
        % if we have a SF Chart we copy the SF data from the Parent Sub
        % and then from the SF-Libs (same as for Subsystem)
        sOrigSubsysPath = get_param(sOrigSubsysPath, 'Parent');
    end
    % transfer SF data from the main original model into the destination model
    % do this only for versions <ML2022a because model data structure has changed
    if verLessThan('matlab', '9.12')
        stEmptyEnv = []; % no entering of messages
        bOverwrite = true;
        atgcv_m13_sfdata_transfer(stEmptyEnv, sOrigSubsysPath, sDestBlock, bOverwrite);
    end
       
    if (bTlModel && bIsTopLevel)
        sMappingPath = [sDestBlock, sMilSimPath];
    else
        sMappingPath = getfullname(hSub);
    end
    sNewSubsysPath = sMappingPath;
    
catch exception
    rethrow(exception);
end
end


%%
function hSub = i_addSubsystemSub(stEnv, sDestMdl, sSubsysPath, iModelRefMode, casPreserveLibLinks)
sSrcName = get_param(sSubsysPath, 'Name');
arPosition = get_param(sSubsysPath, 'Position');

if( ~atgcv_debug_status )
    stWarn = warning;
    warning off all;
end
% here are warnings because of the TL copy function
try
    % make sure that the Copy-hook is deactivated (BTS/32860)
    sCopyFcn = get_param(sSubsysPath, 'CopyFcn');
    if isempty(sCopyFcn)
        hSub = atgcv_m13_add_block(sSubsysPath, sDestMdl, sSrcName);
        %extended handling to avoid removal of copy function for blocks taken
        %from library because that is forbidden, linked to customer issue EP-2227
    else
        try
            hSub = atgcv_m13_add_block(sSubsysPath, sDestMdl, sSrcName, '', {'CopyFcn', ''});
        catch oEx
            if strcmp('Simulink:Libraries:CannotChangeLinkedBlkParam', oEx.identifier)
                hSub = atgcv_m13_add_block(sSubsysPath, sDestMdl, sSrcName);
            else
                rethrow(oEx);
            end
        end
    end
    
    if (iModelRefMode ~= ep_sl.Constants.KEEP_REFS)
        if strcmp(get_param(hSub, 'BlockType'), 'ModelReference')
            sFullName = getfullname(hSub);
            atgcv_m13_modelref_replace(stEnv, hSub, false);
            hSub = get_param(sFullName, 'Handle');
        end
    end
catch exception
    if ~atgcv_debug_status
        warning( stWarn );
    end
    rethrow(exception);
end

if ~atgcv_debug_status
    warning( stWarn );
end

% Note: make sure that the subsystems are valid subsystems (precaution)
if (iModelRefMode ~= ep_sl.Constants.KEEP_REFS)
    atgcv_m13_break_linkstatus(hSub, casPreserveLibLinks);
end
try
    atgcv_m13_unmask_block(hSub);
catch exception
    rethrow(exception);
end

set_param(hSub, 'Name', sSrcName);
set_param(hSub, 'Position', arPosition);
end


%%
function [hSub, bIsModelRefReplaced] = i_addModelBlockSub(stEnv, sDestMdl, xSubsystem, iModelRefMode, ...
    casPreserveLibLinks, bSubsystemIsOrigModel)
bIsModelRefReplaced = false;

sName = ep_em_entity_attribute_get(xSubsystem, 'name');
sModelName = ep_em_entity_attribute_get(xSubsystem, 'physicalPath');

if( ~atgcv_debug_status )
    stWarn = warning;
    warning off all;
end
% here are warnings because of the TL copy function
try
    hSub = add_block('built-in/ModelReference', [sDestMdl, '/', sName]);
    set_param(hSub, 'ModelName', sModelName);
    
    if((iModelRefMode ~= ep_sl.Constants.KEEP_REFS) || bSubsystemIsOrigModel)
        if strcmp(get(hSub, 'BlockType'), 'ModelReference')
            sFullName = getfullname(hSub);
            atgcv_m13_modelref_replace(stEnv, hSub, true);
            hSub = get_param(sFullName, 'Handle');
            bIsModelRefReplaced = true;
        end
    else
        sSimMode = i_getSimMode(xSubsystem);
        set_param(hSub, 'SimulationMode', sSimMode);
    end
    
catch exception
    if( ~atgcv_debug_status )
        warning( stWarn );
    end
    rethrow(exception);
end

if( ~atgcv_debug_status )
    warning( stWarn );
end

% Note: make sure that the subsystems are valid subsystems (precaution)
if (iModelRefMode ~= ep_sl.Constants.KEEP_REFS)
    atgcv_m13_break_linkstatus(hSub, casPreserveLibLinks);
end
try
    atgcv_m13_unmask_block(hSub);
catch exception
    rethrow(exception);
end

set_param(hSub, 'Name', sName);
end


%%
function i_unmarkStateflowCharts(sDestMdl)
casStatecharts = ep_find_system(sDestMdl, ...
    'FollowLinks', 'off', ...
    'BlockType',   'SubSystem', ...
    'MaskType',    'Stateflow');
for i = 1:length(casStatecharts)
    sStatechart = casStatecharts{i};
    set_param(sStatechart, 'MaskType', '');
end
end


%%
function hSub = i_addSubsystemSF(sDestMdl, sSubsysPath)
sSrcName = get_param(sSubsysPath, 'Name');
arPosition = get_param(sSubsysPath, 'Position');
if ~atgcv_debug_status
    sWarn = warning;
    warning off all;
end
% here are warnings because of the TL copy function
try
    hSub = atgcv_m13_add_block(sSubsysPath, sDestMdl, sSrcName);
    set_param(hSub,'position',arPosition);
catch exception
    if( ~atgcv_debug_status )
        warning( sWarn );
    end
    rethrow(exception);
end

if ~atgcv_debug_status
    warning( sWarn );
end
% important the library link to hSub should be deleted

linkStatus = get_param(hSub,'LinkStatus');
if any(strcmp(linkStatus, {'inactive','implicit','resolved'}))
    set_param( hSub, 'LinkStatus', 'none' );
end

if any(strcmp(linkStatus, {'inactive','implicit','resolved'}))
    set_param( hSub, 'LinkStatus', 'restore' );
end
end


%%
function [sTLSimFramePath, sMilSimPath] = i_getTLSimFramePath(sSubsysPath)
% assumption: TL toplevel system means sSubsysPath has at least three slashes
% (looks like '.../toplevel/Subsystem/Subsystem/Subsystem')
% cut sSubsysPath before second last slash
try
    aSlashLocations = strfind(sSubsysPath, '/');
    nNumberSlashes = length(aSlashLocations);
    sMilSimPath = sSubsysPath(aSlashLocations(nNumberSlashes-2):end);
    sTLSimFramePath = sSubsysPath(1:aSlashLocations(nNumberSlashes-1)-1);
    
    % check if subsys exists and if tag is 'TargetLink Simulation Frame'
    sSubsysTag = get_param(sTLSimFramePath, 'Tag');
    if strcmp(sSubsysTag, 'TargetLink Simulation Frame')
        % everything ok, TL Sim frame found
        return
    end
catch
    % nothing to do here
end
end


%%
function sSimMode = i_getSimMode(xScope)
sScopePath = ep_em_entity_attribute_get( xScope, 'path');
sModelName = regexprep(sScopePath, '/.*', '');
sModelRefName = regexprep(atgcv_m13_path_get( xScope ), '/.*', '');
[~, casPaths] = ep_find_mdlrefs(sModelName);
casPathsEscaped = strcat('^', regexptranslate('Escape', casPaths), '$');
sBlockPathToModelRef = sScopePath;
while ~strcmp(sScopePath, sModelRefName)
    sBlockPathToModelRef = sScopePath;
    iIdx = find(~cellfun('isempty',regexp(sScopePath,  casPathsEscaped, 'ONCE')));
    if isempty(iIdx)
        sSimMode = 'normal';
        return;
    end
    sScopePath = regexprep(sScopePath, casPathsEscaped{iIdx}, get_param(casPaths{iIdx}, 'ModelName'));
end
sSimMode = get_param(sBlockPathToModelRef, 'SimulationMode');
end

