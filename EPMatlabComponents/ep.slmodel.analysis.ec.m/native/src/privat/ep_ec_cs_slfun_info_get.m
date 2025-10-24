function [astServerRunaInfo, casIntRuna] = ep_ec_cs_slfun_info_get(sAutosarModelName)

casIntRuna = {};
astServerRunaInfo = [];
casSLFunTrigBlks = ep_find_system(sAutosarModelName, ...
    'BlockType',          'TriggerPort', ...
    'IsSimulinkFunction', 'on');
casSLFunNames = get_param(casSLFunTrigBlks, 'FunctionName');

if ~isempty(casSLFunTrigBlks)
    oArProps = autosar.api.getAUTOSARProperties(sAutosarModelName);
    oArSLMap = autosar.api.getSimulinkMapping(sAutosarModelName);
    sArCmpPath = oArProps.get('XmlOptions', 'ComponentQualifiedName');
    casRunArPaths = find(oArProps, sArCmpPath, 'Runnable', 'PathType', 'FullyQualified');
    %query for all OperationInvokedEvents
    casOpInvokedEvents = find(oArProps, sArCmpPath, 'OperationInvokedEvent', 'PathType', 'FullyQualified');
    %query for new InternalTriggerOccuredEvent, to sort out Runnables being triggered internally
    casIntTrigOccEvents = find(oArProps, sArCmpPath, 'InternalTriggerOccurredEvent', 'PathType', 'FullyQualified');  
    
    % Get Names and Symbols of the runnables
    casRunNames   = cell(1, numel(casRunArPaths));
    casRunSymbols = cell(1, numel(casRunArPaths));

    iServerRuna = 0;
    iIntRuna = 0;

    for iRun = 1:numel(casRunArPaths)
        bIntTrig = false;
        
        sRunnable = casRunArPaths{iRun};

        casRunNames{iRun} = get(oArProps, sRunnable, 'Name');
        casRunSymbols{iRun} = get(oArProps, sRunnable, 'symbol');

        sFunName = casRunSymbols{iRun};
        if verLessThan('matlab' , '9.9')
            sSLFct = sFunName;
        else
            sSLFct = strcat('SimulinkFunction:', sFunName);
        end

        try 
            oArSLMap.getFunction(sSLFct); 
            bExist = true; 
        catch 
            bExist = false; 
        end
        idxSLFun = find(ismember(casSLFunNames, sFunName), 1);
        bHasErrorArg = false; %#ok<NASGU>
        
        %check if we got Runnables with internal trigger and ignore them for now

        if ~isempty(casIntTrigOccEvents) && bExist && ~isempty(idxSLFun)
           for iIOE = 1:numel(casIntTrigOccEvents)
                sIntTrigOccEvent = casIntTrigOccEvents{iIOE};
                
                casSOEs = oArProps.get(sIntTrigOccEvent, 'StartOnEvent', 'PathType', 'FullyQualified');
                if ismember(sRunnable, cellstr(casSOEs))
                    iIntRuna = iIntRuna + 1;
                    casIntRuna{iIntRuna} = sFunName;%#ok<AGROW>
                    bIntTrig = true;
                    break;
                end
           end
        end

        if bExist && ~isempty(idxSLFun) && ~bIntTrig
            iServerRuna = iServerRuna + 1;
            sTriggerPort = casSLFunTrigBlks{idxSLFun};

            astServerRunaInfo(iServerRuna).sRunaName = casRunNames{iRun};
            astServerRunaInfo(iServerRuna).sRunaSymbol = sFunName;
            astServerRunaInfo(iServerRuna).sSLFuncBlkPath = get_param(sTriggerPort, 'Parent');
            astServerRunaInfo(iServerRuna).sRetArgName = '';
            astServerRunaInfo(iServerRuna).casAllArgsAutosarOrdered = {};
            astServerRunaInfo(iServerRuna).mstArgProps = containers.Map();
            
            
            % Get all (ordered) arguments of the Server runnable
            for iOIE = 1:numel(casOpInvokedEvents)
                sOpInvokedEvent = casOpInvokedEvents{iOIE};

                casSOEs = oArProps.get(sOpInvokedEvent, 'StartOnEvent', 'PathType', 'FullyQualified');
                if any(strcmp(sRunnable, cellstr(casSOEs)))
                    sTrigger = oArProps.get(sOpInvokedEvent, 'Trigger');
                    casStr = strsplit(sTrigger, '.');
                    sArPortName = casStr{1};
                    sArOpName = casStr{2};
                    casPortPath = find(oArProps, sArCmpPath, 'ServerPort', ...
                        'Name', sArPortName, 'PathType', 'FullyQualified');
                    sCSItfPath = get(oArProps, char(casPortPath), 'Interface', 'PathType', 'FullyQualified');
                    sOpPath = [sCSItfPath '/' sArOpName];
                    casArgumentsPaths = get(oArProps, sOpPath, 'Arguments', 'PathType', 'FullyQualified');
                    astServerRunaInfo(iServerRuna).casAllArgsAutosarOrdered = ...
                        cellfun(@(x) i_getNameFromPath(x), casArgumentsPaths, 'UniformOutput', false);
                    break;
                end
            end

            %get Err argument namesRetArgName
            for iArg = 1:numel(casArgumentsPaths)
                bHasErrorArg = strcmp('Error', get(oArProps, casArgumentsPaths{iArg}, ...
                    'Direction', 'PathType', 'FullyQualified'));
                if bHasErrorArg
                    astServerRunaInfo(iServerRuna).sRetArgName = i_getNameFromPath(casArgumentsPaths{iArg});
                    break;
                end
            end
            
            %Extract Function Signature from In/Out argument ports
            casArgInBlks = ep_find_system(get_param(casSLFunTrigBlks{idxSLFun}, 'Parent'), ...
                'SearchDepth', 1, ...
                'BlockType',   'ArgIn');
            casArgInNames = get_param(casArgInBlks, 'ArgumentName');
            anArgInPortNums = cellfun(@(x) str2double(x), get_param(casArgInBlks, 'Port'));
            [~, idxArgInSorted] = sort(anArgInPortNums);
            %sort the Input argumens names
            casArgInNames = casArgInNames(idxArgInSorted);
            
            casArgOutBlks = ep_find_system(get_param(casSLFunTrigBlks{idxSLFun}, 'Parent'), ...
                'SearchDepth', 1, ...
                'BlockType',   'ArgOut');
            casArgOutNames = get_param(casArgOutBlks, 'ArgumentName');
            anArgOutPortNums = cellfun(@(x) str2double(x), get_param(casArgOutBlks, 'Port'));
            [~, idxArgOutSorted] = sort(anArgOutPortNums);
            %sort the Input argumens names
            casArgOutNames = casArgOutNames(idxArgOutSorted);
            astServerRunaInfo(iServerRuna).casArgInNames = casArgInNames;
            astServerRunaInfo(iServerRuna).casArgOutNames = casArgOutNames;
            %get datatypes and dimensions of server Argument Blocks
            if ~isempty(casArgOutBlks)
                i_getSrvArgsBlkDtAndDim ('ArgOut', casArgOutBlks, astServerRunaInfo(iServerRuna).mstArgProps);
            end
            if ~isempty(casArgInBlks)
                i_getSrvArgsBlkDtAndDim ('ArgIn', casArgInBlks, astServerRunaInfo(iServerRuna).mstArgProps);
            end
            
            %Output parts
            sOutParts = ''; %#ok<NASGU>
            if isempty(casArgOutNames)
                sOutParts = '';
            else
                if numel(casArgOutNames) == 1
                    sOutParts = [casArgOutNames{1} ' = '];
                else
                    sOutParts = '[';
                    for iArgOut = 1:numel(casArgOutNames)-1
                        sOutParts = [sOutParts casArgOutNames{iArgOut} ', '];
                    end
                    sOutParts = [sOutParts casArgOutNames{end} '] = '];
                end
            end
            %Input parts
            sInParts = ''; %#ok<NASGU>
            if isempty(casArgInNames)
                sInParts = '()';
            else
                if numel(casArgInNames) == 1
                    sInParts = [ '(' casArgInNames{1} ')'];
                else
                    sInParts = '(';
                    for iArgIn = 1:numel(casArgInNames)-1
                        sInParts = [sInParts casArgInNames{iArgIn} ', '];
                    end
                    sInParts = [sInParts casArgInNames{end} ')'];
                end
            end
            astServerRunaInfo(iServerRuna).sFunPrototype = [sOutParts sFunName sInParts];
        end
    end
