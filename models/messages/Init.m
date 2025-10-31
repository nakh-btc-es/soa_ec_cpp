model_cfg = Model_cfg();
InitBuses;


ParamScalar = 2;
ParamArray = [2 2];


InBusA = Simulink.Signal;
InBusA.CoderInfo.StorageClass = 'ExportedGlobal';
InBusA.DataType = 'myBus';

InB = Simulink.Signal;
InB.DataType = 'single';
InB.Min = -20;
InB.Max = 20;
InB.CoderInfo.StorageClass = 'ExportedGlobal';

InC = copy(InB);

InD = copy(InB);
InD.DataType = 'single';

%parameters
K = Simulink.Parameter;
K.CoderInfo.StorageClass = 'Custom';
K.CoderInfo.CustomStorageClass = 'ConstVolatile';
K.DataType = 'single';
K.Value = 1;
K.Min = -125;

%outputs
OutBusA = copy(InBusA);

OutB = copy(InB);
OutC = copy(InB);
OutD = copy(InB);
OutE = copy(InB);
OutF = copy(InB);
OutG = copy(InB);
OutH = copy(InB);
OutI = copy(InB);

%Params

BusParamStruct.FlptSig1 = single(1);
BusParamStruct.FlptSig2 = single(2);

BusParamObj = Simulink.Parameter;
BusParamObj.DataType = 'Bus: myBus';
BusParamObj.CoderInfo.StorageClass = 'ExportedGlobal';
BusParamObj.Value = BusParamStruct;
