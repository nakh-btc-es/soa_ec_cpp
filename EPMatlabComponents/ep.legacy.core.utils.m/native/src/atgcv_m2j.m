function oObject = atgcv_m2j( xObject )
% This function transform a matlab object to a java object, when possible
%
% function oObject = atgcv_m2j( xObject )
%
%   INPUT               DESCRIPTION
%     
%   OUTPUT              DESCRIPTION
%
%   REMARKS
%     
%
%   (c) 2007-2010 by OSC Embedded Systems AG, Germany


%% intertnal
%
%   REFERENCE(S):
%     EP5 Document: 
%        Download: ...
%
%   RELATED MODULES:
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

% Step 1: Check Parameters




if( isjava( xObject ) )
    oObject = xObject;
else
    switch( class( xObject ) )
        case 'logical'
            oObject = java.lang.Boolean( xObject );
        case 'char'
            oObject = java.lang.String( xObject );
        case 'int8'
            oObject = java.lang.Byte( xObject );
        case 'int16'
            oObject = java.lang.Short( xObject );
        case 'int32'
            oObject = java.lang.Integer( xObject );
        case 'int64'
            oObject = java.lang.Long( xObject );
        case 'double'
            oObject = java.lang.Double( xObject );
        case 'cell'
            oObject = java.util.ArrayList();
            nLength = length(xObject);
            for i = 1:nLength
                xSubObject = xObject{i};
                xSubObject = atgcv_m2j( xSubObject );
                oObject.add( xSubObject );
            end
        otherwise
            error( 'ATGCV:API:NOT_SUPPORTED_PARAMETER', ...
                'The parameter is not supported.' );
    end

end



%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
