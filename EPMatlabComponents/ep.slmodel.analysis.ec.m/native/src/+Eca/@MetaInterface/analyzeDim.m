function [bIsScalar, bIsArray1D, nRowCol, bArrayUseRowIndexingOnly] = analyzeDim(oItf)

nDim = oItf.dimension;
sKind = oItf.kind;
%analyze dimension
if not(isempty(nDim)) && not(isequal(nDim, [1 1])) && not(isequal(nDim, 1))
    bIsScalar = false;
    bIsArray1D = (min(nDim(1)) == 1) || (numel(nDim)==1 && min(nDim) > 1); % [1 3] or [3 1] or 3
    if numel(nDim) == 1,
        nRowCol = [1 nDim]; 
    else
        nRowCol = nDim;
    end
    bArrayUseRowIndexingOnly =...
        (~strcmp(sKind, 'PARAM') && numel(nDim) == 1) || (strcmp(sKind, 'PARAM') && bIsArray1D);
else
    bIsScalar = true;
    bIsArray1D = false;
    nRowCol = [1 1];
    bArrayUseRowIndexingOnly = true;
end

end