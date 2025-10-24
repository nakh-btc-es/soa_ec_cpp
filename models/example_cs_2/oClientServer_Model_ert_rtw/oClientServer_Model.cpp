//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: oClientServer_Model.cpp
//
// Code generated for Simulink model 'oClientServer_Model'.
//
// Model version                  : 1.13
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Sun Sep 28 22:06:31 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives: Unspecified
// Validation result: Not run
//
#include "oClientServer_Model.h"
#include "rtwtypes.h"
#include "ClientServiceInterfaceT.h"

// Exported block states
real_T DataD_Display;                 // Simulink.Signal object 'DataD_Display'
namespace ComponentNamespace
{
  // Model step function
  void oClientServer_Model::setDataB(real_T rtu_DataB)
  {
    // Outputs for Function Call SubSystem: '<Root>/Simulink Function'
    // SignalConversion generated from: '<S1>/DataB'
    oClientServer_Model_B.TmpSignalConversionAtDataBOut_k = rtu_DataB;

    // End of Outputs for SubSystem: '<Root>/Simulink Function'
  }

  // Model step function
  void oClientServer_Model::setDataA(real_T rtu_DataA)
  {
    // Outputs for Function Call SubSystem: '<Root>/Simulink Function1'
    // SignalConversion generated from: '<S2>/DataA'
    oClientServer_Model_B.TmpSignalConversionAtDataAOut_b = rtu_DataA;

    // End of Outputs for SubSystem: '<Root>/Simulink Function1'
  }

  // Model step function
  void oClientServer_Model::getDataC(real_T *rty_DataC)
  {
    // Outputs for Function Call SubSystem: '<Root>/Simulink Function2'
    // SignalConversion generated from: '<S3>/DataC_In'
    oClientServer_Model_B.DataC = oClientServer_Model_B.DataC_d;

    // SignalConversion generated from: '<S3>/DataC'
    *rty_DataC = oClientServer_Model_B.DataC;

    // End of Outputs for SubSystem: '<Root>/Simulink Function2'
  }

  // Model step function
  void oClientServer_Model::callAdd(const real_T rtu_DataA, const real_T
    rtu_DataB, real_T *rty_DataD)
  {
    // Outputs for Function Call SubSystem: '<Root>/Simulink Function3'
    // SignalConversion generated from: '<S4>/DataA'
    oClientServer_Model_B.TmpSignalConversionAtDataAOutpo = rtu_DataA;

    // SignalConversion generated from: '<S4>/DataB'
    oClientServer_Model_B.TmpSignalConversionAtDataBOutpo = rtu_DataB;

    // FunctionCaller: '<S4>/Function Caller'
    ClientService.add(oClientServer_Model_B.TmpSignalConversionAtDataAOutpo,
                      oClientServer_Model_B.TmpSignalConversionAtDataBOutpo,
                      &oClientServer_Model_B.FunctionCaller);

    // SignalConversion generated from: '<S4>/DataD'
    *rty_DataD = oClientServer_Model_B.FunctionCaller;

    // End of Outputs for SubSystem: '<Root>/Simulink Function3'
  }

  // Model step function
  void oClientServer_Model::step()
  {
    real_T b;

    // RootInportFunctionCallGenerator generated from: '<Root>/step' incorporates:
    //   SubSystem: '<Root>/Subsystem'

    // Chart: '<S5>/Chart'
    if (oClientServer_Model_B.TmpSignalConversionAtDataAOut_b > 5.0) {
      oClientServer_Model_B.DataC_d =
        oClientServer_Model_B.TmpSignalConversionAtDataAOut_b +
        oClientServer_Model_B.TmpSignalConversionAtDataBOut_k;
    } else {
      oClientServer_Model_B.DataC_d =
        oClientServer_Model_B.TmpSignalConversionAtDataAOut_b *
        oClientServer_Model_B.TmpSignalConversionAtDataBOut_k;
    }

    callAdd(oClientServer_Model_B.TmpSignalConversionAtDataAOut_b,
            oClientServer_Model_B.TmpSignalConversionAtDataBOut_k, &b);
    oClientServer_Model_B.DataD = b;

    // End of Chart: '<S5>/Chart'

    // DataStoreWrite: '<S5>/DataD'
    DataD_Display = oClientServer_Model_B.DataD;

    // End of Outputs for RootInportFunctionCallGenerator generated from: '<Root>/step' 
  }

  // Model initialize function
  void oClientServer_Model::initialize()
  {
    // (no initialization code required)
  }

  // Model terminate function
  void oClientServer_Model::terminate()
  {
    // (no terminate code required)
  }

  const char_T* oClientServer_Model::RT_MODEL_oClientServer_Model_T::
    getErrorStatus() const
  {
    return (errorStatus);
  }

  void oClientServer_Model::RT_MODEL_oClientServer_Model_T::setErrorStatus(const
    char_T* const volatile aErrorStatus)
  {
    (errorStatus = aErrorStatus);
  }

  // Constructor
  oClientServer_Model::oClientServer_Model(ClientServiceInterfaceT&
    ClientService_arg) :
    oClientServer_Model_B(),
    ClientService(ClientService_arg),
    ServerService(*this),
    oClientServer_Model_M()
  {
    // Currently there is no constructor body generated.
  }

  // Destructor
  // Currently there is no destructor body generated.
  oClientServer_Model::~oClientServer_Model() = default;

  // Real-Time Model get method
  oClientServer_Model::RT_MODEL_oClientServer_Model_T * oClientServer_Model::
    getRTM()
  {
    return (&oClientServer_Model_M);
  }

  ServerServiceInterfaceT & oClientServer_Model::get_ServerService()
  {
    return ServerService;
  }

  oClientServer_ModelServerServiceT::oClientServer_ModelServerServiceT
    (oClientServer_Model &aProvider): oClientServer_Model_mProvider{ aProvider }
  {
  }

  void oClientServer_ModelServerServiceT::getDataC(real_T *DataC)
  {
    oClientServer_Model_mProvider.getDataC(DataC);
  }

  void oClientServer_ModelServerServiceT::setDataA(real_T DataA)
  {
    oClientServer_Model_mProvider.setDataA(DataA);
  }

  void oClientServer_ModelServerServiceT::setDataB(real_T DataB)
  {
    oClientServer_Model_mProvider.setDataB(DataB);
  }
}

//
// File trailer for generated code.
//
// [EOF]
//
