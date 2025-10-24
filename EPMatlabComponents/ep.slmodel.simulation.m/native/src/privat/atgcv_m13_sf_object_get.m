function hSfObject = atgcv_m13_sf_object_get(sModel,hModelContextNode,sStateChart)
%
% function hSfObject = atgcv_m13_sf_object_get(sModel,hModelContextNode,sStateChart)
%
%   INPUTS               DESCRIPTION
%
%
%   OUTPUT               DESCRIPTION
%     -                     -
%
%   
%%

% find the corresponding Stateflow chart object
root= sfroot;
machine= root.find('-isa','Stateflow.Machine', ...
    '-and','Path',sModel,'-and','FullFileName','');


sStateChartName = get_param(sStateChart, 'Name');
sfchart= machine.find('-isa','Stateflow.Chart', ...
    '-and','Name',sStateChartName);
if isempty(sfchart)
    % workaround for lib-linked SF-Charts
    sfchart = machine.find('Name', sStateChartName);
    if (length(sfchart) > 1)
        sfchart = machine.find('-isa','Simulink.SubSystem', ...
            '-and','Name',sStateChartName);
    end
    if ~isempty(sfchart)
        atgcv_m13_break_linkstatus(sfchart);
        sfchart= machine.find('-isa','Stateflow.Chart','-and','Name',sStateChartName);
    end
end
if isempty(sfchart)
    error('ATGCV:MIL_GEN:INTERNAL_ERROR', 'Could not find SF Chart %s.', ...
        sStateChartName);
end

for counter=1:length(sfchart)
    TmpChart= sfchart(counter);
    if strcmp(TmpChart.Path, sStateChart)
        sfStateHandle = TmpChart.Id;
        break
    end
end

% find the variables-Identifier
dataItems = sf('DataOf', sfStateHandle);

% get the name of the calibration variable and the identifier
sSFVarName = ep_em_entity_attribute_get(hModelContextNode, 'stateflowVariable');

bVarFound = false;
for j=1:length(dataItems),
    dataName = sf('get', dataItems(j), '.name');
    if strcmp(dataName,sSFVarName)
        bVarFound = true;
        break;
    end
end
if ~bVarFound
    error('ATGCV:MIL_GEN:INTERNAL_ERROR', ...
        'Could not find variable %s in SF Chart %s.', ...
        sSFVarName, sStateChartName);
end
hSfObject = dataItems(j);
end
