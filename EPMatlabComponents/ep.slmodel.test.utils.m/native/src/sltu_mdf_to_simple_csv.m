function sltu_mdf_to_simple_csv(sMdfFile, sTargetCsv)
if (nargin < 2)
    [p, f] = fileparts(sMdfFile);
    sTargetCsv = fullfile(p, [f, '.csv']);
end

stDataMdf = sltu_mdf_to_struct(sMdfFile);
stDataMdf.casIds = i_checkCharWithSpecialLinuxHandling(stDataMdf.casIds);
writetable( ...
    array2table([stDataMdf.casIds; stDataMdf.casTypes; stDataMdf.caxValues]), ...
    sTargetCsv, ...
    'WriteVariableNames', false);
end

function casIds = i_checkCharWithSpecialLinuxHandling(casIds)
if isunix
    for i=1:length(casIds)
        sId = casIds{i};
        if contains(sId, char(10))  %#ok<CHARTEN> 
            sId(sId == char(10)) = char(13); %#ok<CHARTEN> 
            casIds{i} = sId;
        end
    end
end
end
