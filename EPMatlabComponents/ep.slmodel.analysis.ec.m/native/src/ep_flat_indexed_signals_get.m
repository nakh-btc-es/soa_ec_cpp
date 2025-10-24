function casFlatSigs = ep_flat_indexed_signals_get(casSigParts, caaiWidth, sHandling2D)
% Returns full list of flat names for of all signal-parts/widths combinations.
%
% For C-code indexing:
%      sHandling2D == 'keep' | 'transpose' | 'col-major' | 'row-major'

%%
if (nargin < 3)
    bUseModelIndexing = true;
else
    bUseModelIndexing = false;
end


%%
nParts = numel(casSigParts);
if (nParts ~= numel(caaiWidth))
    error('USAGE:ERROR', 'Number of signal parts and number of width-arrays have to match.');
end

ccasIndexedSigParts = cell(1, nParts);
for i = 1:nParts
    sSigPart = casSigParts{i};
    aiPartWidth = caaiWidth{i};
    
    if bUseModelIndexing
        ccasIndexedSigParts{i} = i_getIndexedSigPartsModel(sSigPart, aiPartWidth);
    else
        ccasIndexedSigParts{i} = i_getIndexedSigPartsCode(sSigPart, aiPartWidth, sHandling2D);
    end
end

casFlatSigs = i_combineAndJoin(ccasIndexedSigParts);
end


%%
function casJoinedParts = i_combineAndJoin(ccasParts)
if (numel(ccasParts) == 1)
    casJoinedParts = ccasParts{1};
else
    casPrefixParts = ccasParts{1};
    casPostfixParts = i_combineAndJoin(ccasParts(2:end));
    
    nPre = numel(casPrefixParts);
    nPost = numel(casPostfixParts);
    nCombined = nPre*nPost;
    casJoinedParts = cell(1, nCombined);
    
    m = 0;
    for k = 1:nPre
        for i = 1:nPost
            m = m + 1;
            
            casJoinedParts{m} = sprintf('%s.%s', casPrefixParts{k}, casPostfixParts{i});
        end
    end
end
end


%%
%  Returned element order of 2-dim matrix A will be row-major: A(1)(1), A(1)(2), ..., A(1)(M), A(2)(1), ..., A(N)(M)
%       
function casIndexedSigParts = i_getIndexedSigPartsModel(sSigPart, aiPartWidth)
if (numel(aiPartWidth) > 2)
    error('UNSUPPORTED:HIGH_DIM', 'Number of supported dimensions is limited to two.');
end

if isempty(aiPartWidth)
    casIndexedSigParts = {sSigPart};
else
    if (numel(aiPartWidth) == 1)        
        nCols = aiPartWidth(1);
        casIndexedSigParts = cell(1, nCols);
        for i = 1:nCols
            casIndexedSigParts{i} = sprintf('%s(%d)', sSigPart, i);
        end
        
    else
        nRows = aiPartWidth(1);
        nCols = aiPartWidth(2);
        
        nAll = nRows*nCols;
        m = 0;
        casIndexedSigParts = cell(1, nAll);
        for k = 1:nRows
            for i = 1:nCols
                m = m + 1;
                casIndexedSigParts{m} = sprintf('%s(%d)(%d)', sSigPart, k, i);
            end
        end
    end
end
end


%%
% sHandling2D == 'keep' | 'transpose' | 'col-major' | 'row-major'
function casIndexedSigParts = i_getIndexedSigPartsCode(sSigPart, aiPartWidth, sHandling2D)
if (numel(aiPartWidth) > 2)
    error('UNSUPPORTED:HIGH_DIM', 'Number of supported dimensions is limited to two.');
end

if isempty(aiPartWidth)
    casIndexedSigParts = {sSigPart};
else
    if (numel(aiPartWidth) == 1)        
        nCols = aiPartWidth(1);
        casIndexedSigParts = cell(1, nCols);
        for i = 1:nCols
            casIndexedSigParts{i} = sprintf('%s[%d]', sSigPart, i - 1);
        end
        
    else
        nRows = aiPartWidth(1);
        nCols = aiPartWidth(2);
        
        nAll = nRows*nCols;
        m = 0;
        casIndexedSigParts = cell(1, nAll);
        for k = 0:nRows-1 % note: starting from zero!
            for i = 0:nCols-1 % note: starting from zero!
                m = m + 1;
                switch sHandling2D
                    case 'row-major'
                        casIndexedSigParts{m} = sprintf('%s[%d]', sSigPart, m-1);
                    case 'col-major'
                        casIndexedSigParts{m} = sprintf('%s[%d]', sSigPart, i*nRows + k);
                    case 'keep'
                        casIndexedSigParts{m} = sprintf('%s[%d][%d]', sSigPart, k, i);
                    case 'transpose'
                        casIndexedSigParts{m} = sprintf('%s[%d][%d]', sSigPart, i, k);
                    otherwise
                        error('UNKNOWN:HANDLING_2D', '2D-handling "%s" unknown.', sHandling2D);
                end
            end
        end
    end
end
end
