function ep_ec_model_wrapper_block_codegen_create(sModel, adPosition)
% Creates the BTC codegen block.
% Position of this block is determined by the scheduler block or the SUT block as fallback.
%
%  INPUT              DESCRIPTION
%    sModel              (char)     Name of model.
%    adPosition          (double)   Position coordinates for the block.

hCodegenBlock = add_block('built-in/Subsystem', [sModel, '/BTC Wrapper Codegen']);
set_param(hCodegenBlock, 'ShowName', 'off');
set_param(hCodegenBlock, 'Position', adPosition);

sCommand = i_getCallbackCommand();
set_param(hCodegenBlock, 'OpenFcn', sCommand);
% btc blue = [0.11 0.34 0.51], green = [0.22 0.79 0.62]
set_param(hCodegenBlock,'BackgroundColor', '[0.11 0.34 0.51]');
i_createCodeGenMask(hCodegenBlock);
end


 %%
function i_createCodeGenMask(hBlock)
oMask = Simulink.Mask.create(hBlock);
% FYI: this type name influences the callback mechanism
oMask.Type = 'BTC Wrapper Codegen Block';

oMask.addDialogControl( ...
    'Name',    'DescGroupVar', ...
    'Type',    'group', ...
    'Prompt',  'BTC Codegen');

oMask.addDialogControl( ...
    'Name',    'DescTextVar', ...
    'Type',    'text', ...
    'Prompt',  ['This is the BTC Embedded Systems Wrapper Codegen block.' ...
    'By double-clicking this block, code will be generated for the referenced model and the wrapper.'], ...
    'Container', 'DescGroupVar');

oMask.Display = ['disp(''\color{white}\fontsize{15} Generate Code' ...
    '\newline \color{white}\it\fontsize{12}     (double-click)'', ''texmode'', ''on'');'];
end


%%
function sCommand = i_getCallbackCommand()
sCommand = 'ep_core_feval(''ep_ec_model_callbacks'', gcbh);';
end

