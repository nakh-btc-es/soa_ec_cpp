function stConfig = ep_ec_ecacfg_codeformat_config_get(xEnv, stUserConfig)

if (nargin == 0)
    stConfig = i_getDefaultConfig();
else
    casKnownIndermediateSettings = {};
    stConfig = ep_ec_settings_merge(xEnv, i_getDefaultConfig(), stUserConfig, casKnownIndermediateSettings);
end
end


%%
function stCfg = i_getDefaultConfig()
%
%
% AdditionalFilterCond : Must return a boolean (True enable the filter)
%
% Available Macros that can be interpreted by "eval" command
% <DATANAME>                : name of the data object
% <DATAOBJ>                 : data object variable
% <PARSCOPEDEFFILE>         : name of parent subssystem's c-file
% <MODELCFILE>              : model.c
% <MODELHFILE>              : model.h
% <MODELPRIVHFILE>          : model_private.h
% <PARSCOPEFUNCNAME>        : name of parent c-function
% <PARSCOPEFULLNAME>        : name of parent subsystem
% <CCODDATATYPE>            : datatype used in c-code
% <MODELNAME>               : name of the model

ii = 0;
stCfg.VarObjectClasses = { ...
    'BTC.Signal', ...
    'mpt.Signal', ...
    'Simulink.Signal', ...
    'AUTOSAR.Signal', ...
    'AUTOSAR4.Signal', ...
    'BTC.Parameter', ...
    'mpt.Parameter', ...
    'Simulink.Parameter', ...
    'AUTOSAR.Parameter', ...
    'AUTOSAR4.Parameter', ...
    'Simulink.Breakpoint', ...
    'Simulink.LookupTable'};
stCfg.AdditionalFilterCond = ...
    '~isa(<DATAOBJ>, ''Simulink.LookupTable'') || strcmp(<DATAOBJ>.BreakpointsSpecification, ''Reference'')';  % NEW !!!


ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'Global'};
stCfg.VarFormat(ii).Filter.AdditionalFilterCond     = 'ismember(class(<DATAOBJ>), {''AUTOSAR4.Signal'', ''AUTOSAR4.Parameter''})'; 
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = false;

ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'Const', 'ConstVolatile', 'Global', 'ExportToFile', 'Volatile'};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '<DATAOBJ>.CoderInfo.CustomAttributes.DefinitionFile';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = false;

%Signal / StorageClass = 'ExportedGlobal'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = {'ExportedGlobal'};
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {''};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '<MODELHFILE>';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '<MODELCFILE>';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = false;

%Signal / StorageClass = 'Default'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = {'Custom'};
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'Default'};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '<MODELHFILE>';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '<MODELCFILE>';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = false;

ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'GetSet'};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = true;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
%'''user_data_definition.c'''; %If is empty or not found in codegen file list, stubgen will be activated
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = true;
%Simplified Get/Set functions
stCfg.VarFormat(ii).Stub.accessFuncType             = 'Simplified'; %Advanced
%get access stub format
%Could also be '[''get_'',<DATANAME>]';
stCfg.VarFormat(ii).Stub.getFunc.Name               = '<DATAOBJ>.CoderInfo.CustomAttributes.GetFunction';
%set access stub format
%Could also be '[''set_'',<DATANAME>]';
stCfg.VarFormat(ii).Stub.setFunc.Name               = '<DATAOBJ>.CoderInfo.CustomAttributes.SetFunction';
stCfg.VarFormat(ii).Stub.StubVariableName           = '<DATANAME>';
%Advanced Get/Set functions
% stDefaultConfig.VarFormat(ii).Stub.accessFuncType             = 'Advanced';
% stDefaultConfig.VarFormat(ii).Stub.StubVariableName           = '<DATANAME>';
% %-get access stub format
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(1).kind       = 'input'; %input or output or return
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(1).isPointer  = false; %ignored if argument kind = output or return
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(1).argName    = 'arg1';
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(1).DataType   = 'Uint8'; %can be 'xxxx'
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(2).kind       = 'return'; %input or output or return
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(2).isPointer  = false; %ignored if argument kind = output or return
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(2).argName    = 'arg1';
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(2).DataType   = 'Uint8'; %can be 'xxxx'
% stDefaultConfig.VarFormat(ii).Stub.getFunc.ArgForStubVar      = stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(2);
% %-set access stub format
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(1).kind       = 'input'; %input or output or return
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(1).isPointer  = false;
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(1).argName    = 'argIn';
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(1).DataType   = 'Uint8'; %can be 'xxxx'
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(2).kind       = 'output'; %input or output or return
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(2).isPointer  = true; %ignored if argument kind = output or return
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(2).argName    = 'argIn';
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(2).DataType   = 'Uint8'; %can be 'xxxx'
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(3).kind       = 'return'; %input or output or return
% stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(3).isPointer  = false; %ignored if argument kind = output or return
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(3).argName    = 'arg1';
% stDefaultConfig.VarFormat(ii).Stub.setFunc.Args(3).DataType   = 'Uint8'; %can be 'xxxx'
% stDefaultConfig.VarFormat(ii).Stub.setFunc.ArgUsedForStub     = stDefaultConfig.VarFormat(ii).Stub.getFunc.Args(1);

ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = {'Custom'};
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'Struct', 'BitField', 'StructVolatile'};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = true;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '<DATAOBJ>.CoderInfo.CustomAttributes.StructName';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeVariableName         = '';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '<MODELCFILE>';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = false;

