function ep_ec_model_wrapper_codegen(sModel)
% This script can be used to generate code for the wrapper and the referenced model.
%
%  INPUT              DESCRIPTION
%   sModel              (char)*    Name of the wrapper model.
%
% (*) Optional inputs.

if nargin < 1
    sModel = bdroot;
end

bWrapperIsValid = i_isWrapperComplete(sModel);
if ~bWrapperIsValid
    error('EP:ERROR', 'Cannot generate code because model is not a valid BTC Wrapper.');
end

oDirectorySwitch = i_switchToModelDirectory(sModel); %#ok<NASGU> onCleanup object

[sWrapperVariant, sMainModel, bIsAdaptiveAutosar] = i_findMainModelSubsystemWithTag(sModel);
if ~bdIsLoaded(sMainModel)
    load_system(sMainModel);
end

stResult = ep_ec_codegen(sMainModel);
i_appendMarkerToBuildInfo(stResult);
if (bIsAdaptiveAutosar)
    % generated code for AA wrapper models may be incomplete without EC AA analysis (missing namespace workaround)
    ep_ec_aa_adapter_code_create(sMainModel, fullfile(stResult.oBuildInfo.getBuildDirList{1}, [sMainModel '_adapter.cpp']));
end

oRestoreVariant = i_switchVariantToDummy(sWrapperVariant); %#ok<NASGU> onCleanup object
stResult = ep_ec_codegen(sModel);
i_appendMarkerToBuildInfo(stResult);
end


%%
function bIsWrapperComplete = i_isWrapperComplete(sModel)
bIsWrapperComplete = strcmp(get_param(sModel, 'Tag'), ep_ec_tag_get('all wrappers'));
end


%%
function oDirectorySwitch = i_switchToModelDirectory(sModel)
sOriginDir = pwd;
sModelDir = fileparts(get_param(sModel, 'FileName'));
cd(sModelDir);
oDirectorySwitch = onCleanup(@() cd(sOriginDir));
end


%%
function [sWrapperVariant, sMainModel, bIsAdaptiveAutosar] = i_findMainModelSubsystemWithTag(sWrapperModel)
bIsAdaptiveAutosar = false;
casMainModelBlock = ep_find_system(sWrapperModel, ...
    'SearchDepth',      3, ...
    'FollowLinks',      'on', ...
    'LookUnderMasks',   'all', ...
    'IncludeCommented', 'off', ...
    'BlockType',        'ModelReference', ...
    'Tag',              ep_ec_tag_get('Autosar Main ModelRef'));

[sWrapperVariant, sMainModel] = fileparts(casMainModelBlock{1});
if (strcmp(get_param(sWrapperModel, 'Tag'), Eca.aa.wrapper.Tag.Toplevel))
    bIsAdaptiveAutosar = true;    
    sMainModel = replace(sMainModel,'W_integ_','');
end
end


%%
function oRestoreVariant = i_switchVariantToDummy(sVariantSubsystem)
sModel = bdroot(sVariantSubsystem);

% note: the switching of the variant will make the model artificially dirty
% --> try to avoid that and to return to the previous dirty sate
bHasCleanStateBefore = ~strcmp(get_param(sModel, 'Dirty'), 'on');

sCurrentVariant = get_param(sVariantSubsystem, 'OverrideUsingVariant');
if ~strcmp(sCurrentVariant, 'orig')
    error('EP:DEV:ERROR', 'Expecting variant "orig" to be the overriding active variant.');
end
set_param(sVariantSubsystem, 'OverrideUsingVariant', 'dummy');

oRestoreVariant = onCleanup(@() i_restoreVariant(sVariantSubsystem, sCurrentVariant, bHasCleanStateBefore));
end


%%
function i_restoreVariant(sVariantSubsystem, sCurrentVariant, bSetNonDirty)
set_param(sVariantSubsystem, 'OverrideUsingVariant', sCurrentVariant);

if bSetNonDirty
    sModel = bdroot(sVariantSubsystem);
    set_param(sModel, 'Dirty', 'off');
end
end


%%
function i_appendMarkerToBuildInfo(stResult)
buildInfo = stResult.oBuildInfo;
sBuildFile = fullfile(stResult.oBuildInfo.getBuildDirList{1}, 'buildInfo.mat');

% note: this flag is currently not used elsewhere
buildInfo.Settings.TargetInfo.BTCCodegen = 'yes';
save(sBuildFile, 'buildInfo', '-append');
end

