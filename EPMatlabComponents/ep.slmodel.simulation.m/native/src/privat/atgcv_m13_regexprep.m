function xRes = atgcv_m13_regexprep(xInput, sPrefix, sReplace)
% Utility function to replace the first prefix wiht the replace string of
% all inputs.
%
% AUTHOR(S):
%   Remmer.Wilts@btc-es.de
% $$$COPYRIGHT$$$-2011
%
%%
if( iscell( xInput ) )
    xRes = cell(0);
    for i=1:length(xInput)
        sInput = xInput{i};
        anRes = strfind( sInput, sPrefix );
        if( ~isempty(anRes) )
            nValue = anRes(1);
            if( nValue == 1 )
                nStart = length(sPrefix)+1;
                sResult = [sReplace,sInput(nStart:end)];
                xRes{i} = sResult;
            else
                xRes{i} = sInput;
            end
        else
            xRes{i} = sInput;
        end
    end
else
    anRes = strfind( xInput, sPrefix );
    if( ~isempty(anRes) )
        nValue = anRes(1);
        if( nValue == 1 )
            nStart = length(sPrefix)+1;
            sResult = [sReplace,xInput(nStart:end)];
            xRes = sResult;
        else
            xRes = xInput;
        end
    else
        xRes = xInput;
    end
end
%**************************************************************************
% END OF FILE
%**************************************************************************