%StorageClass = 'ImportedExtern' / CustomStorage = ''
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = 'ImportedExtern';
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {''};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '<MODELPRIVHFILE>';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = true;
stCfg.VarFormat(ii).Stub.codeStructName             = '';
stCfg.VarFormat(ii).Stub.codeStructComponentName    = '';
stCfg.VarFormat(ii).Stub.codeVariableName           = '<DATANAME>';

%StorageClass = 'Custom' / CustomStorageClass = 'FileScope'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'FileScope'};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '<PARSCOPEDEFFILE>';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = false;

%StorageClass = 'Custom' / CustomStorage = 'ImportFromFile'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass             = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass       = {'ImportFromFile'};
stCfg.VarFormat(ii).Format.isCodeStructComponent    = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction     = false;
stCfg.VarFormat(ii).Format.codeStructName           = '';
stCfg.VarFormat(ii).Format.codeStructComponentName  = '';
stCfg.VarFormat(ii).Format.codeVariableName         = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile           = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
stCfg.VarFormat(ii).Format.codeDefinitionFile       = '';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stCfg.VarFormat(ii).Stub.canBeStubbed               = true;
stCfg.VarFormat(ii).Stub.codeStructName             = '';
stCfg.VarFormat(ii).Stub.codeStructComponentName    = '';
stCfg.VarFormat(ii).Stub.codeVariableName           = '<DATANAME>';

%StorageClass = 'Custom' / CustomStorage = 'Reusable.Imported'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass                 = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass           = {'Reusable'};
stCfg.VarFormat(ii).Filter.CustomAttributes(1).name     = 'DataScope';
stCfg.VarFormat(ii).Filter.CustomAttributes(1).value    = 'Imported';
stCfg.VarFormat(ii).Format.isCodeStructComponent        = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction         = false;
stCfg.VarFormat(ii).Format.codeStructName               = '';
stCfg.VarFormat(ii).Format.codeStructComponentName      = '';
stCfg.VarFormat(ii).Format.codeVariableName             = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile               = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
stCfg.VarFormat(ii).Format.codeDefinitionFile           = '';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode            = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv        = 'ColumnMajor';
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv        = '';
stCfg.VarFormat(ii).Stub.canBeStubbed                   = true;
stCfg.VarFormat(ii).Stub.codeStructName                 = '';
stCfg.VarFormat(ii).Stub.codeStructComponentName        = '';
stCfg.VarFormat(ii).Stub.codeVariableName               = '<DATANAME>';

