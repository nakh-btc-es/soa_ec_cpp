function hPort = findParentRunnableExternalPort(oItf)
hPort = i_findSourcePort(oItf, oItf.externalSourcePortHandle);
end

% Find source port
function ph_out = i_findSourcePort(oItf, ph_in)
ph_out = [];
if strcmp(oItf.kind, 'IN')
    sParSys = get(ph_in, 'Parent');
    if strcmp(sParSys, oItf.sParentRunnablePath)
        ph_out = ph_in;
    else
        lnh = get(ph_in, 'Line');
        if lnh ~= -1
            hBlk = get(lnh, 'SrcBlockHandle');
            if strcmp(get(hBlk, 'BlockType'), 'Inport')
                sParSys = get(hBlk, 'Parent');
                sType = get_param(sParSys, 'Type');
                if strcmp(sType, 'block_diagram')
                    % we are on model-level and cannot go further up: this Inport must be the source block
                    phdls = get(get_param(hBlk, 'handle'), 'PortHandles');
                    ph_out = phdls.Outport(1);
                else
                    pnum = str2double(get(hBlk, 'Port'));
                    phdls = get(get_param(sParSys, 'handle'), 'PortHandles');
                    ph_out = i_findSourcePort(oItf, phdls.Inport(pnum));
                end
            else
                %check if is From block and cross it
                if strcmp(get(hBlk, 'BlockType'), 'From')
                    hBlk = i_crossGotoFrom(hBlk);
                    if ~isempty(hBlk)
                        phdls = get(hBlk, 'PortHandles');
                        ph_out = i_findSourcePort(oItf, phdls.Inport);
                    end
                end
            end
        end
    end
elseif strcmp(oItf.kind, 'OUT')
    sParSys = get(ph_in, 'Parent');
    if strcmp(sParSys, oItf.sParentRunnablePath)
        ph_out = ph_in;
    else
        lnh = get(ph_in, 'Line');
        if lnh ~= -1
            hBlk = get(lnh, 'DstBlockHandle');
            %find the connected destination blocks (could be multiple)
            abIdx = strcmp(get(hBlk, 'BlockType'), 'Outport');
            if any(abIdx)
                iSel = find(abIdx); 
                hBlk = hBlk(iSel(1)); % Pick one of them
                sParSys = get(hBlk, 'Parent');
                
                sType = get_param(sParSys, 'Type');
                if strcmp(sType, 'block_diagram')
                    % we are on model-level and cannot go further up: this Outport must be the destination block
                    phdls = get(get_param(hBlk, 'handle'), 'PortHandles');
                    ph_out = phdls.Inport(1);
                else
                    pnum = str2double(get(hBlk, 'Port'));
                    phdls = get(get_param(sParSys, 'handle'), 'PortHandles');
                    ph_out = i_findSourcePort(oItf, phdls.Outport(pnum));
                end                
            else
                %check if is Goto block and cross it (only 1 Goto is supported as destination blk)
                if numel(hBlk) == 1 && strcmp(get(hBlk, 'BlockType'), 'Goto')
                    ahBlk = i_crossGotoFrom(hBlk);
                    for i = 1:length(ahBlk)
                        phdls = get(ahBlk(i), 'PortHandles');
                        ph_out = i_findSourcePort(oItf, phdls.Outport);
                        if ~isempty(ph_out)
                            break;
                        end
                    end
                end
            end
        end
    end
end
end


%%
% hBlk : handle of the Goto (resp. From block)
% hDstBlock: handle of corresponding From block (resp. Goto block)
function ahDstBlock = i_crossGotoFrom(hBlk)
ahDstBlock = [];
if strcmp(get(hBlk, 'BlockType'), 'Goto')
    % if Goto block
    sTag = get(hBlk,'Gototag');
    casSys = ep_core_feval('ep_find_system', get(hBlk, 'Parent'), ...
        'Searchdepth', 1, ...
        'Blocktype',   'From', ...
        'Gototag',     sTag);
    if ~isempty(casSys)
        ahDstBlock = zeros(1, length(casSys));
        for i = 1:length(casSys)
            ahDstBlock(i) = get_param(char(casSys{i}), 'handle');
        end
    end
else
    % if starting point is From
    sTag = get(hBlk,'Gototag');
    casSys = ep_core_feval('ep_find_system', get(hBlk, 'Parent'), ...
        'Searchdepth', 1, ...
        'Blocktype', 'Goto', ...
        'Gototag', sTag);
    if ~isempty(casSys)
        ahDstBlock = get_param(char(casSys), 'handle');
    end
end
end

