classdef Types
    properties (Access = private)
        bAllowInt64
    end
    
    methods (Access = private)
        % Private constructor to prevent direct instantiation
        function oObj = Types()
            oObj.bAllowInt64 = ep_core_feval('ep_sl_feature_toggle', 'get', 'ALLOW_64_BIT');
        end
    end
    
    methods (Static)
        function oObj = getInstance()
            persistent p_oInstance
            if isempty(p_oInstance)
                p_oInstance = ep_sl.Types();
            end
            oObj = p_oInstance;
        end
    end
    
    methods
        % Note: important that sType is not an alias type or similar; should be something that e.g.
        %       "ep_sl_type_info_get" returns for "sType"
        function bIsSupported = isSupported(oObj, sType)
            bIsSupported = ~i_isHighBitFxp(sType) && (oObj.bAllowInt64 || ~i_is64Bit(sType));
        end
    end
end


%%
% 64bit types: int64, uint64 
function bIs64Bit = i_is64Bit(sType)
bIs64Bit = ~isempty(regexp(sType, '^u?int64$', 'match'));
end


%%
% Every FXP type with bith width higher 32 is considered a high bit FXP
% Examples for high bit FXP: fixdt(1,33), fixdt(0,64,10), ...
function bIsHighBitFxp = i_isHighBitFxp(sType)
bIsFxp = ~isempty(regexp(sType, '^fixdt\(.+\)$', 'match'));
if bIsFxp
    oType = eval(sType);
    bIsHighBitFxp = oType.WordLength > 32;
else
    bIsHighBitFxp = false;
end
end
