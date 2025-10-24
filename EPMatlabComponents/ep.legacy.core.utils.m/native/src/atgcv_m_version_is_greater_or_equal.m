function bRet = atgcv_m_version_is_greater_or_equal( version )
%Compare current matlab, targetlink or stateflow version with given string, return greater or equal.
%
%function bRet = atgcv_m_version_is_greater_or_equal( version )
%
%   INPUT                   DESCRIPTION
%
%   version                  string, allowed values are in descending order
%
%                            for matlab versions:
%                            ML7.3
%                            ML7.2
%                            ML7.1
%                            ML7.0.4
%                            ML7.0.1
%                            ML7.0
%                            ML6.5.2
%                            ML6.5.1
%                            ML6.1
%                            
%
%                            for targetlink versions: 
%                            TL [x.*]x
%
%                            for stateflow versions:
%                            SF6.3
%                            SF6.2
%                            SF6.1
%                            SF5.1.2
%                            SF5.1.1
%                            SF4.2.1
%
%                                        
%   OUTPUT                  DESCRIPTION
%
%   bRet                    (0|1|-1)
%                           1: version string is greater or equal current version
%                           0: version string is lower than current version 
%                          -1: version string is unknown 
%                           
%                               
%                           
%   EXAMPLE:
%
%   osc_version_is_greater_or_equal('TL1.3') %true if TL 1.3 or TL1.3p2 or TL1.3p3 ...
%   osc_version_is_greater_or_equal('SF6.1') %true if SF 6.1, 6.2, 6.3
%
%   AUTHOR(S):
%       marten.penning@o-s-c.de
% $$$COPYRIGHT$$$
%
% $Revision: 18220 $ Last modified: $Date: 2007-04-03 15:13:48 +0200 (Di, 03 Apr 2007) $ $Author: marten $ 



persistent OSC_CURRENT_SF_VERSION;
persistent OSC_CURRENT_TL_VERSION;
persistent OSC_CURRENT_ML_VERSION;

% fill persistent variables
if isempty(OSC_CURRENT_ML_VERSION)
  fe_info     = atgcv_frontend_info_get;
  OSC_CURRENT_ML_VERSION=fe_info.matlab_info.version;                                         
  OSC_CURRENT_TL_VERSION=fe_info.ds_targetlink_info.version;
  OSC_CURRENT_SF_VERSION=fe_info.stateflow_info.version;
end

% set return value to false initially
bRet=0;


%check for malformed parameter

%not a string? exit..
if ~ischar(version) 
    return;
end

%length needs to be gt 2
if length(version) <=2
    return
end

%store the version string minus the 2 first characters
version_short=version(3:length(version));

if strncmpi(version,'ML',2) 
    
    flag = i_osc_compare_matlab_version(OSC_CURRENT_ML_VERSION,version_short);
    if flag==1 || flag==0
        bRet=1;
    end
    %unknown version
    if flag==2
        bRet=-1;
    end
    
elseif strncmpi(version,'TL',2) 
    flag = i_osc_compare_tl_version(OSC_CURRENT_TL_VERSION,version_short);
    if flag==1 || flag==0
        bRet=1;
    end
elseif strncmpi(version,'SF',2) 
    
    flag = i_osc_compare_stateflow_version(OSC_CURRENT_SF_VERSION,version_short);
    if flag==1 || flag==0
        bRet=1;
    end
    %unknown version
    if flag==2
        bRet=-1;
    end
end


return;



% calculate if version1 is greater than version2
function flag = i_osc_compare_tl_version(version1, version2)

% Compares two strings corresponding to targetlink versions.
%
% function flag = i_osc_compare_stateflow_version(version1, version2)
%
%   INPUT                     DESCRIPTION
%    version1                  string representing version
%    version2                  string representing version
%
%   OUTPUT                    DESCRIPTION
%    flag                       0 if version1 = version2
%                               1 if version1 > version2
%                              -1 if version1 < version2

flag=0;

v1Sub=sscanf(version1,'%d%*[^0123456789]');
v2Sub=sscanf(version2,'%d%*[^0123456789]');

subVers=length(v2Sub);

if length(v1Sub)< subVers
    subVers=length(v1Sub);
end

%go through each sub version and compare. Exit if difference found
for i = 1:subVers
   if v1Sub(i) > v2Sub(i)
      flag=1; 
      return;  
   end
   
   if v1Sub(i) < v2Sub(i)
      flag=-1; 
      return;  
   end