%StorageClass = 'Custom' / CustomStorage = 'Reusable.Exported'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID                               = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass                 = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass           = {'Reusable'};
stCfg.VarFormat(ii).Filter.CustomAttributes(1).name     = 'DataScope';
stCfg.VarFormat(ii).Filter.CustomAttributes(1).value    = 'Exported';
stCfg.VarFormat(ii).Format.isCodeStructComponent        = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction         = false;
stCfg.VarFormat(ii).Format.codeStructName               = '';
stCfg.VarFormat(ii).Format.codeStructComponentName      = '';
stCfg.VarFormat(ii).Format.codeVariableName             = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile               = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
stCfg.VarFormat(ii).Format.codeDefinitionFile           = '<DATAOBJ>.CoderInfo.CustomAttributes.DefinitionFile';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode            = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv        = 'ColumnMajor'; %RowMajor
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv        = '';
stCfg.VarFormat(ii).Stub.canBeStubbed                   = false;

%StorageClass = 'Custom' / CustomStorage = 'Reusable.Auto'
ii = ii + 1;
stCfg.VarFormat(ii).cfgID                               = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass                 = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass           = {'Reusable'};
stCfg.VarFormat(ii).Filter.CustomAttributes(1).name     = 'DataScope';
stCfg.VarFormat(ii).Filter.CustomAttributes(1).value    = 'Auto';
stCfg.VarFormat(ii).Format.isCodeStructComponent        = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction         = false;
stCfg.VarFormat(ii).Format.codeStructName               = '';
stCfg.VarFormat(ii).Format.codeStructComponentName      = '';
stCfg.VarFormat(ii).Format.codeVariableName             = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile               = '<MODELHFILE>';
stCfg.VarFormat(ii).Format.codeDefinitionFile           = '<MODELCFILE>';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode            = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv        = 'ColumnMajor';
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv        = '';
stCfg.VarFormat(ii).Stub.canBeStubbed                   = false;

% ImportedDefine
ii = ii + 1;
stCfg.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stCfg.VarFormat(ii).Filter.StorageClass                   = 'Custom';
stCfg.VarFormat(ii).Filter.CustomStorageClass             = {'ImportedDefine'};
stCfg.VarFormat(ii).Format.isCodeStructComponent          = false;
stCfg.VarFormat(ii).Format.isAccessedByFunction           = false;
stCfg.VarFormat(ii).Format.codeStructName                 = '';
stCfg.VarFormat(ii).Format.codeStructComponentName        = '';
stCfg.VarFormat(ii).Format.codeVariableName               = '<DATANAME>';
stCfg.VarFormat(ii).Format.codeHeaderFile                 = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
stCfg.VarFormat(ii).Format.codeDefinitionFile             = '';
stCfg.VarFormat(ii).Format.b2DMatlabIs1DCode              = true;
stCfg.VarFormat(ii).Format.s2DMatlabTo1DCodeConv          = 'ColumnMajor';
stCfg.VarFormat(ii).Format.s2DMatlabTo2DCodeConv          = '';
stCfg.VarFormat(ii).Stub.canBeStubbed                     = true;
stCfg.VarFormat(ii).Stub.codeStructName                   = '';
stCfg.VarFormat(ii).Stub.codeStructComponentName          = '';
stCfg.VarFormat(ii).Stub.codeVariableName                 = '<DATANAME>';

% Extensions that define special cases not covered by the main config
stCfg.Ext = i_getExtensions(ii);
end


%%
function astExt = i_getExtensions(iCounterID)
[astExt(1), iCounterID] = i_getExtensionLUT(iCounterID);
% ...
end


%%
function [stExt, iCounterID] = i_getExtensionLUT(iCounterID)
ii = 0;
stExt.VarObjectClasses = {'Simulink.LookupTable'};
stExt.AdditionalFilterCond = '~strcmp(<DATAOBJ>.BreakpointsSpecification, ''Reference'')'; 

