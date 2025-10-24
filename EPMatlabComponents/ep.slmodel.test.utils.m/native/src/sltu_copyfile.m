function sltu_copyfile(sFileFrom, sFileTo)
if ~exist(sFileFrom, 'file')
    error('SLTU:MISSING_FILE', 'File "%s" to be copied not found.', sFileFrom);
end

sDirTo = fileparts(sFileTo);
if ~exist(sDirTo, 'dir')
    mkdir(sDirTo);
end

copyfile(sFileFrom, sFileTo);
end
