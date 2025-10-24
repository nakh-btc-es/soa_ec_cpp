function [hSFunctionIn, hSFunctionOut] = ep_sim_harness_create_sfunc(stExtrModelInfo, ...
    sHarnessModelFileIn, sHarnessModelFileOut, astBusInfo, bVirtualBusCreationFallback)
% This function creates a simulation harness using SFunction blocks

[hSFunctionIn, hSFunctionOut] = i_create_harness_sfunction(stExtrModelInfo,...
    sHarnessModelFileIn, sHarnessModelFileOut, astBusInfo, bVirtualBusCreationFallback);
end


%%
function [hSubIn, hSubOut] = i_create_harness_sfunction(stExtrModelInfo,...
    sHarnessModelFileIn, sHarnessModelFileOut, astBusInfo, bVirtualBusCreationFallback)
i_copyFiles(stExtrModelInfo.sPath, sHarnessModelFileIn, sHarnessModelFileOut);
sPath = getfullname(stExtrModelInfo.hModel);
hSFunctionIn = i_addSFuncIn(sPath, sHarnessModelFileIn);
hSFunctionOut = i_addSFunctOut(sPath, sHarnessModelFileOut);

oEx = i_compileModel(stExtrModelInfo.sName);
if ~isempty(oEx)
    error('EP:EXTRACTION:INIT_SFUNCS_FAILED', ...
        'Harness S-Functions could not be compiled: %s', oEx.getReport('basic', 'hyperlinks', 'off'));
end

hSubIn = get_param(get_param(hSFunctionIn, 'Parent'), 'handle');
hSubOut = get_param(get_param(hSFunctionOut, 'Parent'), 'handle');

i_create_input_and_output_ports(hSFunctionIn, hSFunctionOut, sHarnessModelFileIn, sHarnessModelFileOut, ...
    astBusInfo, bVirtualBusCreationFallback);

i_setSignalNameOnLine(sHarnessModelFileIn, hSFunctionIn);
end


%%
function oEx = i_compileModel(sModelName)
oEx = [];

stState = warning('off', 'all');
oOnCleanupResetWarnings = onCleanup(@() warning(stState));

try
    eval([sModelName, '([], [], [], ''compile'')']);
    eval([sModelName, '([], [], [], ''term'')']);
catch oEx
end
end


%%
function i_setSignalNameOnLine(sHarnessModelFileIn, hSFunctionBlock)
hHarnessIn = mxx_xmltree('load', sHarnessModelFileIn);
onCleanupCloseHarnessIn = onCleanup(@() mxx_xmltree('clear', hHarnessIn));

ahNodes = mxx_xmltree('get_nodes', hHarnessIn, '/SFunction/Outports//Outport');
for i = 1:numel(ahNodes)
    nPortNr = str2double(mxx_xmltree('get_attribute', ahNodes(i), 'portNr'));
    sSignalName = mxx_xmltree('get_attribute', ahNodes(i), 'signalName');
    if ~isempty(sSignalName)
        stPortHandles = get_param(hSFunctionBlock, 'PortHandles');
        ahOutports = stPortHandles.Outport;
        hLine = get_param(ahOutports(nPortNr), 'Line');
        set_param(hLine, 'Name', sSignalName);
    end
end
end


%%
function i_copyFiles(sPath, sHarnessModelFileIn, sHarnessModelFileOut)
if ~strcmp(fileparts(sHarnessModelFileIn), sPath)
    copyfile(sHarnessModelFileIn, sPath);
    copyfile(sHarnessModelFileOut, sPath );
end
end


%%
function hSFuncIn = i_addSFuncIn(sPath, sHarnessModelFileIn)
hSFuncIn = i_addSFuncGeneric('BTCHarnessIN', 'BTCHarnessIN', 'BTC_SIM_MODEL_INPUTS', sPath, sHarnessModelFileIn);
end


%%
function hSFuncOut = i_addSFunctOut(sPath, sHarnessModelFileOut)
hSFuncOut = i_addSFuncGeneric('BTCHarnessOut', 'BTCHarnessOUT', 'BTC_SIM_MODEL_OUTPUTS', sPath, sHarnessModelFileOut);
end


