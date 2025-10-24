function stResult = ep_arch_get_sl_subsystem_hierarchy(xEnv, sSlModelName, hSubsystemFilter)
% This function returns the subsystem hierarchy of a given Simulink model.
%
% function stResult = ep_arch_get_sl_subsystem_hierarchy(xEnv, sSlModelName)
%
%  INPUT                   DESCRIPTION
%  - xEnv                   (Object)     environment
%  - sSlModelFile           (String)     name of the Simulink model
%  - hSubsystemFilter       (handle)     Optional callback function for filtering subsystems. If not given, a default
%                                        filter will be used
%
%  OUTPUT                  DESCRIPTION
%  - stSubsystemHierarchy   (Struct)     the subsystem hierarchy
%      .sPath               (String)     the (virtual) path of a subsystem
%      .caSubsystems        (cell array) Entities of subsystem nodes
%
%  REMARKS
%
% $$$COPYRIGHT$$$-2014

%%  internal
%  $Author: myname $
%  $Date: 2014-09-24 10:32:35 +0200 (Mi, 24 Sep 2014) $
%  $Revision: 452 $


%%
try
    if nargin < 3
        hSubsystemFilter = [];
    end
    stResult = i_getHierarchy(sSlModelName, hSubsystemFilter);
catch oEx
    xEnv.throwException(xEnv.addMessage('EP:STD:GENERAL_ERROR', ...
        'msg', sprintf('Subsystem hierarchy could not be read.\nMessage: %s', oEx.message)));
end
end


%%
function stModel = i_getHierarchy(sModel, hSubFilter)
if isempty(hSubFilter)
    astSubs = ep_model_subsystems_get('ModelContext', sModel);
else 
    astSubs = ep_model_subsystems_get('ModelContext', sModel, 'SubsystemFilter', hSubFilter);
end

% starting the recursive algorithm
stModel.caSubsystems = i_getChildrenOf(astSubs, []);
end


%%
function caSubsystems = i_getChildrenOf(astSubs, iParent)
aiChildIdx = find(arrayfun(@(stSub) isequal(stSub.iParentIdx, iParent), astSubs));

caSubsystems = cell(1, 0);
for i = 1:length(aiChildIdx)
    iChildIdx = aiChildIdx(i);
    
    stSubChild = astSubs(iChildIdx);
    
    caChildrenOfChild = i_getChildrenOf(astSubs, iChildIdx);
    if isempty(caChildrenOfChild)
        stChild = struct( ...
            'sPath', stSubChild.sVirtualPath);
    else
        stChild = struct( ...
            'sPath', stSubChild.sVirtualPath, ...
            'caSubsystems', {caChildrenOfChild});
    end
    caSubsystems{end + 1} = stChild; %#ok<AGROW>
end
end
