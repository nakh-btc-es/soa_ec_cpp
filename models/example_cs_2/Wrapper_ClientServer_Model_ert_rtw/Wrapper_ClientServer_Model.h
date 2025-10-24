//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: Wrapper_ClientServer_Model.h
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
#ifndef Wrapper_ClientServer_Model_h_
#define Wrapper_ClientServer_Model_h_
#include <stdbool.h>
#include <stdint.h>
#include <cmath>
#include "complex_types.h"
#include "Wrapper_ClientServer_Model_types.h"
#include "sut_ServerService_setDataA.h"
#include "call_ServerService_setDataB.h"
#include "sut_ServerService_getDataC.h"
#include "sut_step.h"
#include "call_ServerService_setDataA.h"
#include "call_ServerService_getDataC.h"
#include "sut_ServerService_setDataB.h"

// Block states (default storage) for system '<Root>'
struct w_DW_Wrapper_ClientServer_Model_T {
  uint8_t is_active_c3_Wrapper_ClientServer_Model;// '<S2>/SF_Scheduler'
  uint8_t temporalCounter_i1;          // '<S2>/SF_Scheduler'
};

// Real-time Model Data Structure
struct w_tag_RTM_Wrapper_ClientServer_Model_T {
  const char *errorStatus;
  const char* getErrorStatus() const;
  void setErrorStatus(const char* const aErrorStatus);
  const char** getErrorStatusPointer();
};

// Block states (default storage)
extern struct w_DW_Wrapper_ClientServer_Model_T w_Wrapper_ClientServer_Model_DW;

//
//  Exported States
//
//  Note: Exported states are block states with an exported global
//  storage class designation.  Code generation will declare the memory for these
//  states and exports their symbols.
//

extern double ServerService_setDataA_DataA_In;// Simulink.Signal object 'c_01EAF' 
extern double ServerService_getDataC_DataC_Out;// Simulink.Signal object 'c_47DC4' 
extern double ServerService_setDataB_DataB_In;// Simulink.Signal object 'c_D691D' 
extern double ClientService_add_DataA_In;// Simulink.Signal object 's_CC278'
extern double ClientService_add_DataB_In;// Simulink.Signal object 's_D6868'
extern double ClientService_add_DataD_Out;// Simulink.Signal object 's_DAA18'

#ifdef __cplusplus

extern "C"
{

#endif

  // Model entry point functions
  extern void Wrapper_ClientServer_Model_initialize(void);
  extern void Wrapper_ClientServer_Model_step(void);
  extern void Wrapper_ClientServer_Model_terminate(void);

#ifdef __cplusplus

}

#endif

// Real-time Model object
#ifdef __cplusplus

extern "C"
{

#endif

  extern w_RT_MODEL_Wrapper_ClientServer_Model_T *const
    w_Wrapper_ClientServer_Model_M;

#ifdef __cplusplus

}

#endif

//-
//  These blocks were eliminated from the model due to optimizations:
//
//  Block '<S7>/Constant' : Unused code path elimination
//  Block '<S7>/Switch' : Unused code path elimination
//  Block '<S8>/Constant' : Unused code path elimination
//  Block '<S8>/Switch' : Unused code path elimination


//-
//  The generated code includes comments that allow you to trace directly
//  back to the appropriate location in the model.  The basic format
//  is <system>/block_name, where system is the system number (uniquely
//  assigned by Simulink) and block_name is the name of the block.
//
//  Use the MATLAB hilite_system command to trace the generated code back
//  to the model.  For example,
//
//  hilite_system('<S3>')    - opens system 3
//  hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
//
//  Here is the system hierarchy for this model
//
//  '<Root>' : 'Wrapper_ClientServer_Model'
//  '<S1>'   : 'Wrapper_ClientServer_Model/Client Function Mocks'
//  '<S2>'   : 'Wrapper_ClientServer_Model/Scheduler'
//  '<S3>'   : 'Wrapper_ClientServer_Model/W_integ_ClientServer_Model'
//  '<S4>'   : 'Wrapper_ClientServer_Model/Client Function Mocks/call_ServerService_getDataC'
//  '<S5>'   : 'Wrapper_ClientServer_Model/Client Function Mocks/call_ServerService_setDataA'
//  '<S6>'   : 'Wrapper_ClientServer_Model/Client Function Mocks/call_ServerService_setDataB'
//  '<S7>'   : 'Wrapper_ClientServer_Model/Client Function Mocks/call_ServerService_setDataA/BTC Workaround'
//  '<S8>'   : 'Wrapper_ClientServer_Model/Client Function Mocks/call_ServerService_setDataB/BTC Workaround'
//  '<S9>'   : 'Wrapper_ClientServer_Model/Scheduler/SF_Scheduler'
//  '<S10>'  : 'Wrapper_ClientServer_Model/W_integ_ClientServer_Model/dummy_W_integ_ClientServer_Model'
//  '<S11>'  : 'Wrapper_ClientServer_Model/W_integ_ClientServer_Model/dummy_W_integ_ClientServer_Model/call_ServerService_getDataC_sub'
//  '<S12>'  : 'Wrapper_ClientServer_Model/W_integ_ClientServer_Model/dummy_W_integ_ClientServer_Model/call_ServerService_setDataA_sub'
//  '<S13>'  : 'Wrapper_ClientServer_Model/W_integ_ClientServer_Model/dummy_W_integ_ClientServer_Model/call_ServerService_setDataB_sub'
//  '<S14>'  : 'Wrapper_ClientServer_Model/W_integ_ClientServer_Model/dummy_W_integ_ClientServer_Model/sut_step_sub'

#endif                                 // Wrapper_ClientServer_Model_h_

//
// File trailer for generated code.
//
// [EOF]
//