end

%still there? if all sub versions are equal the longer string should be 
%the more current version


if length(v1Sub) < length(v2Sub) 
    flag=-1;
    return;
end
   
if length(v1Sub) > length(v2Sub) 
    flag=1;
    return;
end

%all subversions seem to match, so we return 0 for equal

return;


% calculate if version1 is greater than version2
function flag = i_osc_compare_matlab_version(version1, version2)

% Compares two strings corresponding to matlab versions.
%
% function flag = i_osc_compare_stateflow_version(version1, version2)
%
%   INPUT                     DESCRIPTION
%    version1                  string representing version
%    version2                  string representing version
%
%   OUTPUT                    DESCRIPTION
%    flag                       0 if version1 = version2
%                               1 if version1 > version2
%                              -1 if version1 < version2
%                               2 if either version1 or version2 is an unrecognized version string.
% AUTHOR(S):
%   Marten Penning
%   BTC - Embedded Systems AG, GERMANY
%   Copyright 2003-2006
%


flag = 2;

if strcmp(version1, '6.1')
    if strcmp(version2, '6.1')
        flag = 0;
    elseif strcmp(version2, '6.5.1')
        flag = -1;
    elseif strcmp(version2, '6.5.2')
        flag = -1;
    elseif strcmp(version2, '7.0')
        flag = -1;
    elseif strcmp(version2, '7.0.1')
        flag = -1;
    elseif strcmp(version2, '7.0.4')
        flag = -1;
    elseif strcmp(version2, '7.1')
        flag = -1;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
end

if strcmp(version1, '6.5.1')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 0;
    elseif strcmp(version2, '6.5.2')
        flag = -1;
    elseif strcmp(version2, '7.0')
        flag = -1;
    elseif strcmp(version2, '7.0.1')
        flag = -1;
    elseif strcmp(version2, '7.0.4')
        flag = -1;
    elseif strcmp(version2, '7.1')
        flag = -1;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
end

if strcmp(version1, '6.5.2')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 0;
    elseif strcmp(version2, '7.0')
        flag = -1;
    elseif strcmp(version2, '7.0.1')
        flag = -1;
    elseif strcmp(version2, '7.0.4')
        flag = -1;
    elseif strcmp(version2, '7.1')
        flag = -1;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
end

if strcmp(version1, '7.0')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 1;
    elseif strcmp(version2, '7.0')
        flag = 0;
    elseif strcmp(version2, '7.0.1')
        flag = -1;
    elseif strcmp(version2, '7.0.4')
        flag = -1;
    elseif strcmp(version2, '7.1')
        flag = -1;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
 end
 
if strcmp(version1, '7.0.1')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 1;
    elseif strcmp(version2, '7.0')
        flag = 1;
    elseif strcmp(version2, '7.0.1')
        flag = 0;
    elseif strcmp(version2, '7.0.4')
        flag = -1;
    elseif strcmp(version2, '7.1')
        flag = -1;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
 end
  
if strcmp(version1, '7.0.4')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 1;
    elseif strcmp(version2, '7.0')
        flag = 1;
    elseif strcmp(version2, '7.0.1')
        flag = 1;
    elseif strcmp(version2, '7.0.4')
        flag = 0;
    elseif strcmp(version2, '7.1')
        flag = -1;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
 end

if strcmp(version1, '7.1')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 1;
    elseif strcmp(version2, '7.0')
        flag = 1;
    elseif strcmp(version2, '7.0.1')
        flag = 1;
    elseif strcmp(version2, '7.0.4')
        flag = 1;
    elseif strcmp(version2, '7.1')
        flag = 0;
    elseif strcmp(version2, '7.2')
        flag = -1;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end
end
 
if strcmp(version1, '7.2')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 1;
    elseif strcmp(version2, '7.0')
        flag = 1;
    elseif strcmp(version2, '7.0.1')
        flag = 1;
    elseif strcmp(version2, '7.0.4')
        flag = 1;
    elseif strcmp(version2, '7.1')
        flag = 1;
    elseif strcmp(version2, '7.2')
        flag = 0;
    elseif strcmp(version2, '7.3')
        flag = -1;
    end   
end

