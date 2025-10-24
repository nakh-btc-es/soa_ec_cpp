function [astSrvFunCallsInfo, astServerRunaInfo, casIntRuna] = ep_ec_model_wrapper_fcn_callers_create(stArgs)
% This function creates test-clients using function callers.

%  function [astSrvFunCallsInfo, astServerRunaInfo, casIntRuna] = ep_ec_model_wrapper_fcn_callers_create(stArgs)
%
%  INPUT                         DESCRIPTION
%   - stArgs
%    . WrapperModel        (string)             Name of the wrapper model
%    . OrigModel           (string)             Name of original model
%    . ReferencePosition   (array of numbers)   Reference positions.
%
%  OUTPUT                        DESCRIPTION
%    -  astSrvFunCallsInfo (structs)   Needed Information about the server function calls
%    -  astServerRunaInfo  (structs)   Needed Information about the server runnables
%    -  casIntRuna         (strings)   List of internally triggered SL functions
%

%%
sWrapperModelName = stArgs.WrapperModel;
sModelName        = stArgs.OrigModel;
aiRefPosition     = stArgs.ReferencePosition;
oWrapperData      = stArgs.oWrapperData;

%%
astSrvFunCallsInfo = [];
AREA_WIDTH= 1000;
PARSUBSYSBLK_HEIGHT = 80;
HSHIFT = 200;
VSHIFT = 30;
HQTY = 1;
PARSUBSYSBLK_WIDTH = floor(AREA_WIDTH/HQTY) - HSHIFT;
FUNCLRBLK_WIDTH = 300;
FUNCLRBLK_HEIGHT = 80;
P1_Min = aiRefPosition(1);
P2_Min = aiRefPosition(2) - PARSUBSYSBLK_HEIGHT - VSHIFT;

% Get code mapping object
if verLessThan('matlab', '9.9')     % use old API for ML2020a or less
    oMapping = coder.dictionary.internal.SimulinkFunctionMapping;
else
    oMapping = coder.mapping.utils.create(sWrapperModelName);
end


%Get server runnables info from the AUTOSAR properties
[astServerRunaInfo, casIntRuna] = ep_ec_cs_slfun_info_get(sModelName);

