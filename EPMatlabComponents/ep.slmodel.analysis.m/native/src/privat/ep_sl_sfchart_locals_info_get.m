function astLocals = ep_sl_sfchart_locals_info_get(stEnv, sChartPath)
% Get interface info of provided block in compiled mode.
%
% function astLocals = ep_sl_sfchart_locals_info_get(stEnv, sChartPath)
%
%   INPUT               DESCRIPTION
%     stEnv              (struct)      error messenger environment
%     sBlockPath         (string)      full paths to model block
%
%   OUTPUT              DESCRIPTION
%      astInports         (array)      structs with following fields: 
%       .iNumber            (int)        number of port
%       .sPath           (string)        path of port
%       .aiDim              (int)        'CompiledPortDimensions' of Port
%       .iWidth             (int)        width of the main Signal
%       .sOutMin         (string)        'Min' as defined for the Port
%       .sOutMax         (string)        'Max' as defined for the Port
%       .sBusType        (string)        'NOT_BUS' | 'VIRTUAL_BUS' | 'NON_VIRTUAL_BUS'
%       .sBusObj         (string)        name of corresponding Bus object (if available)
%       .astSignal       (string)        structs with te following fields:
%         .sName         (string)          name of subsignal
%         .sType         (string)          type of subsignal
%         .iWidth       (integer)          width of subsignal
%
%       .bIsInfoComplete   (bool)        "true" if info is complete, otherwise "false"
%
%      astOutports        (array)       ... same struct as astInports 
%
%   REMARKS
%     Note: Assuming the function is called with the model being set to "compiled" mode already.
%
%   <et_copyright>


%%
astSfLocalInfos = atgcv_m01_sf_data_info_get(sChartPath, {'Scope', 'Local'});

% Note: for now filter out nested locals because of limitation in MIL
astSfLocalInfos(arrayfun(@i_isNestedData, astSfLocalInfos)) = [];

if isempty(astSfLocalInfos)
    astLocals = [];
    return;
end

hResolverFunc = atgcv_m01_generic_resolver_get(sChartPath);
astLocals = arrayfun(@(x) i_getLocalAsPortInfo(x, hResolverFunc), astSfLocalInfos);
end


%%
function bIsNested = i_isNestedData(stSfData)
bIsNested = ~isempty(stSfData.sRelPath);
end


%%
function stPortInfo = i_getLocalAsPortInfo(stSfLocal, hResolverFunc)
stPortInfo = struct( ...
    'iNumber',         -1, ...
    'sSfName',         stSfLocal.sName, ...
    'sSfRelPath',      stSfLocal.sRelPath, ...
    'sPath',           stSfLocal.hSfBlock.Path, ...
    'oSig',            ep_sl_signal_from_sf_data_get(stSfLocal.hSfData, hResolverFunc), ...
    'bIsInfoComplete', true);
end

