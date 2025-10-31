//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: messageModel.cpp
//
// Code generated for Simulink model 'messageModel'.
//
// Model version                  : 1.29
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Fri Oct 31 17:00:45 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives:
//    1. Execution efficiency
//    2. Traceability
// Validation result: Not run
//
#include "messageModel.h"
#include "RecvData_real32_T.h"
#include "RecvData_int16_tT.h"
#include "SendData_real32_T.h"
#include "SendData_int16_tT.h"
#include <stdint.h>
#include <stdbool.h>
#ifndef UCHAR_MAX
#include <limits.h>
#endif

#if ( UCHAR_MAX != (0xFFU) ) || ( SCHAR_MAX != (0x7F) )
#error Code was generated for compiler with different sized uchar/char. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

#if ( USHRT_MAX != (0xFFFFU) ) || ( SHRT_MAX != (0x7FFF) )
#error Code was generated for compiler with different sized ushort/short. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

#if ( UINT_MAX != (0xFFFFFFFFU) ) || ( INT_MAX != (0x7FFFFFFF) )
#error Code was generated for compiler with different sized uint/int. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

#if ( ULONG_MAX != (0xFFFFFFFFU) ) || ( LONG_MAX != (0x7FFFFFFF) )
#error Code was generated for compiler with different sized ulong/long. \
Consider adjusting Test hardware word size settings on the \
Hardware Implementation pane to match your compiler word sizes as \
defined in limits.h of the compiler. Alternatively, you can \
select the Test hardware is the same as production hardware option and \
select the Enable portable word sizes option on the Code Generation > \
Verification pane for ERT based targets, which will disable the \
preprocessor word size checks.
#endif

// Skipping ulong_long/long_long check: insufficient preprocessor integer range. 
namespace soa
{
  // Model step function
  void messageModel::step()
  {
    int32_t status;
    int32_t status_0;
    int32_t status_1;
    int32_t status_2;
    int32_t status_3;
    int32_t status_4{ 1 };

    int32_t status_5;

    // Receive: '<Root>/Receive'
    status_4 = 1;
    InScalarMsgRecvData.RecvData(&rtDW.Receive, sizeof(float), &status_4);

    // Send: '<Root>/Send'
    OutScalarMsgSendData.SendData(&rtDW.Receive, sizeof(float), &status);

    // Receive: '<Root>/Receive1'
    status_4 = 1;
    InArrayMsgRecvData.RecvData(&rtDW.Receive1[0], sizeof(float) << 1, &status_4);

    // Send: '<Root>/Send1' incorporates:
    //   Receive: '<Root>/Receive1'

    OutArrayMsgSendData.SendData(&rtDW.Receive1[0], sizeof(float) << 1,
      &status_0);

    // Receive: '<Root>/Receive2'
    status_4 = 1;
    InBusMsgRecvData.RecvData(&rtDW.Receive2, sizeof(myBus), &status_4);

    // Send: '<Root>/Send2' incorporates:
    //   Receive: '<Root>/Receive2'

    OutBusMsgSendData.SendData(&rtDW.Receive2, sizeof(myBus), &status_1);

    // Receive: '<Root>/Receive5'
    status_4 = 1;
    InBusElmMsgMyBusRecvData.RecvData(&rtDW.Receive5, sizeof(myBus), &status_4);

    // Send: '<Root>/Send5' incorporates:
    //   Receive: '<Root>/Receive5'

    OutBusElmMsgMyBusSendData.SendData(&rtDW.Receive5, sizeof(myBus), &status_2);

    // Receive: '<Root>/Receive3'
    status_4 = 1;
    InBusElmSig_a_FxptSig1RecvData.RecvData(&rtDW.Receive3, sizeof(int16_t),
      &status_4);

    // Send: '<Root>/Send3' incorporates:
    //   Receive: '<Root>/Receive3'

    OutBusElmSig_a_FxptSig1SendData.SendData(&rtDW.Receive3, sizeof(int16_t),
      &status_3);

    // Receive: '<Root>/Receive4'
    status_4 = 1;
    InBusElmSig_b_FxptSig2RecvData.RecvData(&rtDW.Receive4, sizeof(int16_t),
      &status_4);

    // Send: '<Root>/Send4' incorporates:
    //   Receive: '<Root>/Receive4'

    OutBusElmSig_b_FxptSig2SendData.SendData(&rtDW.Receive4, sizeof(int16_t),
      &status_5);
  }

