//
// Example usage and test program for signal_dvPrivate_acMethod model
//
// This demonstrates how to use the model test wrapper to:
// - Initialize and test the Simulink-generated model
// - Set inputs, read outputs, and modify parameters
// - Run various test scenarios
//

#include "model_test_wrapper.h"
#include <iostream>
#include <cmath>
#include <iomanip>

void example_basic_usage()
{
    std::cout << "\n🔍 BASIC USAGE EXAMPLE" << std::endl;
    std::cout << std::string(50, '=') << std::endl;
    
    // Initialize the model
    if (!model_initialize()) {
        std::cerr << "Failed to initialize model!" << std::endl;
        return;
    }
    
    // Set input values
    g_InScalar_dvPrivate_amMethod = 1.5f;
    g_InArray_dvPrivate_amMethod[0] = 2.0f;
    g_InArray_dvPrivate_amMethod[1] = 3.0f;
    g_InBus_dvPrivate_amMethod.FlptSig1 = 4.0f;
    g_InBus_dvPrivate_amMethod.FlptSig2 = 5.0f;
    g_InBusElm_dvPrivate_amMethod_FxptSig1 = 100;
    g_InBusElm_dvPrivate_amMethod_FxptSig2 = 200;
    
    std::cout << "📥 Input values set" << std::endl;
    model_print_inputs();
    
    // Execute model step
    if (!model_step()) {
        std::cerr << "Model step failed!" << std::endl;
        model_terminate();
        return;
    }
    
    std::cout << "\n🔄 After first step:" << std::endl;
    model_print_outputs();
    model_print_states();
    
    // Execute another step to see unit delay effect
    if (!model_step()) {
        std::cerr << "Model step failed!" << std::endl;
        model_terminate();
        return;
    }
    
    std::cout << "\n🔄 After second step:" << std::endl;
    model_print_outputs();
    model_print_states();
    
    // Print complete status
    model_print_status();
    
    // Cleanup
    model_terminate();
    std::cout << "\n✅ Basic usage example completed" << std::endl;
}

void example_parameter_modification()
{
    std::cout << "\n⚙️ PARAMETER MODIFICATION EXAMPLE" << std::endl;
    std::cout << std::string(50, '=') << std::endl;
    
    if (!model_initialize()) {
        return;
    }
    
    // Show initial parameters
    std::cout << "📊 Initial parameters:" << std::endl;
    model_print_parameters();
    
    // Set test inputs
    g_InScalar_dvPrivate_amMethod = 1.0f;
    g_InArray_dvPrivate_amMethod[0] = 1.0f;
    g_InArray_dvPrivate_amMethod[1] = 1.0f;
    
    // Run one step with default parameters
    model_step();
    std::cout << "\n🔄 With default parameters (gain = 2.0):" << std::endl;
    model_print_outputs();
    
    // Modify parameters
    g_ParamScalar = 5.0f;
    g_ParamArray[0] = 3.0f;
    g_ParamArray[1] = 4.0f;
    
    if (!model_update_parameters()) {
        model_terminate();
        return;
    }
    
    std::cout << "\n📊 Modified parameters:" << std::endl;
    model_print_parameters();
    
    // Run step with new parameters
    model_step();
    std::cout << "\n🔄 With modified parameters:" << std::endl;
    model_print_outputs();
    
    model_terminate();
    std::cout << "\n✅ Parameter modification example completed" << std::endl;
}

