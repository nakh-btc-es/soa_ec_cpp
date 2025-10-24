function [sValue,sInitValue,bScalar] = atgcv_m13_cal_value_get(xCalibration)
%
% function sValue = atgcv_m13_cal_value_get(xCalibration)
%
%   INPUTS               DESCRIPTION
%
%   OUTPUTS              DESCRIPTION
%
%   AUTHOR(S):
%     Remmer Wilts
% $$$COPYRIGHT$$$-2011
%
%   
%%

sValue = '';
bScalar = true;


% get the dimensions of the calibration variable
VarNode_id = ep_em_entity_find_first( xCalibration, './/Variable');
width1 =  ep_em_entity_attribute_get( VarNode_id, 'width1');
width2 =  ep_em_entity_attribute_get( VarNode_id, 'width2');


ifName = ep_em_entity_find( xCalibration, './/ifName');

% if the variable is a scalar, the mun2str function will convert the
% variable to a string
if isempty(width1)
    % get the identifier of the calibration variable
    
    sIfName_Id = ep_em_entity_attribute_get( ifName{1}, 'ifid');
    sValue = sprintf('(i_%s(1,2))', sIfName_Id);
    sInitValue = sprintf('0');
elseif ~isempty(width1) && isempty(width2),
    sTmpValue= '';
    sTmpInitValue = '';
    for h= 1:str2double(width1)
        sIfName_Id= ep_em_entity_attribute_get( ifName{h}, 'ifid');
        sTmpValue= [sTmpValue ' ' sprintf('i_%s(1,2)', sIfName_Id)];
        sTmpInitValue= [sTmpInitValue ' ' sprintf('0')];
    end
    sValue = sprintf('[%s]', sTmpValue);
    sInitValue = sprintf('[%s]', sTmpInitValue);
    bScalar = false;
elseif ~isempty(width1) && ~isempty(width2),
    dWidth1= str2double(width1);
    dWidth2= str2double(width2);
    dWidth= dWidth1 * dWidth2;
    sTmpValue= '';
    sTmpInitValue = '';
    for k=1: dWidth,
        sIfName_Id= ep_em_entity_attribute_get( ifName{k}, 'ifid');
        sTmpValue= [sTmpValue ' ' sprintf('i_%s(1,2)', sIfName_Id)];
        sTmpInitValue= [sTmpInitValue ' ' sprintf('0')];
    end
    sValue = sprintf('reshape([%s], %i, %i)', sTmpValue, dWidth1, dWidth2);
    sInitValue = sprintf('reshape([%s], %i, %i)', sTmpInitValue, dWidth1, dWidth2);
    bScalar = false;
end



%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
