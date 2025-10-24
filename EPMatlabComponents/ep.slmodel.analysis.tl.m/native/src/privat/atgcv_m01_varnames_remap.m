function stRes = atgcv_m01_varnames_remap(stEnv, sModelAnalysis, sCodeSymbols)
% rename all variable in ModelAnalysis according to CodeSymbols
%
% function res = atgcv_m01_varnames_remap(stEnv, sModelAnalysis, sCodeSymbols)
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)   Environment structure.
%     sModelAnalysis      (string)   full path to the ModelAnalysis.xml file
%     sCodeSymbols        (string)   full path to the CodeSymbols.xml file
%
%   OUTPUT              DESCRIPTION
%     stRes                 (struct)   result structure with following components
%       .sModModelAnalysis  (string)   name of the modified ModelAnalysis file 
%                                      (without path)
%     
%   REMARKS
%       internal function: no input checks
%
%   <et_copyright>


%% internal 
%
%   REFERENCE(S):
%     EP5-Document
%        $ModuleDirectory/doc/M01_ModelAnalysis.odt
%
%   RELATED MODULES:
%     - 
%   AUTHOR(S):
%     Alexander Hornstein
% $$$COPYRIGHT$$$
%
%   $Revision: 176375 $
%   Last modified: $Date: 2014-07-11 17:31:10 +0200 (Fr, 11 Jul 2014) $ 
%   $Author: jbohn $
%%

%% main
stRes = struct('sModModelAnalysis',  'ModModelAnalysis.xml');

if (isempty(stEnv) || ~isstruct(stEnv))
    stEnv = struct('hMessenger', 0, 'sResultPath', pwd());
end
sOutput = fullfile(stEnv.sResultPath, stRes.sModModelAnalysis);
copyfile(sModelAnalysis, sOutput);

i_remapSymbols(stEnv, sOutput, sCodeSymbols);
end



%% hack: remap arguments of functions in Matlab-m
function i_remapSymbols(stEnv, sModelAnalysis, sCodeSymbols)
jSymbolHash = i_getSymbolHash(sCodeSymbols);
if jSymbolHash.isEmpty()
    return;
end

hDoc = mxx_xmltree('load', sModelAnalysis);
try
    bIsModified = false;
    
    ahSubs = mxx_xmltree('get_nodes', hDoc, '/ma:ModelAnalysis/ma:Subsystem');
    for k = 1:length(ahSubs)
        hSub = ahSubs(k);

        sModule = mxx_xmltree('get_attribute', hSub, 'module');        
        sStepFct = mxx_xmltree('get_attribute', hSub, 'stepFct');
        sNewName = i_getNewName(stEnv, jSymbolHash, sStepFct, sModule);
        if ~isempty(sNewName)
            mxx_xmltree('set_attribute', hSub, 'stepFct', sNewName);
            bIsModified = true;
        end
        
        sInitFct = mxx_xmltree('get_attribute', hSub, 'initFct');
        if ~isempty(sInitFct)
            sNewName = i_getNewName(stEnv, jSymbolHash, sInitFct, sModule);
            if ~isempty(sNewName)
                mxx_xmltree('set_attribute', hSub, 'initFct', sNewName);
                bIsModified = true;
            end
        end
        
        if (i_mapArgs(stEnv, jSymbolHash, hSub, sModule))
            bIsModified = true;
        end
        if (i_mapParams(stEnv, jSymbolHash, hSub, sModule))
            bIsModified = true;
        end
        if (i_mapVariables(stEnv, jSymbolHash, hSub, sModule))
            bIsModified = true;
        end        
    end   
    
    if bIsModified
        mxx_xmltree('save', hDoc, sModelAnalysis);
    end
    mxx_xmltree('clear', hDoc);
catch
    stErr = osc_lasterror();
    mxx_xmltree('clear', hDoc);
    osc_throw(stErr);
end
clear jSymbolHash;
end


