//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: Wrapper_ClientServer_Model.cpp
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
#include "Wrapper_ClientServer_Model.h"
#include "Wrapper_ClientServer_Model_private.h"
#include "sut_step.h"
#include <stdint.h>
#include "W_server_mock_ClientServer_Model.h"
#include "call_ServerService_getDataC.h"
#include "call_ServerService_setDataB.h"
#include "call_ServerService_setDataA.h"

// user code (top of source file)
#include "oClientServer_Model.h"

extern void sut_initialize(void);

// Exported block states
double ServerService_setDataA_DataA_In;// Simulink.Signal object 'c_01EAF'
double ServerService_getDataC_DataC_Out;// Simulink.Signal object 'c_47DC4'
double ServerService_setDataB_DataB_In;// Simulink.Signal object 'c_D691D'
double ClientService_add_DataA_In;     // Simulink.Signal object 's_CC278'
double ClientService_add_DataB_In;     // Simulink.Signal object 's_D6868'
double ClientService_add_DataD_Out;    // Simulink.Signal object 's_DAA18'

// Block states (default storage)
w_DW_Wrapper_ClientServer_Model_T w_Wrapper_ClientServer_Model_DW;

// Real-time model
w_RT_MODEL_Wrapper_ClientServer_Model_T w_Wrapper_ClientServer_Model_M_{ };

w_RT_MODEL_Wrapper_ClientServer_Model_T *const w_Wrapper_ClientServer_Model_M{ &
  w_Wrapper_ClientServer_Model_M_ };

// Output and update for function-call system: '<S10>/sut_step_sub'
void Wrapper_ClientServer_Model_sut_step_sub(void)
{
  // FunctionCaller: '<S14>/sut_step_sub'
  sut_step();
}

// Output and update for function-call system: '<S10>/call_ServerService_getDataC_sub'
void Wrapper_ClientServer_Model_call_ServerService_getDataC_sub(void)
{
  // FunctionCaller: '<S11>/call_ServerService_getDataC_sub'
  call_ServerService_getDataC();
}

// Output and update for function-call system: '<S10>/call_ServerService_setDataB_sub'
void Wrapper_ClientServer_Model_call_ServerService_setDataB_sub(void)
{
  // FunctionCaller: '<S13>/call_ServerService_setDataB_sub'
  call_ServerService_setDataB();
}

// Output and update for function-call system: '<S10>/call_ServerService_setDataA_sub'
void Wrapper_ClientServer_Model_call_ServerService_setDataA_sub(void)
{
  // FunctionCaller: '<S12>/call_ServerService_setDataA_sub'
  call_ServerService_setDataA();
}

// Model step function
void Wrapper_ClientServer_Model_step(void)
{
  // Chart: '<S2>/SF_Scheduler'
  if (w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 < 1) {
    w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 = static_cast<uint8_t>
      (w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 + 1);
  }

  if (w_Wrapper_ClientServer_Model_DW.is_active_c3_Wrapper_ClientServer_Model ==
      0) {
    w_Wrapper_ClientServer_Model_DW.is_active_c3_Wrapper_ClientServer_Model = 1U;

    // Update the Order/Rate/Asynchronous calls of the runnables
    w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 = 0U;

    // Outputs for Function Call SubSystem: '<S10>/call_ServerService_setDataB_sub' 
    Wrapper_ClientServer_Model_call_ServerService_setDataB_sub();

    // End of Outputs for SubSystem: '<S10>/call_ServerService_setDataB_sub'

    // Outputs for Function Call SubSystem: '<S10>/call_ServerService_setDataA_sub' 
    Wrapper_ClientServer_Model_call_ServerService_setDataA_sub();

    // End of Outputs for SubSystem: '<S10>/call_ServerService_setDataA_sub'

    // Outputs for Function Call SubSystem: '<S10>/sut_step_sub'
    Wrapper_ClientServer_Model_sut_step_sub();

    // End of Outputs for SubSystem: '<S10>/sut_step_sub'

    // Outputs for Function Call SubSystem: '<S10>/call_ServerService_getDataC_sub' 
    Wrapper_ClientServer_Model_call_ServerService_getDataC_sub();

    // End of Outputs for SubSystem: '<S10>/call_ServerService_getDataC_sub'
  } else if (w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 == 1) {
    // Outputs for Function Call SubSystem: '<S10>/call_ServerService_setDataB_sub' 
    Wrapper_ClientServer_Model_call_ServerService_setDataB_sub();

    // End of Outputs for SubSystem: '<S10>/call_ServerService_setDataB_sub'

    // Outputs for Function Call SubSystem: '<S10>/call_ServerService_setDataA_sub' 
    Wrapper_ClientServer_Model_call_ServerService_setDataA_sub();

    // End of Outputs for SubSystem: '<S10>/call_ServerService_setDataA_sub'

    // Outputs for Function Call SubSystem: '<S10>/sut_step_sub'
    Wrapper_ClientServer_Model_sut_step_sub();

    // End of Outputs for SubSystem: '<S10>/sut_step_sub'

    // Outputs for Function Call SubSystem: '<S10>/call_ServerService_getDataC_sub' 
    Wrapper_ClientServer_Model_call_ServerService_getDataC_sub();

    // End of Outputs for SubSystem: '<S10>/call_ServerService_getDataC_sub'
  }

  if (w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 == 1) {
    w_Wrapper_ClientServer_Model_DW.temporalCounter_i1 = 0U;
  }

  // End of Chart: '<S2>/SF_Scheduler'
}

// Model initialize function
void Wrapper_ClientServer_Model_initialize(void)
{
  // Model Initialize function for ModelReference Block: '<Root>/W_server_mock_ClientServer_Model' 
  W_server_mock_ClientServer_Model_initialize
    (w_Wrapper_ClientServer_Model_M->getErrorStatusPointer());

  // user code (Initialize function Body)
  sut_initialize();
}

// Model terminate function
void Wrapper_ClientServer_Model_terminate(void)
{
  // (no terminate code required)
}

const char* w_RT_MODEL_Wrapper_ClientServer_Model_T::getErrorStatus() const
{
  return (errorStatus);
}

void w_RT_MODEL_Wrapper_ClientServer_Model_T::setErrorStatus(const char* const
  aErrorStatus)
{
  (errorStatus = aErrorStatus);
}

const char** w_RT_MODEL_Wrapper_ClientServer_Model_T::getErrorStatusPointer()
{
  return &errorStatus;
}

//
// File trailer for generated code.
//
// [EOF]
//
