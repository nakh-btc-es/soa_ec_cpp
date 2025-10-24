//
// Test wrapper for signal_dvPrivate_acMethod Simulink model
// 
// This file provides a C interface with global variables for testing
// and integration with external systems or test frameworks.
//
// Generated for model: signal_dvPrivate_acMethod v1.20
// Target: Intel->x86-64 (Windows64)
//

#include "signal_dvPrivate_acMethod.h"

// Global model instance
static btc_soa::signal_dvPrivate_acMethod* g_model = nullptr;

//=============================================================================
// GLOBAL INPUT VARIABLES
//=============================================================================

// Scalar input
float g_InScalar_dvPrivate_amMethod = 0.0f;

// Array input (2 elements)
float g_InArray_dvPrivate_amMethod[2] = {0.0f, 0.0f};

// Bus input
myBus g_InBus_dvPrivate_amMethod = {0.0f, 0.0f};

// Fixed-point bus element inputs
int16_t g_InBusElm_dvPrivate_amMethod_FxptSig1 = 0;
int16_t g_InBusElm_dvPrivate_amMethod_FxptSig2 = 0;
int16_t g_InBusElm_dvPrivate_amMethod1_FxptSig1 = 0;
int16_t g_InBusElm_dvPrivate_amMethod1_FxptSig2 = 0;

//=============================================================================
// GLOBAL OUTPUT VARIABLES
//=============================================================================

// Scalar output
float g_OutScalar_dvPrivate_amMethod = 0.0f;

// Array output (2 elements)
float g_OutArray_dvPrivate_amMethod[2] = {0.0f, 0.0f};

// Bus output
myBus g_OutBus_dvPrivate_amMethod = {0.0f, 0.0f};

// Fixed-point bus element outputs
int16_t g_OutBusElm_dvPrivate_amMethod_FxptSig1 = 0;
int16_t g_OutBusElm_dvPrivate_amMethod_FxptSig2 = 0;
int16_t g_OutBusElm_dvPrivate_amMethod1_FxptSig1 = 0;
int16_t g_OutBusElm_dvPrivate_amMethod1_FxptSig2 = 0;

//=============================================================================
// GLOBAL PARAMETER VARIABLES
//=============================================================================

// Model parameters (can be modified to change model behavior)
float g_ParamScalar = 2.0f;        // Default gain for scalar processing
float g_ParamArray[2] = {2.0f, 2.0f}; // Default gains for array processing

//=============================================================================
// GLOBAL STATE VARIABLES (read-only access to internal states)
//=============================================================================

// Unit delay states (read-only for monitoring)
float g_LocArray_dvPrivate_amMethod[2] = {0.0f, 0.0f};
float g_LocScalar_dvPrivate_amMethod = 0.0f;

//=============================================================================
// MODEL LIFECYCLE FUNCTIONS
//=============================================================================

/**
 * @brief Initialize the model instance and set default parameters
 * @return true if initialization successful, false otherwise
 */
void model_initialize()
{

    // Create model instance
    if (g_model == nullptr) {
        g_model = new btc_soa::signal_dvPrivate_acMethod();
    }
    
    // Initialize the model with default states
    g_model->initialize();
    
    // Set initial parameters
    btc_soa::signal_dvPrivate_acMethod::P params = g_model->getBlockParameters();
    params.ParamScalar = g_ParamScalar;
    params.ParamArray[0] = g_ParamArray[0];
    params.ParamArray[1] = g_ParamArray[1];
    g_model->setBlockParameters(&params);
    
}

/**
 * @brief Terminate the model and cleanup resources
 */
void model_terminate()
{
    if (g_model != nullptr) {
        delete g_model;
        g_model = nullptr;
    }
}

//=============================================================================
// INPUT/OUTPUT TRANSFER FUNCTIONS
//=============================================================================

/**
 * @brief Transfer global input variables to model inputs
 */
static void transfer_inputs_to_model()
{
    if (g_model == nullptr) return;
    
    // Set scalar input
    g_model->setInScalar_dvPrivate_amMethod(g_InScalar_dvPrivate_amMethod);
    
    // Set array input
    g_model->setInArray_dvPrivate_amMethod(g_InArray_dvPrivate_amMethod);
    
    // Set bus input
    g_model->setInBus_dvPrivate_amMethod(g_InBus_dvPrivate_amMethod);
    
    // Set fixed-point bus element inputs
    g_model->setInBusElm_dvPrivate_amMethod_FxptSig1(g_InBusElm_dvPrivate_amMethod_FxptSig1);
    g_model->setInBusElm_dvPrivate_amMethod1_FxptSig2(g_InBusElm_dvPrivate_amMethod1_FxptSig2);
}

/**
 * @brief Transfer model outputs to global output variables
 */
static void transfer_outputs_from_model()
{
    if (g_model == nullptr) return;
    
    // Get scalar output
    g_OutScalar_dvPrivate_amMethod = g_model->getOutScalar_dvPrivate_amMethod();
    
    // Get array output
    const float* array_out = g_model->getOutArray_dvPrivate_amMethod();
    g_OutArray_dvPrivate_amMethod[0] = array_out[0];
    g_OutArray_dvPrivate_amMethod[1] = array_out[1];
    
    // Get bus output
    g_OutBus_dvPrivate_amMethod = g_model->getOutBus_dvPrivate_amMethod();
    
    // Get fixed-point bus element outputs
    g_OutBusElm_dvPrivate_amMethod_FxptSig1 = g_model->getOutBusElm_dvPrivate_amMethod_FxptSig1();
    g_OutBusElm_dvPrivate_amMethod1_FxptSig2 = g_model->getOutBusElm_dvPrivate_amMethod1_FxptSig2();
}

/**
 * @brief Update global state variables from model (for monitoring)
 */
static void update_state_variables()
{
    if (g_model == nullptr) return;
    
    const btc_soa::signal_dvPrivate_acMethod::DW& states = g_model->getDWork();
    
    // Copy state variables for external monitoring
    g_LocArray_dvPrivate_amMethod[0] = states.LocArray_dvPrivate_amMethod[0];
    g_LocArray_dvPrivate_amMethod[1] = states.LocArray_dvPrivate_amMethod[1];
    g_LocScalar_dvPrivate_amMethod = states.LocScalar_dvPrivate_amMethod;
}

//=============================================================================
// PARAMETER UPDATE FUNCTIONS
//=============================================================================

/**
 * @brief Update model parameters from global parameter variables
 * @return true if parameters updated successfully, false otherwise
 */
void update_parameters()
{

    btc_soa::signal_dvPrivate_acMethod::P params = g_model->getBlockParameters();
    params.ParamScalar = g_ParamScalar;
    params.ParamArray[0] = g_ParamArray[0];
    params.ParamArray[1] = g_ParamArray[1];
    g_model->setBlockParameters(&params);
    
}

//=============================================================================
// MAIN MODEL STEP FUNCTION
//=============================================================================

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
void model_step()
{

    // Transfer inputs from global variables to model
    transfer_inputs_to_model();
    
    //Update parameters before step
    update_parameters();

    // Execute model step
    g_model->step();
    
    // Transfer outputs from model to global variables
    transfer_outputs_from_model();
    
    // Update state variables for monitoring
    update_state_variables();

}


//=============================================================================
// C INTERFACE (for external integration)
//=============================================================================

extern "C" {
    // C interface functions for external systems
    bool c_model_initialize() {  model_initialize(); }
    void c_model_terminate() { model_terminate(); }
    bool c_model_step() {  model_step(); }
}