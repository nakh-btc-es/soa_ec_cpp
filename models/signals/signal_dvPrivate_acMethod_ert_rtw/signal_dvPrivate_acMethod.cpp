//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: signal_dvPrivate_acMethod.cpp
//
// Code generated for Simulink model 'signal_dvPrivate_acMethod'.
//
// Model version                  : 1.20
// Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
// C/C++ source code generated on : Fri Oct 24 20:49:05 2025
//
// Target selection: ert.tlc
// Embedded hardware selection: Intel->x86-64 (Windows64)
// Code generation objectives:
//    1. Execution efficiency
//    2. Traceability
// Validation result: Not run
//
#include "signal_dvPrivate_acMethod.h"
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
namespace btc_soa
{
  // Model step function
  void signal_dvPrivate_acMethod::step()
  {
    // BusCreator generated from: '<Root>/OutBus_dvPrivate_amMethod' incorporates:
    //   Inport generated from: '<Root>/InBus_dvPrivate_amMethod'
    //   Outport generated from: '<Root>/OutBus_dvPrivate_amMethod'

    rtY.OutBus_dvPrivate_amMethod = rtU.InBus_dvPrivate_amMethod;

    // Outport generated from: '<Root>/OutArray_dvPrivate_amMethod' incorporates:
    //   Gain: '<Root>/Gain1'
    //   UnitDelay: '<Root>/Unit Delay'

    rtY.OutArray_dvPrivate_amMethod[0] = rtP.ParamArray[0] *
      rtDW.LocArray_dvPrivate_amMethod[0];
    rtY.OutArray_dvPrivate_amMethod[1] = rtP.ParamArray[1] *
      rtDW.LocArray_dvPrivate_amMethod[1];

    // Outport generated from: '<Root>/OutScalar_dvPrivate_amMethod' incorporates:
    //   Gain: '<Root>/Gain'
    //   UnitDelay: '<Root>/Unit Delay1'

    rtY.OutScalar_dvPrivate_amMethod = rtP.ParamScalar *
      rtDW.LocScalar_dvPrivate_amMethod;

    // Update for UnitDelay: '<Root>/Unit Delay' incorporates:
    //   Inport generated from: '<Root>/InArray_dvPrivate_amMethod'

    rtDW.LocArray_dvPrivate_amMethod[0] = rtU.InArray_dvPrivate_amMethod[0];
    rtDW.LocArray_dvPrivate_amMethod[1] = rtU.InArray_dvPrivate_amMethod[1];

    // Update for UnitDelay: '<Root>/Unit Delay1' incorporates:
    //   Inport generated from: '<Root>/InScalar_dvPrivate_amMethod'

    rtDW.LocScalar_dvPrivate_amMethod = rtU.InScalar_dvPrivate_amMethod;

    // Outport generated from: '<Root>/Bus Element Out' incorporates:
    //   Inport generated from: '<Root>/In Bus Element'

    rtY.OutBusElm_dvPrivate_amMethod_Fx = rtU.InBusElm_dvPrivate_amMethod_Fxp;

    // Outport generated from: '<Root>/Bus Element Out1' incorporates:
    //   Inport generated from: '<Root>/In Bus Element1'

    rtY.OutBusElm_dvPrivate_amMethod1_F = rtU.InBusElm_dvPrivate_amMethod1__p;
  }

  // Model initialize function
  void signal_dvPrivate_acMethod::initialize()
  {
    // InitializeConditions for UnitDelay: '<Root>/Unit Delay'
    rtDW.LocArray_dvPrivate_amMethod[0] = rtP.UnitDelay_InitialCondition;
    rtDW.LocArray_dvPrivate_amMethod[1] = rtP.UnitDelay_InitialCondition;

    // InitializeConditions for UnitDelay: '<Root>/Unit Delay1'
    rtDW.LocScalar_dvPrivate_amMethod = rtP.UnitDelay1_InitialCondition;
  }

  // Root inport: '<Root>/InScalar_dvPrivate_amMethod' set method
  void signal_dvPrivate_acMethod::setInScalar_dvPrivate_amMethod(float
    localArgInput)
  {
    rtU.InScalar_dvPrivate_amMethod = localArgInput;
  }

