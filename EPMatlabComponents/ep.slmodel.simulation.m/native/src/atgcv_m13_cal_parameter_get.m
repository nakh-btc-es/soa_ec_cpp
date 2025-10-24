function [sParam,sBlockVariable] = atgcv_m13_cal_parameter_get( sUsage )
% get the adequat parameter of the selected calibration block
%
% function sParam = atgcv_m13_cal_parameter_get( sUsage )
%
%  INPUTS
%   sUsage            (string)     'const', 'sat_lower', 'sat_upper',
%                                  'sf_const','switch_threshold',
%                                  'relay_out_on','relay_out_off',
%                                  'relay_switch_on' or 'relay_switch_off'
% Output:
%   sParam            (string)      'value', 'LowerLimit', 'UpperLimit'
%                                  'Threshold','OnSwitchValue','OnSwitchValue',
%                                  'OffSwitchValue' or 'OffOutputValue'.

%   REFERENCE(S):
%     Design Document:
%        Section : M13
%        Download:
%        http://pcosc29/dp2004/Download.aspx?ID=1cd1982c-9a3f-4a8d-a155-ce05bc5d84a6
%
%   RELATED MODULES:
%    tgcv_m13_subsys_name_get.m
%
%   AUTHOR(S):
%     Khalid Adraoui
% $$$COPYRIGHT$$$-2005
%
%     
%%

if( strcmp( sUsage, 'gain' ) )
    sParam= 'gain';
    sBlockVariable = 'gain';
elseif( strcmp( sUsage, 'const' ) )
    sParam= 'value';
    sBlockVariable = 'output';
elseif( strcmp( sUsage, 'switch_threshold' ) )
    sParam= 'Threshold';
    sBlockVariable = 'threshold';
elseif( strcmp( sUsage, 'sat_lower' ) )
    sParam= 'LowerLimit';
    sBlockVariable = 'lowerlimit';
elseif( strcmp( sUsage, 'sat_upper' ) )
    sParam= 'UpperLimit';
    sBlockVariable = 'upperlimit';
elseif( strcmp( sUsage, 'relay_out_on' ) )
    sParam= 'OnOutputValue';
    sBlockVariable = 'onoutput';
elseif( strcmp( sUsage, 'relay_out_off' ) )
    sParam= 'OffOutputValue';
    sBlockVariable = 'offoutput';
elseif( strcmp( sUsage, 'relay_switch_on' ) )
    sParam= 'OnSwitchValue';
    sBlockVariable = 'onswitch';
elseif( strcmp( sUsage, 'relay_switch_off' ) )
    sParam= 'OffSwitchValue';
    sBlockVariable = 'offswitch';
else
    error('TODO');
end


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
