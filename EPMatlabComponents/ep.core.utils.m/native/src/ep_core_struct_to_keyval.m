function caxKeyValues = ep_core_struct_to_keyval(stSomeStruct)
% This function transforms a struct to a key-values cell array
%
% function caxKeyValues = ep_core_struct_to_keyval(stSomeStruct)
%
%  INPUT             DESCRIPTION
%  - stSomeStruct         (struct)    some struct
%
%
%  OUTPUT            DESCRIPTION
%  - caxKeyValues         (cell)      cell with string-keys and xxx-values
%

%%
casKeys   = fieldnames(stSomeStruct);   % col-sized cell
caxValues = struct2cell(stSomeStruct);  % col-sized cell

% now put keys and values next to each other:
%  --> transform both cols into rows; put them below each other; reshape col-wise
caxKeyValues = reshape([casKeys'; caxValues'], 1, []); 
end