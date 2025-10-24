function atgcv_m46_storage_class_set(stEnv)
%
% function atgcv_m46_storage_class_set(stEnv)
%
%   INPUTS               DESCRIPTION
%   stEnv                (struct)    Environment settings.
%     .hMessenger        (handle)    Messenger handle.
%     .sTmpPath          (string)    TMP directory
%   OUTPUT               DESCRIPTION
%     -                     -
%
%   
%%

ahClasses = dsdd('find','//DD0/Pool/VariableClasses', ...
    'objectkind','VariableClass' );

% This is a hack to pass UT_MT46_032 and should be reconsidered
sStorageSet = 'default';
try
    ahSubsys = dsdd('find','//DD0/Subsystems', 'objectkind', 'Subsystem');
    for i=1:length(ahSubsys)
        hSubsys = ahSubsys(i);
        ahAddFiles = dsdd('GetAdditionalFiles', hSubsys);
        if ~isempty(ahAddFiles)
            sStorageSet = 'static';
            break;
        end
    end
catch
end
% SET EXTERN variables to MERGABLE variables
for i = 1:length( ahClasses )
    hClass = ahClasses(i);
    sStorage = dsdd( 'Get', hClass, 'Storage');
    sModule = dsdd( 'Get', hClass, 'Module');
    sModuleRef = dsdd( 'Get', hClass, 'ModuleRef');
    dMacro = dsdd( 'Get', hClass, 'Macro');
    bMacroOn = isequal(dMacro,1);
    bExtern = strcmp( sStorage, 'extern') ;
    
    % All extern declared variables must be created by the user
    % and they are not part of any predefined module 
    bModuleRef = false;
  
    if( ~isempty(sModuleRef) )
        bModuleRef = true;
        [hModule, nErrorCode] = dsdd('GetModuleRefTarget',hClass); 
        if( nErrorCode == 0)
            [sResponsibility,nErrorCode] = ...
                dsdd('GetModuleInfoResponsibility',hModule); 

            if( nErrorCode == 0)
                if( strcmp( sResponsibility, 'External' ) )
                    % MAN usecase, module is external
                    % therefore external variables should be
                    % make static (redefinition of variables)
                    bModuleRef = false;
                end
            end
        end

    end
      
    bModule = ~isempty(sModule);
    
    if( bExtern && ~bMacroOn && ~bModuleRef && ~bModule )
        %sDescription = dsdd( 'Get', hClass, 'Description');
        %disp(sDescription);
        dsdd('ClearMessageList');
        dsdd('SetAccessRights', hClass,'access','rwrw');
        nNumMes = dsdd('GetNumMessages');
        if nNumMes
            osc_messenger_add( stEnv, ...
                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                'step', 'setting DD calibrations', ...
                'descr', 'Setting access rights of DD calibration variable class failed.' );
        end
        nErrorCode = dsdd( 'Set', hClass, 'Storage', sStorageSet);
        if(nErrorCode)
			osc_messenger_add( stEnv, ...
                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                'step', 'setting DD calibrations', ...
                'descr', 'Setting of DD calibration variable class failed.' );
		end
        nErrorCode = dsdd( 'Set', hClass, 'InitAtDefinition', 'on');
		if(nErrorCode)
			osc_messenger_add( stEnv, ...
                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                'step', 'setting DD calibrations', ...
                'descr', 'Setting of DD calibration variable class failed.' );
		end
        nErrorCode = dsdd( 'Set', hClass, 'Macro', 'off');
		if(nErrorCode)
			osc_messenger_add( stEnv, ...
                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                'step', 'setting DD calibrations', ...
                'descr', 'Setting of DD calibration variable class failed.' );
		end
        nErrorCode = dsdd( 'Set', hClass, 'Optimization', 'MERGEABLE' );
		if(nErrorCode)
			osc_messenger_add( stEnv, ...
                'ATGCV:MDEBUG_ENV:EXPORT_ERROR', ...
                'step', 'setting DD calibrations', ...
                'descr', 'Setting of DD calibration variable class failed.' );
		end
    end
end



%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************
