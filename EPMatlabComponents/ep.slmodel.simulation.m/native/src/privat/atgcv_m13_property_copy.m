function atgcv_m13_property_copy( stEnv, hPropSrc, hPropDst, sProperty )
% Copies a simple property from property source to destination
%
%  function atgcv_m13_property_copy( stEnv, hPropSrc, hPropDst, sProperty )
%
% AUTHOR(S):
%   Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%%


xDst = '';
try
    xDst = hPropDst.get( sProperty );
    xSrc = hPropSrc.get( sProperty );
    
    if( ~isequal(xSrc,xDst) )
        bSettingAllowed = i_isSettingAllowed(hPropDst, sProperty);
        if( bSettingAllowed)
            hPropDst.set( sProperty, xSrc);
        end
    end
catch exception
    if( ischar( xDst ) )
        sValue = xDst;
    else
        try
            sValue = num2str( xDst );
        catch
            sValue = 'n.a.';
        end
    end
    osc_messenger_add(stEnv, ...
        'ATGCV:MIL_GEN:SL_SETTINGS_COPY', ...
        'key', sProperty, ...
        'val', sValue, ...
        'msg', exception.message);
end
end


%%
function bSettingAllowed = i_isSettingAllowed(hPropDst, sProperty)
try
    bEnabledProp = hPropDst.getPropEnabled( sProperty );
catch
    bEnabledProp = true;
end

bUnsetableProp = false;
if bEnabledProp
    % some undocumented properties could be enabled, but could not be set. If the current property is part of these
    % properties, the setting is not allowed.
    casUnsetableProp = {};
    if ~verLessThan('matlab','23.2')
        casUnsetableProp = {casUnsetableProp, 'EvaledLifeSpan'};
    end
    bUnsetableProp = any(strcmp(sProperty, casUnsetableProp));
end

bSettingAllowed = bEnabledProp && ~bUnsetableProp;
end

% xVal1 =  hPropDst.get( sProperty );
% xVal2 =  hPropSrc.get( sProperty );
% if( isempty( xVal1 ) )
%     xVal1 = '[]';
% end
% if( isempty( xVal2 ) )
%     xVal2 = '[]';
% end
% if( ~ischar( xVal1 ) )
%     try
%         disp( sprintf('%s : %s  %s ', sProperty, num2str(xVal1) ,  num2str(xVal2)) );
%     catch
%         disp(sProperty)
%         xVal1
%         xVal2
%     end
% else
%     disp( sprintf('%s : %s  %s ', sProperty,  xVal1 ,  xVal2 )) ;
% end



%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************