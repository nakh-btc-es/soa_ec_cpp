//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: ert_main.cpp
//
// Code generated for Simulink model 'SOA_demo_codegen'.
//
// Model version                  : 1.3
// Simulink Coder version         : 9.8 (R2022b) 13-May-2022
// C/C++ source code generated on : Mon Oct 13 13:41:43 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#include <stdio.h>
#include "SOA_demo_codegen.h"          // Model header file

static SOA_demo_codegen SOA_demo_codegen_Obj;// Instance of model class

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
  SOA_demo_codegen_Obj.initialize();
  while (rtmGetErrorStatus(SOA_demo_codegen_Obj.getRTM()) == (nullptr)) {
    //  Perform application tasks here.
  }

  // Terminate model
  SOA_demo_codegen_Obj.terminate();
  return 0;
}

//
// File trailer for generated code.
//
// [EOF]
//