%%
function bIsModified = i_mapArgs(stEnv, jSymbolHash, hSub, sSubModule)
bIsModified = false;

ahArgs = mxx_xmltree('get_nodes', hSub, './ma:Signature/ma:Args/ma:Arg');
for i = 1:length(ahArgs)
    sExtName = mxx_xmltree('get_attribute', ahArgs(i), 'ext_name');
    if isempty(sExtName)
        % the ReturnValue has no ext name
        continue;
    end

    % check if the corresponding Parameter has an own Module
    % attribute <-- use this preferrably to the Subsystem Module
    sArgModule = sSubModule; % use Subsystem Module as fallback
    hCorrespondingParam = mxx_xmltree('get_nodes', hSub, ...
        sprintf('./ma:Interface/ma:Parameter[@argName="%s"]', sExtName));
    if ~isempty(hCorrespondingParam)
        % note: there could be more than one parameter with the same name
        sParamModule = ...
            mxx_xmltree('get_attribute', hCorrespondingParam(1), 'module');
        if ~isempty(sParamModule)
            sArgModule = sParamModule;
        end
    end
    
    sNewName = i_getNewName(stEnv, jSymbolHash, sExtName, sArgModule);
    if ~isempty(sNewName)
        mxx_xmltree('set_attribute', ahArgs(i), 'ext_name', sNewName);
        bIsModified = true;
    end
end    
end


%%
function bIsModified = i_mapParams(stEnv, jSymbolHash, hSub, sSubModule)
bIsModified = false;

% get all original Params without own declaration
ahParams = mxx_xmltree('get_nodes', hSub, ...
    './/ma:Parameter[not(@declaration)]');
for i = 1:length(ahParams)
    hParam = ahParams(i);    
    sArgName = mxx_xmltree('get_attribute', hParam, 'argName');
    sFullExpression = mxx_xmltree('get_attribute', hParam, 'expression');
    
    % 1) get the original name
    if isempty(sArgName)
        sVarName = sArgName;
    else
        % argName might be empty; in this case
        % try to extract variable name from expression
        % could be: varX, (varX), (*varX), &(varX), &varX->xx, varX.yy, ...
        ccVarName =  regexp(sFullExpression, '(\w+)', 'once', 'tokens');
        if ~isempty(ccVarName)
            sVarName = ccVarName{1};
        else
            sVarName = sFullExpression;
        end
    end
    
    % 2) get the new name
    sParamModule = mxx_xmltree('get_attribute', hParam, 'module');
    if ~isempty(sParamModule)
        sNewName = i_getNewName(stEnv, jSymbolHash, sVarName, sParamModule);
    else
        sNewName = i_getNewName(stEnv, jSymbolHash, sVarName, sSubModule);
    end
    
    % 3) now replace original name with new name if needed
    if ~isempty(sNewName)
        sNewExpression = regexprep(sFullExpression, '\w+', sNewName, 'once');
        mxx_xmltree('set_attribute', hParam, 'expression', sNewExpression);
        
        if ~isempty(sArgName)
            mxx_xmltree('set_attribute', hParam, 'argName', sNewName);
        end
        bIsModified = true;
    end
end    
end


%%
function bIsModified = i_mapVariables(stEnv, jSymbolHash, hSub, sSubModule)
bIsModified = false;

ahVars = mxx_xmltree('get_nodes', hSub, './/ma:Variable[@globalName]');
for i = 1:length(ahVars)
    hVar = ahVars(i);
    
    sModule = mxx_xmltree('get_attribute', hVar, 'module');
    if isempty(sModule)
        sModule = sSubModule;
    end
    
    sName = mxx_xmltree('get_attribute', hVar, 'globalName');
    sNewName = i_getNewName(stEnv, jSymbolHash, sName, sModule);
    if ~isempty(sNewName)
        mxx_xmltree('set_attribute', hVar, 'globalName', sNewName);
        bIsModified = true;
    end
end    
end


