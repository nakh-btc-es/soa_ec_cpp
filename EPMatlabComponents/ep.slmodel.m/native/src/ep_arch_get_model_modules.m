function astModules = ep_arch_get_model_modules(sModelName)
% Returns all modules that are part of the model.
%
% function astModules = ep_arch_get_model_modules(sModelName)
%
%   INPUT               DESCRIPTION
%     sModelName            (string)  name of the main model (required to be open/loaded)
%
%   OUTPUT              DESCRIPTION
%     astModules     (struct)            model modules (see below)
%           .stModule
%              .sKind         (string)     model | library | model_ref
%              .sFile         (string)     full path to model/lib file
%              .sVersion      (string)     version of model/lib file
%              .sCreated      (string)     creation date of model/lib file
%              .sModified     (string)     last modification date of model/lib file
%              .sCreator      (string)     model creator
%              .sIsModified   (string)     'yes'|'no' depending on modified state of model/lib
%
%   REMARKS:
%       Precondition:
%           1. provided model is assumed to be loaded/open
%


%%
astModules = [];
if isempty(sModelName)
    return;
end

% remove last model found by "find_mdlrefs" because it is the name of the main model itself
casModelRefs = ep_find_mdlrefs(sModelName);
casModelRefs(end) = [];

% do not read any info from following libs
casBlackListLibs = {...
    'tllib', ...
    'tldummylib', ...
    'simulink', ...
    'atgcv_lib', ...
    'evlib'}; 

casBlackListPaths = {};

sMlPath = matlabroot();
if ~isempty(sMlPath)
    casBlackListPaths{end + 1} = sMlPath;
end

sTlPath = ep_dspaceroot();
if isempty(sTlPath)
    sTlPath = getenv('TL_ROOT');
end
if ~isempty(sTlPath)
    casBlackListPaths{end + 1} = sTlPath;
end


% get all lib references in model
astLibInfo = ep_libinfo(sModelName);

if ~isempty(astLibInfo)
    % remove all unresolved/inactive lib references
    astLibInfo = astLibInfo(strcmpi({astLibInfo.LinkStatus}, 'resolved'));
    
    % remove double entries
    casLibs = unique({astLibInfo(:).Library});
    
    % exclude tllib and simulink from libs
    abSelect = true(1, length(casLibs));
    for i = 1:length(casLibs)
        abSelect(i) = ~any(strcmpi(casLibs{i}, casBlackListLibs));
    end
    casLibs = casLibs(abSelect);
else
    casLibs = {};
end

astModules = i_getMdlSpec(sModelName, 'model');
if ~isempty(casModelRefs)
    nModelRefs = length(casModelRefs);
    for i = 1:nModelRefs
        try
            get_param(casModelRefs{i}, 'handle');
        catch
            % maybe throw warning here
            continue;
        end        
        astModules(end + 1) = i_getMdlSpec(casModelRefs{i}, 'model_ref');
    end
end

if ~isempty(casLibs)
    nLibs = length(casLibs);
    
    for i = 1:nLibs
        % use lib only if it is accessible (robustness)
        try
            get_param(casLibs{i}, 'handle');
        catch
            % maybe throw warning here
            continue;
        end        
        astModules(end + 1) = i_getMdlSpec(casLibs{i}, 'library');
    end
end

% avoid libs from certain places: MATLABROOT, TL_ROOT (DSPACE_ROOT)
for i = 1:length(casBlackListPaths)
    if (length(astModules) > 1)    
        sPath = casBlackListPaths{i};
        nPathLen = length(sPath);
        
        % don't keep modules if they have the wrong paths
        abKeepModules = ~strncmpi(sPath, {astModules(:).sFile}, nPathLen);
        
        % always keep the original model info (i.e. the first module)
        abKeepModules(1) = true;
        
        astModules = astModules(abKeepModules);
    end
end
end


%%
% Returns the model specification
function stSpec = i_getMdlSpec(sMdlName, sKind)
% first translate Dirty:on|off --> IsModified:yes|no
sIsModified = 'no';
sDirty = get_param(sMdlName, 'Dirty');
if strcmpi(sDirty, 'on')
    sIsModified = 'yes';
end

%retrieve info from MDLInfo object if possible
oMdlInfo = Simulink.MDLInfo(sMdlName);
stSpec = struct( ...
    'sKind',       sKind, ...
    'sFile',       oMdlInfo.FileName, ...
    'sVersion',    oMdlInfo.ModelVersion, ...
    'sCreated',    get_param(sMdlName, 'Created'), ...
    'sModified',   get_param(sMdlName, 'LastModifiedDate'), ...
    'sCreator',    get_param(sMdlName, 'Creator'), ...
    'sIsModified', sIsModified);
end