%%
function hSFuncBlock = i_addSFuncGeneric(sFuncSubName, sSFuncBlockName, sFuncTag, sPath, sHarnessModelFile)
hSubBlock = add_block('built-in/Subsystem', [sPath, '/', sFuncSubName]);
sSubBlockPath = getfullname(hSubBlock);

hSFuncBlock = add_block('built-in/S-Function', [sSubBlockPath, '/', sSFuncBlockName]);
[~, sName, sExt] = fileparts(sHarnessModelFile);
sQuote=char(39);
set_param(hSFuncBlock, 'Parameters', [sQuote, sName, sExt, sQuote, ',', sQuote, sQuote, ',', sQuote, sQuote]);
set_param(hSFuncBlock, 'FunctionName', 'BTCMilSimRec');
set_param(hSFuncBlock, 'Tag', sFuncTag);
end


%%
function i_create_input_and_output_ports(hSFunctionIn, hSFunctionOut, sHarnessModelFileIn, sHarnessModelFileOut,...
    astBusInfo, bVirtualBusCreationFallback)
stPortHandlesIn = get_param(hSFunctionIn, 'PortHandles');
stPortHandlesOut = get_param(hSFunctionOut, 'PortHandles');
hHarnessIn = mxx_xmltree('load', sHarnessModelFileIn);
onCleanupCloseHarnessIn = onCleanup(@() mxx_xmltree('clear', hHarnessIn));
hHarnessOut = mxx_xmltree('load', sHarnessModelFileOut);
onCleanupCloseHarnessOut = onCleanup(@() mxx_xmltree('clear', hHarnessOut));
hHarnessOutports = mxx_xmltree('get_nodes', hHarnessOut, '/SFunction/Inports//Inport');
hHarnessInports = mxx_xmltree('get_nodes', hHarnessIn, '/SFunction/Outports//Outport');
% HarnessIn
nSender=0;
for i=1:length(stPortHandlesIn.Outport)
    hPort = stPortHandlesIn.Outport(i);
    iPortNumber = get(hPort, 'PortNumber');
    sPortNumber = num2str(iPortNumber);
    bIsMessage = mxx_xmltree('get_attribute', hHarnessInports(i), 'isMessage'); 
    if bIsMessage
        nSender = nSender + 1;
        hOutport = add_block('built-in/Outport', [get_param(hSFunctionIn,'parent'), '/out', sPortNumber]);
        hSend = add_block('built-in/Send', [get_param(hSFunctionIn,'parent'), '/Send', num2str(nSender)]);
        add_line(get_param(hSFunctionIn,'parent'),  [get_param(hSFunctionIn, 'name'),'/', sPortNumber], [get_param(hSend, 'Name'),'/', '1']);
        add_line(get_param(hSFunctionIn,'parent'),  [get_param(hSend, 'Name'),'/', '1'], [get_param(hOutport, 'Name'),'/', '1']);
        aiPortPos = get_param(stPortHandlesIn.Outport(i), 'Position');
        set_param(hSend, 'Position', [aiPortPos(1)+55, aiPortPos(2)-5 , aiPortPos(1)+85, aiPortPos(2)+5]);
        set_param(hOutport, 'Position', [aiPortPos(1)+150, aiPortPos(2)-5 , aiPortPos(1)+170, aiPortPos(2)+5]);
    else
        hOutport = add_block('built-in/Outport', [get_param(hSFunctionIn,'parent'), '/out', sPortNumber]);
        add_line(get_param(hSFunctionIn,'parent'),  [get_param(hSFunctionIn, 'name'),'/', sPortNumber], [get_param(hOutport, 'Name'),'/', '1']);
        aiPortPos = get_param(stPortHandlesIn.Outport(i), 'Position');
        set_param(hOutport, 'Position', [aiPortPos(1)+150, aiPortPos(2)-5 , aiPortPos(1)+170, aiPortPos(2)+5]);
    end
end

