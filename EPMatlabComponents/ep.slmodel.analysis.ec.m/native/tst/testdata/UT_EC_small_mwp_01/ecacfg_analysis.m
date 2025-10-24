function stConfig = ecacfg_analysis(stConfig, stAdditionalInfo)
%
% stConfig                                      (struct)  describing settings needed for the analysis
%
%   .General                                    (struct)  describing general settings (see below stGeneral)
%       .AllowStubGeneration                    (boolean)
%       .bExcludeScopesWithoutMapping           (boolean)
%       .sStubCodeFolderPath                    (string)
% ----------------------
%   .ScopeCfg                                   (struct)   describing scope specific settings (see below stScopeCfg)
%       .RootScope                              (struct)   describing root scope specific settings
%           .SearchFromFunction                 (string)
%           .ForceUseOfModelStepFunc            (boolean)
%       .Subsys                                 (struct)
%           .PropFilter                         (array of structures)
%               .BlockParameterName             (string)
%               .BlockParameterValue            (string)
% ----------------------
%   .ParameterDOCfg                             (struct)
%       .SearchGlobal                           (struct)
%           .DataObjectName                     (string)
%           .DataObjectClass                    (string)
%           .FilterMethod                       (string)
%           .PropFilter                         (array of structures)
%               .Property                       (struct)
%                   .Name                       (string)
%                   .Value                      (cell array of strings)
% ----------------------
%   .LocalDOCfg                                 (struct)
%       .SearchGlobal                           (struct)
%           .DataObjectName                     (cell array of strings)
%           .DataObjectClass                    (cell array of strings)
%           .PropFilter                         (array of structures)
%               .Property                       (struct)
%                   .Name                       (string)
%                   .Value                      (cell array of strings)
% ----------------------
%   .DefineDOCfg                                (struct)
%       .SearchGlobal                           (struct)
%           .DataObjectName                     (cell array of strings)
%           .DataObjectClass                    (cell array of strings)
%           .PropFilter                         (array of structures)
%               .Property                       (struct)
%                   .Name                       (string)
%                   .Value                      (cell array of strings)

stConfig.General.bExcludeParamsWithoutMapping = false;

pp = numel(stConfig.ParameterDOCfg.SearchGlobal.PropFilter);
pp = pp + 1;
stConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Name  = 'CoderInfo.StorageClass';
stConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Value = {'Custom'};
stConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(2).Name  = 'CoderInfo.CustomStorageClass';
stConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(2).Value = {'ParamStruct', 'MultiInstance'};

pp = pp + 1;
stConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Name  = 'CoderInfo.StorageClass';
stConfig.ParameterDOCfg.SearchGlobal.PropFilter(pp).Property(1).Value = {'Auto', 'Model default'};
end