%% 
function sNewName = i_getNewName(stEnv, jSymbolHash, sSymbol, sModule)
sNewName = '';
if isempty(sSymbol)
    return;
end

sFound = char(jSymbolHash.get(sSymbol));
if ~isempty(sFound)
    if ~strcmp(sFound, i_getInvalidSymbol())
        sNewName = sFound;
    else
        if isempty(sModule)
            sFound = '';
        else
            sFound = ...
                char(jSymbolHash.get(i_getSymbolFileKey(sSymbol, sModule)));
        end
        if (~isempty(sFound) && ~strcmp(sFound, i_getInvalidSymbol()))
            sNewName = sFound;
        else
            stErr = atgcv_messenger_add(stEnv.hMessenger, ...
                'ATGCV:MOD_ANA:INTERNAL_ERROR', ...
                'script', 'atgcv_m01_varnames_remap', ...
                'text', sprintf( ...
                'Static symbol "%s" could not be uniquely identified.', ...
                sSymbol));
            atgcv_throw(stErr);
        end
    end
end
end


%% i_getSymbolHash
function jSymbolHash = i_getSymbolHash(sCodeSymbols)
jSymbolHash = java.util.Hashtable;
astRes = mxx_xmltool(sCodeSymbols, '//cs:CodeSymbol', 'origName', 'newName');
if isempty(astRes)
    return;
end

casNonUniqueNames = {};
nSymb = length(astRes);
for i = 1:nSymb
    sFormerName = char(jSymbolHash.put(astRes(i).origName, astRes(i).newName));
    if ~isempty(sFormerName)
        casNonUniqueNames{end + 1} = astRes(i).origName;
        
        % replace the original name with an invalid empty string
        jSymbolHash.put(astRes(i).origName, i_getInvalidSymbol());
    end
end
if ~isempty(casNonUniqueNames)
    i_extendSymbolHash(jSymbolHash, sCodeSymbols, casNonUniqueNames);
end
end


%% i_extendSymbolHash
% handle non-unique symbols by adding the file name to symbol
function i_extendSymbolHash(jSymbolHash, sCodeSymbols, casNonUniqueNames)
hDoc = mxx_xmltree('load', sCodeSymbols);
try
    ahFiles = mxx_xmltree('get_nodes', hDoc, '/cs:CodeSymbols/cs:CodeFile');
    for i = 1:length(ahFiles)
        hFile = ahFiles(i);
        
        sFilePath = mxx_xmltree('get_attribute', hFile, 'fileName');
        [p, f, e] = fileparts(sFilePath); %#ok
        sFileName = [f, e];
        
        ahSymbols = mxx_xmltree('get_nodes', hFile, './cs:CodeSymbol');
        for k = 1:length(ahSymbols)
            hSymbol = ahSymbols(k);
            
            sOrigName = mxx_xmltree('get_attribute', hSymbol, 'origName');
            if any(strcmpi(sOrigName, casNonUniqueNames))
                sUniqueKey = i_getSymbolFileKey(sOrigName, sFileName);
                sNewName = mxx_xmltree('get_attribute', hSymbol, 'newName');
                
                % check that we really have a unique key!
                sFormerName = char(jSymbolHash.put(sUniqueKey, sNewName));
                if ~isempty(sFormerName)
                    % replace the original name with an invalid empty string
                    jSymbolHash.put(sUniqueKey, i_getInvalidSymbol());                   
                end
            end
        end
    end    
    mxx_xmltree('clear', hDoc);
    
catch
    stErr = osc_lasterror();
    mxx_xmltree('clear', hDoc);
    osc_throw(stErr);
end
end


%% i_getSymbolFileKey
function sKey = i_getSymbolFileKey(sSymbolName, sFileName)
sKey = [sSymbolName, '|', lower(sFileName)];
end


%% i_getInvalidSymbol
function sInvalidSymbol = i_getInvalidSymbol()
sInvalidSymbol = '!XXX!';
end
