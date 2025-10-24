function atgcv_m46_calibration_info_set(stEnv, sExportDir)
%
% function atgcv_m46_calibration_info_set(stEnv, sExportDir)
%
%   INPUTS               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%     .sResultPath       (string)    Result directory for outputs
%   sExportDir           (string)    Export directory of the M-debug
%                                    environment.
%   OUTPUT               DESCRIPTION
%     -                     -
%
%
%%


bIsWithVariants = ~isempty(dsdd('GetDataVariants'));
    
sCalibrationInfo = fullfile(sExportDir, 'CalibrationInfo.xml');

if( exist( sCalibrationInfo, 'file' ) )
    hRoot = mxx_xmltree('load', sCalibrationInfo);

    ahCalibrationNodes = mxx_xmltree('get_nodes', hRoot, '//Calibration');
    for i = 1:length(ahCalibrationNodes)
        xCalibration = ahCalibrationNodes(i);

        % get the origin from the modelanalysis xml tree.
        [sUsage, sPath, sInit, sDDVar] = i_eval_calibration( xCalibration );

        if( strcmp( sUsage, 'explicit_param'))
            continue;
        end

        try
            xValue = evalin('base', sInit );
            hBlock = get_param(sPath,'Handle');
            % TODO type must be given by XML file
            sType = i_type_get( sUsage, hBlock );
            sFullDDVariable = ['/Pool/Variables/',sDDVar];
            if( ~isempty( sDDVar ) && dsdd('Exist', sFullDDVariable))     
                % Setting of the DD value of variable
                sValue = sprintf( '%s( %s )', sType, xValue );
                dValue = eval( sValue );
% 				nErrorCode = dsdd('SetAccessRights',['/Pool/Variables/',sDDVar],'access','rwrw');
% 				if(nErrorCode)
% 					osc_throw( osc_messenger_add( stEnv, ...
% 						'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
% 						'descr', 'Settting access rights of DD calibration variable class failed.' ) );
% 				end
                nErrorCode = dsdd('SetValue', sFullDDVariable, double(dValue) );
                if(nErrorCode)
                    osc_messenger_add( stEnv, ...
                        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                        'step', 'setting DD calibrations', ...
                        'descr', 'Settting of DD calibration variable value failed.');
                end
                if bIsWithVariants
                    % set value for *all* variants
                    aiActiveVariantIds = i_getActiveVariantIDs(sFullDDVariable);
                    for k = 1:numel(aiActiveVariantIds)
                        nErrorCode = dsdd('SetValue', sFullDDVariable, double(dValue), aiActiveVariantIds(k));
                        if(nErrorCode)
                            osc_messenger_add( stEnv, ...
                                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                                'step', 'setting DD calibrations', ...
                                'descr', 'Setting of DD calibration variable value failed.');
                        end
                    end
                end
            end


            switch( sUsage )
                case 'const'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'output.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'output.value', sValue );
                        i_adapt_name( hBlock, 'output.name' );
                    end
                    
                case 'relay_switch_on'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'onswitch.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'onswitch.value', sValue );
                        i_adapt_name( hBlock, 'onswitch.name' );
                    end
                case 'relay_switch_off'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'offswitch.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'offswitch.value', sValue );
                        i_adapt_name( hBlock, 'offswitch.name' );
                    end
                case 'relay_out_on'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'onoutput.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'onoutput.value', sValue );
                        i_adapt_name( hBlock, 'onoutput.name' )
                    end
                case 'relay_out_off'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'offoutput.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'offoutput.value', sValue );
                        i_adapt_name( hBlock, 'offoutput.name' );
                    end
                case 'sat_upper'
                    if( atgcv_version_compare('TL3.0') < 0 )
                        if( ~isempty( sDDVar ) )
                            sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                            tl_set( hBlock, 'output.value', sValue );
                        else
                            sValue = sprintf( '%s( %s )', sType, xValue );
                            tl_set( hBlock, 'output.value', sValue );
                            i_adapt_name( hBlock, 'output.name' );
                        end
                    else
                        if( ~isempty( sDDVar ) )
                            sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                            tl_set( hBlock, 'upperlimit.value', sValue );
                        else
                            sValue = sprintf( '%s( %s )', sType, xValue );
                            tl_set( hBlock, 'upperlimit.value', sValue );
                            i_adapt_name( hBlock, 'upperlimit.name' );
                        end
                    end
                case 'sat_lower'
                    if( atgcv_version_compare('TL3.0') < 0 )
                        if( ~isempty( sDDVar ) )
                            sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                            tl_set( hBlock, 'output.value', sValue );
                        else
                            sValue = sprintf( '%s( %s )', sType, xValue );
                            tl_set( hBlock, 'output.value', sValue );
                            i_adapt_name( hBlock, 'output.name' );
                        end
                    else
                        if( ~isempty( sDDVar ) )
                            sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                            tl_set( hBlock, 'lowerlimit.value', sValue );
                        else
                            sValue = sprintf( '%s( %s )', sType, xValue );
                            tl_set( hBlock, 'lowerlimit.value', sValue );
                            i_adapt_name( hBlock, 'lowerlimit.name' );
                        end
                    end
                case 'switch_threshold'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'threshold.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'threshold.value', sValue );
                        i_adapt_name( hBlock, 'threshold.name' );
                    end
                case 'gain'
                    if( ~isempty( sDDVar ) )
                        sValue = sprintf( '%s(ddv(''%s''))', sType, sDDVar );
                        tl_set( hBlock, 'gain.value', sValue );
                    else
                        sValue = sprintf( '%s( %s )', sType, xValue );
                        tl_set( hBlock, 'gain.value', sValue );
                        i_adapt_name( hBlock, 'gain.name' );
                    end
                case {'sf_param','sf_const'}
                case 'explicit_param'
                otherwise
                    osc_messenger_add( stEnv, ...
                        'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                        'step', 'setting DD calibrations', ...
                        'descr', 'Usage of calibration variable not considered.' );
            end
        catch
            osc_messenger_add( stEnv, ...
                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                'step', 'setting DD calibrations', ...
                'descr', 'Setting of calibration variable failed.' );
        end

    end

    mxx_xmltree('clear', hRoot);
