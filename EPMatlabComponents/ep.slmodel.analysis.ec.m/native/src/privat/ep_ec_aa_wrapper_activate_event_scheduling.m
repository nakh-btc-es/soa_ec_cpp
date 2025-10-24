function [bActivated, bMissingEvents] = ep_ec_aa_wrapper_activate_event_scheduling(sWrapperModel, bForceSaveModel, oEca)
%
%
%
if nargin < 1
    sWrapperModel = bdroot;
    bForceSaveModel = false;
    oEca = '';
elseif nargin < 2
    bForceSaveModel = false;
    oEca = '';
elseif nargin < 3
    oEca = '';
end

bActivated = false;
bMissingEvents  = false;

[sMainModelPath, bIsAdaptiveAutosar] = i_findIntegrationModel(sWrapperModel);
if ~bIsAdaptiveAutosar
    return;
end

if bForceSaveModel
    oSaveup = onCleanup(@()save_system(sWrapperModel));
elseif strcmp(get_param(sWrapperModel, 'Dirty'), 'off')
    oCleanup = onCleanup(@()set_param(sWrapperModel, 'Dirty', 'off'));
end

oSchedule = get_param(sWrapperModel, 'Schedule');
aoEvents = oSchedule.Events;
if isempty(aoEvents)
    set_param(sWrapperModel, 'SimulationCommand','Update');
end

casChartsBlocks = ep_find_system(sMainModelPath, 'SearchDepth', 1, 'IncludeCommented', 'on', 'SFBlockType', 'Chart');
casNeededEvents = [];
for i= 1:numel(casChartsBlocks)
    sChart = casChartsBlocks{i};
    if strcmp(get_param(sChart, 'Commented'), 'on')
        oSFChart = find(sfroot, "-isa", "Stateflow.Chart", 'Path', sChart);
        oState = find(oSFChart, "-isa", "Stateflow.State");
        sEvent = char(extractBetween(oState.DuringAction, 'send(', ');'));

        casNeededEvents = [casNeededEvents; extractBetween(oState.DuringAction, 'send(', ');')]; %#ok
        % only activate SFChart when the corresponding event is actually found in the schedule editor
        if any(arrayfun(@(x) endsWith(x.Name, sEvent), aoEvents))
            if strcmp(get_param(sChart, 'Commented'), 'on')
                set_param(sChart, 'Commented', 'off');
            end
            bActivated = true;
        end
    end
end

casFoundEvents = arrayfun(@(x) char(x.Name), aoEvents, 'UniformOutput', false);
if ~all(arrayfun(@(x) endsWith(x, casFoundEvents), casNeededEvents))
    for i=1:numel(casFoundEvents)
        sEventName = casFoundEvents{i};
        adFound = strfind(sEventName, '.');
        if ~isempty(adFound)
            casFoundEvents{i} = strrep(sEventName(adFound(end)+1:length(sEventName)), 'ev_', '');
        end
    end
    casMissingEvents = casNeededEvents(not(ismember(casNeededEvents, casFoundEvents)));
    if ~isempty(casMissingEvents)
        bMissingEvents = true;
        for i = 1:numel(casMissingEvents)
            sMsg = sprintf(['Mandatory event "%s" is not found in the ScheduleEditor. Please add it manually to' ...
                ' enable MIL simulation.'], casMissingEvents{i});
            if ~isempty(oEca)
                oEca.addMessageEPEnv('EP:SLC:ERROR', 'msg', sMsg);
            else
                warning(sMsg); %#ok
            end
        end
    end
end
end

%%
function [sIntegrationModel, bIsAdaptiveAutosar] = i_findIntegrationModel(sWrapperModel)
bIsAdaptiveAutosar = false;
casMainModelBlock = ep_find_system(sWrapperModel, ...
    'SearchDepth',      3, ...
    'FollowLinks',      'on', ...
    'LookUnderMasks',   'all', ...
    'IncludeCommented', 'off', ...
    'BlockType',        'ModelReference', ...
    'Tag',              ep_ec_tag_get('Autosar Main ModelRef'));

if (strcmp(get_param(sWrapperModel, 'Tag'), Eca.aa.wrapper.Tag.Toplevel))
    bIsAdaptiveAutosar = true;
    sIntegrationModel = fileparts(casMainModelBlock{1});
end
end