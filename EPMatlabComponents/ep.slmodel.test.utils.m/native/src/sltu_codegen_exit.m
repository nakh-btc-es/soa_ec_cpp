function sltu_codegen_exit
% Suite: CodeGen EXIT function
%


%%
global ATGCV_DS_ERROR_MODE;
global ATGCV_TL_ERROR_MODE;

try
    ds_error_set('BatchMode', ATGCV_DS_ERROR_MODE); 
    tl_error_set('BatchMode', ATGCV_TL_ERROR_MODE); 
    
catch oEx
    MU_FAIL_FATAL(oEx.message);
end
end