void example_continuous_simulation()
{
    std::cout << "\n📈 CONTINUOUS SIMULATION EXAMPLE" << std::endl;
    std::cout << std::string(50, '=') << std::endl;
    
    if (!model_initialize()) {
        return;
    }
    
    std::cout << "Running 10 steps with sinusoidal inputs...\n" << std::endl;
    std::cout << std::setw(8) << "Step" 
              << std::setw(12) << "Input" 
              << std::setw(12) << "Output" 
              << std::setw(12) << "State" << std::endl;
    std::cout << std::string(44, '-') << std::endl;
    
    for (int step = 0; step < 10; step++) {
        // Set time-varying inputs
        float input_value = std::sin(step * 0.5f);
        g_InScalar_dvPrivate_amMethod = input_value;
        g_InArray_dvPrivate_amMethod[0] = input_value;
        g_InArray_dvPrivate_amMethod[1] = input_value * 0.5f;
        g_InBus_dvPrivate_amMethod.FlptSig1 = input_value * 2.0f;
        g_InBus_dvPrivate_amMethod.FlptSig2 = input_value * 3.0f;
        
        // Execute step
        if (!model_step()) {
            std::cerr << "Step failed at iteration " << step << std::endl;
            break;
        }
        
        // Print results
        std::cout << std::setw(8) << step 
                  << std::setw(12) << std::fixed << std::setprecision(3) << input_value
                  << std::setw(12) << g_OutScalar_dvPrivate_amMethod
                  << std::setw(12) << g_LocScalar_dvPrivate_amMethod << std::endl;
    }
    
    model_terminate();
    std::cout << "\n✅ Continuous simulation example completed" << std::endl;
}

void example_bus_signal_testing()
{
    std::cout << "\n🚌 BUS SIGNAL TESTING EXAMPLE" << std::endl;
    std::cout << std::string(50, '=') << std::endl;
    
    if (!model_initialize()) {
        return;
    }
    
    // Test bus signal pass-through
    g_InBus_dvPrivate_amMethod.FlptSig1 = 10.5f;
    g_InBus_dvPrivate_amMethod.FlptSig2 = 20.7f;
    
    std::cout << "📥 Input bus signals:" << std::endl;
    std::cout << "  FlptSig1: " << g_InBus_dvPrivate_amMethod.FlptSig1 << std::endl;
    std::cout << "  FlptSig2: " << g_InBus_dvPrivate_amMethod.FlptSig2 << std::endl;
    
    model_step();
    
    std::cout << "\n📤 Output bus signals (should be identical):" << std::endl;
    std::cout << "  FlptSig1: " << g_OutBus_dvPrivate_amMethod.FlptSig1 << std::endl;
    std::cout << "  FlptSig2: " << g_OutBus_dvPrivate_amMethod.FlptSig2 << std::endl;
    
    // Verify pass-through
    bool bus_passthrough_ok = (g_InBus_dvPrivate_amMethod.FlptSig1 == g_OutBus_dvPrivate_amMethod.FlptSig1) &&
                              (g_InBus_dvPrivate_amMethod.FlptSig2 == g_OutBus_dvPrivate_amMethod.FlptSig2);
    
    std::cout << "\n🔍 Bus pass-through verification: " 
              << (bus_passthrough_ok ? "✅ PASSED" : "❌ FAILED") << std::endl;
    
    model_terminate();
    std::cout << "\n✅ Bus signal testing completed" << std::endl;
}

int main()
{
    std::cout << "\n🚀 SIGNAL MODEL TEST SUITE" << std::endl;
    std::cout << "Model: signal_dvPrivate_acMethod v1.20" << std::endl;
    std::cout << "Target: Intel x86-64 (Windows64)" << std::endl;
    std::cout << std::string(60, '=') << std::endl;
    
    try {
        // Run built-in step response test
        if (!model_test_step_response()) {
            std::cerr << "Built-in step response test failed!" << std::endl;
            return -1;
        }
        
        // Run custom examples
        example_basic_usage();
        example_parameter_modification();
        example_continuous_simulation();
        example_bus_signal_testing();
        
        std::cout << "\n🎉 ALL TESTS COMPLETED SUCCESSFULLY!" << std::endl;
        std::cout << std::string(60, '=') << std::endl;
        
        return 0;
        
    } catch (const std::exception& e) {
        std::cerr << "\n❌ Exception caught: " << e.what() << std::endl;
        return -1;
    }
}