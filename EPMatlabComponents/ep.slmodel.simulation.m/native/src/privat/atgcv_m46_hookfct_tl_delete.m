function atgcv_m46_hookfct_tl_delete(sSourceDir)
% 
% function atgcv_m46_hookfct_tl_delete(sSourceDir)
%
%   INPUT               DESCRIPTION
%     sSourceDir          (string)      Source Directory Full Path
%  <et_copyright>

%% Internal
%   REFERENCE(S):
%     Design Document:
%
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2010
%
%%



%% Check if both directories exist
if ~exist(sSourceDir, 'dir')
    error('ATGCV:API:FILE_NOT_FOUND', ...
        'Directory "%s" does not exist.', sSourceDir);
end

casHookPatterns = { ...
	'*pre_codegen_hook*.m', ...
	'*post_codegen_hook*.m', ...
	'*pre_compile_host_hook*.m', ...
	'*post_compile_host_hook*.m', ...
	'*pre_compile_target_hook*.m', ...
	'*post_compile_target_hook*.m', ...
	'*pre_download_hook*.m', ...
	'*post_download_hook*.m', ...
	'*pre_preparation_hook*.m', ...
	'*post_preparation_hook*.m', ...
	'*pre_clear_hook*.m', ...
	'*post_clear_hook*.m'};
for k = 1:length(casHookPatterns)
    sHookPattern = casHookPatterns{k};
    
    hookFcnName = tl_find_hook(sHookPattern, {sSourceDir});
    for i = 1:length( hookFcnName )
        sHookFcn = hookFcnName{i};
        sFullHookFcn = fullfile( sSourceDir, sHookFcn );
        delete(sFullHookFcn);
    end
end


sConfigDir = fullfile(sSourceDir, 'config');
if( exist(sConfigDir,'dir') == 7 )
    rmdir(sConfigDir,'s');
end

end
%**************************************************************************
% END OF FILE
%**************************************************************************