if strcmp(version1, '7.3')
    if strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '6.5.1')
        flag = 1;
    elseif strcmp(version2, '6.5.2')
        flag = 1;
    elseif strcmp(version2, '7.0')
        flag = 1;
    elseif strcmp(version2, '7.0.1')
        flag = 1;
    elseif strcmp(version2, '7.0.4')
        flag = 1;
    elseif strcmp(version2, '7.1')
        flag = 1;
    elseif strcmp(version2, '7.2')
        flag = 1;
    elseif strcmp(version2, '7.3')
        flag = 0;
    end   
end


return;


function flag = i_osc_compare_stateflow_version(version1, version2)

% Compares two strings corresponding to stateflow versions.
%
% function flag = i_osc_compare_stateflow_version(version1, version2)
%
%   INPUT                     DESCRIPTION
%    version1                  string representing version
%    version2                  string representing version
%
%   OUTPUT                    DESCRIPTION
%    flag                       0 if version1 = version2
%                               1 if version1 > version2
%                              -1 if version1 < version2
%                               2 if either version1 or version2 is an unrecognized version string.
% AUTHOR(S):
%   Marten Penning
%   BTC - Embedded Systems AG, GERMANY
%   Copyright 2003-2006
%

flag = 2;
if strcmp(version1, '6.5')
    if strcmp(version2, '6.5')
        flag = 0;
    elseif strcmp(version2, '6.4.1')
        flag = 1;
    elseif strcmp(version2, '6.4')
        flag = 1;
    elseif strcmp(version2, '6.3')
        flag = 1;        
    elseif strcmp(version2, '6.2')
        flag = 1;
    elseif strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '5.1.2')
        flag = 1;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '6.4.1')
     if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = 0;
    elseif strcmp(version2, '6.4')
        flag = 1;
    elseif strcmp(version2, '6.3')
        flag = 1;        
    elseif strcmp(version2, '6.2')
        flag = 1;
    elseif strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '5.1.2')
        flag = 1;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '6.4')
     if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = 0;
    elseif strcmp(version2, '6.3')
        flag = 1;        
    elseif strcmp(version2, '6.2')
        flag = 1;
    elseif strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '5.1.2')
        flag = 1;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '6.3')
    if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = -1;
    elseif strcmp(version2, '6.3')
        flag = 0;        
    elseif strcmp(version2, '6.2')
        flag = 1;
    elseif strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '5.1.2')
        flag = 1;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;        
    end
elseif strcmp(version1, '6.2')
    if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = -1;
    elseif strcmp(version2, '6.3')
        flag = -1;        
    elseif strcmp(version2, '6.2')
        flag = 0;
    elseif strcmp(version2, '6.1')
        flag = 1;
    elseif strcmp(version2, '5.1.2')
        flag = 1;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '6.1')
    if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = -1;
    elseif strcmp(version2, '6.3')
        flag = -1;        
    elseif strcmp(version2, '6.2')
        flag = -1;
    elseif strcmp(version2, '6.1')
        flag = 0;
    elseif strcmp(version2, '5.1.2')
        flag = 1;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '5.1.2')
    if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = -1;
    elseif strcmp(version2, '6.3')
        flag = -1;        
    elseif strcmp(version2, '6.2')
        flag = -1;
    elseif strcmp(version2, '6.1')
        flag = -1;
    elseif strcmp(version2, '5.1.2')
        flag = 0;
    elseif strcmp(version2, '5.1.1')
        flag = 1;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '5.1.1')
    if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = -1;
    elseif strcmp(version2, '6.3')
        flag = -1;        
    elseif strcmp(version2, '6.2')
        flag = -1;
    elseif strcmp(version2, '6.1')
        flag = -1;
    elseif strcmp(version2, '5.1.2')
        flag = -1;
    elseif strcmp(version2, '5.1.1')
        flag = 0;
    elseif strcmp(version2, '4.2.1')
        flag = 1;
    end
elseif strcmp(version1, '4.2.1')
    if strcmp(version2, '6.5')
        flag = -1;
    elseif strcmp(version2, '6.4.1')
        flag = -1;
    elseif strcmp(version2, '6.4')
        flag = -1;
    elseif strcmp(version2, '6.3')
        flag = -1;        
    elseif strcmp(version2, '6.2')
        flag = -1;
    elseif strcmp(version2, '6.1')
        flag = -1;
    elseif strcmp(version2, '5.1.2')
        flag = -1;
    elseif strcmp(version2, '5.1.1')
        flag = -1;
    elseif strcmp(version2, '4.2.1')
        flag = 0;
    end
end

return;

