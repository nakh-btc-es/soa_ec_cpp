function astOpCallInfo = ep_ec_cs_opcall_info_get(sAutosarModelName, casIntRuna)

%  INPUT              DESCRIPTION
%    - sAutosarModelName        (string)            Name of the AUTOSAR model
%    - casIntRuna               (cell a.o. string)  Blacklist with internal runnables
%  OUTPUT            DESCRIPTION
%    astOpCallInfo               (a.o. struct)       Return values
%       .sFunCallerBlk           (string)            Full path of the Function caller block
%       .casAllRefFunCallerBlks  (cell a.o. string)  Paths of all referenced caller blocks
%       .sArCmpName              (string)            Autosar compliant name
%       .sFunName                (string)            Name of the called function
%       .sPortName               (string)            Autosar port name of the client
%       .sOpName                 (string)            Name of the operation
%       .sOpName                 (string)            Name of the operation
%       .sErrArgName             (string)            Block name of the erroneous block
%       .abIsErrorArgument       (a.o. bool)         Array with error argument flag
%       .bHasErrorArguments      (bool)              Flag to indicate presence of err. arguments
%       .casOrderedArgName       (cell a.o. string)  Ordered argument names
%       .casInArgsName           (cell a.o. string)  Input arguments
%       .casOutArgsName          (cell a.o. string)  Output arguments
%       .casInVarInjName         (cell a.o. string)  Input stub variable names for injection
%       .casOutVarInjName        (cell a.o. string)  Output stub variable names for injection
%       .casInArgsDT             (cell a.o. string)  Data type of input arguments
%       .casInArgsCodeDT         (cell a.o. string)  Data type of input arguments in code
%       .casInArgsDim            (cell a.o. string)  Dimension of input arguments
%       .casInArgsScaling        (cell a.o. string)  Scaling of input arguments
%       .casInArgsSpec           (cell a.o. string)  Spec of input arguments
%       .casOutArgsDT            (cell a.o. string)  Data type of output arguments
%       .casOutArgsCodeDT        (cell a.o. string)  Data type of output arguments in code
%       .casOutArgsDim           (cell a.o. string)  Dimension of output arguments
%       .casOutArgsScaling       (cell a.o. string)  Scaling of output arguments
%       .casOutArgsSpec          (cell a.o. string)  Spec of output arguments
%       .sRteCallFunName         (string)            Autosar rte stub function caller name
%       .sErrStatusVarName       (string)            Variable name for error status


%%
if (nargin < 2)
    casIntRuna = {};
    if (nargin < 1)
        sAutosarModelName = bdroot(gcs);
    end
end

astOpCallInfo = [];

if verLessThan('matlab', '9.13')
    casAllCallerBlks = find_system(sAutosarModelName, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks',    'on', ...
        'BlockType',      'FunctionCaller');
else
    % Note: for ML2022b we need to actively filter out callers in inactive Runnables
    casAllCallerBlks = find_system(sAutosarModelName, ...
        'MatchFilter',    @Simulink.match.activeVariants, ...
        'LookUnderMasks', 'all', ...
        'FollowLinks',    'on', ...
        'BlockType',      'FunctionCaller');
end

