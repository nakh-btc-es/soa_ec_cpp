//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: SOA_demo_codegen.h
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
#ifndef RTW_HEADER_SOA_demo_codegen_h_
#define RTW_HEADER_SOA_demo_codegen_h_
#include "rtwtypes.h"
#include "SOA_demo_codegen_types.h"
#include "aT.h"

// Macros for accessing real-time model data structure
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

// Class declaration for model SOA_demo_codegen
// Forward declaration
class SOA_demo_codegen;


class SOA_demo_codegenaT : public aT
{
  // public data and function members
 public:
  SOA_demo_codegenaT(SOA_demo_codegen &aProvider);
  virtual void f(real_T u, real_T *y);

  // private data and function members
 private:
  SOA_demo_codegen &SOA_demo_codegen_mProvider;
};

class SOA_demo_codegen final
{
 public:
  // Real-time Model Data Structure
  struct RT_MODEL_SOA_demo_codegen_T {
    const char_T * volatile errorStatus;
  };

  // Copy Constructor
  SOA_demo_codegen(SOA_demo_codegen const&) = delete;

  // Assignment Operator
  SOA_demo_codegen& operator= (SOA_demo_codegen const&) & = delete;

  // Move Constructor
  SOA_demo_codegen(SOA_demo_codegen &&) = delete;

  // Move Assignment Operator
  SOA_demo_codegen& operator= (SOA_demo_codegen &&) = delete;

  // Real-Time Model get method
  SOA_demo_codegen::RT_MODEL_SOA_demo_codegen_T * getRTM();

  // model initialize function
  static void initialize();

  // model service function
  void f(real_T rtu_u, real_T *rty_y);

  // model terminate function
  static void terminate();

  // Constructor
  SOA_demo_codegen();

  // Destructor
  ~SOA_demo_codegen();

  // Service port get method
  aT & get_a();
 private:
  SOA_demo_codegenaT a;

  // Real-Time Model
  RT_MODEL_SOA_demo_codegen_T SOA_demo_codegen_M;
};

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
//  '<Root>' : 'SOA_demo_codegen'
//  '<S1>'   : 'SOA_demo_codegen/Simulink Function'

#endif                                 // RTW_HEADER_SOA_demo_codegen_h_

//
// File trailer for generated code.
//
// [EOF]
//
