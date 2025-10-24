//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: ert_main.cpp
//
// Code generated for Simulink model 'oClientServer_Model'.
//
// Model version                  : 1.13
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Sun Sep 28 22:06:31 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#include <stdio.h>
#include "oClientServer_Model.h"       // Model header file

class oClientServer_ModelClientServiceT : public ClientServiceInterfaceT{
 public:
  void add( real_T arg0, real_T arg1, real_T* arg2) override {
    // Add logic here
  } };

static oClientServer_ModelClientServiceT ClientService_arg;
static ComponentNamespace::oClientServer_Model oClientServer_Model_Obj{
  ClientService_arg };                 // Instance of model class

// Example use case for call to exported function: oClientServer_Model_Obj.step
extern void sample_usage_step(void);
void sample_usage_step(void)
{
  // Set task inputs here

  // Call to exported function
  oClientServer_Model_Obj.step();

  // Read function outputs here
}

//
// The example main function illustrates what is required by your
// application code to initialize, execute, and terminate the generated code.
// Attaching exported functions to a real-time clock is target specific.
//
int_T main(int_T argc, const char *argv[])
{
  // Unused arguments
  (void)(argc);
  (void)(argv);

  // Initialize model
  oClientServer_Model_Obj.initialize();
  while (oClientServer_Model_Obj.getRTM()->getErrorStatus() == (nullptr)) {
    //  Perform application tasks here.
  }

  // Terminate model
  oClientServer_Model_Obj.terminate();
  return 0;
}

//
// File trailer for generated code.
//
// [EOF]
//
