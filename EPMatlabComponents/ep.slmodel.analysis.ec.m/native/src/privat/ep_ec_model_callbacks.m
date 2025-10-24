function ep_ec_model_callbacks(hCallerBlock)
if nargin < 1
    hCallerBlock = gcbh;
end

oMask = Simulink.Mask.get(hCallerBlock);
sCaller = oMask.Type;
if strcmp(sCaller, 'BTC Wrapper Codegen Block')
    i_callWrapperCodegen(hCallerBlock);
else
    error('EP:ERROR', 'No callback found for this block.');
end
end


%%
function i_callWrapperCodegen(hBlock)
sWrapperModel = get_param(bdroot(hBlock), 'Name');
try
    if ~bdIsDirty(sWrapperModel)
        oCleanupDirty = onCleanup(@() set_param(sWrapperModel, 'Dirty', 'off'));
    end
    set_param(hBlock, 'Commented', 'on');

    ep_ec_model_wrapper_codegen(sWrapperModel);
    set_param(hBlock, 'Commented', 'off');
catch Ex
    sldiagviewer.reportError(Ex);
    set_param(hBlock, 'Commented', 'off');
end
end

