//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: call_ServerService_setDataA.cpp
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
#include "call_ServerService_setDataA.h"
#include "sut_ServerService_setDataA.h"
#include "call_ServerService_setDataA_private.h"
#include "Wrapper_ClientServer_Model.h"

// Output and update for Simulink Function: '<S1>/call_ServerService_setDataA'
void call_ServerService_setDataA(void)
{
  // FunctionCaller: '<S5>/setDataA' incorporates:
  //   DataStoreRead: '<S5>/ServerService_setDataA_DataA_In'

  sut_ServerService_setDataA(ServerService_setDataA_DataA_In);
}

//
// File trailer for generated code.
//
// [EOF]
//
