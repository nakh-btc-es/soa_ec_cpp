function [sHtmlFile] = atgcv_m_messenger_export_html(sResultPath, sXMLfile, sKind)
% Export the messenger XML file to a HTML file.
%
% function [sHtmlFile] = atgcv_m_messenger_export_html(sResultPath, sXMLfile, sKind)
%
%   INPUT               DESCRIPTION
%     sResultPath        (string)     Result Path. Outputs are placed here. 
%                                     Existence is assumed.
%     sXMLfile           (string)     full path to the messengers xml file.
%     sKind              (string)     two kinds of report:
%                                     ('creation' | 'runtime')
%                                     1) 'creation' includes all error/warning
%                                     messages produced during profile creation
%                                     2) 'runtime' includes all messages that
%                                     were inserted after profile creation 
%                                     (can be reset)
%   OUTPUT              DESCRIPTION
%     sHtmlFile          (string) name of the generated html file (without path)
%     
%   REMARKS
%     
%

%% Internal
%  
%   REFERENCE(S):
%     -
%     
%
%   AUTHOR(S):
%     Hilger Steenblock, Remmer Wilts
% $$$COPYRIGHT$$$-2005
%
%%

sHtmlFile  = 'profileinfo.html';



% do the path extension
sOrigPath = getenv('PATH');
if atgcv_env_version_bits_get('WIN') == 64
    setenv('PATH', sprintf('%s;%s', atgcv_env_bin64_path, sOrigPath));
else
    setenv('PATH', sprintf('%s;%s', atgcv_env_bin_path, sOrigPath));
end
try
    switch sKind
        case 'runtime'
            %        atgcv_exec( 0, 'xsltproc', ...
            %              '-o', fullfile(sResultPath,sHtmlFile), ...
            %              fullfile(atgcv_env_xslt_path, ...
            %              'atgcv_m_messenger_export_runtime_html.xslt'), ...
            %              sXMLfile);
            com.btc.et.messenger.MessengerUtils.xsltproc( atgcv_global_messenger_get, ...
                java.io.File(sXMLfile), ...
                java.io.File(fullfile(atgcv_env_xslt_path, ...
                'atgcv_m_messenger_export_runtime_html.xslt')), ...
                java.io.File(fullfile(sResultPath,sHtmlFile)));
            
        case 'creation'
            %         atgcv_exec( 0, 'xsltproc', ...
            %             '-o', fullfile(sResultPath,sHtmlFile), ...
            %             fullfile(atgcv_env_xslt_path,...
            %             'atgcv_m_messenger_export_creation_html.xslt'), ...
            %             sXMLfile);
            com.btc.et.messenger.MessengerUtils.xsltproc( atgcv_global_messenger_get, ...
                java.io.File(sXMLfile), ...
                java.io.File(fullfile(atgcv_env_xslt_path, ...
                'atgcv_m_messenger_export_creation_html.xslt')), ...
                java.io.File(fullfile(sResultPath,sHtmlFile)));
        otherwise
            stErr = osc_messenger_add( 0, 'ATGCV:STD:WRONG_PARAM_CNT');
            osc_throw(stErr);
    end
catch %#ok
    e = lasterror; %#ok
    % restore the original path
    setenv('PATH', sOrigPath);
    error(e);
end
% restore the original path
setenv('PATH', sOrigPath);

%**************************************************************************
% INTERNAL FUNCTION DEFINITION(S)                                       ***
%                                                                       ***
%**************************************************************************


%**************************************************************************
% END OF FILE                                                           ***
%**************************************************************************
