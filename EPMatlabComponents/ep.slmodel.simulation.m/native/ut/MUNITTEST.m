function status = MUNITTEST(varargin)

caxArgs = varargin;

if ~verLessThan('matlab' , '23.2') && verLessThan('matlab', '24.1')
    % only for R2023b
    caxArgs = i_deactivateCoverage(caxArgs);
end

casPaths = which('MUNITTEST', '-all');
for i=2:numel(casPaths)
    sDir = fileparts(casPaths{i});
    [~, sParentDir] = fileparts(sDir);
    if ~strcmp(sParentDir, 'ut')
        break;
    end
end
sPwd = pwd;
cd(sDir);
hMunitFunc = @MUNITTEST;
cd(sPwd);

status = hMunitFunc(caxArgs{:});

end

function caxArgs = i_deactivateCoverage(caxArgs)
iFound = [];
for i=1:2:numel(caxArgs)
    sKey = caxArgs{i};
    if strcmp(sKey, '-cov')
        iFound = i;
    end
end
if ~isempty(iFound)
    caxArgs(iFound:iFound+1) = [];
end
end