  // Model initialize function
  void messageModel::initialize()
  {
    // InitializeConditions for Receive: '<Root>/Receive'
    rtDW.Receive = rtP.Receive_InitialValue;

    // InitializeConditions for Receive: '<Root>/Receive1'
    rtDW.Receive1[0] = rtP.Receive1_InitialValue;
    rtDW.Receive1[1] = rtP.Receive1_InitialValue;

    // InitializeConditions for Receive: '<Root>/Receive2'
    rtDW.Receive2 = rtP.Receive2_InitialValue;

    // InitializeConditions for Receive: '<Root>/Receive5'
    rtDW.Receive5 = rtP.Receive5_InitialValue;

    // InitializeConditions for Receive: '<Root>/Receive3'
    rtDW.Receive3 = rtP.Receive3_InitialValue;

    // InitializeConditions for Receive: '<Root>/Receive4'
    rtDW.Receive4 = rtP.Receive4_InitialValue;
  }

  // Block states get method
  const messageModel::DW &messageModel::getDWork() const
  {
    return rtDW;
  }

  // Block states set method
  void messageModel::setDWork(const messageModel::DW *pDW)
  {
    rtDW = *pDW;
  }

  // Block parameters get method
  const messageModel::P &messageModel::getBlockParameters() const
  {
    return rtP;
  }

  // Block parameters set method
  void messageModel::setBlockParameters(const messageModel::P *pP) const
  {
    rtP = *pP;
  }

  // Constructor
  messageModel::messageModel(RecvData_real32_T& InArrayMsgRecvData_arg,
    RecvData_myBusT& InBusElmMsgMyBusRecvData_arg,RecvData_int16_tT&
    InBusElmSig_a_FxptSig1RecvData_,RecvData_int16_tT&
    InBusElmSig_b_FxptSig2RecvData_,RecvData_myBusT& InBusMsgRecvData_arg,
    RecvData_real32_T& InScalarMsgRecvData_arg,SendData_real32_T
    & OutArrayMsgSendData_arg,SendData_myBusT& OutBusElmMsgMyBusSendData_arg,
    SendData_int16_tT& OutBusElmSig_a_FxptSig1SendDa_0,SendData_int16_tT&
    OutBusElmSig_b_FxptSig2SendDa_0,SendData_myBusT& OutBusMsgSendData_arg,
    SendData_real32_T& OutScalarMsgSendData_arg) :
    rtDW(),
    InArrayMsgRecvData(InArrayMsgRecvData_arg),
    InBusElmMsgMyBusRecvData(InBusElmMsgMyBusRecvData_arg),
    InBusElmSig_a_FxptSig1RecvData(InBusElmSig_a_FxptSig1RecvData_),
    InBusElmSig_b_FxptSig2RecvData(InBusElmSig_b_FxptSig2RecvData_),
    InBusMsgRecvData(InBusMsgRecvData_arg),
    InScalarMsgRecvData(InScalarMsgRecvData_arg),
    OutArrayMsgSendData(OutArrayMsgSendData_arg),
    OutBusElmMsgMyBusSendData(OutBusElmMsgMyBusSendData_arg),
    OutBusElmSig_a_FxptSig1SendData(OutBusElmSig_a_FxptSig1SendDa_0),
    OutBusElmSig_b_FxptSig2SendData(OutBusElmSig_b_FxptSig2SendDa_0),
    OutBusMsgSendData(OutBusMsgSendData_arg),
    OutScalarMsgSendData(OutScalarMsgSendData_arg)
  {
    // Currently there is no constructor body generated.
  }

  // Destructor
  // Currently there is no destructor body generated.
  messageModel::~messageModel() = default;
}

//
// File trailer for generated code.
//
// [EOF]
//
