function [hLogger, sMemoryPath, nPort] = atgcv_m13_logger_state_create(hDestBlock, sName)
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

%% Create Constant block
sInputName = 'btc_const';
sLoggerPath = [sParent,'/',sInputName];
hInport = add_block('built-in/Constant', sLoggerPath);
anPosition = [ 100 90 125 102];
set_param( hInport, 'Position', anPosition );


%% Create Sum block
sSumName = 'btc_sum';
sSumPath = [sParent,'/',sSumName];
hSum = add_block('built-in/Sum', sSumPath);
anPosition = [ 200 90 225 110];
set_param( hSum, 'Position', anPosition );


%% Crete connections
atgcv_m13_add_line( sParent, sInputName, nPort, sSumName, nPort);

%% Create Memory block
sMemoryName = 'btc_mem';
sMemoryPath = [sParent,'/',sMemoryName];
hMemory = add_block('built-in/Memory', sMemoryPath);
set_param(hMemory,'InheritSampleTime','on');
anPosition = [ 300 80 325 120];
set_param( hMemory, 'Position', anPosition );

%% Crete connections
atgcv_m13_add_line( sParent, sSumName, nPort, sMemoryName, nPort);
atgcv_m13_add_line( sParent, sMemoryName, nPort, sSumName, 2);









%**************************************************************************
% END OF FILE
%**************************************************************************