function ep_ec_model_dir_reset(sDir)
if (nargin < 1)
    sDir = pwd;
end

delete(fullfile(sDir, '*.slxc'));
delete(fullfile(sDir, '*.mexw64'));

sSlPrj = fullfile(sDir, 'slprj');
if exist(sSlPrj, 'dir')
    rmdir(sSlPrj, 's');
end
end
