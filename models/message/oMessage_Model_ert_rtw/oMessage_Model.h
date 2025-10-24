//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: oMessage_Model.h
//
// Code generated for Simulink model 'oMessage_Model'.
//
// Model version                  : 1.4
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Mon Sep 29 10:47:40 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#ifndef oMessage_Model_h_
#define oMessage_Model_h_
#include "rtwtypes.h"
#include <stddef.h>
#include "oMessage_Model_types.h"

// Class declaration for model oMessage_Model
namespace ComponentNamespace
{
  class oMessage_Model final
  {
    // public data and function members
   public:
    // Block signals (default storage)
    struct B_oMessage_Model_T {
      InputDataInterface Receive;      // '<Root>/Receive'
      OutputDataInterface BusCreator;  // '<Root>/Bus Creator'
    };

    // Real-time Model Data Structure
    struct RT_MODEL_oMessage_Model_T {
      const char_T * volatile errorStatus;
      const char_T* getErrorStatus() const;
      void setErrorStatus(const char_T* const volatile aErrorStatus);
    };

    // Copy Constructor
    oMessage_Model(oMessage_Model const&) = delete;

    // Assignment Operator
    oMessage_Model& operator= (oMessage_Model const&) & = delete;

    // Move Constructor
    oMessage_Model(oMessage_Model &&) = delete;

    // Move Assignment Operator
    oMessage_Model& operator= (oMessage_Model &&) = delete;

    // Real-Time Model get method
    oMessage_Model::RT_MODEL_oMessage_Model_T * getRTM();

    // Constructor
    oMessage_Model(RecvData_InputDataInterfaceT &InputDataRecvData_arg,
                   SendData_OutputDataInterfaceT &OutputDataSendData_arg);

    // model initialize function
    static void initialize();

    // model step function
    void step();

    // model terminate function
    static void terminate();

    // Destructor
    ~oMessage_Model();

    // private data and function members
   private:
    // Block signals
    B_oMessage_Model_T oMessage_Model_B;
    RecvData_InputDataInterfaceT &InputDataRecvData;
    SendData_OutputDataInterfaceT &OutputDataSendData;

    // Real-Time Model
    RT_MODEL_oMessage_Model_T oMessage_Model_M;
  };
}

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
//  '<Root>' : 'oMessage_Model'
//  '<S1>'   : 'oMessage_Model/Chart'

#endif                                 // oMessage_Model_h_

//
// File trailer for generated code.
//
// [EOF]
//
