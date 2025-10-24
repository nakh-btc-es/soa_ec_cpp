function xObject = atgcv_j2m( oObject )
% This function transform a java object to a matlab object, when possible
%
% function xObject = atgcv_j2m( oObject )
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

if( isa( oObject, 'java.lang.Boolean' ) )
    xObject = boolean( oObject.booleanValue() );
elseif( isa( oObject, 'java.lang.String' ) )
    xObject = char( oObject );
elseif(isa( oObject, 'java.lang.Float' ) )
    xObject = oObject.floatValue();
elseif(isa( oObject, 'java.lang.Double' ) )
    xObject = oObject.doubleValue();
elseif(isa( oObject, 'java.lang.Byte' ) )
    xObject = int8(oObject.byteValue());
elseif(isa( oObject, 'java.lang.Short' ) )
    xObject = int16(oObject.shortValue());
elseif(isa( oObject, 'java.lang.Integer' ) )
    xObject = int32(oObject.intValue());
elseif(isa( oObject, 'java.lang.Long' ) )
    xObject = int64(oObject.longValue());
elseif(isa( oObject, 'java.util.List' ) )
    nSize = oObject.size();
    caoArgs = cell(0);
    for i = 1:nSize
        oSubObject = oObject.get(i-1);
        xSubObject = atgcv_j2m( oSubObject );
        caoArgs{i} = xSubObject;
    end
    xObject = caoArgs;
else
    xObject = oObject; % for all other java objects
end

%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