if ~isempty(casAllCallerBlks)    
    oArProps = autosar.api.getAUTOSARProperties(sAutosarModelName);
    oArSLMap = autosar.api.getSimulinkMapping(sAutosarModelName);
    sArCmpPath = oArProps.get('XmlOptions', 'ComponentQualifiedName');
    sArCmpName = oArProps.get(sArCmpPath, 'Name');
    
    [~, aiIdxUniqProtoName, aiIdxPosition] = unique(get_param(casAllCallerBlks, 'FunctionPrototype'));
    casCallerBlks = casAllCallerBlks(aiIdxUniqProtoName);
    
    astOpCallInfo = [];
    for iBlk = 1:numel(casCallerBlks)
        sCallerBlock = casCallerBlks{iBlk};

        sFunProto = get_param(sCallerBlock, 'FunctionPrototype');
        sFunName = i_getFunName(sFunProto);
        
        if ~isempty(sFunName)
            if ~isempty(casIntRuna)
                if ismember(sFunName, cellstr(casIntRuna))
                    %skip blacklisted function because of internaL trigger mode
                    continue;
                end
            end

            try
                [sArCltPortName, sArOpName] = oArSLMap.getFunctionCaller(sFunName);

            catch oEx %#ok<NASGU>
                %warning('EP:FUNC_CALLER_MISSING', 'No function caller found for function %s.', sFunName);
                continue;
            end

            stOpCallInfo.bIsInternal = isempty(sArCltPortName) || ~isvarname(sArCltPortName);
            if stOpCallInfo.bIsInternal
                casArgumentsPaths = {};
            else
                casPortPath = find(oArProps, sArCmpPath, 'ClientPort', ...
                    'Name',     sArCltPortName, ...
                    'PathType', 'FullyQualified'); %Path of ClientPort
                sCSItfPath = get(oArProps, char(casPortPath), 'Interface', 'PathType', 'FullyQualified');
                sOpPath = [sCSItfPath '/' sArOpName];
                casArgumentsPaths = get(oArProps, sOpPath, 'Arguments', 'PathType', 'FullyQualified');
            end
            
            % Function information
            stOpCallInfo.sFunCallerBlk = sCallerBlock;
            stOpCallInfo.casAllRefFunCallerBlks = casAllCallerBlks(aiIdxPosition == iBlk);
            stOpCallInfo.sArCmpName = sArCmpName;
            stOpCallInfo.sFunName = sFunName;
            stOpCallInfo.sPortName = sArCltPortName;
            stOpCallInfo.sOpName = sArOpName;
            stOpCallInfo.sErrArgName = '';
            stOpCallInfo.abIsErrorArgument = false(size(casArgumentsPaths));
            stOpCallInfo.bHasErrorArguments = false;
            
            stOpCallInfo.casOrderedArgName = ...
                cellfun(@(x) i_getNameFromPath(x), casArgumentsPaths, 'UniformOutput', false);
            for iArg = 1:numel(casArgumentsPaths)
                bIsErrorArg = strcmp('Error', ...
                    get(oArProps, casArgumentsPaths{iArg}, 'Direction', 'PathType', 'FullyQualified'));
                stOpCallInfo.abIsErrorArgument(iArg) = bIsErrorArg;
                if bIsErrorArg
                    stOpCallInfo.sErrArgName = i_getNameFromPath(casArgumentsPaths{iArg});
                    stOpCallInfo.bHasErrorArguments = true;
                end
            end
            
            % Function argument names
            stOpCallInfo.casInArgsName = i_getInputArgs(sFunProto);
            stOpCallInfo.casOutArgsName = i_getOutputArgs(sFunProto);
            
            % Stub variable names for variable injection
            stOpCallInfo.casInVarInjName = i_getInputVarInjName(stOpCallInfo);
            stOpCallInfo.casOutVarInjName = i_getOutputVarInjName(stOpCallInfo);
            
            sInArgsSpec  = get_param(sCallerBlock, 'InputArgumentSpecifications');
            sOutArgsSpec = get_param(sCallerBlock, 'OutputArgumentSpecifications');

            % DataType and Dimensions
            [stOpCallInfo.casInArgsDT, ...
                stOpCallInfo.casInArgsCodeDT, ...
                stOpCallInfo.casInArgsDim, ...
                stOpCallInfo.casInArgsScaling, ...
                stOpCallInfo.sInArgsSpec] = i_getDataTypeAndDimension(sAutosarModelName, sInArgsSpec);
            
            [stOpCallInfo.casOutArgsDT, ...
                stOpCallInfo.casOutArgsCodeDT, ...
                stOpCallInfo.casOutArgsDim, ...
                stOpCallInfo.casOutArgsScaling, ...
                stOpCallInfo.sOutArgsSpec] = i_getDataTypeAndDimension(sAutosarModelName, sOutArgsSpec);
            
            stOpCallInfo.sRteCallFunName = i_getAutosarRteCallStubFunName(stOpCallInfo);            
            stOpCallInfo.sErrStatusVarName = ['ErrorStatus_' sArCmpName '_' sArCltPortName '_' sArOpName];
            
            astOpCallInfo = [astOpCallInfo, stOpCallInfo]; %#ok<AGROW> 
        end
    end
