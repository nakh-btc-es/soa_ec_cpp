function [astSignals, stMetaInfo] = ep_sim_mdf2struct(sMdfFile, bReadFxpRaw)
% Read information about signals (name, values) and meta info from an MDF file.
%
% function [astSignals, stMetaInfo] = ep_sim_mdf2struct(sMdfFile)
%
%   INPUT               DESCRIPTION
%   sMdfFile             (string)    Full path to the MDF file
%
%   OUTPUT              DESCRIPTION
%   astSignals           (array)     Structs with info about the signals with the following fields
%     .sID               (string)       ID of the signal
%     .sType             (string)       Type of the data values (int32, double, uint8, etc.)
%     .xValue            (<numeric>)    Array of values of an arbitrary data type; number of values is the
%                                       number of steps present in the MDF file
%   stMetaInfo           (struct)    Structure with meta information about the MDF file with the following fields
%     .sName             (string)       Internal name of the MDF file
%     .sScope            (string)       Name of the scope the MDF file belongs to
%     .sMetaData         (string)       Additional information for the MDF file
%     .nSteps            (int)          Number of steps present in the MDF file      


%%
if (nargin < 2)
    bReadFxpRaw = false;
end

%%
hMdf = mxx_mdf('open', sMdfFile);
xOnCleanupCloseMdf = onCleanup(@() mxx_mdf('close', hMdf));

astSignals = i_getSignals(hMdf, bReadFxpRaw);
if (nargout > 1)
    stMetaInfo = i_getMetaInfo(hMdf);
end
end


%%
function astSignals = i_getSignals(hMdf, bReadFxpRaw)
astSignals = struct( ...
    'sID',    mxx_mdf('get_signal_names', hMdf)', ...
    'sType',  mxx_mdf('get_signal_types', hMdf)', ...
    'xValue', i_getValues(hMdf, bReadFxpRaw));
end


%%
function caxValues = i_getValues(hMdf, bReadFxpRaw)
if bReadFxpRaw
    caxValues = i_valuesCellTwoDimToOneDim(mxx_mdf('get_values', hMdf, 'FXP'));
else
    caxValues = i_valuesCellTwoDimToOneDim(mxx_mdf('get_values', hMdf));
end
end


%%
function caxValues1d = i_valuesCellTwoDimToOneDim(caxValues2d)
if isempty(caxValues2d)
    caxValues1d = {};
else
    nSigs = size(caxValues2d, 2);
    caxValues1d = cell(1, nSigs);
    for i = 1:nSigs
        caxValues1d{i} = cell2mat(caxValues2d(:, i));
    end
end
end


%%
function stMetaMdf = i_getMetaInfo(hMdf)
stMetaMdf = struct( ...
    'sName',      mxx_mdf('get_name',      hMdf), ...
    'sScope',     mxx_mdf('get_scope',     hMdf), ...
    'sMetaData',  mxx_mdf('get_meta_data', hMdf), ...
    'nSteps',     mxx_mdf('get_num_steps', hMdf));
end

