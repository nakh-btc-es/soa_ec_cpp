function [casStubHFiles, casStubCFiles, sStubVarInitFunc] = createStub(oStubGrtor, aoItfStubInfo, sStubCFileName, sStubHFileName, casIncludeFiles, casTypedefs)

% aoArItfStubInfo
% aoInterfacesStubInfo(iItem).sStubType = 'function';
% aoInterfacesStubInfo(iItem).sStubFuncType = 'Custom'; %'SimulinkGetSet' or 'Custom'
% aoInterfacesStubInfo(iItem).sStubCustomVariableName = 'ecp_<apiname>_<c>_<re>_<p>_<o>';
% aoInterfacesStubInfo(iItem).sStubCustomGetFunName = cfg.ArCom(ii).Format.sRteApiMapping;
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs = Eca.MetaFunArg; %Array of objects Eca.MetaFunArg
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).bMapToStubVar = true;
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).sKind = 'output';
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).sArgName = 'argOut';
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).sQualiferScalar = '';
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).sQualiferArray = '';
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).bIsPointer = true;
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).bArrayPointerNotation = false;
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).sDataType = '<idt>';
% aoInterfacesStubInfo(iItem).aoStubCustomGetFunArgs(2).bUseArrayDataType = true;

if (nargin < 6)
    casTypedefs = {};
end

casStubHFiles = {};
casStubCFiles = {};

sHFileContent = i_createHeaderFileContent(oStubGrtor, aoItfStubInfo, casTypedefs);
casStubHFiles{end + 1} = oStubGrtor.createHeaderfile(sStubHFileName, sHFileContent, casIncludeFiles);

%Create source file
[sCFileContent, sStubVarInitFunc] = i_createSourceFileContent(oStubGrtor, aoItfStubInfo);
casStubCFiles{end + 1} = oStubGrtor.createSourcefile(sStubCFileName, sCFileContent, Eca.EcaItf.FileName(sStubHFileName));
end


%% Variables/Functions declaration
function sFileContent = i_createHeaderFileContent(oStubGrtor, aoItfStubInfo, casTypedefs)
if ~isempty(casTypedefs)
    sFileContent = sprintf('%s\n', strjoin(casTypedefs, '\n')); % additional newline for aesthetics
else
    sFileContent = '';
end

if ~isempty(aoItfStubInfo)
    for iItem = 1:numel(aoItfStubInfo)
        if strcmpi(aoItfStubInfo(iItem).sStubType, 'Define')
            sFileContent = oStubGrtor.createDefines(aoItfStubInfo(iItem));

        elseif strcmpi(aoItfStubInfo(iItem).sStubType, 'Variable')
            sFileContent = oStubGrtor.createVariableDeclaration(sFileContent, aoItfStubInfo(iItem));

        elseif strcmpi(aoItfStubInfo(iItem).sStubType, 'Function')
            if strcmpi(aoItfStubInfo(iItem).sStubFuncType, 'SimulinkGetSet')
                sFileContent = oStubGrtor.createSLGetSetFunDeclaration(sFileContent, aoItfStubInfo(iItem));

            elseif strcmpi(aoItfStubInfo(iItem).sStubFuncType, 'Custom')
                sFileContent = oStubGrtor.createCustomGetSetFunDeclaration(sFileContent, aoItfStubInfo(iItem));
            
            else
                sFileContent = ['The stub method "', oStubInfo.sStubFuncType, 'n\n'];
            end
        end
    end
    sFileContent = [sFileContent, '\n'];
    sFileContent = sprintf(sFileContent);
end
end


%%
function [sFileContent, sVarInitFunc] = i_createSourceFileContent(oStubGrtor, aoItfStubInfo)
sFileContent = '';
sVarInitFunc = '';

abIsVarInit = false(size(aoItfStubInfo));
if ~isempty(aoItfStubInfo)
    for i = 1:numel(aoItfStubInfo)
        oStubInfo = aoItfStubInfo(i);

        sFileContent = [sFileContent, '\n\n'];
        
        switch lower(oStubInfo.sStubType)
            case 'variable'
                sFileContent = oStubGrtor.createVariableDefinition(sFileContent, oStubInfo);
                
            case 'function'
                if strcmpi(oStubInfo.sStubFuncType, 'SimulinkGetSet')
                    sFileContent = oStubGrtor.createSLGetSetFunDefinition(sFileContent, oStubInfo);
                    
                elseif strcmpi(oStubInfo.sStubFuncType, 'Custom')
                    sFileContent = oStubGrtor.createCustomGetSetFunDefinition(sFileContent, oStubInfo);
                    
                else
                    sFileContent = ['The stub method "', oStubInfo.sStubFuncType, 'n\n'];
                end
                
            case 'varinit'
                abIsVarInit(i) = true;
                
            otherwise
                % do nothing
        end
    end
    sFileContent = sprintf(sFileContent);
end

aoVarInitInfos = aoItfStubInfo(abIsVarInit);
if ~isempty(aoVarInitInfos)
    sVarInitFunc = 'BTC_init_RTE_params';
    sFuncContent = i_getFunctionContent(aoVarInitInfos, ' ');
    sFuncPart = sprintf('void %s() {\n%s\n}\n', sVarInitFunc, sFuncContent);
    
    sFileContent = sprintf('%s\n\n%s\n', sFileContent, sFuncPart);
end
end



%%
function sFuncContent = i_getFunctionContent(aoVarInitInfos, sIndent)
ccasInitLines = arrayfun(@(o) o.getInitAssignments, aoVarInitInfos, 'uni', false);
casInitLines = horzcat(ccasInitLines{:});

sFuncContent = sprintf('%s%s', sIndent, strjoin(casInitLines, ['\n', sIndent]));
end