for iRun = 1:numel(astServerRunaInfo)
    %Function name
    sFunName = astServerRunaInfo(iRun).sRunaSymbol;
    %Add Parent subsystem
    hSubSysBlk = add_block('built-in/Subsystem', [sWrapperModelName '/' 'Call_' sFunName]);
    sSubSysPath = getfullname(hSubSysBlk);
    set(hSubSysBlk, 'ForegroundColor', 'lightBlue');
    %-manage Position
    i_setPosFromTopLeft(hSubSysBlk, ...
        P1_Min + (HSHIFT + PARSUBSYSBLK_WIDTH)*(mod(iRun-1, HQTY)), ...
        P2_Min - floor((iRun-1)/HQTY)*(PARSUBSYSBLK_HEIGHT+VSHIFT), ...
        PARSUBSYSBLK_WIDTH, ...
        PARSUBSYSBLK_HEIGHT);
    %Add Function Caller block
    hFunCallerBlk = add_block('built-in/FunctionCaller', [sSubSysPath '/' sWrapperModelName '_Call_' sFunName]);
    sFunCallerBlkName = get_param(hFunCallerBlk, 'Name');
    set(hFunCallerBlk, 'ForegroundColor', 'lightBlue');
    %-manage Position
    i_setPosFromTopLeft(hFunCallerBlk, 100, 100, FUNCLRBLK_WIDTH, FUNCLRBLK_HEIGHT);
    
    %-set function prototype(before adding Inport/Outport ports)
    set(hFunCallerBlk, 'FunctionPrototype', astServerRunaInfo(iRun).sFunPrototype);
    
    %Add Trigger Port (to be connected to the Scheduler block)
    hTriggerBlk = add_block('built-in/TriggerPort', [sSubSysPath '/' 'Call_' sFunName], ...
        'SampleTimeType', 'triggered', ...
        'TriggerType', 'function-call', ...
        'StatesWhenEnabling', 'held'); %#ok<NASGU>
    
    %-get Args Types, Dim., format them and set them to server fcn callers blks appropriately
    mstArgProps = astServerRunaInfo(iRun).mstArgProps;
    casArgInNames = astServerRunaInfo(iRun).casArgInNames;
    if(~isempty(casArgInNames))
        sFormatedInArgsSpec = i_formatArgsSpec(casArgInNames, mstArgProps, oWrapperData);
        set(hFunCallerBlk, 'InputArgumentSpecifications', sFormatedInArgsSpec);
    end
    casArgOutNames = astServerRunaInfo(iRun).casArgOutNames;
    if(~isempty(casArgOutNames))
        sFormatedOutArgsSpec = i_formatArgsSpec(casArgOutNames, mstArgProps, oWrapperData);
        set(hFunCallerBlk, 'OutputArgumentSpecifications', sFormatedOutArgsSpec);
    end
    
    %Add Inport blocks
    anPortHdls = get_param(hFunCallerBlk, 'PortHandles');
    for iArg = 1:numel(1:numel(astServerRunaInfo(iRun).casArgInNames))
        sArgName = astServerRunaInfo(iRun).casArgInNames{iArg};
        aiArgDim= mstArgProps(sArgName).aiDim;
        if (mstArgProps(sArgName).bIsBus && aiArgDim(1) == 1 && aiArgDim(2) > 1)
            bNeedReshape = true;
        else
            bNeedReshape = false;
        end
        sPortDim = i_getPortDim (aiArgDim);
        sPortName = ['in_' sFunName '_' sArgName];
        sDstBlkPath = [sSubSysPath '/' sPortName];
        hInportBlk = add_block('built-in/Inport', sDstBlkPath);
        nPos = get(anPortHdls.Inport(iArg), 'position');
        
        %add Reshape block to signal path if needed
        if bNeedReshape
           nResPos = [nPos(1) - 80 - 30,...%left point
            nPos(2) - 10, ...%top point
            nPos(1) - 80,...%right point
            nPos(2) + 10]; % bottom point

            sResPortName = ['In_Res_' num2str(iArg)];
            sResPath = [sSubSysPath '/' sResPortName];
            hResBlk = add_block('simulink/Math Operations/Reshape', sResPath);
            set(hResBlk, 'Position', nResPos);
            set(hResBlk, 'OutputDimensionality', 'Column vector (2-D)');

        end
        
        nNewPos = [ nPos(1) - 160 - 30,...%left point
            nPos(2) - 10, ...%top point
            nPos(1) - 160,...%right point
            nPos(2) + 10]; % bottom point
        set(hInportBlk, 'Position', nNewPos);
        set(hInportBlk, 'PortDimensions', sPortDim);
        
        if(astServerRunaInfo(iRun).mstArgProps(sArgName).bIsBus)
            set(hInportBlk, 'OutDataTypeStr', ['Bus: ' mstArgProps(sArgName).sDataType]);
        end

        if length(sPortName) > 63
            %generate trimmed tag
            set(hInportBlk, 'Tag', ['in_' sFunName '_' num2str(iArg)]);
        else
            %take the original port name as tag
            set(hInportBlk, 'Tag', sPortName);
        end
        %wire additional reshape block when needed
        if bNeedReshape
            add_line(sSubSysPath, [sPortName '/1'], [sResPortName '/1']);
            add_line(sSubSysPath, [sResPortName '/1'], [sFunCallerBlkName '/' num2str(iArg)]);
        else
            add_line(sSubSysPath, [sPortName '/1'], [sFunCallerBlkName '/' num2str(iArg)]);
        end
    end
    
    %Add Outport blocks
    for iArg = 1:numel(1:numel(astServerRunaInfo(iRun).casArgOutNames))
        sArgName = astServerRunaInfo(iRun).casArgOutNames{iArg};
        aiArgDim = mstArgProps(sArgName).aiDim;
        if (mstArgProps(sArgName).bIsBus && aiArgDim(1) == 1 && aiArgDim(2) > 1)
            bNeedReshape = true;
        else
            bNeedReshape = false;
        end
        
        sPortDim = i_getPortDim (aiArgDim);
        sPortName = ['out_' sFunName '_' sArgName];
        sDstBlkPath = [sSubSysPath '/' sPortName];
        hOutportBlk = add_block('built-in/Outport', sDstBlkPath);
        nPos = get(anPortHdls.Outport(iArg), 'position');
        
        %add Reshape block to signal path if needed
        if bNeedReshape
           nResPos = [nPos(1) + 80 - 30,...%left point
            nPos(2) - 10, ...%top point
            nPos(1) + 80,...%right point
            nPos(2) + 10]; % bottom point

            sResPortName = ['Out_Res_' num2str(iArg)];
            sResPath = [sSubSysPath '/' sResPortName];
            hResBlk = add_block('simulink/Math Operations/Reshape', sResPath);
            set(hResBlk, 'Position', nResPos);
            set(hResBlk, 'OutputDimensionality', '1-D array');

        end
        nNewPos = [nPos(1) + 160 - 30,...%left point
            nPos(2) - 10, ...%top point
            nPos(1) + 160,...%right point
            nPos(2) + 10]; % bottom point
        set(hOutportBlk, 'Position', nNewPos);
        set(hOutportBlk, 'PortDimensions', sPortDim);
        
        if(astServerRunaInfo(iRun).mstArgProps(sArgName).bIsBus)
            set(hOutportBlk, 'OutDataTypeStr', ['Bus: ' mstArgProps(sArgName).sDataType]);
        end

        if length(sPortName) > 63
            %generate trimmed tag
            set(hOutportBlk, 'Tag', ['out_' sFunName '_' num2str(iArg)]);
        else
            %take the original port name as tag
            set(hOutportBlk, 'Tag', sPortName);
        end
        
        %wire additional reshape block when needed
        if bNeedReshape
            add_line(sSubSysPath, [sFunCallerBlkName '/' num2str(iArg)], [sResPortName '/1']);
            add_line(sSubSysPath, [sResPortName '/1'], [sPortName '/1']);
        else
            add_line(sSubSysPath, [sFunCallerBlkName '/' num2str(iArg)], [sPortName '/1']);
        end
    end
    % Add Root I/Os to the parent Subsytem
    i_addInports(hSubSysBlk);
    i_addOutports(hSubSysBlk);
    % Update return arguments
    astSrvFunCallsInfo(iRun).sRunaSymbol = sFunName; %#ok<*AGROW>
    astSrvFunCallsInfo(iRun).sEventName = ['Call_' sFunName];
    astSrvFunCallsInfo(iRun).hParentSubSys = hSubSysBlk;
    casAllArgsAutosarOrdered = astServerRunaInfo(iRun).casAllArgsAutosarOrdered;
    sRetErrArgName = astServerRunaInfo(iRun).sRetArgName;
    i_setFunctionInterfaceArguments(oMapping, sWrapperModelName, hFunCallerBlk, sFunName, casAllArgsAutosarOrdered, sRetErrArgName);