% HarnessOut
nReceiver=0;
for i=1:length(stPortHandlesOut.Inport)
    hPort = stPortHandlesOut.Inport(i);
    iPortNumber = get(hPort, 'PortNumber');
    sPortNumber = num2str(iPortNumber);
    bIsMessage = mxx_xmltree('get_attribute', hHarnessOutports(i), 'isMessage');
    if bIsMessage
        nReceiver = nReceiver + 1;
        hInport = add_block('built-in/Inport', [get_param(hSFunctionOut,'parent'), '/in', sPortNumber]);
        hReceive = add_block('built-in/Receive', [get_param(hSFunctionOut,'parent'), '/Receive', num2str(nReceiver)]);
        add_line(get_param(hSFunctionOut,'parent'),  [get_param(hInport, 'Name'),'/', '1'], [get_param(hReceive, 'name'),'/', '1']);
        add_line(get_param(hSFunctionOut,'parent'),  [get_param(hReceive, 'Name'),'/', '1'], [get_param(hSFunctionOut, 'name'),'/', sPortNumber]);
        aiPortPos = get_param(stPortHandlesOut.Inport(i), 'Position');
        set_param(hReceive, 'Position', [aiPortPos(1)-85, aiPortPos(2)-5 , aiPortPos(1)-55, aiPortPos(2)+5]);
        set_param(hInport, 'Position', [aiPortPos(1)-170, aiPortPos(2)-5 , aiPortPos(1)-150, aiPortPos(2)+5]);
    else
        hInport = add_block('built-in/Inport', [get_param(hSFunctionOut,'parent'), '/in', sPortNumber]);
        add_line(get_param(hSFunctionOut,'parent'),  [get_param(hInport, 'Name'),'/', '1'], [get_param(hSFunctionOut, 'name'),'/', sPortNumber]);
        aiPortPos = get_param(stPortHandlesOut.Inport(i), 'Position');
        set_param(hInport, 'Position', [aiPortPos(1)-170, aiPortPos(2)-5 , aiPortPos(1)-150, aiPortPos(2)+5]);
    end
end

% bus conversion
for i=1:length(astBusInfo)
    if astBusInfo(i).bIsVirtbusConversion
        if strcmp(astBusInfo(i).Kind, 'Inport')
            i_create_conversion_bus2virtualbus(hSFunctionIn, astBusInfo(i), stPortHandlesIn.Outport, bVirtualBusCreationFallback);
        else
            i_create_conversion_virtualbus2bus(hSFunctionOut, astBusInfo(i), stPortHandlesOut.Inport, bVirtualBusCreationFallback);
        end
    end
end
end


%%
function i_create_conversion_bus2virtualbus(hSFunctionIn, stBusInfo, ahPorts, bVirtualBusCreationFallback)
hConversion = add_block('simulink/Signal Attributes/Signal Conversion', ...
    [get_param(hSFunctionIn,'parent'), '/sigCon', stBusInfo.Kind, stBusInfo.PortNumber]);
hOutport = get_param([get_param(hSFunctionIn, 'parent'), '/out', stBusInfo.PortNumber], 'handle');

set_param(hConversion, 'ConversionOutput', 'Virtual Bus')
delete_line(get_param(hSFunctionIn, 'parent'), ...
    [get_param(hSFunctionIn, 'Name'), '/', num2str(stBusInfo.PortNumber)], ...
    [get_param(hOutport, 'Name'), '/1']);
add_line(get_param(hSFunctionIn, 'parent'), ...
    [get_param(hSFunctionIn, 'Name'), '/', num2str(stBusInfo.PortNumber)], [get_param(hConversion, 'name'), '/1']);

