function sCurrBom = ep_core_file_bom_adapt(sFile, sNewBom, sNewFile)
% BOM updates the Byte Order Mark at the beginning of a file for the
% Unicode encoding. This function is useful following other Matlab
% functions such as WRITETABLE, which doesn't add a BOM even when an
% encoding such as "UTF-8" is selected.
%
% Supported encodings:
%     UTF-8
%     UTF-32_BE
%     UTF-32_lE
%     UTF-16_BE
%     UTF-16_LE
%     UTF-7 (reading only)
%     UTF-1
%     UTF-EBCDIC
%     SCSU
%     BOCU-1
%     GB-18030
%
%
% Usage:
%   CurrBom = BOM(Fname) - return a string of the file encoding, without
%   changing it. If no BOM exists, then CurrBom is returned as an empty
%   array.
%
%   CurrBom = BOM(Fname, NewBom) - rewrite the file Fname with the new BOM.
%   No action is taken if the current BOM is same as NewBom. If NewBom is
%   an empty array, then the current BOM is erased from the file.
%
%   CurrBom = BOM(Fname, NewBom, NewFile) - create a new file NewFile with
%   NewBom - the original file remains unchanged.
%


%%
sCurrBom = ''; % default output

%%
caxKnownBoms = {...
    'UTF-8',        [239 187 191];
    'UTF-32_BE',    [0 0 254 255];
    'UTF-32_lE',    [255 254 0 0];
    'UTF-16_BE',    [254 255]; % UTF-16 must come after UTF-32
    'UTF-16_LE',    [255 254];
    'UTF-7',        [43 47 118];
    'UTF-1',        [247 100 76];
    'UTF-EBCDIC',   [221 115 102 115];
    'SCSU',         [14 254 255];
    'BOCU-1',       [251 238 40];
    'GB-18030',     [132 49 149 51];
    '',             [];
    };


%% load file
adFileContent = [];
if exist(sFile, 'file')
    try %#ok<TRYNC> 
        hFid = fopen(sFile, 'r');
        adFileContent = fread(hFid);
        fclose(hFid);
    end
end
if isempty(adFileContent)
    return;
end

%% read current
for i = 1:size(caxKnownBoms, 1)
    N = length(caxKnownBoms{i, 2});
    if isequal(adFileContent(1:N), caxKnownBoms{i, 2}')
        sCurrBom = caxKnownBoms{i, 1};
        break;
    end
end
iCurrInd = i;


if (nargin > 1)
    if isempty(sNewBom)
        sNewBom = ''; % make sure to use string
    elseif strcmpi(sNewBom, 'UTF-7')
        error('BOM:UNSUPPORTED', 'UTF-7 is not supported for updating.');
    end
    iFoundBomIdx = find(strcmpi(sNewBom, caxKnownBoms(:, 1)), 1, 'first');
    if isempty(iFoundBomIdx) % unknown encoding
        error('BOM:UNKNOWN', 'Unknown BOM "%s" provided.', sNewBom);
    end
    if iCurrInd == iFoundBomIdx % same encoding, do nothing
        return;
    end

    N = 0; % no BOM
    if ~isempty(sCurrBom)
        N = length(caxKnownBoms{iCurrInd, 2});
    end
    % check if we can simply replace or need to remove && prepend
    if (N == length(caxKnownBoms{iFoundBomIdx, 2}))
        % just replace the first N bytes with other N bytes
        adFileContent(1:N) = caxKnownBoms{iFoundBomIdx, 2}';
    else
        % different numbers of bytes --> remove old bytes && prepend new bytes
        adFileContent = [caxKnownBoms{iFoundBomIdx, 2}' ; adFileContent(N+1:end)];
    end

    if (nargin > 2)
        sFile = sNewFile;
    end

    % write file
    hFid = fopen(sFile, 'w');
    fwrite(hFid, adFileContent);
    fclose(hFid);
end
end
