//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: oMessage_Model.cpp
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
#include "oMessage_Model.h"
#include "oMessage_Model_types.h"
#include "rtwtypes.h"

namespace ComponentNamespace
{
  // Model step function
  void oMessage_Model::step()
  {
    int32_T status{ 1 };

    int32_T status_0;

    // Receive: '<Root>/Receive'
    status = 1;
    InputDataRecvData.RecvData(&oMessage_Model_B.Receive, sizeof
      (InputDataInterface), &status);

    // Chart: '<Root>/Chart'
    if (oMessage_Model_B.Receive.DataA > 5.0) {
      oMessage_Model_B.BusCreator.DataC = oMessage_Model_B.Receive.DataA +
        oMessage_Model_B.Receive.DataB;
    } else {
      oMessage_Model_B.BusCreator.DataC = oMessage_Model_B.Receive.DataA *
        oMessage_Model_B.Receive.DataB;
    }

    // End of Chart: '<Root>/Chart'

    // Send: '<Root>/Send'
    OutputDataSendData.SendData(&oMessage_Model_B.BusCreator, sizeof
      (OutputDataInterface), &status_0);
  }

  // Model initialize function
  void oMessage_Model::initialize()
  {
    // (no initialization code required)
  }

  // Model terminate function
  void oMessage_Model::terminate()
  {
    // (no terminate code required)
  }

  const char_T* oMessage_Model::RT_MODEL_oMessage_Model_T::getErrorStatus()
    const
  {
    return (errorStatus);
  }

  void oMessage_Model::RT_MODEL_oMessage_Model_T::setErrorStatus(const char_T*
    const volatile aErrorStatus)
  {
    (errorStatus = aErrorStatus);
  }

  // Constructor
  oMessage_Model::oMessage_Model(RecvData_InputDataInterfaceT&
    InputDataRecvData_arg,SendData_OutputDataInterfaceT& OutputDataSendData_arg)
    :
    oMessage_Model_B(),
    InputDataRecvData(InputDataRecvData_arg),
    OutputDataSendData(OutputDataSendData_arg),
    oMessage_Model_M()
  {
    // Currently there is no constructor body generated.
  }

  // Destructor
  // Currently there is no destructor body generated.
  oMessage_Model::~oMessage_Model() = default;

  // Real-Time Model get method
  oMessage_Model::RT_MODEL_oMessage_Model_T * oMessage_Model::getRTM()
  {
    return (&oMessage_Model_M);
  }
}

//
// File trailer for generated code.
//
// [EOF]
//
