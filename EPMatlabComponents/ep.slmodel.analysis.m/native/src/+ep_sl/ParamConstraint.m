classdef ParamConstraint
    % Class represents a constraint for a particular model parameter.
    properties (Hidden, Access = private)
        sKind_   % empty | array | param
        sRelop_  % '' | LES | LEQ | EQ | NEQ | GEQ | GRE
        sUsage_  % the origin of the constraint
        
        oValueParam_ % non-empty only for sKind_ == 'param'
    end
    
    properties (Constant, Hidden, Access = private)
        casUsagesForArrayLes = { ...
            'breakpointsfordimension1', ...
            'breakpointsfordimension2', ...
            'breakpointsfordimension3', ...
            'breakpointsfordimension4', ...
            'breakpointsdata', ...
            'breakpointobject'};
    end
    
    methods (Static)
        function oObj = getForBlockProperty(xBlock, sBlockProperty)
            oObj = ep_sl.ParamConstraint();
            oObj.sUsage_ = sBlockProperty;
            [oObj.sKind_, oObj.sRelop_] = i_getConstraintKindFromUsage(sBlockProperty);
            if strcmp(oObj.sKind_, 'param')
                oObj.oValueParam_ = i_getConstraintParam(xBlock, sBlockProperty);
            end
        end
    end
    
    methods
        function bIsEmpty = isEmptyKind(oObj)
            bIsEmpty = strcmp(oObj.sKind_, 'empty');
        end
        
        function bIsArray = isArrayKind(oObj)
            bIsArray = strcmp(oObj.sKind_, 'array');
        end
        
        function bIsAParam = isParamKind(oObj)
            bIsAParam = strcmp(oObj.sKind_, 'param');
        end
        
        function sRelop = getRelop(oObj)
            sRelop = oObj.sRelop_;
        end

        function sOrigin = getOrigin(oObj)
            sOrigin = oObj.sUsage_;
        end
        
        function oValueParam = getValueParam(oObj)
            oValueParam = oObj.oValueParam_;
        end
        
        function stRes = getParamConstAsStruct(oObj)
            stRes = struct(...
                'sKind', oObj.sKind_, ...
                'sRelop', oObj.sRelop_, ...
                'sUsage', oObj.sUsage_, ...
                'oValueParam', oObj.oValueParam_);
        end
    end
end


%%
function [sKind, sRelop] = i_getConstraintKindFromUsage(sBlockProprty)
switch lower(sBlockProprty)
    case ep_sl.ParamConstraint.casUsagesForArrayLes
        sKind  = 'array';
        sRelop = 'LES';
        
    case 'offswitchvalue'
        sKind  = 'param';
        sRelop = 'LEQ';
        
    case 'onswitchvalue'
        sKind  = 'param';
        sRelop = 'GEQ';
        
    case 'upperlimit'
        sKind  = 'param';
        sRelop = 'GEQ';
        
    case 'lowerlimit'
        sKind  = 'param';
        sRelop = 'LEQ';

    otherwise
        sKind  = 'empty';
        sRelop = '';
end
end


%%
function oParam = i_getConstraintParam(xBlock, sBlockProperty)
switch lower(sBlockProperty)
    case 'offswitchvalue'
        sConstraintProperty  = 'onswitchvalue';
        
    case 'onswitchvalue'
        sConstraintProperty  = 'offswitchvalue';
        
    case 'upperlimit'
        sConstraintProperty = 'lowerlimit';

    case 'lowerlimit'
        sConstraintProperty = 'upperlimit';
        
    otherwise
        error('EP:UNKNOWN_USAGE', 'Block usage "%s" is unknown.', sBlockProperty);
end
oParam = ep_sl.ValueParam.getForBlockProperty(xBlock, sConstraintProperty);
end

