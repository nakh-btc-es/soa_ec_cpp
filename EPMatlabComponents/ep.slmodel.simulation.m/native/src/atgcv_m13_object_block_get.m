function [sBlockPath, sModelRef] = atgcv_m13_object_block_get(xObject, bBreakModelRefs)
% get the full path name to the target link block in the extraction model including the calibration variable
%
% function [sBlockPath, sModelRef] = atgcv_m13_display_object_get(xObject, bBreakModelRefs)
%
%   INPUTS                   DESCRIPTION
%   xObject                (object)    Interface object
%   bBreakModelRefs        (boolean)   Should the model be selfcontained
%
% OutPUT:
%   sBlockPath             (string)    full block path name into the extraction model
%   sModelRef              (string)    Model reference name
%

%%
[sTargetRootPath, sSrcRootPhysicalPath, sSrcRootVirtualPath] = i_get_mapped_root_paths(xObject);

if ~bBreakModelRefs
    % note: if the model references were kept intact only the objects part of the main model were moved and
    %       the ones from the referenced models remained where they were --> physical paths are partly still valid
    
    sObjPhysicalPath = i_get_path(xObject, 'physicalPath');
    if isempty(sObjPhysicalPath)
        % it is assumed it is the same path (only a UT issue)
        % should be removed in the future
        sObjPhysicalPath = i_get_path(xObject, 'path');
    end
        
    % object has been moved if it is originating from inside the source root path AND if the source root path is not
    % a model itself --> (now its inside the target root)
    bIsPartOfSrcRootContent = i_is_prefix_path_of(sSrcRootPhysicalPath, sObjPhysicalPath);
    bSrcRootContentWasMoved = ~(i_is_model_diagram(sSrcRootPhysicalPath) && i_is_model_ref_block(sTargetRootPath));
    bObjWasMoved = bIsPartOfSrcRootContent && bSrcRootContentWasMoved;
    if bObjWasMoved
        % object has been moved  --> physical info from the original model not valid anymore
        %                        --> the new path needs to be computed from the root source path and root target path
        sBlockPath = i_replace_prefix_path(sObjPhysicalPath, sSrcRootPhysicalPath, sTargetRootPath);
        sModelRef  = '';
    else
        % object has not been moved --> physical info from the original model is still valid
        sModelRef  = i_get_model_name_from_path(sObjPhysicalPath);
        sBlockPath = sObjPhysicalPath;
    end
    
else
    % note: all model references were resolved
    %       --> *all* objects have been moved and none resides in a model reference
    %       --> this means that all virtual paths have become reality and must be considered instead of the physical path!
    sModelRef = '';
    
    sObjVirtualPath = i_get_path(xObject, 'path');
    sBlockPath = i_replace_prefix_path(sObjVirtualPath, sSrcRootVirtualPath, sTargetRootPath);
end
end


%%
function sPath = i_replace_prefix_path(sPath, sPrefixPath, sNewPrefixPath)
if strcmp(sPath, sPrefixPath)
    sPath = sNewPrefixPath;
else
    % note1: trying to replace prefix path with new prefix path inside an existing path
    %        example: orig-path = "a/b/c", pre-fix = "a/b", new-pre-fix = "x/y/z" --> new-path = "x/y/z/c"
    % note2: include the path separator in match pattern to avoid illegal matches like "a/bbb/c" <--> "a/b"
    %        example: orig-path = "a/bbb/c", pre-fix = "a/b", new-pre-fix = "x/y/z" --> new-path = "a/bbb/c"
    sMatchPattern = ['^', regexptranslate('escape', sPrefixPath), '/'];
    sPath = regexprep(sPath, sMatchPattern, [sNewPrefixPath, '/']);
end
end


%%
function bIsPrefix = i_is_prefix_path_of(sCandidatePrefixPath, sPath)
if strcmp(sPath, sCandidatePrefixPath)
    bIsPrefix = true;
else
    % note1: trying to find prefix path inside an existing path
    %        example: orig-path = "a/b/c", pre-fix = "a/b" --> successful match
    % note2: include the path separator in match pattern to avoid illegal matches like "a/bbb/c" <--> "a/b"
    %        example: orig-path = "a/bbb/c", pre-fix = "a/b" --> failed match
    sMatchPattern = ['^', regexptranslate('escape', sCandidatePrefixPath), '/'];
    bIsPrefix = ~isempty(regexp(sPath, sMatchPattern, 'once'));
end
end


%%
function bIsModel = i_is_model_diagram(sPath)
bIsModel = ~any('/' == sPath); % note: a root model path only contains only the model name and *no* path separator "/"
end


%%
function bIsModelRefBlock = i_is_model_ref_block(sPath)
bIsModelRefBlock = false;
try %#ok<TRYNC>
    if strcmp(get_param(sPath, 'type'), 'block')
        bIsModelRefBlock = strcmp(get_param(sPath, 'BlockType'), 'ModelReference');
    end
end
end


%%
function sObjPath = i_get_path(hObj, sPathAttrib)
sName = mxx_xmltree('get_name', hObj);
if any(strcmp(sName, {'InPort', 'OutPort'}))
    sName = mxx_xmltree('get_attribute', hObj, 'name');
    xScope = i_get_parent_scope(hObj);
    sScopePath = mxx_xmltree('get_attribute', xScope, sPathAttrib);
    sObjPath = [sScopePath, '/', sName];
else
    sObjPath = mxx_xmltree('get_attribute', hObj, sPathAttrib);
end
end


%%
function hParentScope = i_get_parent_scope(hObj)
hParentScope = mxx_xmltree('get_nodes', hObj, 'ancestor::Scope[1]'); % the next highest scope
end


%%
% note: both the physical and the virtual path are mapped to the the target root path!
function [sTargetRootPath, sSrcRootPhysicalPath, sSrcRootVirtualPath] = i_get_mapped_root_paths(hObj)
sTargetRootPath      = '';
sSrcRootPhysicalPath = '';
sSrcRootVirtualPath  = '';

% the next highest scope with mapping info is the root of the mapping!
hMappedRootScope = mxx_xmltree('get_nodes', hObj, 'ancestor-or-self::Scope[@mappingPath][1]');
if isempty(hMappedRootScope)
    warning('INTERNAL:NO_MAPPING_INFO', 'No root mapping info found.');
    return;
end

sTargetRootPath = mxx_xmltree('get_attribute', hMappedRootScope, 'mappingPath');
if (nargout > 1)
    sSrcRootPhysicalPath = mxx_xmltree('get_attribute', hMappedRootScope, 'physicalPath');
end
if (nargout > 2)
    sSrcRootVirtualPath = mxx_xmltree('get_attribute', hMappedRootScope, 'path');
end
end


%%
function sModel = i_get_model_name_from_path(sPath)
sModel = strtok(sPath, '/');
end