end
end


%% [1 2]
function sDimToSet = i_getPortDim (aiArgDim)
if aiArgDim(1) == 1
    sDimToSet = sprintf('%d', aiArgDim(2));
elseif aiArgDim(1) == 2  %Matrix
    sDimToSet = sprintf('[%d %d]', aiArgDim(2), aiArgDim(3));
else
    ME = MException('Given Matrix dimension = %s! Matrix dimensions above 2 are not supported.', aiArgDim(1));
    throw(ME);
end
end


%%
function i_setFunctionInterfaceArguments(oMapping, sWrapperModelName, hFunCallerBlk, sFunName, casAllArgsAutosarOrdered, sRetErrArgName)
% get function Interface setting
stParsedProto = i_getParsedDefaultPrototype(oMapping, sWrapperModelName, hFunCallerBlk, sFunName);
% set right autosar order
stIfSettings = i_makeFuncCallAutosarConform(stParsedProto, casAllArgsAutosarOrdered, sRetErrArgName);
% set function interface settings
i_setFunctionInterfaceSettings(sWrapperModelName, sFunName, stIfSettings);
end



%%
function stParsedProto = i_getParsedDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFunName)
sPrototype = i_getDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFunName);
stParsedProto = ep_ec_func_interface_settings_parse(sPrototype);
end