end
end



%%
function [sUsage, sPath, sInit, sDDVar] = i_eval_calibration( xCalibration )
sUsage = mxx_xmltree('get_attribute', xCalibration, 'origin');
sPath =  mxx_xmltree('get_attribute', xCalibration, 'path');
sInit =  mxx_xmltree('get_attribute', xCalibration, 'init');
%sAccess = mxx_xmltree('get_attribute', xCalibration, 'access');
sDDVar = mxx_xmltree('get_attribute', xCalibration, 'ddVariable');
end


%%
function sType = i_type_get( sUsage, hBlock )
sType = '';
switch( sUsage )
    case 'const'
        sParam = get_param( hBlock, 'value' );
        sType = i_evaluate_type( sParam );
    case 'relay_switch_on'
        sParam = get_param( hBlock, 'OnSwitchValue' );
        sType = i_evaluate_type( sParam );
    case 'relay_switch_off'
        sParam = get_param( hBlock, 'OffSwitchValue' );
        sType = i_evaluate_type( sParam );
    case 'relay_out_on'
        sParam = get_param( hBlock, 'OnOutputValue' );
        sType = i_evaluate_type( sParam );
    case 'relay_out_off'
        sParam = get_param( hBlock, 'OffOutputValue' );
        sType = i_evaluate_type( sParam );
    case 'sat_upper'
        if( atgcv_version_compare('TL3.0') < 0 )
            sParam = get_param( hBlock, 'value' );
            sType = i_evaluate_type( sParam );
        else
            sParam = get_param( hBlock, 'UpperLimit' );
            sType = i_evaluate_type( sParam );
        end
    case 'sat_lower'
        if( atgcv_version_compare('TL3.0') < 0 )
            sParam = get_param( hBlock, 'value' );
            sType = i_evaluate_type( sParam );
        else
            sParam = get_param( hBlock, 'LowerLimit' );
            sType = i_evaluate_type( sParam );
        end
    case 'switch_threshold'
        sParam = get_param( hBlock, 'threshold' );
        sType = i_evaluate_type( sParam );
    case 'gain'
        sParam = get_param( hBlock, 'gain' );
        sType = i_evaluate_type( sParam );
    case {'sf_param','sf_const'}
        % nothing to do here yet
        % NOT SUPPORTED YET
    case 'explicit_param'
        % nothing to do here yet
        % NOT SUPPORTED YET
    otherwise
        osc_messenger_add( stEnv, ...
            'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
            'step', 'setting DD calibrations', ...
            'descr', 'Usage of calibration variable not considered.');
end
end


%%
function i_adapt_name( hBlock, sAccess )
% check if 'output.name' is not $P otherwise
% exception during comiling
sName = tl_get( hBlock,  sAccess);
if( strcmp( sName, '$P' ) )
    tl_set( hBlock, sAccess, '$S_$B' );
end
end


%%
function aiActiveVariantIds = i_getActiveVariantIDs(sDdPath)
hDataVariant = dsdd('GetDataVariant', sDdPath);
if isempty(hDataVariant)
    aiActiveVariantIds = [];
else
    aiActiveVariantIds = dsdd('GetDataVariantIDs', hDataVariant);
end
end


%%
function sType = i_evaluate_type( sExpression )
try
    if( ~ischar( sExpression ) )
        if isa(sExpression, 'Simulink.Parameter')
            sType = 'Simulink.Parameter';
        else
            sType = class( sExpression );
        end
    else
        if evalin('base', ['isa(', sExpression, ', ''Simulink.Parameter'')'])
            sType = 'Simulink.Parameter';
        else
            sType = evalin('base', ['class(',sExpression,')']);
        end
    end
catch
    % TODO find variable in model
    % now is default double
    sType = 'double';
end

switch( sType )
    case{'double','float','single'}
    case{'logical','char','numeric','integer'}
    case{'int8','int16','int32','int64'}
    case{'uint8','uint16','uint32','uint64'}
    case{'Simulink.Parameter'}
        if( ~ischar( sExpression ) )
            sType = sExpression.DataType;
        else
            sType = evalin( 'base', [sExpression,'.DataType'] );
        end

        if( strcmp(sType,'auto') )
            sType = 'double';
        end
    otherwise
        sType = 'double';
end
end
