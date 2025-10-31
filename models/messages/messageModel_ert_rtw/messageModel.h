//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: messageModel.h
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
#ifndef messageModel_h_
#define messageModel_h_
#include <stdbool.h>
#include <stdint.h>
#include <stddef.h>
#include "RecvData_real32_T.h"
#include "RecvData_int16_tT.h"
#include "SendData_real32_T.h"
#include "SendData_int16_tT.h"
#ifndef DEFINED_TYPEDEF_FOR_myBus_
#define DEFINED_TYPEDEF_FOR_myBus_

struct myBus
{
  float FlptSig1;
  float FlptSig2;
};

#endif

class RecvData_myBusT
{
 public:
  virtual void RecvData(myBus *data, int32_t length, int32_t *status) = 0;
  virtual ~RecvData_myBusT()
    = default;
};

class SendData_myBusT
{
 public:
  virtual void SendData(const myBus *data, int32_t length, int32_t *status) = 0;
  virtual ~SendData_myBusT()
    = default;
};

// Class declaration for model messageModel
namespace soa
{
  class messageModel final
  {
    // public data and function members
   public:
    // Block signals and states (default storage) for system '<Root>'
    struct DW {
      myBus Receive2;                  // '<Root>/Receive2'
      myBus Receive5;                  // '<Root>/Receive5'
      float Receive1[2];               // '<Root>/Receive1'
      float Receive;                   // '<Root>/Receive'
      int16_t Receive3;                // '<Root>/Receive3'
      int16_t Receive4;                // '<Root>/Receive4'
    };

    // Parameters (default storage)
    struct P {
      myBus Receive2_InitialValue;  // Computed Parameter: Receive2_InitialValue
                                       //  Referenced by: '<Root>/Receive2'

      myBus Receive5_InitialValue;  // Computed Parameter: Receive5_InitialValue
                                       //  Referenced by: '<Root>/Receive5'

      float Receive_InitialValue;    // Computed Parameter: Receive_InitialValue
                                        //  Referenced by: '<Root>/Receive'

      float Receive1_InitialValue;  // Computed Parameter: Receive1_InitialValue
                                       //  Referenced by: '<Root>/Receive1'

      int16_t Receive3_InitialValue;// Computed Parameter: Receive3_InitialValue
                                       //  Referenced by: '<Root>/Receive3'

      int16_t Receive4_InitialValue;// Computed Parameter: Receive4_InitialValue
                                       //  Referenced by: '<Root>/Receive4'

    };

    // Copy Constructor
    messageModel(messageModel const&) = delete;

    // Assignment Operator
    messageModel& operator= (messageModel const&) & = delete;

    // Move Constructor
    messageModel(messageModel &&) = delete;

    // Move Assignment Operator
    messageModel& operator= (messageModel &&) = delete;

    // Constructor
    messageModel(RecvData_real32_T &InArrayMsgRecvData_arg, RecvData_myBusT &
                 InBusElmMsgMyBusRecvData_arg, RecvData_int16_tT &
                 InBusElmSig_a_FxptSig1RecvData_, RecvData_int16_tT &
                 InBusElmSig_b_FxptSig2RecvData_, RecvData_myBusT &
                 InBusMsgRecvData_arg, RecvData_real32_T
                 &InScalarMsgRecvData_arg, SendData_real32_T
                 &OutArrayMsgSendData_arg, SendData_myBusT &
                 OutBusElmMsgMyBusSendData_arg, SendData_int16_tT &
                 OutBusElmSig_a_FxptSig1SendDa_0, SendData_int16_tT &
                 OutBusElmSig_b_FxptSig2SendDa_0, SendData_myBusT &
                 OutBusMsgSendData_arg, SendData_real32_T
                 &OutScalarMsgSendData_arg);

    // Block states get method
    const DW &getDWork() const;

    // Block states set method
    void setDWork(const DW *pDW);

    // Block parameters get method
    const P &getBlockParameters() const;

    // Block parameters set method
    void setBlockParameters(const P *pP) const;

    // model initialize function
    void initialize();

    // model step function
    void step();

    // Destructor
    ~messageModel();

    // private data and function members
   private:
    // Block states
    DW rtDW;

    // Tunable parameters
    static P rtP;
    RecvData_real32_T &InArrayMsgRecvData;
    RecvData_myBusT &InBusElmMsgMyBusRecvData;
    RecvData_int16_tT &InBusElmSig_a_FxptSig1RecvData;
    RecvData_int16_tT &InBusElmSig_b_FxptSig2RecvData;
    RecvData_myBusT &InBusMsgRecvData;
    RecvData_real32_T &InScalarMsgRecvData;
    SendData_real32_T &OutArrayMsgSendData;
    SendData_myBusT &OutBusElmMsgMyBusSendData;
    SendData_int16_tT &OutBusElmSig_a_FxptSig1SendData;
    SendData_int16_tT &OutBusElmSig_b_FxptSig2SendData;
    SendData_myBusT &OutBusMsgSendData;
    SendData_real32_T &OutScalarMsgSendData;
  };
}

//-
//  These blocks were eliminated from the model due to optimizations:
//
//  Block '<Root>/Signal Copy1' : Eliminate redundant signal conversion block
//  Block '<Root>/Signal Copy3' : Eliminate redundant signal conversion block
//  Block '<Root>/Signal Copy4' : Eliminate redundant signal conversion block
//  Block '<Root>/Signal Copy5' : Eliminate redundant signal conversion block
//  Block '<Root>/Signal Copy6' : Eliminate redundant signal conversion block
//  Block '<Root>/Signal Copy7' : Eliminate redundant signal conversion block


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
//  '<Root>' : 'messageModel'


//-
//  Requirements for '<Root>': messageModel


#endif                                 // messageModel_h_

//
// File trailer for generated code.
//
// [EOF]
//
