//
// Third Party Support License -- for use only to support products
// interfaced to MathWorks software under terms specified in your
// company's restricted use license agreement.
//
// File: signal_dvPrivate_acMethod.h
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
#ifndef signal_dvPrivate_acMethod_h_
#define signal_dvPrivate_acMethod_h_
#include <stdbool.h>
#include <stdint.h>
#ifndef DEFINED_TYPEDEF_FOR_myBus_
#define DEFINED_TYPEDEF_FOR_myBus_

struct myBus
{
  float FlptSig1;
  float FlptSig2;
};

#endif

// Class declaration for model signal_dvPrivate_acMethod
namespace btc_soa
{
  class signal_dvPrivate_acMethod final
  {
    // public data and function members
   public:
    // Block signals and states (default storage) for system '<Root>'
    struct DW {
      float LocArray_dvPrivate_amMethod[2];// '<Root>/Unit Delay'
      float LocScalar_dvPrivate_amMethod;// '<Root>/Unit Delay1'
    };

    // External inputs (root inport signals with default storage)
    struct ExtU {
      float InScalar_dvPrivate_amMethod;// '<Root>/InScalar_dvPrivate_amMethod'
      float InArray_dvPrivate_amMethod[2];// '<Root>/InArray_dvPrivate_amMethod' 
      myBus InBus_dvPrivate_amMethod;  // '<Root>/InBus_dvPrivate_amMethod'
      int16_t InBusElm_dvPrivate_amMethod_Fxp;
                               // '<Root>/InBusElm_dvPrivate_amMethod_FxptSig1'
      int16_t InBusElm_dvPrivate_amMethod_F_p;
                               // '<Root>/InBusElm_dvPrivate_amMethod_FxptSig2'
      int16_t InBusElm_dvPrivate_amMethod1_Fx;
                              // '<Root>/InBusElm_dvPrivate_amMethod1_FxptSig1'
      int16_t InBusElm_dvPrivate_amMethod1__p;
                              // '<Root>/InBusElm_dvPrivate_amMethod1_FxptSig2'
    };

    // External outputs (root outports fed by signals with default storage)
    struct ExtY {
      float OutScalar_dvPrivate_amMethod;// '<Root>/OutScalar_dvPrivate_amMethod' 
      float OutArray_dvPrivate_amMethod[2];// '<Root>/OutArray_dvPrivate_amMethod' 
      myBus OutBus_dvPrivate_amMethod; // '<Root>/OutBus_dvPrivate_amMethod'
      int16_t OutBusElm_dvPrivate_amMethod_Fx;
                              // '<Root>/OutBusElm_dvPrivate_amMethod_FxptSig1'
      int16_t OutBusElm_dvPrivate_amMethod__p;
                              // '<Root>/OutBusElm_dvPrivate_amMethod_FxptSig2'
      int16_t OutBusElm_dvPrivate_amMethod1_p;
                             // '<Root>/OutBusElm_dvPrivate_amMethod1_FxptSig1'
      int16_t OutBusElm_dvPrivate_amMethod1_F;
                             // '<Root>/OutBusElm_dvPrivate_amMethod1_FxptSig2'
    };

    // Parameters (default storage)
    struct P {
      float ParamArray[2];             // Variable: ParamArray
                                          //  Referenced by: '<Root>/Gain1'

      float ParamScalar;               // Variable: ParamScalar
                                          //  Referenced by: '<Root>/Gain'

      float UnitDelay_InitialCondition;
                               // Computed Parameter: UnitDelay_InitialCondition
                                  //  Referenced by: '<Root>/Unit Delay'

      float UnitDelay1_InitialCondition;
                              // Computed Parameter: UnitDelay1_InitialCondition
                                 //  Referenced by: '<Root>/Unit Delay1'

    };

    // Copy Constructor
    signal_dvPrivate_acMethod(signal_dvPrivate_acMethod const&) = delete;

    // Assignment Operator
    signal_dvPrivate_acMethod& operator= (signal_dvPrivate_acMethod const&) & =
      delete;

    // Move Constructor
    signal_dvPrivate_acMethod(signal_dvPrivate_acMethod &&) = delete;

    // Move Assignment Operator
    signal_dvPrivate_acMethod& operator= (signal_dvPrivate_acMethod &&) = delete;

    // Root inport: '<Root>/InScalar_dvPrivate_amMethod' set method
    void setInScalar_dvPrivate_amMethod(float localArgInput);

    // Root inport: '<Root>/InArray_dvPrivate_amMethod' set method
    void setInArray_dvPrivate_amMethod(float localArgInput[2]);

    // Root inport: '<Root>/InBus_dvPrivate_amMethod' set method
    void setInBus_dvPrivate_amMethod(myBus localArgInput);

    // Root inport: '<Root>/InBusElm_dvPrivate_amMethod_FxptSig1' set method
    void setInBusElm_dvPrivate_amMethod_FxptSig1(int16_t localArgInput);

    // Root inport: '<Root>/InBusElm_dvPrivate_amMethod1_FxptSig2' set method
    void setInBusElm_dvPrivate_amMethod1_FxptSig2(int16_t localArgInput);

    // Root outport: '<Root>/OutScalar_dvPrivate_amMethod' get method
    float getOutScalar_dvPrivate_amMethod() const;

    // Root outport: '<Root>/OutArray_dvPrivate_amMethod' get method
    const float *getOutArray_dvPrivate_amMethod() const;

    // Root outport: '<Root>/OutBus_dvPrivate_amMethod' get method
    myBus getOutBus_dvPrivate_amMethod() const;

    // Root outport: '<Root>/OutBusElm_dvPrivate_amMethod_FxptSig1' get method
    int16_t getOutBusElm_dvPrivate_amMethod_FxptSig1() const;

    // Root outport: '<Root>/OutBusElm_dvPrivate_amMethod1_FxptSig2' get method
    int16_t getOutBusElm_dvPrivate_amMethod1_FxptSig2() const;

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

    // Constructor
    signal_dvPrivate_acMethod();

    // Destructor
    ~signal_dvPrivate_acMethod();

    // private data and function members
   private:
    // External inputs
    ExtU rtU;

    // External outputs
    ExtY rtY;

    // Block states
    DW rtDW;

    // Tunable parameters
    static P rtP;
  };
}

//-
//  These blocks were eliminated from the model due to optimizations:
//
//  Block '<Root>/Signal Copy3' : Eliminate redundant signal conversion block
//  Block '<Root>/Signal Copy4' : Eliminate redundant signal conversion block
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
//  '<Root>' : 'signal_dvPrivate_acMethod'


//-
//  Requirements for '<Root>': signal_dvPrivate_acMethod


#endif                                 // signal_dvPrivate_acMethod_h_

//
// File trailer for generated code.
//
// [EOF]
//
