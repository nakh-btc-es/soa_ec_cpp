function xSignalValues = verdict_function_signal_values_get(stComparisonData,sSignalName)
%
% Utility function for retrieving signal values from the verdict function
% comparison data
%
% function xSignalValues = verdict_function_signal_values_get(stComparsionData, sSignalName)
%
%   INPUT                   DESCRIPTION
%   stComparisonData        (struct)    the comparison data (the input argument of the verdict function)
%   sSignalName             (string)    the signal name for which to retrieve the signals
%
%   OUTPUT                  DESCRIPTION
%   xSignalValues           (struct/cell-struct) the signal values
%
%   Depending on the signal type (scalar, 1-dimensional array,
%   2-dimensional array), the return will be different:
%
%   For scalar signals:
%   xSignalValues            (struct)
%          .sName            (string) the name of the signal
%          .refValues        (cell)   the reference values as double
%          .simValues        (cell)   the simulated values as double
%          .stTolerance      (struct) tolerance data (only available for
%                                     outputs and local displays)
%   For 1-dimensional arrays:
%   xSignalValues            (cell-struct)   1xN, N = length of the array
%   Each element of the array:
%        stSignalValues      (struct)
%          .sName            (string) the name of the signal
%          .refValues        (cell)   the reference values as double
%          .simValues        (cell)   the simulated values as double
%          .nIndex1          (int)    index in array
%          .stTolerance      (struct) tolerance data (only available for
%                                     outputs and local displays)
%   For 1-dimensional arrays:
%   xSignalValues            (cell-struct)   NxM, size of the matrix
%   Each element of the matrix:
%        stSignalValues      (struct)
%          .sName            (string) the name of the signal
%          .refValues        (cell)   the reference values as double
%          .simValues        (cell)   the simulated values as double
%          .nIndex1          (int)    row index number
%          .nIndex2          (int)    column index number
%          .stTolerance      (struct) tolerance data (only available for
%                                     outputs and local displays)
%
%  Please keep in mind that nIndex1 and nIndex2 could be negative!
%
% $$$COPYRIGHT$$$-2017
%
if verLessThan('MATLAB','7.13')
    nargchk(2,2,nargin);%#ok
else
    narginchk(2,2);
end
% initialize output
xSignalValues=[];
[xSignalValues,stArrayData] = i_search_for_scalar(stComparisonData,sSignalName);
if isempty(xSignalValues) && ~isempty(stArrayData)
    xSignalValues = i_search_for_composite(stArrayData);
end

function [stSignalValue,stPartialData] = i_search_for_scalar(stComparisonData,sSignalName)
stSignalValue=[];
stPartialData=struct();
casFields = {'astOutputs','astLocals','astInputs','astParameters'};
for iField = 1:length(casFields)
    [astArray,bFound] = i_process_signal_list(stComparisonData.(casFields{iField}),sSignalName);
    % if we found the scalar, just return the values for it
    if (bFound)
        stSignalValue=astArray{1};
        return;
    end
    % if we found the a possible array, just return the
    if ~isempty(astArray)
        stPartialData=astArray;
        return;
    end
end

function astSignalValue = i_search_for_composite(stArrayData)
astSignal = stArrayData.array;
if (stArrayData.numberOfColumns==-1)
    astSignalValue=astSignal;
else
    astSignalValue=cell(stArrayData.numberOfRows,stArrayData.numberOfColumns);
    nRowAdjustment=1-astSignal{1}.nIndex1;
    nColumnAdjustment=1-astSignal{1}.nIndex2;
    for iSignal=1:length(astSignal)
        stSignal=astSignal{iSignal};
        astSignalValue{stSignal.nIndex1+nRowAdjustment,stSignal.nIndex2+nColumnAdjustment}=stSignal;
    end
end


function [astSignal,bFound] = i_process_signal_list(astSignalList,sSignalName)
sModelRegexp = sprintf('^(%s)\\(\\d+[,\\d+]*\\)',sSignalName);
sCodeRegexp = sprintf('^(%s)\\[\\d+\\][\\[\\d+\\]]*',sSignalName);
astSignal={};
bFound=false;
numberOfRows=-1;
numberOfColumns=-1;
for iSignal = 1:length(astSignalList)
    stSignal = astSignalList{iSignal};
    sSignalNameInList = stSignal.sName;
    if strcmp(sSignalName,sSignalNameInList)
        bFound=true;
        astSignal={stSignal};
        return;
    elseif ~isempty(regexp(sSignalNameInList,sModelRegexp))
        % keep the signal
        stSignal = i_fill_model_indexes(sSignalName,stSignal);
        astSignal{end+1}=stSignal;
        numberOfRows=max(numberOfRows,stSignal.nIndex1);
        if isfield(stSignal,'nIndex2')
            numberOfColumns=max(numberOfColumns,stSignal.nIndex2);
        end
    elseif ~isempty(regexp(sSignalNameInList,sCodeRegexp))
        % keep the signal
        stSignal = i_fill_code_indexes(sSignalName, stSignal);
        astSignal{end+1}=stSignal;
        numberOfRows=max(numberOfRows,stSignal.nIndex1);
        if isfield(stSignal,'nIndex2')
            numberOfColumns=max(numberOfColumns,stSignal.nIndex2);
        end
    end
end
if ~isempty(astSignal)
    stArray.numberOfRows=numberOfRows;
    stArray.numberOfColumns=numberOfColumns;
    stArray.('array')=astSignal;
    astSignal=stArray;
end

function stSignal =i_fill_code_indexes(sSignalName, stSignal)
sArrayIndexes = strrep(stSignal.sName,sSignalName,'');
[anIndexes,matches] = strsplit(sArrayIndexes,'][');
if isempty(matches)
    sArrayIndexes=regexprep(sArrayIndexes,'[\[\]]','');
    stSignal.('nIndex1')=str2double(sArrayIndexes);
else
    stSignal.('nIndex1')=str2double(strrep(anIndexes{1},'[',''));
    stSignal.('nIndex2')=str2double(strrep(anIndexes{2},']',''));
end

function stSignal =i_fill_model_indexes(sSignalName, stSignal)
sArrayIndexes = strrep(stSignal.sName,sSignalName,'');
sArrayIndexes=regexprep(sArrayIndexes,'[\(\)]','');
anIndexes = strsplit(sArrayIndexes,',');
stSignal.('nIndex1')=str2double(anIndexes{1});
if (length(anIndexes)>1)
    stSignal.('nIndex2')=str2double(anIndexes{2});
end




