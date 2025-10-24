function ep_tl_debug_mode_settings(stEnv, sExportDir, sModelName, bSilMode, bEnableTLHook, bSelfContained)
% Sets the TL SIL mode to the given model
%
% function ep_tl_debug_mode_settings(stEnv, sExportDir, sModelName,
% sMatFileName, bSilMode, bEnableTLHook, bSelfContained) 
%
%   INPUT               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sExportDir           (string)    Location of the the extraction model
%   sModelName           (string)    Model name of the TL model
%   sMatFileName         (string)    MAT file to load the initial values.
%   bSilMode             (logical)   TRUE if TL model should be put in 
%                                    TL_SIL mode
%   bEnableTLHook        (logical)   Enable/Disable TL hook
%   bSelfContained       (logical)   set for self-contained mode
%   OUTPUT              DESCRIPTION
%   none



%%
sPwd = pwd;
xOnCleanupReturn = onCleanup(@() cd(sPwd));
cd(sExportDir);

if ~bEnableTLHook
    atgcv_m46_hookfct_tl_delete(sExportDir);
end

%% Load and initialize the model
[sPath, sModel] = fileparts(sModelName);
if ~isempty(sPath)
    return;
end

% Note: the name of the DD is _assumed_ to be the same as the model name
%       --> this is only true for the exported ET MIL Models
sOrigDD = fullfile(sExportDir, [sModel, '.dd']);
i_assertLoadedDD(stEnv, sOrigDD);
try
    i_adaptFunctions(sModel);
    
    atgcv_m46_adapt_addfile_location(sModel);
    if bSelfContained
        i_adaptBlockOutputs(sModel);

        atgcv_m46_calibration_info_set(stEnv, sExportDir);

        atgcv_m46_storage_class_set(stEnv);
    end

catch
    stError = lasterror; %#ok
    atgcv_throw( stError );
end

atgcv_m46_tl_sil_compile(stEnv, sModel, sOrigDD, bSilMode);

end

%%
function i_assertLoadedDD(stEnv, sOrigDD)
sLoadedDD = dsdd('GetDDAttribute', 0, 'fileName');
if ~strcmpi(sLoadedDD, sOrigDD)
    stError = osc_messenger_add(stEnv, ...
            'ATGCV:MDEBUG_ENV:INVALID_ACTIVE_DD', ...
            'ModelDD',  sOrigDD, ...
            'ActiveDD', sLoadedDD);
    osc_throw(stError);
end
end


%%
function i_adaptBlockOutputs(sModel)
xBlockMap = containers.Map;
xFixedNameMap = containers.Map;
caoBlocks = tl_get_blocks(sModel, 'TargetLink');
nLength = length(caoBlocks);
for i = 1:nLength
    oBlock = caoBlocks(i);
    
    try
        sName = tl_get(oBlock, 'output.name');
    catch
        continue;
    end
    
    % TODO: find out why ExpressionMacros found in name need to be changed
    if ~isempty(strfind(sName, '$E'))
        tl_set(oBlock, 'output.name', '$S_$B');
        continue;
    end
    
    % change pure BlockMacros "$B"
    %    when breaking Lib links, pure BlockMacros "$B" can produces issues
    if strcmp(sName, '$B')
        sBlockName = get(oBlock, 'Name');
        
        if isKey(xBlockMap, sBlockName)
            xBlockMap(sBlockName) = [xBlockMap(sBlockName), {oBlock}];
        else
            xBlockMap(sBlockName) = {oBlock};
        end        
       continue;
    end

    % no name Macro used at all
    %  can be dangerous if by breaking the links, the variable is used in
    %  multiple locations but is not MERGEABLE
    if (~isempty(sName) && ~any(sName == '$') && isempty(tl_get(oBlock, 'output.variable')))
        if ~i_check_extern_macro_class(oBlock)
            if isKey(xFixedNameMap, sName)
                xFixedNameMap(sName) = [xFixedNameMap(sName), {oBlock}];
            else
                xFixedNameMap(sName) = {oBlock};
            end
        end
    end
end

casBlockNames = keys(xBlockMap);
for i = 1:length(casBlockNames)
    sBlockName = casBlockNames{i};
    caoSameNameBlocks = xBlockMap(sBlockName);
    
    if (length(caoSameNameBlocks) > 1)
        for k = 1:length(caoSameNameBlocks)
            oBlock = caoSameNameBlocks{k};
            tl_set(oBlock, 'output.name', '$S_$B');
        end
    end
end

casNames = keys(xFixedNameMap);
for i = 1:length(casNames)
    sName = casNames{i};
    caoNameBlocks = xFixedNameMap(sName);
    
    if (length(caoNameBlocks) > 1)
        for k = 1:length(caoNameBlocks)
            oBlock = caoNameBlocks{k};
            tl_set(oBlock, 'output.name', '$S_$B');
        end
    end
end
end



%%
function bExternMacro = i_check_extern_macro_class(oBlock)
% BTS/34216
% CHECK IF CLASS of the type is not extern macro
bExternMacro = false;
try
    sClass = tl_get( oBlock, 'output.class' );
    if( ~isempty( sClass ) )
        hClass = dsdd('find','//DD0/Pool/VariableClasses', ...
            'objectkind','VariableClass', 'name', sClass);
        sStorage = dsdd( 'Get', hClass, 'Storage');
        dMacro = dsdd( 'Get', hClass, 'Macro');
        bMacroOn = isequal(dMacro,1);
        bExtern = strcmp(sStorage, 'extern') ;
        if (bExtern && bMacroOn)
            bExternMacro = true;
        end
    end
catch
    bExternMacro = false;
end
end    


%%
function i_adaptFunctions(sModel)
% assumption: just _one_ TL Subsystem
casTopSub = ep_find_system(sModel, 'LookUnderMasks', 'on', 'Tag', 'MIL Subsystem');
if isempty(casTopSub)
    return;
end
sTopSub = getfullname(casTopSub{1});

casFunction = ep_find_system(sTopSub, ...
    'LookUnderMasks', 'all',...
    'FollowLinks',    'off',...
    'MaskType',       'TL_Function');


% TODO check if valid for all TL versions
for i = 1:length(casFunction)
    sFunction = casFunction{i};

    % Set that no incrementental code generation is done
    tl_set(sFunction, 'incrcodegen', 0);

    % Check for shared subsystems
    if (tl_get(sFunction, 'forcereuse') == 1)
        % switch off reuse (shared subsystems are not allowed)
        tl_set(sFunction, 'forcereuse', 0);

        % force that function names are different
        % set for all the default names
        sNewFuncName = '$S_$B';
        sNewInitFuncName = 'INIT_$S_$B';
        tl_set(sFunction, 'stepfunctionname', sNewFuncName);
        tl_set(sFunction, 'initfunctionname', sNewInitFuncName);
        tl_set(sFunction, 'subsystemid', 'default');
    end
    % to prevent warnings set the parent subsystem
    % to an atomic subsystem
    sParent = get_param(sFunction, 'Parent');
    set_param(sParent, 'TreatAsAtomicUnit', 'on');
end
end

