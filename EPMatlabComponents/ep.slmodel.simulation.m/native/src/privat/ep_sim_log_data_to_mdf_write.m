function ep_sim_log_data_to_mdf_write(sMdfFile, astLogData, nVecLength)
% Writes logged signals into an MDF file. NOTE: An existing MDF file will be overwritten during this process.
%
% function ep_sim_log_data_to_mdf_write(sMdfFile, astLogData, nVecLength)
%
%   INPUTS               DESCRIPTION
%     sMdfFile           (string)     full path to the mdf file
%     astLocalsData      (struct)     array of structs all following the specification in "ep_sim_log_data_struct"
%     nVecLength         (number)     length of the vector
%
%   OUTPUT               DESCRIPTION
%     -                     -


%%
if (nVecLength > intmax('uint32'))
    error('Vector length greater than %s is not supported.', intmax('uint32'));
end

if exist(sMdfFile, 'file')
    delete(sMdfFile);
end

sMDFDialect = ep_core_mdf('GetPreferredDialect');
if isempty(astLogData)
    hFile = mxx_mdf('create', sMdfFile, {}, {}, [], [], [], sMDFDialect);
else
    hFile = mxx_mdf('create', sMdfFile, {astLogData(:).sId}, {astLogData(:).sType}, [], [], [], sMDFDialect);
end
xOnCleanup = onCleanup(@() mxx_mdf('close', hFile));    
mxx_mdf('append_logdata', hFile, astLogData, nVecLength);
end
