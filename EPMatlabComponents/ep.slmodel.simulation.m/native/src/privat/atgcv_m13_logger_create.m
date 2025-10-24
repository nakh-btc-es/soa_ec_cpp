function [hLogger,sCastPath,nPort] = atgcv_m13_logger_create(hDestBlock, sName)
% Create the logger block
%
% Parameters:
%  	 hDestBlock      (handle)    Handle of the parent block.
%
% Output:
%    hLogger         (handle)    Handle of the logger block.
%
% AUTHOR(S):
%   Remmer.Wilts@osc-es.de
% $$$COPYRIGHT$$$-2006
%
%%

nPort = 1;

hLogger = atgcv_m13_add_block('built-in/Subsystem',...
    getfullname( hDestBlock ), sName);
set_param( hLogger, 'BackgroundColor', 'Yellow');
set_param( hLogger, 'ShowPortLabels', 'off' );
set_param( hLogger, 'ShowName', 'off' );

sParent = getfullname( hLogger );

%% Create Inport block
sInputName = 'btc_in';
sInportPath = [sParent,'/',sInputName];
hInport = add_block('built-in/Inport', sInportPath);
anPosition = [ 100 100 100+25 100+12];
set_param( hInport, 'Position', anPosition );


%% Create Cast block
sCastName = 'btc_cast';
sCastPath = [sParent,'/',sCastName];
hCast = add_block('built-in/DataTypeConversion', sCastPath);
anPosition = [ 200 100 200+25 112];
set_param( hCast, 'Position', anPosition );

%% Create Terminator block
sTermName = 'btc_term';
sTermPath = [sParent,'/',sTermName];
hCast = add_block('built-in/Terminator', sTermPath);
anPosition = [ 300 100 300+25 112];
set_param( hCast, 'Position', anPosition );


%% Crete connections
atgcv_m13_add_line( sParent, sInputName, nPort, sCastName, nPort);
atgcv_m13_add_line( sParent, sCastName, nPort, sTermName, nPort);













%**************************************************************************
% END OF FILE
%**************************************************************************