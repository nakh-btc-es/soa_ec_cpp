/*
 * Simple C interface test for signal_dvPrivate_acMethod model
 * 
 * This demonstrates how to use the model from pure C code
 * using the extern "C" interface functions.
 */

#include "model_test_wrapper.h"
#include <stdio.h>
#include <math.h>

int main(void)
{
    printf("\n🚀 C INTERFACE TEST\n");
    printf("Model: signal_dvPrivate_acMethod v1.20\n");
    printf("========================================\n");
    
    /* Initialize the model */
    if (!c_model_initialize()) {
        printf("❌ Failed to initialize model!\n");
        return -1;
    }
    printf("✅ Model initialized successfully\n");
    
    /* Set some input values */
    g_InScalar_dvPrivate_amMethod = 3.5f;
    g_InArray_dvPrivate_amMethod[0] = 1.5f;
    g_InArray_dvPrivate_amMethod[1] = 2.5f;
    g_InBus_dvPrivate_amMethod.FlptSig1 = 10.0f;
    g_InBus_dvPrivate_amMethod.FlptSig2 = 20.0f;
    g_InBusElm_dvPrivate_amMethod_FxptSig1 = 1000;
    g_InBusElm_dvPrivate_amMethod_FxptSig2 = 2000;
    
    printf("\n📥 Input values set:\n");
    printf("  Scalar: %.2f\n", g_InScalar_dvPrivate_amMethod);
    printf("  Array: [%.2f, %.2f]\n", 
           g_InArray_dvPrivate_amMethod[0], 
           g_InArray_dvPrivate_amMethod[1]);
    printf("  Bus: {%.2f, %.2f}\n", 
           g_InBus_dvPrivate_amMethod.FlptSig1,
           g_InBus_dvPrivate_amMethod.FlptSig2);
    printf("  Fixed-point: [%d, %d]\n", 
           g_InBusElm_dvPrivate_amMethod_FxptSig1,
           g_InBusElm_dvPrivate_amMethod_FxptSig2);
    
    /* Run a few simulation steps */
    printf("\n🔄 Running simulation steps:\n");
    printf("Step | Scalar In | Scalar Out | Scalar State\n");
    printf("-----|-----------|------------|-------------\n");
    
    for (int step = 0; step < 5; step++) {
        /* Modify input for this step */
        g_InScalar_dvPrivate_amMethod = 1.0f + 0.5f * (float)step;
        
        /* Execute model step */
        if (!c_model_step()) {
            printf("❌ Model step %d failed!\n", step);
            c_model_terminate();
            return -1;
        }
        
        /* Print results */
        printf("%4d | %9.2f | %10.2f | %11.2f\n",
               step,
               g_InScalar_dvPrivate_amMethod,
               g_OutScalar_dvPrivate_amMethod,
               g_LocScalar_dvPrivate_amMethod);
    }
    
    /* Test parameter modification */
    printf("\n⚙️ Testing parameter modification:\n");
    printf("Original ParamScalar: %.2f\n", g_ParamScalar);
    
    g_ParamScalar = 5.0f;
    g_ParamArray[0] = 3.0f;
    g_ParamArray[1] = 4.0f;
    
    if (!c_model_update_parameters()) {
        printf("❌ Failed to update parameters!\n");
        c_model_terminate();
        return -1;
    }
    
    printf("Updated ParamScalar: %.2f\n", g_ParamScalar);
    printf("Updated ParamArray: [%.2f, %.2f]\n", g_ParamArray[0], g_ParamArray[1]);
    
    /* Run one more step with new parameters */
    g_InScalar_dvPrivate_amMethod = 1.0f;
    g_InArray_dvPrivate_amMethod[0] = 1.0f;
    g_InArray_dvPrivate_amMethod[1] = 1.0f;
    
    if (!c_model_step()) {
        printf("❌ Final step failed!\n");
        c_model_terminate();
        return -1;
    }
    
    printf("\n📤 Final outputs with new parameters:\n");
    printf("  Scalar Output: %.2f (should be 5.0 * previous input)\n", 
           g_OutScalar_dvPrivate_amMethod);
    printf("  Array Output: [%.2f, %.2f] (should be [3.0, 4.0] * previous inputs)\n", 
           g_OutArray_dvPrivate_amMethod[0], 
           g_OutArray_dvPrivate_amMethod[1]);
    
    /* Print complete status */
    printf("\n📋 Complete model status:\n");
    c_model_print_status();
    
    /* Cleanup */
    c_model_terminate();
    
    printf("\n🎉 C interface test completed successfully!\n");
    return 0;
}