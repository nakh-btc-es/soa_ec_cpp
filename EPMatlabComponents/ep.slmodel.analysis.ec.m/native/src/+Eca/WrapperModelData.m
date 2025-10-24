classdef WrapperModelData < handle
    properties (SetAccess = private)
        sWrapperModelName = '';
        sModelPath = '';
        sModelName = '';
        oDD = [];
        sFileDD = '';
        sInitScript = '';
        
        oStorage = [];
    end
    
    methods
        function oObj = WrapperModelData(sWrapperModelName, sModelName)
            oObj.sWrapperModelName = sWrapperModelName;
            oObj.sModelName = sModelName;
            oObj.sModelPath = fileparts(get_param(sModelName, 'FileName'));
            
            oObj.oStorage = Eca.ModelDataStorage(sWrapperModelName);
        end
        
        function sTypeInstance = getTypeInstance(oObj, sType, aiCompiledDim)
            if (nargin < 3)
                aiCompiledDim = [1 1];
            end
            sTypeInstance = oObj.oStorage.getTypeInstance(sType, aiCompiledDim);
        end
                
        function stInfo = getTypeInfo(oObj, sType)
            stInfo = oObj.oStorage.getTypeInfo(sType);
        end

        function createAndPersistDataStoreSignal(oObj, sNameDS, sOutDataTypeStrDS, aiVariableStyleDimDS, sAliasName)
            if ~exist('sAliasName', 'var')
                sAliasName = '';
            end
            oObj.persistContent(i_getDataStoreInitCommands(oObj, sNameDS, sOutDataTypeStrDS, aiVariableStyleDimDS, sAliasName));
        end
                
        function sInitScript = getInitScript(oObj)
            sInitScript = oObj.sInitScript;
        end
        
        function sFileDD = getFileDD(oObj)
            sFileDD = oObj.sFileDD;
        end

        function close(oObj)
            if (~isempty(oObj.oDD) && oObj.oDD.isOpen)
                oObj.oDD.close();
            end
        end
    end
    
    methods (Hidden = true)
        function persistContent(oObj, sContent)
            if isempty(sContent)
                return;
            end
            
            if ~isempty(oObj.oDD)
                i_addContentDD(oObj.oDD, sContent);
            else
                oObj.addInitScriptContent(sContent, true);
            end
        end
        
        function referenceDD(oObj, sReferenceDD)
            if ~isempty(oObj.oDD)
                error('EP:WRONG_USAGE', 'Already referencing an SL-DD.');
            end
            [oObj.oDD, oObj.sFileDD] = i_createWrapperDD(sReferenceDD, oObj.sWrapperModelName);
            oObj.oStorage.setDD(oObj.oDD);
        end
        
        function addInitScriptContent(oObj, sContent, bEvalinBase)
            if (nargin < 3)
                bEvalinBase = false;
            end
            if isempty(sContent)
                return;
            end
            
            if isempty(oObj.sInitScript)
                oObj.sInitScript = fullfile(oObj.sModelPath, ['init_' oObj.sWrapperModelName '.m']);
                i_avoidOverwrite(oObj.sInitScript);
                
                if ~oObj.oStorage.isTargetSet()
                    oObj.oStorage.setInitScript(oObj.sInitScript);
                end

                % if init script is just being created, prepend also a docu header explaining the purpose of the script
                sAddContent = [ ...
                    sprintf('%% Init script for AUTOSAR wrapper model: %s', oObj.sWrapperModelName), ...
                    newline(), ...
                    sContent];
            else
                % always prepend a newline to *new* content
                sAddContent = [newline(), sContent];
            end
            i_addContent(oObj.sInitScript, sAddContent);
            if bEvalinBase
                i_evalinBase(sContent);
            end
        end
    end                
end


%%
function i_addContent(sFile, sContent)
hFid = fopen(sFile, 'a'); % IMPORTANT: use _append_ to add content at the end of file
if (hFid > 0)
    oOnCleanupClose = onCleanup(@() fclose(hFid));
    
    fprintf(hFid, '%s', sContent);
else
    fprintf('\n[ERROR] Could not write to file "%s".\n', sFile);
end
end


%%
function i_addContentDD(oDD, sContent)
sTmpScript = fullfile(pwd, ['btc_tmp' datestr(now, 30), '.m']);
i_addContent(sTmpScript, sContent);

oSectionData = oDD.getSection('Design Data');
oSectionData.importFromFile(sTmpScript);
oDD.saveChanges();

delete(sTmpScript);
end