ii = ii + 1; iCounterID = iCounterID + 1;
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', iCounterID);
stExt.VarFormat(ii).Filter.StorageClass             = {'Custom'};
stExt.VarFormat(ii).Filter.CustomStorageClass       = {'Const', 'ConstVolatile', 'Global', 'ExportToFile', 'Volatile'};
stExt.VarFormat(ii).Format.isCodeStructComponent    = true;
stExt.VarFormat(ii).Format.isAccessedByFunction     = false;
stExt.VarFormat(ii).Format.codeStructName           = '<DATANAME>';
stExt.VarFormat(ii).Format.codeStructComponentName  = '<DATAOBJ>.Table.FieldName';
stExt.VarFormat(ii).Format.codeVariableName         = '';
stExt.VarFormat(ii).Format.codeHeaderFile           = '<DATAOBJ>.CoderInfo.CustomAttributes.HeaderFile';
stExt.VarFormat(ii).Format.codeDefinitionFile       = '<DATAOBJ>.CoderInfo.CustomAttributes.DefinitionFile';
stExt.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stExt.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stExt.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stExt.VarFormat(ii).Stub.canBeStubbed               = false;

ii = ii + 1; iCounterID = iCounterID + 1;
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', iCounterID);
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stExt.VarFormat(ii).Filter.StorageClass             = {'Custom'};
stExt.VarFormat(ii).Filter.CustomStorageClass       = {'Struct', 'BitField'};
stExt.VarFormat(ii).Format.isCodeStructComponent    = true;
stExt.VarFormat(ii).Format.isAccessedByFunction     = false;
stExt.VarFormat(ii).Format.codeStructName           = '<DATAOBJ>.CoderInfo.CustomAttributes.StructName';
stExt.VarFormat(ii).Format.codeStructComponentName  = {'<DATANAME>.', '<DATAOBJ>.Table.FieldName'}; % NEW!!!
stExt.VarFormat(ii).Format.codeVariableName         = '';
stExt.VarFormat(ii).Format.codeHeaderFile           = '';
stExt.VarFormat(ii).Format.codeDefinitionFile       = '<MODELCFILE>';
stExt.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stExt.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stExt.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stExt.VarFormat(ii).Stub.canBeStubbed               = false;

ii = ii + 1; iCounterID = iCounterID + 1;
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', iCounterID);
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stExt.VarFormat(ii).Filter.StorageClass             = 'Custom';
stExt.VarFormat(ii).Filter.CustomStorageClass       = {'FileScope'};
stExt.VarFormat(ii).Format.isCodeStructComponent    = true;
stExt.VarFormat(ii).Format.isAccessedByFunction     = false;
stExt.VarFormat(ii).Format.codeStructName           = '<DATANAME>';
stExt.VarFormat(ii).Format.codeStructComponentName  = '<DATAOBJ>.Table.FieldName';
stExt.VarFormat(ii).Format.codeVariableName         = '';
stExt.VarFormat(ii).Format.codeHeaderFile           = '';
stExt.VarFormat(ii).Format.codeDefinitionFile       = '<PARSCOPEDEFFILE>';
stExt.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stExt.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stExt.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stExt.VarFormat(ii).Stub.canBeStubbed               = false;

ii = ii + 1; iCounterID = iCounterID + 1;
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', iCounterID);
stExt.VarFormat(ii).cfgID = sprintf('BTCVARFORMATID%.3d', ii);
stExt.VarFormat(ii).Filter.StorageClass             = {'ExportedGlobal'};
stExt.VarFormat(ii).Filter.CustomStorageClass       = {''};
stExt.VarFormat(ii).Format.isCodeStructComponent    = true;
stExt.VarFormat(ii).Format.isAccessedByFunction     = false;
stExt.VarFormat(ii).Format.codeStructName           = '<DATANAME>';
stExt.VarFormat(ii).Format.codeStructComponentName  = '<DATAOBJ>.Table.FieldName';
stExt.VarFormat(ii).Format.codeVariableName         = '';
stExt.VarFormat(ii).Format.codeHeaderFile           = '<MODELHFILE>';
stExt.VarFormat(ii).Format.codeDefinitionFile       = '<MODELCFILE>';
stExt.VarFormat(ii).Format.b2DMatlabIs1DCode        = true;
stExt.VarFormat(ii).Format.s2DMatlabTo1DCodeConv    = 'ColumnMajor';
stExt.VarFormat(ii).Format.s2DMatlabTo2DCodeConv    = '';
stExt.VarFormat(ii).Stub.canBeStubbed               = false;
end