%%
function sPrototype = i_getDefaultPrototype(oMapping, sWrapperModelName, hSlFuncBlock, sFunName)
if verLessThan('matlab', '9.9')     % use old API for ML2020a or less
    sPrototype = oMapping.createDefaultFunctionPrototypeFromBlock(hSlFuncBlock);
else
    oMapping = coder.mapping.api.get(sWrapperModelName);
    sPrototype = getFunction(oMapping, ['SimulinkFunction:' sFunName], 'Arguments');
end
end


%%
function stProto = i_moveReturnToLastArg(stProto)
if ~isempty(stProto.sReturn)
    if isempty(stProto.astArgs)
        stProto.astArgs.sName = stProto.sReturn;
        stProto.astArgs.sMacro = '';
        stProto.astArgs.bIsPointer = false;
    else
        stProto.astArgs(end + 1).sName = stProto.sReturn; % place returned output at the end
    end
    stProto.sReturn = '';
end
end


%%
function stProto = i_makeFuncCallAutosarConform(stProto, casAllArgsAutosarOrdered, sRetErrArgName)
stProto = i_moveReturnToLastArg(stProto);

nArgs = numel(casAllArgsAutosarOrdered);
if (nArgs < 0)
    return;
end

% first sort the prototype arguments according to the order provided by AUTOSAR
aiOrderedArgsIdx = cellfun(@(s) find(strcmp(s, {stProto.astArgs(:).sName})), casAllArgsAutosarOrdered);
stProto.astArgs = stProto.astArgs(aiOrderedArgsIdx);

% if AUTOSAR has an explicit error return, remove it from the argument list and set the return value of the prototype 
% accordingly
if ~isempty(sRetErrArgName)
    abIsIdxRet = strcmp(sRetErrArgName, casAllArgsAutosarOrdered);
    stProto.sReturn = sRetErrArgName;
    stProto.astArgs(abIsIdxRet) = [];
end
end


%%
function i_setFunctionInterfaceSettings(sWrapperModelName, sFuncName, stInterfaceSettings)
sFunctionInterfaceSettings = ep_ec_func_interface_settings_create(stInterfaceSettings);
if verLessThan('matlab', '9.9')     % use old API for ML2020a or less
    drawnow;
    coder.dictionary.api.set(sWrapperModelName, 'SimulinkFunction', sFuncName, 'CodePrototype', sFunctionInterfaceSettings);
else
    oMapping = coder.mapping.api.get(sWrapperModelName);
    pause(0.5); % need wait time else the api call will give wrong results.
    setFunction(oMapping, ['SimulinkFunction:' sFuncName], 'Arguments', sFunctionInterfaceSettings)
end
end


%%
%  Get needed info about the exact original signal dimensions!
%    --> special handling for Mx1 (or 1xN) signals
function sFormatedArgsSpec = i_formatArgsSpec(casArgNames, mstArgProps, oWrapperData)
casArgsSpec = cell(1, numel(casArgNames));
sFormatedArgsSpec = ''; %#ok<NASGU>

for i = 1:numel(casArgNames)
    sArgsDt = mstArgProps(char(casArgNames(i))).sDataType;
    aiArgsDim = mstArgProps(char(casArgNames(i))).aiDim;
    casArgsSpec{i} = oWrapperData.getTypeInstance(sArgsDt, aiArgsDim);
end
sFormatedArgsSpec = strjoin(casArgsSpec , ', ');
end


%%
function i_addInports(hBlk, anIgnorePortNumbers)
HSHIFT = 100;
if nargin < 2
    anIgnorePortNumbers = [];
end
sBlkName = get_param(hBlk,'Name');
sBlkPath = getfullname(hBlk);
if strcmp(get(hBlk, 'BlockType'),'SubSystem')
    InportHandles = ep_find_system(sBlkPath, ...
        'SearchDepth',    1, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks',    'on', ...
        'BlockType',      'Inport');

elseif strcmp(get(hBlk, 'BlockType'),'ModelReference')
    sRefModelName = get(hBlk,'ModelName');
    load_system(sRefModelName);
    InportHandles = ep_find_system(sRefModelName, ...
        'SearchDepth', 1, ...
        'BlockType',   'Inport');
else
    return;
end

