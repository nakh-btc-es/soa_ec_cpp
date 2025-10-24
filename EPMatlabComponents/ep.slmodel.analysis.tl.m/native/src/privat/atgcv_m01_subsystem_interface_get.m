function stInterface = atgcv_m01_subsystem_interface_get(stEnv, hSub)
% Get interface of a subsystem in DD.
%
% function stInterface = atgcv_m01_subsystem_interface_get(stEnv, hSub)
%
%   INPUT           DESCRIPTION
%     stEnv            (struct)    error environment
%     hSub             (handle)    DD handle of Subsystem
%
%   OUTPUT          DESCRIPTION
%     stInterface      (struct)    interface of subsystem
%        .astInports   (array)       array of structs with inport info
%        .astOutports  (array)       array of structs with outport info
%
%   both arrays have following structure:
%     stPort           (struct)    info for single port
%        .iPortNumber  (integer)      port number in model
%        .sSlPortPath  (string)       model path to Simulink port
%        .sPortKind    (string)       kind of Port (Inport, Outport, FcnCallPort, ...)
%        .sBlockType   (string)       type of Port (TL_Inport, TL_Outport, ...)
%        .hBlock       (handle)       DD handle of Port
%        .astSignals   (array)        structs describing the individual signals of port
%


%% main
% default port info
stPort = struct( ...
    'iPortNumber',  [],  ...
    'sSlPortPath',  '',  ...
    'sPortKind',    '',  ...
    'sBlockType',   '',  ...
    'hBlock',       [],  ...
    'astSignals',   []);

% default interface info
stInterface = struct( ...
    'astInports',  repmat(stPort, 0, 0), ...
    'astOutports', repmat(stPort, 0, 0));

% find all ports
ahPortRefs = i_getAllPortReferences(stEnv, hSub);
for i = 1:length(ahPortRefs)
    hPortRef = ahPortRefs(i);
    
    sKind  = atgcv_mxx_dsdd(stEnv, 'GetKind', hPortRef);    
    hBlock = atgcv_mxx_dsdd(stEnv, 'GetBlockRef', hPortRef);
    
    if ~any(strcmpi(sKind, {'Outport', 'Inport'}))
        % extra check for kind: trigger/enable/action ports
        % use this kind of port only if it maps to a valid Simulink Port
        % Example: sKind is FcnCallPort but the signal is passed through a Simulink-Inport into the Subystem
        hPort = atgcv_mxx_dsdd(stEnv, 'Find', hBlock, 'name', 'Port');
        if isempty(hPort)
            continue;
        end
    end
    iPortNumber = atgcv_mxx_dsdd(stEnv, 'GetPortPortNumber', hBlock);
    sBlockType  = atgcv_mxx_dsdd(stEnv, 'GetBlockType', hBlock); 
    
    sSlPortPath = dsdd_get_block_path(hBlock);
    sSlBlockType = get_param(sSlPortPath, 'BlockType');    
    if any(strcmpi(sSlBlockType, {'Outport', 'Inport'}))
        stPort = struct( ...
            'iPortNumber', iPortNumber, ...
            'sSlPortPath', sSlPortPath, ...
            'sPortKind',   sKind, ...
            'sBlockType',  sBlockType, ...
            'hBlock',      hBlock, ...
            'astSignals',  atgcv_m01_block_output_signals_get(stEnv, hBlock));
        if strcmpi(sSlBlockType, 'Outport')
            stInterface.astOutports(end + 1) = stPort;
        else
            stInterface.astInports(end + 1) = stPort;
        end
    end
end

% sort according to port number
if (length(stInterface.astInports) > 1)
    aiPortNumber = [stInterface.astInports(:).iPortNumber];
    [~, aiSort] = sort(aiPortNumber);
    stInterface.astInports = stInterface.astInports(aiSort);
end
if (length(stInterface.astOutports) > 1)
    aiPortNumber = [stInterface.astOutports(:).iPortNumber];
    [~, aiSort] = sort(aiPortNumber);
    stInterface.astOutports = stInterface.astOutports(aiSort);
end
end



%%
function ahPortRefs = i_getAllPortReferences(stEnv, hSub)
hGroupInfo = atgcv_mxx_dsdd(stEnv, 'GetGroupInfo', hSub);
if (~isempty(hGroupInfo) && dsdd('Exist', 'Ports', 'Parent', hGroupInfo))
    hPorts = atgcv_mxx_dsdd(stEnv, 'GetGroupInfoPorts', hSub);
    ahPortRefs = atgcv_mxx_dsdd(stEnv, 'GetChildren', hPorts);
else
    ahPortRefs = [];
end
end


