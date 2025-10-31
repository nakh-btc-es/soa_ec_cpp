function InitBuses() 
% INITBUSES2 initializes a set of bus objects in the MATLAB base workspace 

%% Bus object: myBus 
clear elemsA;
elemsA(1) = Simulink.BusElement;
elemsA(1).Name = 'FlptSig1';
elemsA(1).Dimensions = 1;
elemsA(1).DimensionsMode = 'Fixed';
elemsA(1).DataType = 'single';
elemsA(1).SampleTime = -1;
elemsA(1).Complexity = 'real';
elemsA(1).SamplingMode = 'Sample based';
elemsA(1).Min = -10;
elemsA(1).Max = 10;
elemsA(1).DocUnits = '';
elemsA(1).Description = '';

elemsA(2) = Simulink.BusElement;
elemsA(2).Name = 'FlptSig2';
elemsA(2).Dimensions = 1;
elemsA(2).DimensionsMode = 'Fixed';
elemsA(2).DataType = 'single';
elemsA(2).SampleTime = -1;
elemsA(2).Complexity = 'real';
elemsA(2).SamplingMode = 'Sample based';
elemsA(2).Min = -20;
elemsA(2).Max = 20;
elemsA(2).DocUnits = '';
elemsA(2).Description = '';

myBus = Simulink.Bus;
myBus.HeaderFile = '';
myBus.Description = '';
myBus.DataScope = 'Auto';
myBus.Alignment = -1;
myBus.Elements = elemsA;

assignin('base','myBus', myBus);

%% Bus object: myBus2 
clear elemsB;
elemsB(1) = Simulink.BusElement;
elemsB(1).Name = 'FxptSig1';
elemsB(1).Dimensions = 1;
elemsB(1).DimensionsMode = 'Fixed';
elemsB(1).DataType = 'fixdt(1,16,2^-5,0)';
elemsB(1).SampleTime = -1;
elemsB(1).Complexity = 'real';
elemsB(1).SamplingMode = 'Sample based';
elemsB(1).Min = [];
elemsB(1).Max = 10;
elemsB(1).DocUnits = '';
elemsB(1).Description = '';

elemsB(2) = Simulink.BusElement;
elemsB(2).Name = 'FxptSig2';
elemsB(2).Dimensions = 1;
elemsB(2).DimensionsMode = 'Fixed';
elemsB(2).DataType = 'fixdt(1,16,2^-5,0)';
elemsB(2).SampleTime = -1;
elemsB(2).Complexity = 'real';
elemsB(2).SamplingMode = 'Sample based';
elemsB(2).Min = -10;
elemsB(2).Max = 15;
elemsB(2).DocUnits = '';
elemsB(2).Description = '';

myBus2 = Simulink.Bus;
myBus2.HeaderFile = '';
myBus2.Description = '';
myBus2.DataScope = 'Auto';
myBus2.Alignment = -1;
myBus2.Elements = elemsB;

assignin('base','myBus2', myBus2);

% Bus object: myBusOfBuses 
clear elemsC;
elemsC(1) = Simulink.BusElement;
elemsC(1).Name = 'BusSig1';
elemsC(1).Dimensions = 1;
elemsC(1).DimensionsMode = 'Fixed';
elemsC(1).DataType = 'Bus: myBus';
elemsC(1).SampleTime = -1;
elemsC(1).Complexity = 'real';
elemsC(1).SamplingMode = 'Sample based';
elemsC(1).Min = [];
elemsC(1).Max = [];
elemsC(1).DocUnits = '';
elemsC(1).Description = '';

elemsC(2) = Simulink.BusElement;
elemsC(2).Name = 'BusSig2';
elemsC(2).Dimensions = 1;
elemsC(2).DimensionsMode = 'Fixed';
elemsC(2).DataType = 'Bus: myBus2';
elemsC(2).SampleTime = -1;
elemsC(2).Complexity = 'real';
elemsC(2).SamplingMode = 'Sample based';
elemsC(2).Min = [];
elemsC(2).Max = [];
elemsC(2).DocUnits = '';
elemsC(2).Description = '';

myBusOfBuses = Simulink.Bus;
myBusOfBuses.HeaderFile = '';
myBusOfBuses.Description = '';
myBusOfBuses.DataScope = 'Auto';
myBusOfBuses.Alignment = -1;
myBusOfBuses.Elements = elemsC;


assignin('base','myBusOfBuses', myBusOfBuses);

%myBusOfSignalAndBus

elemt = Simulink.BusElement;
elemt.Name = 'DoubleFlptSig';
elemt.Dimensions = 1;
elemt.DimensionsMode = 'Fixed';
%elemt.DataType = 'single';
elemt.SampleTime = -1;
elemt.Complexity = 'real';
elemt.SamplingMode = 'Sample based';
elemt.Min = -10;
elemt.Max = 10;
elemt.DocUnits = '';
elemt.Description = '';

myBusOfSignalAndBus = Simulink.Bus;
myBusOfSignalAndBus.HeaderFile = '';
myBusOfSignalAndBus.Description = '';
myBusOfSignalAndBus.DataScope = 'Auto';
myBusOfSignalAndBus.Alignment = -1;
myBusOfSignalAndBus.Elements = [elemt, elemsC(1)];

assignin('base','myBusOfSignalAndBus', myBusOfSignalAndBus);