if bVirtualBusCreationFallback
    hBusSelector = add_block('simulink/Signal Routing/Bus Selector', ...
        [get_param(hSFunctionIn, 'parent'), '/busSel', stBusInfo.PortNumber]);
    add_line(get_param(hConversion, 'parent'),  ...
        [get_param(hConversion, 'name'), '/1'], [get_param(hBusSelector, 'Name'), '/1']);
    
    casInputSignals = get_param(hBusSelector, 'InputSignals');
    sAllSelectedSignals = '';
    for i=1:numel(casInputSignals)
        if iscell(casInputSignals{i})
            casInSig = casInputSignals{i};
            sAllSelectedSignals = strcat(sAllSelectedSignals, casInSig{1});    
        else
            sAllSelectedSignals = strcat(sAllSelectedSignals, casInputSignals{i});
        end
        if i ~=numel(casInputSignals)
            sAllSelectedSignals = strcat(sAllSelectedSignals, ',');
        end
    end
    if ~isempty(sAllSelectedSignals)
        set_param(hBusSelector, 'OutputSignals', sAllSelectedSignals);
        set_param(hBusSelector, 'OutputAsBus', 1);
    end
    
    add_line(get_param(hSFunctionIn, 'parent'),  ...
        [get_param(hBusSelector, 'name'), '/1'], [get_param(hOutport, 'Name'), '/1']);
else
    add_line(get_param(hSFunctionIn, 'parent'),  ...
        [get_param(hConversion, 'name'), '/1'], [get_param(hOutport, 'Name'), '/1']);
end

aiPortPos = get_param(ahPorts(str2double(stBusInfo.PortNumber)), 'Position');

set_param(hConversion, 'Position', [aiPortPos(1)+70, aiPortPos(2)-10 , aiPortPos(1)+90, aiPortPos(2)+10]);
set_param(hOutport, 'Position', [aiPortPos(1)+200, aiPortPos(2)-5, aiPortPos(1)+220, aiPortPos(2)+5]);
if bVirtualBusCreationFallback
    set_param(hBusSelector, 'Position', [aiPortPos(1)+130, aiPortPos(2)-10 , aiPortPos(1)+140, aiPortPos(2)+10]);
end
end


%%
function i_create_conversion_virtualbus2bus(hSFunctionOut, stBusInfo, ahPorts, bVirtualBusCreationFallback)
hConversion = add_block('simulink/Signal Attributes/Signal Conversion', ...
    [get_param(hSFunctionOut,'parent'), '/sigCon', stBusInfo.Kind, stBusInfo.PortNumber]);
hInport = get_param([get_param(hSFunctionOut, 'parent'), '/in', stBusInfo.PortNumber], 'handle');

set_param(hConversion, 'ConversionOutput', 'Nonvirtual Bus')
set_param(hConversion, 'OutDataTypeStr', ['Bus: ', stBusInfo.Type])

delete_line(get_param(hSFunctionOut, 'parent'), ...
    [get_param(hInport, 'Name'), '/1'], ...
    [get_param(hSFunctionOut, 'Name'), '/', stBusInfo.PortNumber]);

if bVirtualBusCreationFallback
    hBusSelector = add_block('simulink/Signal Routing/Bus Selector', ...
        [get_param(hSFunctionOut, 'parent'), '/busSel', stBusInfo.PortNumber]);
    add_line(get_param(hInport, 'parent'),  ...
        [get_param(hInport, 'name'), '/1'], [get_param(hBusSelector, 'Name'), '/1']);
    add_line(get_param(hBusSelector, 'parent'),  ...
        [get_param(hBusSelector, 'name'), '/1'], [get_param(hConversion, 'Name'), '/1']);
else
    add_line(get_param(hSFunctionOut, 'parent'),  ...
        [get_param(hInport, 'Name'), '/1'], [get_param(hConversion, 'name'), '/1']);
end

add_line(get_param(hSFunctionOut, 'parent'), ...
    [get_param(hConversion, 'name'), '/1'], [get_param(hSFunctionOut, 'Name'), '/', stBusInfo.PortNumber]);

aiPortPos = get_param(ahPorts(str2double(stBusInfo.PortNumber)), 'Position');

set_param(hConversion, 'Position', [aiPortPos(1)-90, aiPortPos(2)-10 , aiPortPos(1)-70, aiPortPos(2)+10]);
set_param(hInport, 'Position', [aiPortPos(1)-170, aiPortPos(2)-5 , aiPortPos(1)-150, aiPortPos(2)+5]);

if bVirtualBusCreationFallback
    set_param(hBusSelector, 'Position', [aiPortPos(1)-130, aiPortPos(2)-10 , aiPortPos(1)-125, aiPortPos(2)+10]);
end
end
