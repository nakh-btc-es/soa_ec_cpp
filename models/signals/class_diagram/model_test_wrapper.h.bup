//
// Test wrapper header for signal_dvPrivate_acMethod Simulink model
//
// This header provides declarations for global variables and functions
// to test and integrate the Simulink-generated model class.
//
// Generated for model: signal_dvPrivate_acMethod v1.20
//

#ifndef MODEL_TEST_WRAPPER_H
#define MODEL_TEST_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

// Include the custom bus type definition
#ifndef DEFINED_TYPEDEF_FOR_myBus_
#define DEFINED_TYPEDEF_FOR_myBus_
struct myBus
{
  float FlptSig1;
  float FlptSig2;
};
#endif

//=============================================================================
// GLOBAL INPUT VARIABLES (external write access)
//=============================================================================

// Scalar input
extern float g_InScalar_dvPrivate_amMethod;

// Array input (2 elements)
extern float g_InArray_dvPrivate_amMethod[2];

// Bus input
extern myBus g_InBus_dvPrivate_amMethod;

// Fixed-point bus element inputs
extern int16_t g_InBusElm_dvPrivate_amMethod_FxptSig1;
extern int16_t g_InBusElm_dvPrivate_amMethod_FxptSig2;
extern int16_t g_InBusElm_dvPrivate_amMethod1_FxptSig1;
extern int16_t g_InBusElm_dvPrivate_amMethod1_FxptSig2;

//=============================================================================
// GLOBAL OUTPUT VARIABLES (external read access)
//=============================================================================

// Scalar output
extern float g_OutScalar_dvPrivate_amMethod;

// Array output (2 elements)
extern float g_OutArray_dvPrivate_amMethod[2];

// Bus output
extern myBus g_OutBus_dvPrivate_amMethod;

// Fixed-point bus element outputs
extern int16_t g_OutBusElm_dvPrivate_amMethod_FxptSig1;
extern int16_t g_OutBusElm_dvPrivate_amMethod_FxptSig2;
extern int16_t g_OutBusElm_dvPrivate_amMethod1_FxptSig1;
extern int16_t g_OutBusElm_dvPrivate_amMethod1_FxptSig2;

//=============================================================================
// GLOBAL PARAMETER VARIABLES (external write access)
//=============================================================================

// Model parameters (can be modified to change model behavior)
extern float g_ParamScalar;        // Gain for scalar processing
extern float g_ParamArray[2];      // Gains for array processing

//=============================================================================
// GLOBAL STATE VARIABLES (external read access for monitoring)
//=============================================================================

// Unit delay states (read-only for monitoring)
extern float g_LocArray_dvPrivate_amMethod[2];
extern float g_LocScalar_dvPrivate_amMethod;

//=============================================================================
// MODEL LIFECYCLE FUNCTIONS
//=============================================================================

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Initialize the model instance and set default parameters
 * @return true if initialization successful, false otherwise
 */
bool model_initialize();

/**
 * @brief Terminate the model and cleanup resources
 */
void model_terminate();

/**
 * @brief Execute one time step of the model
 * 
 * This function:
 * 1. Transfers global input variables to model inputs
 * 2. Executes the model step function  
 * 3. Transfers model outputs to global output variables
 * 4. Updates global state variables for monitoring
 * 
 * @return true if step executed successfully, false otherwise
 */
bool model_step();

/**
 * @brief Update model parameters from global parameter variables
 * @return true if parameters updated successfully, false otherwise
 */
bool model_update_parameters();

//=============================================================================
// UTILITY AND DEBUG FUNCTIONS
//=============================================================================

/**
 * @brief Print current input values
 */
void model_print_inputs();

/**
 * @brief Print current output values
 */
void model_print_outputs();

/**
 * @brief Print current state variables
 */
void model_print_states();

/**
 * @brief Print current parameter values
 */
void model_print_parameters();

/**
 * @brief Print complete model status
 */
void model_print_status();

/**
 * @brief Run a simple test scenario with step inputs
 * @return true if test completed successfully
 */
bool model_test_step_response();

//=============================================================================
// C INTERFACE (for external integration)
//=============================================================================

/**
 * @brief C interface for model initialization
 * @return true if initialization successful, false otherwise
 */
bool c_model_initialize();

/**
 * @brief C interface for model termination
 */
void c_model_terminate();

/**
 * @brief C interface for model step execution
 * @return true if step executed successfully, false otherwise
 */
bool c_model_step();

/**
 * @brief C interface for parameter updates
 * @return true if parameters updated successfully, false otherwise
 */
bool c_model_update_parameters();

/**
 * @brief C interface for status printing
 */
void c_model_print_status();

#ifdef __cplusplus
}
#endif

//=============================================================================
// USAGE EXAMPLES AND DOCUMENTATION
//=============================================================================

/*

BASIC USAGE EXAMPLE:
===================

#include "model_test_wrapper.h"

int main() {
    // Initialize the model
    if (!model_initialize()) {
        return -1;
    }
    
    // Set input values
    g_InScalar_dvPrivate_amMethod = 1.5f;
    g_InArray_dvPrivate_amMethod[0] = 2.0f;
    g_InArray_dvPrivate_amMethod[1] = 3.0f;
    g_InBus_dvPrivate_amMethod.FlptSig1 = 4.0f;
    g_InBus_dvPrivate_amMethod.FlptSig2 = 5.0f;
    
    // Execute model step
    if (!model_step()) {
        model_terminate();
        return -1;
    }
    
    // Read output values
    printf("Scalar Output: %f\n", g_OutScalar_dvPrivate_amMethod);
    printf("Array Output: [%f, %f]\n", 
           g_OutArray_dvPrivate_amMethod[0], 
           g_OutArray_dvPrivate_amMethod[1]);
    
    // Print complete status
    model_print_status();
    
    // Cleanup
    model_terminate();
    return 0;
}

PARAMETER MODIFICATION EXAMPLE:
==============================

// Change gain parameters
g_ParamScalar = 3.0f;
g_ParamArray[0] = 1.5f;
g_ParamArray[1] = 2.5f;

// Apply parameter changes
model_update_parameters();

// Continue with model execution...


CONTINUOUS SIMULATION EXAMPLE:
=============================

model_initialize();

for (int step = 0; step < 1000; step++) {
    // Set time-varying inputs
    g_InScalar_dvPrivate_amMethod = sin(step * 0.1f);
    g_InArray_dvPrivate_amMethod[0] = cos(step * 0.1f);
    g_InArray_dvPrivate_amMethod[1] = step * 0.01f;
    
    // Execute step
    model_step();
    
    // Log or process outputs as needed
    if (step % 100 == 0) {
        printf("Step %d: Output = %f\n", step, g_OutScalar_dvPrivate_amMethod);
    }
}

model_terminate();

*/

#endif // MODEL_TEST_WRAPPER_H