  // Root inport: '<Root>/InArray_dvPrivate_amMethod' set method
  void signal_dvPrivate_acMethod::setInArray_dvPrivate_amMethod(float
    localArgInput[2])
  {
    rtU.InArray_dvPrivate_amMethod[0] = localArgInput[0];
    rtU.InArray_dvPrivate_amMethod[1] = localArgInput[1];
  }

  // Root inport: '<Root>/InBus_dvPrivate_amMethod' set method
  void signal_dvPrivate_acMethod::setInBus_dvPrivate_amMethod(myBus
    localArgInput)
  {
    rtU.InBus_dvPrivate_amMethod = localArgInput;
  }

  // Root inport: '<Root>/InBusElm_dvPrivate_amMethod_FxptSig1' set method
  void signal_dvPrivate_acMethod::setInBusElm_dvPrivate_amMethod_FxptSig1
    (int16_t localArgInput)
  {
    rtU.InBusElm_dvPrivate_amMethod_Fxp = localArgInput;
  }

  // Root inport: '<Root>/InBusElm_dvPrivate_amMethod1_FxptSig2' set method
  void signal_dvPrivate_acMethod::setInBusElm_dvPrivate_amMethod1_FxptSig2
    (int16_t localArgInput)
  {
    rtU.InBusElm_dvPrivate_amMethod1__p = localArgInput;
  }

  // Root outport: '<Root>/OutScalar_dvPrivate_amMethod' get method
  float signal_dvPrivate_acMethod::getOutScalar_dvPrivate_amMethod() const
  {
    return rtY.OutScalar_dvPrivate_amMethod;
  }

  // Root outport: '<Root>/OutArray_dvPrivate_amMethod' get method
  const float *signal_dvPrivate_acMethod::getOutArray_dvPrivate_amMethod() const
  {
    return rtY.OutArray_dvPrivate_amMethod;
  }

  // Root outport: '<Root>/OutBus_dvPrivate_amMethod' get method
  myBus signal_dvPrivate_acMethod::getOutBus_dvPrivate_amMethod() const
  {
    return rtY.OutBus_dvPrivate_amMethod;
  }

  // Root outport: '<Root>/OutBusElm_dvPrivate_amMethod_FxptSig1' get method
  int16_t signal_dvPrivate_acMethod::getOutBusElm_dvPrivate_amMethod_FxptSig1()
    const
  {
    return rtY.OutBusElm_dvPrivate_amMethod_Fx;
  }

  // Root outport: '<Root>/OutBusElm_dvPrivate_amMethod1_FxptSig2' get method
  int16_t signal_dvPrivate_acMethod::getOutBusElm_dvPrivate_amMethod1_FxptSig2()
    const
  {
    return rtY.OutBusElm_dvPrivate_amMethod1_F;
  }

  // Block states get method
  const signal_dvPrivate_acMethod::DW &signal_dvPrivate_acMethod::getDWork()
    const
  {
    return rtDW;
  }

  // Block states set method
  void signal_dvPrivate_acMethod::setDWork(const signal_dvPrivate_acMethod::DW
    *pDW)
  {
    rtDW = *pDW;
  }

  // Block parameters get method
  const signal_dvPrivate_acMethod::P &signal_dvPrivate_acMethod::
    getBlockParameters() const
  {
    return rtP;
  }

  // Block parameters set method
  void signal_dvPrivate_acMethod::setBlockParameters(const
    signal_dvPrivate_acMethod::P *pP) const
  {
    rtP = *pP;
  }

  // Constructor
  signal_dvPrivate_acMethod::signal_dvPrivate_acMethod():
    rtU(),
    rtY(),
    rtDW()
  {
    // Currently there is no constructor body generated.
  }

  // Destructor
  // Currently there is no destructor body generated.
  signal_dvPrivate_acMethod::~signal_dvPrivate_acMethod() = default;
}

//
// File trailer for generated code.
//
// [EOF]
//
