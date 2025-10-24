function str = atgcv_var2str(var,varargin)
% Function generates string 'str' which creates MATLAB variable 'var' when invoked in MATLAB.
%
% function str = atgcv_var2str(var,varargin)
%
% Wrapper function for the TL 1.3 API function *tlvar2str* For details about the parameters 
% please see the % appropriate TL API documentation. 
%                        
%   AUTHOR(S):
%     Hilger Steenblock
% $$$COPYRIGHT$$$-2005
%
%   $Revision: 48234 $ Last modified: $Date: 2009-01-22 11:02:42 +0100 (Do, 22 Jan 2009) $ $Author: hilger $

if nargin > 1,
   str = ds_var2str(var, varargin{1});
else
   str = ds_var2str(var);
end

%******************************************************************************
% END OF FILE                                                               ***
%******************************************************************************