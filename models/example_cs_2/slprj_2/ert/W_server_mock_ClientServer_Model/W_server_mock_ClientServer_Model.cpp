//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: W_server_mock_ClientServer_Model.cpp
//
// Code generated for Simulink model 'W_server_mock_ClientServer_Model'.
//
// Model version                  : 1.2
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Wed Sep 24 20:23:17 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#include "W_server_mock_ClientServer_Model.h"
#include "W_server_mock_ClientServer_Model_private.h"
#include "ClientServiceInterface_ClientService_add.h"

w_MdlrefDW_W_server_mock_ClientServer_Model_T
  w_W_server_mock_ClientServer_Model_MdlrefDW;

// Output and update for referenced model: 'W_server_mock_ClientServer_Model'
void ClientServiceInterface_ClientService_add(double rtu_DataA, double rtu_DataB,
  double *rty_DataD)
{
  // Outputs for Function Call SubSystem: '<Root>/Mock_ClientServiceInterface_ClientService_add' 
  // SignalConversion generated from: '<S1>/ArgIn_DataA' incorporates:
  //   DataStoreWrite: '<S1>/ClientService_add_DataA_In'

  ClientService_add_DataA_In = rtu_DataA;

  // SignalConversion generated from: '<S1>/ArgIn_DataB' incorporates:
  //   DataStoreWrite: '<S1>/ClientService_add_DataB_In'

  ClientService_add_DataB_In = rtu_DataB;

  // SignalConversion generated from: '<S1>/ArgOut_DataD' incorporates:
  //   DataStoreRead: '<S1>/ClientService_add_DataD_Out'

  *rty_DataD = ClientService_add_DataD_Out;

  // End of Outputs for SubSystem: '<Root>/Mock_ClientServiceInterface_ClientService_add' 
}

// Model initialize function
void W_server_mock_ClientServer_Model_initialize(const char **rt_errorStatus)
{
  w_RT_MODEL_W_server_mock_ClientServer_Model_T *const
    w_W_server_mock_ClientServer_Model_M{ &
    (w_W_server_mock_ClientServer_Model_MdlrefDW.rtm) };

  // Registration code

  // initialize error status
  w_W_server_mock_ClientServer_Model_M->setErrorStatusPointer(rt_errorStatus);
}

const char* w_RT_MODEL_W_server_mock_ClientServer_Model_T::getErrorStatus()
  const
{
  return (*(errorStatus));
}

void w_RT_MODEL_W_server_mock_ClientServer_Model_T::setErrorStatus(const char*
  const aErrorStatus) const
{
  (*(errorStatus) = aErrorStatus);
}

const char** w_RT_MODEL_W_server_mock_ClientServer_Model_T::
  getErrorStatusPointer() const
{
  return errorStatus;
}

void w_RT_MODEL_W_server_mock_ClientServer_Model_T::setErrorStatusPointer(const
  char** aErrorStatusPointer)
{
  (errorStatus = aErrorStatusPointer);
}

//
// File trailer for generated code.
//
// [EOF]
//
