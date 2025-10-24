function oOnCleanupRevertClosing = ep_sim_harness_prepare_ws(sSrcModelName, sDefineDDEnumInWSScript)
% This function clears all enum types defined in the DD and re-defines them in the WS. 
%
% In order to do this the original model is first closed and then loaded again.
% The enum types that are initially defined in a start script are not affected.
%
%%  INPUT              DESCRIPTION
%
%   astDDEnumTypes         (Array of struct)      Structure containing the name and the elements of the enum types defined in DD
%
%   sSrcModelName          (String)               Source model's name
%
%   sExtrModelPath         (String)               Path of the extraction model
%
%
%%   OUTPUT              
%
%   oOnCleanupRevertClosing    (onCleanupObj)     onCleanup object that reverts the potential closing of models. Note:
%                                                 might be empty.
%

%%
oOnCleanupRevertClosing = [];
if ~isempty(sDefineDDEnumInWSScript)
    oOnCleanupRevertClosing = i_defineDDEnumsInWS(sSrcModelName, sDefineDDEnumInWSScript);   
end
end


%%
function oOnCleanupRevertClosing = i_defineDDEnumsInWS(sSrcModelName, sDefineDDEnumInWSScript)
evalin('base', 'save(''baseWS.mat'')');

oOnCleanupRevertClosing = i_closeAllModels(sSrcModelName);

run(sDefineDDEnumInWSScript);

if exist('baseWS.mat', 'file')
    warning('off', 'MATLAB:class:EnumerationValueChanged');
    evalin('base', 'load(''baseWS.mat'');');
    warning('on', 'MATLAB:class:EnumerationValueChanged');
end
end


%%
function oOnCleanupRevertClosing = i_closeAllModels(sSrcModelName)
astModels = i_getAllModels(sSrcModelName);
warning('off', 'Simulink:DataType:DynamicEnum_NowNotOwnedByDictionary');
cellfun(@close_system, {astModels(:).sName});
warning('on', 'Simulink:DataType:DynamicEnum_NowNotOwnedByDictionary');

oOnCleanupRevertClosing = onCleanup(@() arrayfun(@i_revertClosing, astModels));
end


%%
function astModels = i_getAllModels(sSrcModelName)
casModels = ep_find_mdlrefs(sSrcModelName);
casLibs = get_param(Simulink.allBlockDiagrams('library'), 'Name');
if ~isempty(casLibs)
    casModels = vertcat(casModels, casLibs);
end
cabIsOpen = cellfun(@i_isModelOpen, casModels, 'uni', false);
astModels = struct( ...
    'sName',  casModels, ...
    'bIsOpen', cabIsOpen);
end


%%
function i_revertClosing(stModel)
warning('off','SLDD:sldd:ReferencedEnumDefinedExternally');
if (stModel.bIsOpen)
    open_system(stModel.sName);
else
    load_system(stModel.sName);
end
warning('on','SLDD:sldd:ReferencedEnumDefinedExternally');
end


%%
function bIsOpen = i_isModelOpen(sModel)
bIsOpen = false;
try %#ok<TRYNC>
    sOpenState = get_param(sModel, 'Open');
    bIsOpen = strcmp(sOpenState, 'on');
end
end