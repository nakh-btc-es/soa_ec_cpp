#include "messageModel.h"
#include "RecvData_int16_tT.h"
#include "RecvData_real32_T.h"
#include "SendData_int16_tT.h"
#include "SendData_real32_T.h"


//=============================================================================
// BTC ADAPTER CLASSES
//=============================================================================

namespace BTC {
  //////// Derivation of Receive Message abstract classes

  //Int16 Receive Message
  class BTCMsg_RecvData_int16_tT : public RecvData_int16_tT {
   public:
    void RecvData(int16_t *data, int32_t length, int32_t *status) override {

      (void)length;
      (void)status;

      *data = data16;
    }

   public:
    int16_t data16;
    };

  //Float32 Receive Message
  class BTCMsg_RecvData_float32_T : public RecvData_real32_T {
   public:
    void RecvData(float *data, int32_t length, int32_t *status) override {

      (void)length;
      (void)status;

      *data = data32;
    }
    
   public:
    float data32;
  };

  //myBus Receive Message
  class BTCMsg_RecvData_myBusT : public RecvData_myBusT {
   public:
    void RecvData(myBus *data, int32_t length, int32_t *status) override {

      (void)length;
      (void)status;

      *data = dataMyBus;
    }

   public:
    myBus dataMyBus;
  };

  //////// Derivation of Send Message abstract class

  //Int16 Send Message
  class BTCMsg_SendData_int16_tT : public SendData_int16_tT {
   public:
    void SendData(const int16_t *data, int32_t length, int32_t *status) {

      (void)length;
      (void)status;

      data16 = *data;
    }

   public:
    int16_t data16;
  
  };

  //Float32 Send Message
  class BTCMsg_SendData_float32_T : public SendData_real32_T {
   public:
    void SendData(const float *data, int32_t length, int32_t *status) {

      (void)length;
      (void)status;

      data32 = *data;
    }

   public:
    float data32;
  };

  //myBus Send Message
  class BTCMsg_SendData_myBusT : public SendData_myBusT {
   public:
    void SendData(const myBus *data, int32_t length, int32_t *status) override {

      (void)length;
      (void)status;

      dataMyBus = *data;
    }

   public:
    myBus dataMyBus;
  };

};

  // Received Message Objects
  BTC::BTCMsg_RecvData_int16_tT oInBusElmSig_a_FxptSig1RecvData;
  BTC::BTCMsg_RecvData_int16_tT oInBusElmSig_b_FxptSig2RecvData;
  
  BTC::BTCMsg_RecvData_float32_T oInScalar_RecvMsgFloat32;
  BTC::BTCMsg_RecvData_float32_T oInArray_RecvMsgFloat32;
  
  BTC::BTCMsg_RecvData_myBusT oInBusMsgRecvData;
  BTC::BTCMsg_RecvData_myBusT oInBusElmMyBusRecvData;

  // Sent Message Objects
  BTC::BTCMsg_SendData_int16_tT oOutBusElmSig_a_FxptSig1;
  BTC::BTCMsg_SendData_int16_tT oOutBusElmSig_b_FxptSig2;

  BTC::BTCMsg_SendData_float32_T oOutScalar_RecvMsgFloat32;
  BTC::BTCMsg_SendData_float32_T oOutArray_RecvMsgFloat32;

  BTC::BTCMsg_SendData_myBusT oOutBusMsgSendData;
  BTC::BTCMsg_SendData_myBusT oOutBusElmMyBusSendData;


//=============================================================================
// GLOBAL INPUT VARIABLES
//=============================================================================

// Scalar input
float g_InScalar = 0.0f;
float g_InArray[2] = {0.0f, 0.0f};
myBus g_InBusMsg = {0.0f, 0.0f};
myBus g_InBusElmMyBus = {0.0f, 0.0f};
int16_t g_InBusElmSig1_FxptSig = 0;
int16_t g_InBusElmSig2_FxptSig = 0;

//=============================================================================
// GLOBAL OUTPUT VARIABLES
//=============================================================================

// Scalar output
float g_OutScalar = 0.0f;
float g_OutArray[2] = {0.0f, 0.0f};
myBus g_OutBusMsg = {0.0f, 0.0f};
myBus g_OutBusElmMyBus = {0.0f, 0.0f};
int16_t g_OutBusElmSig1_FxptSig = 0;
int16_t g_OutBusElmSig2_FxptSig = 0;

//=============================================================================
// INPUT/OUTPUT TRANSFER FUNCTIONS
//=============================================================================

  static void transfer_btcinputs_to_model()
{
    oInScalar_RecvMsgFloat32.data32 = g_InScalar;
    // oInArray_RecvMsgFloat32.data32[0] = g_InArray[0]; // Assuming single value for simplicity
    // oInArray_RecvMsgFloat32.data32[1] = g_InArray[1];
    oInBusMsgRecvData.dataMyBus = g_InBusMsg;
    oInBusElmMyBusRecvData.dataMyBus = g_InBusElmMyBus;
    oInBusElmSig_a_FxptSig1RecvData.data16 = g_InBusElmSig1_FxptSig;
    oInBusElmSig_b_FxptSig2RecvData.data16 = g_InBusElmSig2_FxptSig;
}

static void transfer_btcoutputs_from_model()  
{
    g_OutScalar = oOutScalar_RecvMsgFloat32.data32;
    // g_OutArray[0] = oOutArray_RecvMsgFloat32.data32[0];
    // g_OutArray[1] = oOutArray_RecvMsgFloat32.data32[1];
    g_OutBusMsg = oOutBusMsgSendData.dataMyBus;
    g_OutBusElmMyBus = oOutBusElmMyBusSendData.dataMyBus;
    g_OutBusElmSig1_FxptSig = oOutBusElmSig_a_FxptSig1.data16;
    g_OutBusElmSig2_FxptSig = oOutBusElmSig_b_FxptSig2.data16;
}



// Model Object
soa::messageModel oModel(
    oInArray_RecvMsgFloat32,
    oInBusElmMyBusRecvData,
    oInBusElmSig_a_FxptSig1RecvData,
    oInBusElmSig_b_FxptSig2RecvData,
    oInBusMsgRecvData,
    oInScalar_RecvMsgFloat32, 
    oOutArray_RecvMsgFloat32,
    oOutBusElmMyBusSendData,
    oOutBusElmSig_a_FxptSig1,
    oOutBusElmSig_b_FxptSig2,
    oOutBusMsgSendData,
    oOutScalar_RecvMsgFloat32
  );


  //=============================================================================
// INIT FUNCTION
//=============================================================================
void main_initialize() {


    // Calling the method under test.
    oModel.initialize();
    
  }

//=============================================================================
// MAIN MODEL STEP FUNCTION
//=============================================================================

  void main_step() {

    // Transfer inputs from global variables to model
    transfer_btcinputs_to_model();

    // Calling the method under test.
    oModel.step();
    
    // Transfer outputs from model to global variables
    transfer_btcoutputs_from_model();

  }


