function atgcv_m13_sf_calibrate_set(stEnv,fid,xCalibration,hModelContextNode,sBlockChart, bModelRef)
%
% function atgcv_m13_sf_calibrate_set(stEnv,fid,xCalibration,hModelContextNode,sBlockChart, bModelRef)
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


sModel = bdroot(sBlockChart);
[sValue,sZeroValue,bScalar] = atgcv_m13_cal_value_get(xCalibration);
ahVariable = ep_em_entity_find( xCalibration, './Variable');
sVarid =  ep_em_entity_attribute_get( ahVariable{1}, 'varid');

sSFVarName = ep_em_entity_attribute_get(hModelContextNode,'stateflowVariable');
hSfObject = [];

[sVarType, bIsSimParam, bIsSimSignal, bIsBwVar, bIsMwVar, sVarPath, bIsNotDefined] = ...
    atgcv_m13_eval_vartype(stEnv, sBlockChart, sSFVarName, '0'); % default 0 init value
sTypeValue = sprintf( '%s( %s )', sVarType, sValue );
bInitSFVar = false;
if( ~bModelRef )
    hSfObject = atgcv_m13_sf_object_get(sModel,...
        hModelContextNode, ...
        sBlockChart);
    
    sf('set', hSfObject,'.description', ''); %Reset TL init values
    
    
    % Note type of sf object not yet used
    % sType = sf( 'get', hSfObject, '.dataType');
    % sTypeValue = sprintf( '%s(%s)', sType, sValue);
    
    
    sInitValue =  sf( 'get', hSfObject,'.props.initialValue');
    [sVarType, bIsSimParam, bIsSimSignal, bIsBwVar, bIsMwVar, sVarPath, bIsNotDefined] = ...
        atgcv_m13_eval_vartype(stEnv, sBlockChart, sSFVarName, sInitValue);
    sTypeValue = sprintf( '%s( %s )', sVarType, sValue );
    %sTypeInitValue = sprintf( '%s( %s )', sVarType, sZeroValue );
    
    
    % Note: Type convert to parameter, when scope is constant or
    % local and variable is not a scalar
    bML77 = atgcv_version_compare('ML7.7');
    bInitFromWS = sf('get', hSfObject,'.initFromWorkspace');
    bInitSFVar = ~isempty( sInitValue ) || bInitFromWS;
    if(bML77 < 0 )
        if( bInitSFVar )
            if(~bScalar) % only when it is not a scalar
                dScope = sf( 'get', hSfObject,'.scope');
                % Note: this is of course changing the model !!!
                if( isequal(dScope,7) || isequal(dScope,0)) % constant or local
                    sf('set', hSfObject,'.scope', 10); % 10 is Parameter
                end
            end
        end
    end
end

fprintf(fid,'\n%s%s %s\n', '%', atgcv_var2str(sBlockChart), sSFVarName);
if( ~bModelRef )
    if( bInitSFVar )
        if(bML77 >= 0 || bScalar )
            sVariable = ['btc_',sVarid,'_init'];
            hws = get_param(sModel,'modelworkspace');
            try
                xValue = evalin('base',sInitValue);
            catch 
                xValue = 0; % just not to throw an exception
            end
            hws.assignin(sVariable, xValue);
            if( ~isempty(hSfObject) )
                sf( 'set', hSfObject,'.props.initialValue', sVariable);
            end
            
            fprintf(fid,'\t try\n');
            fprintf(fid,'\t\t hws = get_param(''%s'',''modelworkspace'');\n', sModel);
            fprintf(fid,'\t\t hws.assignin(''%s'',%s);\n', sVariable, sTypeValue);
            fprintf(fid,'\t catch \n');
            fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
            fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
            fprintf(fid,'\t end\n');
        end
    end
    
    if( bIsSimSignal )
        if( bIsMwVar )      
            fprintf(fid,'\t try\n');
            fprintf(fid,'\t\t hws = get_param(''%s'',''modelworkspace'');\n', sModel);
            fprintf(fid,'\t\t hws.evalin(''%s.InitialValue = ''''%s'''';'');\n', sSFVarName, sTypeValue);
            fprintf(fid,'\t catch \n');
            fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
            fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
            fprintf(fid,'\t end\n');         
        elseif( bIsBwVar )    
            fprintf(fid,'\t try\n');
            fprintf(fid,'\t\t evalin(''base'',''%s.InitialValue = ''''%s'''';'');\n', ...
                sSFVarName, sTypeValue);
            fprintf(fid,'\t catch \n');
            fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
            fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
            fprintf(fid,'\t end\n');          
        end
    else
        if( bIsMwVar )
            if bIsSimParam              
                fprintf(fid,'\t try\n');
                fprintf(fid,'\t\t hws = get_param(''%s'',''modelworkspace'');\n', sModel);
                fprintf(fid,'\t\t hws.assignin(''et_temp_%s'',%s);\n', ...
                    sSFVarName, sTypeValue);
                fprintf(fid,'\t\t hws.evalin(''%s.Value = et_temp_%s;'');\n',sSFVarName, sSFVarName);
                fprintf(fid,'\t\t hws.clear(''et_temp_%s'');\n', sSFVarName);
                fprintf(fid,'\t catch \n');
                fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
                fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
                fprintf(fid,'\t end\n');              
            else              
                fprintf(fid,'\t try\n');
                fprintf(fid,'\t\t hws = get_param(''%s'',''modelworkspace'');\n', sModel);
                fprintf(fid,'\t\t hws.assignin(''%s'',%s);\n',sSFVarName, sTypeValue);
                fprintf(fid,'\t catch \n');
                fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
                fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
                fprintf(fid,'\t end\n');               
            end
        elseif( bIsBwVar )
            if bIsSimParam              
                fprintf(fid,'\t try\n');
                fprintf(fid,'\t\t assignin(''base'',''et_temp_%s'',%s);\n', ...
                    sSFVarName, sTypeValue);
                fprintf(fid,'\t\t evalin(''base'',''%s.Value = et_temp_%s;'');\n', ...
                    sSFVarName, sSFVarName);
                fprintf(fid,'\t\t evalin(''base'',''clear et_temp_%s;'');\n', ...
                    sSFVarName);
                fprintf(fid,'\t catch \n');
                fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
                fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
                fprintf(fid,'\t end\n');            
            else             
                fprintf(fid,'\t try\n');
                fprintf(fid,'\t\t assignin(''base'',''%s'',%s);\n', ...
                    sSFVarName, sTypeValue);
                fprintf(fid,'\t catch \n');
                fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
                fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
                fprintf(fid,'\t end\n');              
            end
        else           
            fprintf(fid,'\t try\n');
            fprintf(fid,'\t\t set_param(''%s'', ''%s'', mat2str(%s));\n', ...
                sVarPath, sSFVarName, sTypeValue);
            fprintf(fid,'\t catch \n');
            fprintf(fid,'\t\t stError = lasterror; %s\n','%#ok');
            fprintf(fid,'\t\t warning(''ATGCV:MDEBBUG:WARNING'',stError.message);\n');
            fprintf(fid,'\t end\n');         
        end
    end
end



%**************************************************************************
%  END OF FILE                                                            *
%**************************************************************************