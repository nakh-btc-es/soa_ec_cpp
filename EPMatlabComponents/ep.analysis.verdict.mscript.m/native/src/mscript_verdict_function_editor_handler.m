function xResult = mscript_verdict_function_editor_handler(sAction,varargin)
% Handles the editor lifecycle for a M-based Verdict Function
%
%   INPUTS                  DESCRIPTION
%   - sAction               (string) Action to perform
%                           Can be: 'open_editor', 'close_editor',
%                           'check_function_name', 'find_editor'
%   - varargin              (variable) Depends on sAction
%     'open_editor'         (string) full-path to file to open
%     'close_editor'        (string) full-path to file to close
%                           (boolean) flag to specify if the editor should be
%                            saved before closing
%     'check_function_name' (string) name to check
%     'find_editor'         (string) full-path to file to find
%
% $$$COPYRIGHT$$$-2017

xResult = [];
switch lower(sAction)
    case 'open_editor'
        sFileToOpen = varargin{1};
        clearDebug(sFileToOpen);
        warning('off');
        open(sFileToOpen);
        warning('on');
        i_activateEditor(sFileToOpen);
    case 'close_editor'
        asFilePaths = varargin{1};
        bSaveFlag = varargin{2};
            sFilePath = asFilePaths;
            oEditor = i_getEditor(sFilePath); 
            if isempty(oEditor)
                return;
            end
            if i_isEditorDirty(oEditor) && bSaveFlag == true
                i_saveEditor(oEditor) 
            end
            i_closeEditor(oEditor);
            clearDebug(sFilePath);
            warning('on');
    case 'check_function_name'
        sFunctionName = char(varargin{1});
        xResult = validate_verdict_function_name(sFunctionName);
    case 'find_editor'
        sFilePath = varargin{1};
        xResult = i_getEditor(sFilePath);
end

end

function i_activateEditor(sFilePath)
oEditor = i_getEditor(sFilePath);
if ~isempty(oEditor)
    sMlVersion = i_getMatlabVersion();
    switch (sMlVersion)
        case 'm2010b'
            oEditor.bringToFront();
        case 'm2011a'
            oEditor.makeActive();
    end
end
    
end
function nMessageKind = validate_verdict_function_name(sName)
nMessageKind = 0;
if isvarname(sName)
    if exist(sName,'builtin')
        nMessageKind = 1; %name must not be a builtin function
        return;
    end
    sMatlabToolbox=fullfile(matlabroot,'toolbox','matlab');
    castFileInfo = which(sName,'-all');
    for iFile = 1:length(castFileInfo)
        sFile=castFileInfo{iFile};
        if any(strfind(sFile,sMatlabToolbox))
            nMessageKind=1; % name 
            return;
        end
    end
else
    nMessageKind = -1; %name must be a valid function name
end
end
function clearDebug(sFilePath)
sCWD=cd();
try
    [sFileParentPath,sFileName]=fileparts(sFilePath);
    cd(sFileParentPath);
    eval(['dbclear in ', sFileName]);
    cd(sCWD);
catch
    cd(sCWD);
end
end

function sMlVersion = i_getMatlabVersion()
sMlVersion = 'm2011a';
if verLessThan('matlab','7.1')
    sMlVersion = 'm2010a';
elseif verLessThan('matlab','7.12')
    sMlVersion = 'm2010b';
end
end

function oEditor = i_getEditor(sScriptPath)
oEditor = [];
sMlVersion = i_getMatlabVersion();
jScriptPath = java.io.File(sScriptPath).getCanonicalPath();
switch lower(sMlVersion)
    case 'm2010a'
        ajEditorNames =  com.mathworks.mlservices.MLEditorServices.builtinGetOpenDocumentNames();
        jScriptPath = java.io.File(sScriptPath).getCanonicalPath();
        for iEditor = 1:length(ajEditorNames)
            sEditorName = ajEditorNames(iEditor);
            sEditorCanonicalName = java.io.File(sEditorName).getCanonicalPath();
            if jScriptPath.equals(sEditorCanonicalName)
                oEditor = sEditorName;
                return;
            end
        end
    case 'm2010b'
        oEditorApplication = com.mathworks.mlservices.MLEditorServices.getEditorApplication() ;
        aoEditors = oEditorApplication.getOpenEditors;
        for iEditor = 0:aoEditors.size()-1
            oCurrentEditor = aoEditors.get(iEditor);
            sCurrentEditorPath = java.io.File(oCurrentEditor.getLongName()).getCanonicalPath();
            if sCurrentEditorPath.equals(jScriptPath)
                oEditor = oCurrentEditor;
                return;
            end
        end
    case 'm2011a'
        oEditor = matlab.desktop.editor.findOpenDocument(sScriptPath);
end
end

function bIsDirty = i_isEditorDirty(oEditor)
if isempty(oEditor)
    bIsDirty = false;
    return;
end
sMlVersion = i_getMatlabVersion();
switch lower(sMlVersion)
    case 'm2010a'
        bIsDirty = com.mathworks.mlservices.MLEditorServices.isDocumentDirty(oEditor);
    case 'm2010b'
        bIsDirty = oEditor.isDirty();
    case 'm2011a'
        bIsDirty = oEditor.Modified;
end
end

function i_closeEditor(oEditor)
if isempty(oEditor)
    return;
end
sMlVersion = i_getMatlabVersion();
switch lower(sMlVersion)
    case 'm2010a'
        com.mathworks.mlservices.MLEditorServices.closeDocument(oEditor);
    case {'m2010b','m2011a'}
        oEditor.closeNoPrompt();
end
end

function i_saveEditor(oEditor)
if isempty(oEditor)
    return;
end
sMlVersion = i_getMatlabVersion();
switch lower(sMlVersion)
    case 'm2010a'
        com.mathworks.mlservices.MLEditorServices.saveDocument(oEditor);
    case 'm2010b'
        % not available
    case 'm2011a'
        oEditor.save();
end
end
