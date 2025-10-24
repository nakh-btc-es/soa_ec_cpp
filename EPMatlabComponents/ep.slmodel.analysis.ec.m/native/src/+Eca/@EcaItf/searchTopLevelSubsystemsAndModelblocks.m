function sBlockPath = searchTopLevelSubsystemsAndModelblocks(oEca, sModelName)
if (nargin < 2)
   sModelName = oEca.sModelName;
end

sBlockPath = i_searchUniqueOnRootLevel(oEca.EPEnv, sModelName);
if isempty(sBlockPath)
    sMsg = 'No root scope found.';
    oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sMsg);
	oEca.consoleErrorPrint(sMsg);
end
end


%%
function sRootSub = i_searchUniqueOnRootLevel(xEnv, sSearchRoot)
sRootSub = '';

astSubs = ep_core_feval('ep_model_subsystems_get', ...
    'Environment',  xEnv, ...
    'ModelContext', sSearchRoot);
if ~isempty(astSubs)
    sRootSub = astSubs(1).sPath;
end
end