end
end


%%
function sName = i_getNameFromPath(sPath)
[~, sName] = fileparts(sPath);
end


%%
%     Type definitions for the inputs/outputs are missing
%     NOTE: info needed about the exact original signal dimensions!
%       --> special handling for Mx1 (or 1xN) signals
function i_getSrvArgsBlkDtAndDim (sBlockArgType, casArgBlks, mstArgProps)
casArgNames =  get_param(casArgBlks, 'ArgumentName');
astPortDatatype = get_param(casArgBlks, 'CompiledPortDataTypes');
astPortDim = get_param(casArgBlks, 'CompiledPortDimensions');
stArgsDtDim = struct( ...
    'sDataType', '', ...
    'aiDim', [],...
    'bIsBus', 0);
for j = 1:numel(casArgNames)
    if (strcmp(sBlockArgType,'ArgIn'))
        sDataType = char(astPortDatatype{j, 1}.Outport);
        stArgsDtDim.aiDim = astPortDim{j, 1}.Outport;
        stArgsDtDim.sDataType = sDataType;
        sDataTypeStr = get_param(casArgBlks{j}, 'OutDataTypeStr');
        stArgsDtDim.bIsBus = contains(sDataTypeStr, 'Bus:');
    elseif (strcmp(sBlockArgType,'ArgOut'))
        sDataType = char(astPortDatatype{j, 1}.Inport);
        stArgsDtDim.aiDim = astPortDim{j, 1}.Inport;
        stArgsDtDim.sDataType = sDataType;
        sDataTypeStr = get_param(casArgBlks{j}, 'OutDataTypeStr');
        stArgsDtDim.bIsBus = contains(sDataTypeStr, 'Bus:');
    else
        warning('DEV:INTERNAL_ERROR', 'Unexpected: Blocktype.');
        return;
    end
    mstArgProps(char(casArgNames(j))) = stArgsDtDim;
end
end