%%
function i_evalinBase(sContent)
sTmpScript = [tempname(pwd), '.m'];
i_addContent(sTmpScript, sContent);

try %#ok<TRYNC>
    evalin('base', ['run(''', sTmpScript, ''');']);
end

delete(sTmpScript);
end


%%
function [oDD, sFileDD] = i_createWrapperDD(sReferencedDD, sWrapperModelName)
oDD = [];
sFileDD = '';
if isempty(sReferencedDD)
    return;
end

sPathDD = fileparts(which(sReferencedDD));
sFileDD = fullfile(sPathDD, [sWrapperModelName '.sldd']);
if exist(sFileDD, 'file')
    oDD = Simulink.data.dictionary.open(sFileDD);
    oDD.saveChanges();
    oDD.close();
    i_avoidOverwrite(sFileDD);
end
oDD = Simulink.data.dictionary.create(sFileDD);
oDD.addDataSource(sReferencedDD);

oDD.saveChanges();

[~, f, e] = fileparts(sFileDD);
set_param(sWrapperModelName, 'DataDictionary', [f, e]);
end


%%
function i_avoidOverwrite(sFileToBeWritten)
if ~exist(sFileToBeWritten, 'file')
    return;
end

nTries = 0;
nMaxTries = 100;
sBakFileBase = [sFileToBeWritten, '.bak'];
sBakFile = sBakFileBase;
while exist(sBakFile, 'file')
    nTries = nTries + 1;
    if (nTries > nMaxTries)
        error('EP:FILE_CREATE_FAILED', ...
            ['File "%s" cannot be created because it already exists. ', ...
            'Ranaming existing file failed because number of such backup files exceeds maximum.'], ...
            sFileToBeWritten);
    end
    
    sBakFile = sprintf('%s_%.3d', sBakFileBase, nTries);
end
fprintf('\n[INFO] To avoid overwriting data, moving file "%s" to "%s".\n\n', sFileToBeWritten, sBakFile);
movefile(sFileToBeWritten, sBakFile, 'f');
end


%%
function sContent = i_getDataStoreInitCommands(oWrapperData, sNameDS, sDataTypeDS, aiDimDS, sAliasName)
sContent = '';

[bEnum, sEnumType] = i_isEnumType(sDataTypeDS);
if bEnum
    sInitValue = [sEnumType '.' char(evalin('base', [sEnumType '.getDefaultValue']))];
else
    sInitValue = i_getInitValue(oWrapperData, sDataTypeDS, aiDimDS);
end
sTmp = [sNameDS '= Simulink.Signal;\n', ...
    sNameDS '.StorageClass = ''ExportedGlobal'';\n', ...
    sNameDS '.DataType = ''', sDataTypeDS, ''';\n', ...
    sNameDS '.Dimensions = ', mat2str(aiDimDS), ';\n',...
    sNameDS '.Complexity = ''real'';\n',...
    sNameDS '.InitialValue = ''', sInitValue, ''';'];

if ~isempty(sAliasName)
    sTmp = [sTmp '\n' sNameDS '.CoderInfo.Identifier = ''' sAliasName ''';'];
end

sContent = sprintf('%s\n\n%s', sContent, sprintf(sTmp));
end


%%
function sInitValue = i_getInitValue(oWrapperData, sDataType, aiDim)
sInitValue = ''; % default init value is an empty string; so SL/EC is able to use defaults on his own
try %#ok<TRYNC> 
    stInfo = oWrapperData.getTypeInfo(sDataType);
    if (~stInfo.bIsFxp || i_isZeroInAllowedRange(stInfo))
        sInitValue = '';
    else
        sInitValue = oWrapperData.oStorage.getTypeInstance(sDataType, aiDim);
    end
end
end


%%
function bIsInAllowedRange = i_isZeroInAllowedRange(stTypeInfo)
oValZero = ep_sl.Value(0);
bIsInAllowedRange = ...
    (stTypeInfo.oRepresentMin.compareTo(oValZero) <= 0) && ...
    (stTypeInfo.oRepresentMax.compareTo(oValZero) >= 0);
end


%%
function [bTrue, sEnumType] = i_isEnumType(sDataTypeStr)
bTrue = false;
sEnumType = '';
if strncmp(sDataTypeStr, 'Enum:', 5)
    bTrue = true;
    sEnumType = strtrim(sDataTypeStr(6:end));
elseif ~isempty(enumeration(bTrue))
    bTrue = true;
    sEnumType = sDataTypeStr;
end
end


