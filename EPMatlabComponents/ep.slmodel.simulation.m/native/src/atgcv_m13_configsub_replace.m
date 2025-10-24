function nReplaceCnt = atgcv_m13_configsub_replace(stEnv, hBlock, casPreserveLibLinks)
% Replace configurable subsystem with the user choosen subsystem.
%
% function atgcv_m13_configsub_replace(stEnv, hBlock, casPreserveLibLinks)
%
% INPUTS             DESCRIPTION
%   hBlock           (handle)     Simulink block.
%   casPreserveLibLinks
%                     (cell-array) Defines a list of library names for which the links must not be broken.
%                                  For some libraries it is possible that a link break leads to an invalid 
%                                  extraction model. E.g (SimScape). Hence no simulation is possible.
%                                  Only active if 'BreakLinks' is true
%

%%
if (nargin < 3)
    casPreserveLibLinks = {};
end
atgcv_m13_break_links(hBlock, casPreserveLibLinks);
aoSubsystems = ep_find_system(hBlock,...
    'LookUnderMasks', 'all', ...
    'RegExp',         'on', ...
    'BlockType',      'SubSystem', ...
    'TemplateBlock',  '.*');
nReplaceCnt = length( aoSubsystems );

if( nReplaceCnt > 0 )
    hSubsystem = aoSubsystems(1);
    
    sName = get( hSubsystem, 'Name' );
    hParent = get( hSubsystem, 'Parent' );
    % now check if subsystem is a template subsystem
    sTemplate = get( hSubsystem, 'TemplateBlock' );
    if( ~isempty( sTemplate ) )
        sChoiceBlock = get( hSubsystem, 'BlockChoice' );
        if( ~isempty( sChoiceBlock ) )
            sReplaceBlock = [get_param( sTemplate, 'Parent' ), ...
                '/',sChoiceBlock ];
            hReplaceBlock = get_param( sReplaceBlock, 'Handle' );
            
            % now replace the replacement block with template block
            anPos = get_param( hSubsystem, 'Position' );
            
            sBlockName = [ getfullname( hParent), '/btc_temp' ];
            hRepSub = add_block('built-in/SubSystem', sBlockName);
            
            sBlockName = [ getfullname(hRepSub), '/btc_temp' ];
            hRepBlock = add_block(getfullname( hReplaceBlock ), sBlockName);
            set( hRepBlock, 'Name', sChoiceBlock);
            
            % copy inputs and outputs to subsystem block
            % and add lines
            i_copyPorts(hSubsystem, hRepBlock);
            atgcv_m13_copy_mask_info(stEnv, hRepSub, hSubsystem );
            
            % Save Link data
            stDialogParameters = [];
            astLinkData = get_param(hSubsystem, 'LinkData');
            if ~isempty(astLinkData)
                casBlockNames = {astLinkData.BlockName};
                sBlockChoice = get_param(hSubsystem, 'BlockChoice');
                abMatches = strcmp(casBlockNames, sBlockChoice);
                if any(abMatches)
                    stDialogParameters = ...
                        astLinkData(abMatches).DialogParameters;
                end
            end
            
            % Find and break port-block links
            ahPortBlocks = ep_find_system(hRepSub, ...
                'SearchDepth', 1, ...
                'regexp',      'on', ...
                'blocktype',   'port');
            
            for i = 1:length(ahPortBlocks)
                atgcv_m13_break_links(ahPortBlocks(i), casPreserveLibLinks);
            end
            
            % Replace configurable subsystem with new block
            delete_block( hSubsystem );
            set( hRepSub, 'Name', sName);
            set( hRepSub, 'Position', anPos );
            
            % Set LinkData
            if ~isempty(stDialogParameters)
                hParamSub = ep_find_system(hRepSub, ...
                    'SearchDepth', 1, ...
                    'Name',        sBlockChoice);
                
                casNames = get_param(hParamSub, 'MaskNames');
                if ~iscell(casNames)
                    casNames = {casNames};
                end
                
                casMaskValues = get_param(hParamSub, 'MaskValues');
                
                for i = 1:length(casNames)
                    if isfield(stDialogParameters, casNames{i})
                        casMaskValues{i} = ...
                            stDialogParameters.(casNames{i});
                    end
                end
                
                set_param(hParamSub, 'MaskValues', casMaskValues);
            end
        end
    end
    
    nReplaceCntSub = atgcv_m13_configsub_replace(stEnv, hBlock, casPreserveLibLinks);
    nReplaceCnt = nReplaceCnt + nReplaceCntSub;
end
end



%%
% copy Ports from Subsystem hConfigSub into Parent Subsystem of hChildBlock
% and add_line between all equally named Ports
%
function i_copyPorts(hConfigSub, hChildBlock)
sTemplPath  = getfullname(hConfigSub);
sParentPath = get_param(hChildBlock, 'Parent');
sChildName  = get_param(hChildBlock, 'Name');

set_param(hChildBlock, 'Position', ...
    get_param([sTemplPath, '/', sChildName], 'Position'));

% IMPORTANT: look for Ports in the original ConfigSubsystem
% --> this yields an _ordered_ list of Ports with the _correct_ PortNumber
%     ordering
% --> copying the Ports in _this_ particular order automatically transfers
%     the same PortNumber to the copied Ports
ahInports = ep_find_system(hConfigSub, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      'Inport');
for i = 1:length(ahInports)
    sName = get_param(ahInports(i), 'Name');
    sSrc  = [sTemplPath,  '/', sName];
    sDest = [sParentPath, '/', sName];
    
    add_block(sSrc, sDest, 'Position', get_param(sSrc, 'Position'));
end
ahOutports = ep_find_system(hConfigSub, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      'Outport');
for i = 1:length(ahOutports)
    sName = get_param(ahOutports(i), 'Name');
    sSrc  = [sTemplPath,  '/', sName];
    sDest = [sParentPath, '/', sName];
    
    add_block(sSrc, sDest, 'Position', get_param(sSrc, 'Position'));
end


% now look for the same Ports in the ChildBlock (== BlockChoice)
%
% IMPORTANT: The PortNumbers may _differ_ from the Ports that were copied
%            from the ConfigSub! So the Port ordering _must_not_ be used
%            for connecting the Inport/Outports and the BlockChoice.
%
% --> Instead, the correct Mapping can be established via the same Port-Name.
%
ahInports = ep_find_system(hChildBlock, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      'Inport');
for i = 1:length(ahInports)
    sName = get_param(ahInports(i), 'Name');
    nPort = str2double(get_param(ahInports(i), 'Port'));
    
    atgcv_m13_add_line(sParentPath, sName, 1, sChildName, nPort);
end

ahOutports = ep_find_system(hChildBlock, ...
    'LookUnderMasks', 'all', ...
    'FollowLinks',    'on', ...
    'SearchDepth',    1, ...
    'BlockType',      'Outport');
for i = 1:length(ahOutports)
    sName = get_param(ahOutports(i), 'Name');
    nPort = str2double(get_param(ahOutports(i), 'Port'));
    
    atgcv_m13_add_line(sParentPath, sChildName, nPort, sName, 1);
end
end


