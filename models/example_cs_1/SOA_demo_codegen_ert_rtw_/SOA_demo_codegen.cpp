//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: SOA_demo_codegen.cpp
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
#include "SOA_demo_codegen.h"
#include "rtwtypes.h"

// Model step function
void SOA_demo_codegen::f(real_T rtu_u, real_T *rty_y)
{
  // Outputs for Function Call SubSystem: '<Root>/Simulink Function'
  // SignalConversion generated from: '<S1>/y' incorporates:
  //   SignalConversion generated from: '<S1>/u'

  *rty_y = rtu_u;

  // End of Outputs for SubSystem: '<Root>/Simulink Function'
}

// Model initialize function
void SOA_demo_codegen::initialize()
{
  // (no initialization code required)
}

// Model terminate function
void SOA_demo_codegen::terminate()
{
  // (no terminate code required)
}

// Constructor
SOA_demo_codegen::SOA_demo_codegen() :
  a(*this),
  SOA_demo_codegen_M()
{
  // Currently there is no constructor body generated.
}

// Destructor
SOA_demo_codegen::~SOA_demo_codegen()
{
  // Currently there is no destructor body generated.
}

// Real-Time Model get method
SOA_demo_codegen::RT_MODEL_SOA_demo_codegen_T * SOA_demo_codegen::getRTM()
{
  return (&SOA_demo_codegen_M);
}

aT & SOA_demo_codegen::get_a()
{
  return a;
}

SOA_demo_codegenaT::SOA_demo_codegenaT(SOA_demo_codegen &aProvider):
  SOA_demo_codegen_mProvider{ aProvider }
{
}

void SOA_demo_codegenaT::f(real_T u, real_T *y)
{
  SOA_demo_codegen_mProvider.f(u, y);
}

//
// File trailer for generated code.
//
// [EOF]
//
