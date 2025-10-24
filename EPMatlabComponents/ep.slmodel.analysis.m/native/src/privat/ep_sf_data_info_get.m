function stInfo = ep_sf_data_info_get(varargin)
% AlHo: This function has to be removed ASAP!



%% default output
stInfo = struct( ...
    'sSfName',       '', ...
    'sSfRelPath',    '', ...
    'sSfScope',      '', ...
    'iSfFirstIndex', [], ...
    'sInitValue',    '');

%%
sChartPath = varargin{1};
stData = struct( ...
    'sName',    varargin{2}, ...
    'sAccess',  '', ...
    'sRelPath', '');
if (numel(varargin) > 2)
    stData.sRelPath = varargin{3};
end

sVarPath = sChartPath;
if ~isempty(stData.sRelPath)
    sVarPath = [sVarPath, '/', stData.sRelPath];
end

stSfInfo = atgcv_m01_sf_data_info_get(sChartPath, {'Path', sVarPath, 'Name', stData.sName});
if ~isempty(stSfInfo)
    stInfo.sSfName = stSfInfo.sName;
    stInfo.sSfRelPath = stData.sRelPath;
    stInfo.sSfScope = stSfInfo.sScope;
    stInfo.iSfFirstIndex = stSfInfo.iFirstIndex;
    stInfo.sInitValue = stSfInfo.sInitValue;
end
end

