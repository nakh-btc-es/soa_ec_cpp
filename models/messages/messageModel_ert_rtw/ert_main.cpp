//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: ert_main.cpp
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
#include <stdio.h>              // This example main program uses printf/fflush
#include "messageModel.h"              // Model header file

class messageModelRecvData_real32_T : public RecvData_real32_T{
 public:
  void RecvData(float* data, int32_t length, int32_t* status)
  {
    // Add receive data logic here
  }
};

static messageModelRecvData_real32_T InArrayMsgRecvData_arg;
class messageModelRecvData_myBusT : public RecvData_myBusT{
 public:
  void RecvData(myBus* data, int32_t length, int32_t* status)
  {
    // Add receive data logic here
  }
};

static messageModelRecvData_myBusT InBusElmMsgMyBusRecvData_arg;
class messageModelRecvData_int16_tT : public RecvData_int16_tT{
 public:
  void RecvData(int16_t* data, int32_t length, int32_t* status)
  {
    // Add receive data logic here
  }
};

static messageModelRecvData_int16_tT InBusElmSig_a_FxptSig1RecvData_;
static messageModelRecvData_int16_tT InBusElmSig_b_FxptSig2RecvData_;
static messageModelRecvData_myBusT InBusMsgRecvData_arg;
static messageModelRecvData_real32_T InScalarMsgRecvData_arg;
class messageModelSendData_real32_T : public SendData_real32_T{
 public:
  void SendData(const float* data, int32_t length, int32_t* status)
  {
    // Add send data logic here
  }
};

static messageModelSendData_real32_T OutArrayMsgSendData_arg;
class messageModelSendData_myBusT : public SendData_myBusT{
 public:
  void SendData(const myBus* data, int32_t length, int32_t* status)
  {
    // Add send data logic here
  }
};

static messageModelSendData_myBusT OutBusElmMsgMyBusSendData_arg;
class messageModelSendData_int16_tT : public SendData_int16_tT{
 public:
  void SendData(const int16_t* data, int32_t length, int32_t* status)
  {
    // Add send data logic here
  }
};

static messageModelSendData_int16_tT OutBusElmSig_a_FxptSig1SendDa_0;
static messageModelSendData_int16_tT OutBusElmSig_b_FxptSig2SendDa_0;
static messageModelSendData_myBusT OutBusMsgSendData_arg;
static messageModelSendData_real32_T OutScalarMsgSendData_arg;
static soa::messageModel rtObj{ InArrayMsgRecvData_arg,
  InBusElmMsgMyBusRecvData_arg, InBusElmSig_a_FxptSig1RecvData_,
  InBusElmSig_b_FxptSig2RecvData_, InBusMsgRecvData_arg, InScalarMsgRecvData_arg,
  OutArrayMsgSendData_arg, OutBusElmMsgMyBusSendData_arg,
  OutBusElmSig_a_FxptSig1SendDa_0, OutBusElmSig_b_FxptSig2SendDa_0,
  OutBusMsgSendData_arg, OutScalarMsgSendData_arg };// Instance of model class

//
// Associating rt_OneStep with a real-time clock or interrupt service routine
// is what makes the generated code "real-time".  The function rt_OneStep is
// always associated with the base rate of the model.  Subrates are managed
// by the base rate from inside the generated code.  Enabling/disabling
// interrupts and floating point context switches are target specific.  This
// example code indicates where these should take place relative to executing
// the generated code step function.  Overrun behavior should be tailored to
// your application needs.  This example simply sets an error status in the
// real-time model and returns from rt_OneStep.
//
void rt_OneStep(void);
void rt_OneStep(void)
{
  static bool OverrunFlag{ false };

  // Disable interrupts here

  // Check for overrun
  if (OverrunFlag) {
    return;
  }

  OverrunFlag = true;

  // Save FPU context here (if necessary)
  // Re-enable timer or interrupt here
  // Set model inputs here

  // Step the model
  rtObj.step();

  // Get model outputs here

  // Indicate task complete
  OverrunFlag = false;

  // Disable interrupts here
  // Restore FPU context here (if necessary)
  // Enable interrupts here
}

//
// The example main function illustrates what is required by your
// application code to initialize, execute, and terminate the generated code.
// Attaching rt_OneStep to a real-time clock is target specific. This example
// illustrates how you do this relative to initializing the model.
//
int main(int argc, const char *argv[])
{
  // Unused arguments
  (void)(argc);
  (void)(argv);

  // Initialize model
  rtObj.initialize();

  // Attach rt_OneStep to a timer or interrupt service routine with
  //  period 0.2 seconds (base rate of the model) here.
  //  The call syntax for rt_OneStep is
  //
  //   rt_OneStep();

  printf("Warning: The simulation will run forever. "
         "Generated ERT main won't simulate model step behavior. "
         "To change this behavior select the 'MAT-file logging' option.\n");
  fflush((nullptr));
  while (1) {
    //  Perform application tasks here
  }

  // The option 'Remove error status field in real-time model data structure'
  //  is selected, therefore the following code does not need to execute.

  return 0;
}

//
// File trailer for generated code.
//
// [EOF]
//
