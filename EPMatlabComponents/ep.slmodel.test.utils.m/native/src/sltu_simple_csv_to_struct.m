function stDataCsv = sltu_simple_csv_to_struct(sCsvFile, nHeaderLines)
if (nargin < 2)
    nHeaderLines = 0;
end

% change in readtable API for ML-versions >= ML2016b
if verLessThan('matlab', '9.1')
    stTable = readtable(sCsvFile, 'HeaderLines', nHeaderLines, 'ReadVariableNames', false);
    casTable = stTable{:, :};
else
    % slight change in readtable API for ML-versions >= ML2020a
    if verLessThan('matlab', '9.8')
        stTable = readtable(sCsvFile, 'HeaderLines', nHeaderLines, 'ReadVariableNames', false);
    else
        stTable = readtable(sCsvFile, 'HeaderLines', nHeaderLines, 'ReadVariableNames', false, 'Format', 'auto');
    end
    casTable = stTable.Variables;
end

if isempty(casTable)
    casIds    = {};
    casTypes  = {};
    casValues = {};
else
    casIds    = casTable(1, :);
    casTypes  = casTable(2, :);
    casValues = casTable(3:end, :);
end

stDataCsv = struct( ...
    'casIds',    {casIds}, ...
    'casTypes',  {casTypes}, ...
    'casValues', {casValues});
end
