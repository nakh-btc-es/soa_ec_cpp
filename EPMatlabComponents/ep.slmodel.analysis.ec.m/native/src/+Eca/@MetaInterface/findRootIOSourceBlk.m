function hBlk = findRootIOSourceBlk(oItf)
% findRootIoSourceBlk
hBlk = [];

if ~isempty(oItf.externalSourcePortHandle)
    lh = get(oItf.externalSourcePortHandle, 'Line');
else
    lh = get(oItf.internalSourcePortHandle, 'Line');    
end
hBlk = i_find_sourceblock(oItf, lh);
end


%%
function hBlk = i_find_sourceblock(oItf, lh)
if (isempty(lh) || lh == -1)
    hBlk = [];
    return;
end
sRootModel = i_getRootModel(lh);

if strcmp(oItf.kind,'IN')
    hBlk = get(lh,'SrcBlockHandle');
    %find the connected block
    if strcmp(get(hBlk, 'BlockType'), 'Inport')
        sParSys = get(hBlk, 'Parent');
        if ~strcmp(sParSys, sRootModel)
            pn = str2double(get(hBlk,'Port'));
            phs = get(get_param(sParSys, 'handle'), 'PortHandles');
            inph = phs.Inport(pn);
            lh = get(inph, 'Line');
            if lh ~= -1
                hBlk  = i_find_sourceblock(oItf, lh);
            end
        end
    else
        %check if is From block and cross it
        if strcmp(get(hBlk, 'BlockType'), 'From')
            lh = i_crossGotoFrom(hBlk);
            hBlk = i_find_sourceblock(oItf, lh);
        else
            hBlk = [];
        end
    end
elseif strcmp(oItf.kind, 'OUT')
    hBlk = get(lh,'DstBlockHandle');
    %find the connected destination blocks (could be multiple)
    bIdx = strcmp(get(hBlk, 'BlockType'), 'Outport');
    if any(bIdx)
        iSel = find(bIdx); hBlk = hBlk(iSel(1)); % Pick one of them
        sParSys = get(hBlk, 'Parent');
        if ~strcmp(sParSys, sRootModel)
            pn = str2double(get(hBlk,'Port'));
            phs = get(get_param(sParSys, 'handle'), 'PortHandles');
            inph = phs.Outport(pn);
            lh = get(inph, 'Line');
            hBlk = i_find_sourceblock(oItf, lh);
        end
    else
        %check if is Goto block and cross it (only 1 Goto is supported as destination blk)
        if numel(hBlk) == 1 && strcmp(get(hBlk, 'BlockType'), 'Goto')
            lh = i_crossGotoFrom(hBlk);
            hBlk = i_find_sourceblock(oItf, lh);
        elseif strcmp(get(hBlk, 'BlockType'), 'Merge')           
            lh = i_crossMergeBlock(hBlk);
            hBlk = i_find_sourceblock(oItf, lh);            
        else
            hBlk = [];
        end
    end
else
    hBlk = [];
end
end


%%
function lh = i_crossGotoFrom(hBlk)
% hBlk : handle of the Goto (resp. From block)
% lh: handle of the line connected on the Goto outport (resp. From inport)

lh = [];
if strcmp(get(hBlk, 'BlockType'), 'Goto')
    % if Goto block
    sTag = get(hBlk,'Gototag');
    casSys = ep_core_feval('ep_find_system', get(hBlk, 'Parent'), ...
        'Searchdepth', 1, ...
        'Blocktype',   'From', ...
        'Gototag',     sTag);
    if ~isempty(casSys) && numel(casSys)==1 % Only one From block as destination is supported
        hDstBlock = get_param(char(casSys), 'handle');
        phdls = get(hDstBlock, 'PortHandles');
        outph = phdls.Outport;
        lh = get(outph, 'Line');
        if isequal(lh, -1)
            lh = [];
        end
    end
    
else
    % if starting point is From
    sTag = get(hBlk,'Gototag');
    casSys = ep_core_feval('ep_find_system', get(hBlk, 'Parent'), ...
        'Searchdepth', 1, ...
        'Blocktype',   'Goto', ...
        'Gototag',     sTag);
    if ~isempty(casSys)
        hDstBlock = get_param(char(casSys), 'handle');
        phdls = get(hDstBlock, 'PortHandles');
        inph = phdls.Inport;
        lh = get(inph, 'Line');
        if isequal(lh, -1)
            lh = [];
        end
    end
end
end


%%
function lh = i_crossMergeBlock(hBlk)

lh = []; %Line handle of the Merge output signal
if ~isempty(hBlk)
    phdls = get(hBlk, 'PortHandles');
    outph = phdls.Outport;
    lh = get(outph, 'Line');
    if isequal(lh, -1)
        lh = [];
    end
end
end


%%
% note: xModelElement can be block diagram, block, port, ... (either as handle or as full path)
function sRootModel = i_getRootModel(xModelElement)
sRootModel = '';
if ~isempty(xModelElement)
    try %#ok<TRYNC>
        sRootModel = get_param(bdroot(xModelElement), 'Name');
    end
end
end