if ~isempty(InportHandles)
    PortsHdl = get_param(hBlk,'PortHandles');
    InportsHdl = PortsHdl.Inport;
    InportsPos = get_param(InportsHdl,'position');
    for iPort =1:length(InportHandles)
        if isempty(anIgnorePortNumbers) || ...
                (~isempty(anIgnorePortNumbers) && ~ismember(iPort,anIgnorePortNumbers))
            sNewBlkName = get_param(InportHandles{iPort},'Name');
            sTrimmedSigName = get_param(InportHandles{iPort},'Tag');
            sDataType = get_param(InportHandles{iPort}, 'OutDataTypeStr');
            if ~iscell(InportsPos), InportsPos = {InportsPos}; end
            blkPos = [ InportsPos{iPort}(1) - HSHIFT - 30,...%left point
                InportsPos{iPort}(2) - 10, ...%top point
                InportsPos{iPort}(1) - HSHIFT,...%right point
                InportsPos{iPort}(2) + 10]; % bottom point
            hInport = add_block('built-in/Inport',[get(hBlk,'Parent') '/' sNewBlkName],...
                'MakeNameUnique', 'on',...
                'Position',blkPos,...
                'showname','on');
            hSignal= add_line(get(hBlk,'Parent'),[sNewBlkName '/1'],[sBlkName '/' num2str(iPort)]);               
            cValidSignalId= matlab.lang.makeValidName(sTrimmedSigName);  
            set(hSignal, 'Name', cValidSignalId);
            set(hSignal, 'RTWStorageClass', 'ExportedGlobal');
            set(hInport, 'OutDataTypeStr', sDataType);
            if (contains(sDataType, 'Bus: '))
                set(hInport, 'BusOutputAsStruct', 'on');
            end
        end
    end
end
end


%%
function i_addOutports(hBlk)
HSHIFT = 100;
sBlkName = get_param(hBlk,'Name');
sBlkPath = getfullname(hBlk);
if strcmp(get(hBlk,'BlockType'), 'SubSystem')
    OutportHandles = ep_find_system(sBlkPath, ...
        'SearchDepth',    1,...
        'LookUnderMasks', 'all',...
        'FollowLinks',    'on',...
        'BlockType',      'Outport');
elseif strcmp(get(hBlk,'BlockType'), 'ModelReference')
    sRefModelName = get(hBlk,'ModelName');
    load_system(sRefModelName);
    OutportHandles = ep_find_system(sRefModelName, ...
        'SearchDepth', 1,...
        'BlockType',   'Outport');
else
    return;
end

if ~isempty(OutportHandles)
    PortsHdl = get_param(hBlk,'PortHandles');
    OutportsHdl = PortsHdl.Outport;
    OutportsPos = get_param(OutportsHdl,'position');
    for iPort =1:length(OutportHandles)
        newBlkName = get_param(OutportHandles{iPort},'Name');
        sTrimmedSigName = get_param(OutportHandles{iPort},'Tag');
        sDataType = get_param(OutportHandles{iPort},'OutDataTypeStr');
        if ~iscell(OutportsPos), OutportsPos = {OutportsPos};end
        blkPos = [ OutportsPos{iPort}(1) + HSHIFT - 30,...%left point
            OutportsPos{iPort}(2) - 10, ...%top point
            OutportsPos{iPort}(1) + HSHIFT,...%right point
            OutportsPos{iPort}(2) + 10]; % bottom point
        g = add_block('built-in/Outport',[get(hBlk,'Parent') '/' newBlkName],...
            'MakeNameUnique', 'on',...
            'Position',blkPos,...
            'showname','on');
        hSignal=add_line(get(hBlk,'Parent'), [sBlkName '/' num2str(iPort)], [newBlkName '/1']);
        cValidSignalId= matlab.lang.makeValidName(sTrimmedSigName);
        set(hSignal, 'Name', cValidSignalId);
        set(hSignal, 'RTWStorageClass', 'ExportedGlobal');
        set(g, 'OutDataTypeStr', sDataType);
    end
end
end


%%
function i_setPosFromTopLeft(hdl_or_sys, pt1, pt2, l, h)
nPos = [pt1, pt2, pt1+l, pt2+h];
if ischar(hdl_or_sys)
    set_param(hdl_or_sys,'Position',nPos);
else
    set(hdl_or_sys,'Position',nPos);
end
end
