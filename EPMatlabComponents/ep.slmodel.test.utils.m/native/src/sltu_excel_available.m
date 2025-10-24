function bIsAvailable = sltu_excel_available()
% Checks if Excel is installed and available for usage in Matlab.
%

persistent p_bIsAvailable;

if isempty(p_bIsAvailable)
    p_bIsAvailable = i_isExcelAvaiable();
end
bIsAvailable = p_bIsAvailable;
end


%%
function bIsAvailable = i_isExcelAvaiable()
bIsAvailable = false;
try
    hExcel = actxserver('excel.application');
    bIsAvailable = ~isempty(hExcel);
    clear hExcel; % explicitly free resources (but should be done automatically by Matlab)
catch
end
end
