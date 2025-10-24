function atgcv_messenger_merge_files(casFiles, sResultFile)
% Merge the incomming messenger files to a single result messenger file.
%
% function atgcv_messenger_merge_files(casFiles, sResultFile)
%
%   INPUT              DESCRIPTION
%     casFile           (cell)      Cell array of messenger files
%     sResultFile       (string)    Result messenger file
%   OUTPUT             DESCRIPTION
%
%   REFERENCE(S):
%     ---
%
%   RELATED MODULES:
%     ---
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2010
%%



folder = java.io.File(atgcv_tempname_get(), '_et');
oAPI = ep.core.cdm.CommonDataModel.getInstance();
oEM = oAPI.createProfile(folder);
stEnv.hMessenger = atgcv_m_messenger_create(oEM, 'MERGE');

for i=1:length(casFiles)
    sMessengerFile = casFiles{i};
    atgcv_m_messenger_transfer(stEnv, sMessengerFile);
end


atgcv_m_messenger_save( stEnv.hMessenger, sResultFile );
oAPI.close(oEM);


%**************************************************************************
% END OF FILE
%**************************************************************************