end
end


%%
function cas = i_getInputArgs(sFunProto)
cas = {};
sExp = '\((.*)\)';
tks = regexp(sFunProto, sExp, 'tokens');
if ~isempty(tks)
    tks2 = regexp(tks{1}{1},'(\w+)','tokens');
    for k = 1:numel(tks2)
        cas{k} = char(tks2{k});
    end
end
end


%%
function sFnName = i_getFunName(sFunProto)
sExp = '=*(\w+) *\(';
tks = regexp(sFunProto,sExp,'tokens');
sFnName = char(tks{1});
end


%%
function cas = i_getOutputArgs(sFunProto)
cas = {};
sExp = '(.*) *=';
tks = regexp(sFunProto, sExp, 'tokens');
if ~isempty(tks)
    tks2 = regexp(tks{1}{1},'(\w+)','tokens');
    for k = 1:numel(tks2)
        cas{k} = char(tks2{k});
    end
end
end


%%
function cas = i_getInputVarInjName(astOpCallInfo)
cas = {};
for k=1:numel(astOpCallInfo.casInArgsName)
    cas{k} = ['OutVarInj__', astOpCallInfo.sFunName,'__', astOpCallInfo.casInArgsName{k}];
end
end


%%
function cas = i_getOutputVarInjName(astOpCallInfo)
cas = {};
for k=1:numel(astOpCallInfo.casOutArgsName)
    cas{k} = ['InVarInj__', astOpCallInfo.sFunName, '__', astOpCallInfo.casOutArgsName{k}];
end
end


%%
function sFunName = i_getAutosarRteCallStubFunName(stOpCallInfo)
%Rte_Call_<SWCName>_<ClientPort>_<OperationName>
sFunName = ['Rte_Call_' stOpCallInfo.sArCmpName '_' stOpCallInfo.sPortName '_' stOpCallInfo.sOpName];
end


%%
function [casSLDT, casCodeDT,  casDim, casScaling, sArgsSpec] = i_getDataTypeAndDimension(sAutosarModelName, sArgsSpec)
casSLDT = {};
casDim = {};
casCodeDT = {};
casScaling = {};

if ~isempty(sArgsSpec) && ~strcmpi(sArgsSpec, '<Enter example>')
    caxArgs = Simulink.data.evalinGlobal(sAutosarModelName, ['{' sArgsSpec '}']);
    for iArg = 1:numel(caxArgs)
        if isa(caxArgs{iArg}, 'Simulink.Parameter')
            %DataType
            casSLDT{iArg} = caxArgs{iArg}(1).DataType;
            casDim{iArg} = caxArgs{iArg}(1).Dimensions.* size(caxArgs{iArg});
        else
            %Dimensions
            casDim{iArg} = size(caxArgs{iArg});
            %DataType
            xData = caxArgs{iArg}(1);
            sClass = class(xData);
            if strcmp(sClass, 'logical')
                casSLDT{iArg} = 'boolean';
            elseif strcmp(sClass, 'embedded.fi')
                casSLDT{iArg} = fixdt(xData.numerictype);
            else
                casSLDT{iArg} = sClass;
            end
        end
        
        %Get code datatype name
        casCodeDT{iArg} = i_getCodeDT(sAutosarModelName, casSLDT{iArg});
        
        %Get Scaling
        casScaling{iArg} = i_getScaling(casSLDT{iArg});
    end
end
end


%%
function sCodeDT = i_getCodeDT(sModelName, sSLDT)
sCodeDT = ep_ec_sltype_to_ctype(sModelName, sSLDT);
end


%%
function stScalingInfo = i_getScaling(sSLDT)
stInfo = ep_sl_type_info_get(sSLDT);

stScalingInfo = struct( ...
    'resolution',    stInfo.dLsb, ...
    'offset',        stInfo.dOffset, ...
    'isFloatPoint',  stInfo.bIsFloat, ...
    'isEnumeration', stInfo.bIsEnum);
end


%%
function sName = i_getNameFromPath(sPath)
[~, sName] = fileparts(sPath);
end