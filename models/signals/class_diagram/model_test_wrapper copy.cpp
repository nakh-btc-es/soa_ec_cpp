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
#include <iostream>
#include <iomanip>

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
bool model_initialize()
{
    try {
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
        
        std::cout << "✅ Model initialized successfully" << std::endl;
        return true;
    }
    catch (const std::exception& e) {
        std::cerr << "❌ Model initialization failed: " << e.what() << std::endl;
        return false;
    }
}

/**
 * @brief Terminate the model and cleanup resources
 */
void model_terminate()
{
    if (g_model != nullptr) {
        delete g_model;
        g_model = nullptr;
        std::cout << "🔄 Model terminated and cleaned up" << std::endl;
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
bool model_step()
{
    if (g_model == nullptr) {
        std::cerr << "❌ Model not initialized. Call model_initialize() first." << std::endl;
        return false;
    }
    
    try {
        // Transfer inputs from global variables to model
        transfer_inputs_to_model();
        
        // Execute model step
        g_model->step();
        
        // Transfer outputs from model to global variables
        transfer_outputs_from_model();
        
        // Update state variables for monitoring
        update_state_variables();
        
        return true;
    }
    catch (const std::exception& e) {
        std::cerr << "❌ Model step failed: " << e.what() << std::endl;
        return false;
    }
}

//=============================================================================
// PARAMETER UPDATE FUNCTIONS
//=============================================================================

/**
 * @brief Update model parameters from global parameter variables
 * @return true if parameters updated successfully, false otherwise
 */
bool model_update_parameters()
{
    if (g_model == nullptr) {
        std::cerr << "❌ Model not initialized." << std::endl;
        return false;
    }
    
    try {
        btc_soa::signal_dvPrivate_acMethod::P params = g_model->getBlockParameters();
        params.ParamScalar = g_ParamScalar;
        params.ParamArray[0] = g_ParamArray[0];
        params.ParamArray[1] = g_ParamArray[1];
        g_model->setBlockParameters(&params);
        
        std::cout << "✅ Parameters updated: ParamScalar=" << g_ParamScalar 
                  << ", ParamArray=[" << g_ParamArray[0] << ", " << g_ParamArray[1] << "]" << std::endl;
        return true;
    }
    catch (const std::exception& e) {
        std::cerr << "❌ Parameter update failed: " << e.what() << std::endl;
        return false;
    }
}

//=============================================================================
// UTILITY AND DEBUG FUNCTIONS  
//=============================================================================

/**
 * @brief Print current input values
 */
void model_print_inputs()
{
    std::cout << "\n📥 INPUT VALUES:" << std::endl;
    std::cout << "  Scalar Input: " << g_InScalar_dvPrivate_amMethod << std::endl;
    std::cout << "  Array Input:  [" << g_InArray_dvPrivate_amMethod[0] 
              << ", " << g_InArray_dvPrivate_amMethod[1] << "]" << std::endl;
    std::cout << "  Bus Input:    {FlptSig1: " << g_InBus_dvPrivate_amMethod.FlptSig1 
              << ", FlptSig2: " << g_InBus_dvPrivate_amMethod.FlptSig2 << "}" << std::endl;
    std::cout << "  FxP Inputs:   [" << g_InBusElm_dvPrivate_amMethod_FxptSig1 
              << ", " << g_InBusElm_dvPrivate_amMethod_FxptSig2 
              << ", " << g_InBusElm_dvPrivate_amMethod1_FxptSig1 
              << ", " << g_InBusElm_dvPrivate_amMethod1_FxptSig2 << "]" << std::endl;
}

/**
 * @brief Print current output values
 */
void model_print_outputs()
{
    std::cout << "\n📤 OUTPUT VALUES:" << std::endl;
    std::cout << "  Scalar Output: " << g_OutScalar_dvPrivate_amMethod << std::endl;
    std::cout << "  Array Output:  [" << g_OutArray_dvPrivate_amMethod[0] 
              << ", " << g_OutArray_dvPrivate_amMethod[1] << "]" << std::endl;
    std::cout << "  Bus Output:    {FlptSig1: " << g_OutBus_dvPrivate_amMethod.FlptSig1 
              << ", FlptSig2: " << g_OutBus_dvPrivate_amMethod.FlptSig2 << "}" << std::endl;
    std::cout << "  FxP Outputs:   [" << g_OutBusElm_dvPrivate_amMethod_FxptSig1 
              << ", " << g_OutBusElm_dvPrivate_amMethod_FxptSig2 
              << ", " << g_OutBusElm_dvPrivate_amMethod1_FxptSig1 
              << ", " << g_OutBusElm_dvPrivate_amMethod1_FxptSig2 << "]" << std::endl;
}

/**
 * @brief Print current state variables
 */
void model_print_states()
{
    std::cout << "\n🔄 STATE VALUES:" << std::endl;
    std::cout << "  Array State:  [" << g_LocArray_dvPrivate_amMethod[0] 
              << ", " << g_LocArray_dvPrivate_amMethod[1] << "]" << std::endl;
    std::cout << "  Scalar State: " << g_LocScalar_dvPrivate_amMethod << std::endl;
}

/**
 * @brief Print current parameter values
 */
void model_print_parameters()
{
    std::cout << "\n⚙️ PARAMETER VALUES:" << std::endl;
    std::cout << "  ParamScalar: " << g_ParamScalar << std::endl;
    std::cout << "  ParamArray:  [" << g_ParamArray[0] << ", " << g_ParamArray[1] << "]" << std::endl;
}

/**
 * @brief Print complete model status
 */
void model_print_status()
{
    std::cout << "\n" << std::string(60, '=') << std::endl;
    std::cout << "🔍 MODEL STATUS - signal_dvPrivate_acMethod v1.20" << std::endl;
    std::cout << std::string(60, '=') << std::endl;
    
    if (g_model == nullptr) {
        std::cout << "❌ Model Status: NOT INITIALIZED" << std::endl;
        return;
    }
    
    std::cout << "✅ Model Status: READY" << std::endl;
    
    model_print_parameters();
    model_print_inputs();
    model_print_outputs();
    model_print_states();
    
    std::cout << std::string(60, '=') << std::endl;
}

//=============================================================================
// EXAMPLE TEST SCENARIOS
//=============================================================================

/**
 * @brief Run a simple test scenario with step inputs
 * @return true if test completed successfully
 */
bool model_test_step_response()
{
    std::cout << "\n🧪 RUNNING STEP RESPONSE TEST" << std::endl;
    std::cout << std::string(40, '-') << std::endl;
    
    if (!model_initialize()) {
        return false;
    }
    
    // Set step inputs
    g_InScalar_dvPrivate_amMethod = 1.0f;
    g_InArray_dvPrivate_amMethod[0] = 1.0f;
    g_InArray_dvPrivate_amMethod[1] = 2.0f;
    g_InBus_dvPrivate_amMethod.FlptSig1 = 3.0f;
    g_InBus_dvPrivate_amMethod.FlptSig2 = 4.0f;
    
    // Run several steps to see unit delay behavior
    for (int step = 0; step < 5; step++) {
        std::cout << "\n--- Step " << step << " ---" << std::endl;
        
        if (!model_step()) {
            model_terminate();
            return false;
        }
        
        std::cout << "In: [" << g_InScalar_dvPrivate_amMethod << ", " 
                  << g_InArray_dvPrivate_amMethod[0] << ", " << g_InArray_dvPrivate_amMethod[1] << "]";
        std::cout << " -> Out: [" << g_OutScalar_dvPrivate_amMethod << ", " 
                  << g_OutArray_dvPrivate_amMethod[0] << ", " << g_OutArray_dvPrivate_amMethod[1] << "]";
        std::cout << " | States: [" << g_LocScalar_dvPrivate_amMethod << ", " 
                  << g_LocArray_dvPrivate_amMethod[0] << ", " << g_LocArray_dvPrivate_amMethod[1] << "]" << std::endl;
    }
    
    model_terminate();
    std::cout << "\n✅ Step response test completed" << std::endl;
    return true;
}

//=============================================================================
// C INTERFACE (for external integration)
//=============================================================================

extern "C" {
    // C interface functions for external systems
    bool c_model_initialize() { return model_initialize(); }
    void c_model_terminate() { model_terminate(); }
    bool c_model_step() { return model_step(); }
    bool c_model_update_parameters() { return model_update_parameters(); }
    void c_model_print_status() { model_print_status(); }
}