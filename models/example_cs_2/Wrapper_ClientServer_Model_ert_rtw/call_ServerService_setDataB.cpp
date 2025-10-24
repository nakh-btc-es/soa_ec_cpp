//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: call_ServerService_setDataB.cpp
//
// Code generated for Simulink model 'Wrapper_ClientServer_Model'.
//
// Model version                  : 1.2
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Wed Sep 24 20:23:47 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#include "call_ServerService_setDataB.h"
#include "sut_ServerService_setDataB.h"
#include "call_ServerService_setDataB_private.h"
#include "Wrapper_ClientServer_Model.h"

// Output and update for Simulink Function: '<S1>/call_ServerService_setDataB'
void call_ServerService_setDataB(void)
{
  // FunctionCaller: '<S6>/setDataB' incorporates:
  //   DataStoreRead: '<S6>/ServerService_setDataB_DataB_In'

  sut_ServerService_setDataB(ServerService_setDataB_DataB_In);
}

//
// File trailer for generated code.
//
// [EOF]
//
