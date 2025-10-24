function sltu_codegen_int
% Suite: CodeGen INIT function
%


%%
global ATGCV_DS_ERROR_MODE;
global ATGCV_TL_ERROR_MODE;

try
    ATGCV_DS_ERROR_MODE = ds_error_get('BatchMode');
    ATGCV_TL_ERROR_MODE = tl_error_get('BatchMode');
    ds_error_set('BatchMode', 'on'); 
    tl_error_set('BatchMode', 'on'); 
    
catch oEx
    MU_FAIL_FATAL(oEx.message);
end
end

