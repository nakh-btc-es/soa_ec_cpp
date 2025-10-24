function bIsClosed = atgcv_m_model_close(~, stOpenRes)
% Close the current model, DD and remove the enhanced ML search path
%
% function atgcv_m_model_close(stEnv, stOpenRes)
%
%
%   INPUT               DESCRIPTION
%     stEnv               (struct)  environment structure
%     stOpenRes           (struct)  result of atgcv_m_model_open
%       .sModelFile       (string)  save input param for model_close
%       .casModelRefs       (cell)  contains all model references
%       .abIsModelRefOpen  (array)  TRUE if corresponding ModelRef was already
%                                   open/loaded, FALSE otherwise
%       .caInitScripts (cell array) save input param for model_close
%       .bIsTL           (boolean)  save input param for model_close
%       .bIsModelOpen       (bool)  TRUE if TL-Model is open, FALSE for
%                                   model is loaded
%       .sSearchPath      (string)  enhanced matlab search path or empty
%       .sDdFile          (string)  name of the DD to be reopened
%       .astAddDD          (array)  currently open additional DDs and Workspaces
%           .sFile        (string)  Full path to the DD File
%           .nDDIdx      (numeric)  Id of the DD workspace this DD is loaded in
%       .sActiveVariant   (string)  for TL < 2.2 the active variant of DD
%       .casOpenSys    (cell array) contains all aready loaded/open models and libraries
%
%
%   OUTPUT              DESCRIPTION
%   - bIsClosed             (bool)  TRUE if the model is closed, FALSE if it remains open
%
%   REMARKS
%       Perform following steps:
%       a) close the model without saving changes
%       b) close current DD if the current model was a TL model without
%          saving changes
%       c) remove the enhanced ML search path
%
%   <et_copyright>


%%
bIsClosed = false;
[~, sMdlName] = fileparts(stOpenRes.sModelFile);

if atgcv_use_tl
    % close current DD
    dsdd('Close', 'Save', 'off');
end

casKnownNames = {};
bKeepOpenSLDD = ~isempty(stOpenRes.casOpenSLDDs); % TODO: strange logic here; should be rechecked
for i = 1:length(stOpenRes.casModelRefs)
    sModelName = stOpenRes.casModelRefs{i};
    if bdIsLoaded(sModelName)
        sDictionaryName = get_param(stOpenRes.casModelRefs{i}, 'DataDictionary');
        if (~isempty(sDictionaryName) && ~any(strcmp(casKnownNames, sDictionaryName)))
            warning('off', 'SLDD:sldd:ReferencedEnumDefinedExternally');
            hDictionary = Simulink.data.dictionary.open(sDictionaryName);
            warning('on', 'SLDD:sldd:ReferencedEnumDefinedExternally');
            hDictionary.discardChanges;
            if ~bKeepOpenSLDD
                hDictionary.close;
            end
            casKnownNames{end + 1} = sDictionaryName; %#ok <AGROW>
        end
    end
end

if ~isempty(stOpenRes.casModelRefs)
    for i = 1:length(stOpenRes.casModelRefs)
        if ~stOpenRes.abIsModelRefOpen(i)
            sModelName = stOpenRes.casModelRefs{i};
            if bdIsLoaded(sModelName)
                i_closeLibs(sModelName, stOpenRes.casOpenSys);
                warning('off', 'SLDD:sldd:ReferencedEnumDefinedExternally');
                close_system(sModelName, 0);
                warning('on', 'SLDD:sldd:ReferencedEnumDefinedExternally');
            end
        end
    end
end

i_closeLibs(sMdlName, stOpenRes.casOpenSys);
if ~stOpenRes.bIsModelOpen
    % 1. close the model without saving changes
    if bdIsLoaded(sMdlName)
        warning('off', 'SLDD:sldd:ReferencedEnumDefinedExternally');
        sSLDD = get_param(sMdlName, 'DataDictionary');
        close_system(sMdlName, 0);
        i_robustCloseSLDD(sSLDD);
        warning('on', 'SLDD:sldd:ReferencedEnumDefinedExternally');
        bIsClosed = true;
    end
end

if ~isempty(stOpenRes.sDdFile)
    if atgcv_use_tl
        atgcv_dd_open('File', stOpenRes.sDdFile);
    end
end
if isfield(stOpenRes, 'astAddDD')
    for i = 1:length(stOpenRes.astAddDD)
        if exist(stOpenRes.astAddDD(i).sFile, 'file')
            dsdd('AutoLoad', ...
                'file', stOpenRes.astAddDD(i).sFile, ...
                'DDIdx', stOpenRes.astAddDD(i).nDDIdx);
        end
    end
end


% close all DLLs with suffix dll and mexw32, mexw64
sSearchPath = stOpenRes.sSearchPath;
while ~isempty(sSearchPath)
    [sPartPath, sSearchPath] = strtok(sSearchPath, pathsep()); %#ok<STTOK> 
    astDll   = dir( fullfile(sPartPath, '*.dll') );
    astMex32 = dir( fullfile(sPartPath, '*.mexw32') );
    astMex64 = dir( fullfile(sPartPath, '*.mexw64') );
    astM     = dir( fullfile(sPartPath, '*.m') );
    for k = 1:length(astDll)
        try 
            clear(astDll(k).name); 
        catch 
        end
    end
    for k = 1:length(astMex32)
        try 
            clear(astMex32(k).name);
        catch
        end
    end
    for k = 1:length(astMex64)
        try 
            clear(astMex64(k).name); 
        catch
        end
    end
    for k = 1:length(astM)
        try 
            clear(astM(k).name); 
        catch
        end
    end
end

% remove the enhanced ML search path
if ~isempty(stOpenRes.sSearchPath)
    sWarn = warning;
    warning off all;
    rmpath(stOpenRes.sSearchPath);
    rehash;
    warning( sWarn );
end
end


%%
function i_robustCloseSLDD(sSLDD)
if ~isempty(sSLDD)
    try %#ok<TRYNC> 
        if ~isempty(Simulink.data.dictionary.getOpenDictionaryPaths(sSLDD))
            Simulink.data.dictionary.closeAll(sSLDD, '-discard');
        end
    end
end
end


%%
function i_closeLibs(sModelName, casOpenSys)
% It is necessary to load the libraries explicitly and keep them open. Otherwise the code generation fails, because
% the libraries cannot be found. Hence, the libraries must also be closed explicitly.
try
    astLibInfoData = ep_libinfo(sModelName);
catch
    astLibInfoData = [];
end
for i = 1:length(astLibInfoData)
    if (bdIsLoaded(astLibInfoData(i).Library) && ~any(strcmp(astLibInfoData(i).Library, casOpenSys)))
        close_system(astLibInfoData(i).Library, 0);
    end
end
end
